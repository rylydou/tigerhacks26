class_name Player extends Actor


static var instance: Player


signal dealt_damage_to_enemy(damage: int)
signal died

## Emitted right before a bullet is added to the scene, so upgrades can modify it.
signal shot(bullet: BasicProjectile)
signal hit_target(target: Node2D, damage: int)
signal killed_enemy(enemy: Enemy)
## Emitted after an upgrade is taken or leveled up.
signal upgrades_changed


@export var health := 100
@onready var base_max_health := health
var max_health: int:
	get:
		return roundi(stat_max_health.compute(base_max_health, {}))

@export var move_speed := 4.0

@export var fire_rate := 2.0
var shoot_cooldown := 0.0


@export var bullet_scene: PackedScene
@export var cursor_node: Node2D
@export var shoot_pos_node: Node2D


var gamepad := Gamepad.create(Gamepad.DEVICE_AUTO)

var use_mouse_aim := false

## Seconds since the player last had movement input
var still_time := 0.0
## Fractional healing carried over between `heal()` calls
var heal_remainder := 0.0

var upgrades: Array[Upgrade] = []


# --- STATS ---
# Each stat is computed from the raw value and returns the final value (see Stat).
var stat_move_speed := Stat.new()
var stat_max_health := Stat.new()
var stat_healing := Stat.new()
var stat_damage_taken := Stat.new()
var stat_hit_invuln_time := Stat.new()

## ctx: target, distance (in Global.UNIT_SCALE), source (the hitbox, may be null)

var stat_attack_damage_scale := Stat.new()
## ctx: same as stat_attack_damage_scale
var stat_knockback_scale := Stat.new()
var stat_attack_speed_scale := Stat.new()
var stat_attack_size_scale := Stat.new()
var stat_spread_scale := Stat.new()
var stat_proj_speed_scale := Stat.new()
var stat_proj_range_scale := Stat.new()
var stat_proj_pierce := Stat.new()


func _enter_tree() -> void:
	Player.instance = self


func _process(delta: float) -> void:
	gamepad.poll(delta)


func _physics_process(delta: float) -> void:
	_process_movement(delta)
	
	still_time = 0.0 if is_moving() else still_time + delta
	
	shoot_cooldown -= delta
	if is_shooting():
		if shoot_cooldown <= 0.0:
			# Perform attack logic here
			shoot_cooldown = 1.0 / stat_attack_speed_scale.compute(fire_rate, {})
			shoot()
	
	for upgrade in upgrades:
		upgrade._tick(delta)
	
	super._physics_process(delta)


func _process_movement(delta: float) -> void:
	var move_input := gamepad.move.normalized()
	input = move_input
	
	if gamepad.is_mouse_and_keyboard():
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			use_mouse_aim = true
			# Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
			# cursor_node.show()
		elif gamepad.aim_only != Vector2.ZERO:
			use_mouse_aim = false
			# Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			# cursor_node.hide()
	else:
		use_mouse_aim = false
	
	var aim_input := Vector2.ZERO
	if use_mouse_aim:
		# if Input.is_action_just_pressed("ui_cancel"):
		# 	use_mouse_aim = false
		# 	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# 	cursor_node.hide()
		var mouse_pos := get_global_mouse_position()
		# cursor_node.position = mouse_pos
		
		aim_input = global_position.direction_to(mouse_pos)
		gamepad.aim_only = aim_input
		gamepad.aim = aim_input
	else:
		aim_input = gamepad.aim
	
	if aim_input != Vector2.ZERO:
		angle = aim_input.angle()
	
	var speed := stat_move_speed.compute(move_speed, {})
	velocity = move_input * speed * Global.UNIT_SCALE
	move_and_slide()


func shoot() -> void:
	if not bullet_scene: return
	var bullet_instance: BasicProjectile = bullet_scene.instantiate()
	bullet_instance.global_position = shoot_pos_node.global_position
	bullet_instance.rotation = shoot_pos_node.global_rotation
	bullet_instance.player = self
	
	var ctx := {}
	bullet_instance.speed = stat_proj_speed_scale.compute(bullet_instance.speed, ctx)
	bullet_instance.range = stat_proj_range_scale.compute(bullet_instance.range, ctx)
	bullet_instance.pierce_count = roundi(stat_proj_pierce.compute(bullet_instance.pierce_count, ctx))
	bullet_instance.scale *= stat_attack_size_scale.compute(1.0, ctx)
	
	shot.emit(bullet_instance)
	get_tree().current_scene.add_child(bullet_instance)
	SFX.event(&"player_shoot").at(global_position).play()


func try_attack(target: Node2D, damage: float, knockback_strength: float, source: Node = null) -> bool:
	if not target.has_method(Hurtbox.METHOD_NAME): return false
	
	var ctx := {
		'target': target,
		'distance': global_position.distance_to(target.global_position) / Global.UNIT_SCALE,
		'source': source,
	}
	
	var floating_damange := stat_attack_damage_scale.compute(damage, ctx)
	var real_damage := floori(floating_damange)
	real_damage += int(Math.rand_bool(floating_damange - real_damage))
	
	var real_knockback := stat_knockback_scale.compute(knockback_strength, ctx)
	
	# if real_damage > 0:
	# 	VFX.damage_number(
	# 			target.global_position - Vector2(
	# 					randf_range(-8, 8),
	# 					24.0 + randf_range(-2, 2)
	# 			),
	# 			real_damage,
	# 			crit,
	# 	)
	
	var knockback_vector := global_position.direction_to(target.global_position) * real_knockback
	
	var did_hit: bool = target.call(Hurtbox.METHOD_NAME, real_damage, knockback_vector)
	if did_hit:
		dealt_damage_to_enemy.emit(int(real_damage))
		hit_target.emit(target, real_damage)
		if target is Enemy and (target as Enemy).dying:
			killed_enemy.emit(target)
	
	return did_hit


func take_damage(damage: int, knockback: Vector2) -> bool:
	SFX.event(&"player_hit").at(global_position).play()
	
	# Apply damage to the player's health
	health -= roundi(stat_damage_taken.compute(damage, {}))
	
	# Apply knockback to the player
	velocity += knockback
	
	# Check if the player is dead
	if health <= 0:
		die()
	
	return true


func die() -> void:
	SFX.event(&"player_death").at(global_position).play()
	health = max_health
	velocity = Vector2.ZERO
	died.emit()


func heal(amount: float) -> void:
	if amount <= 0.0 or health <= 0: return
	if health >= max_health:
		heal_remainder = 0.0
		return
	
	heal_remainder += stat_healing.compute(amount, {})
	var whole := floori(heal_remainder)
	heal_remainder -= whole
	health = mini(health + whole, max_health)


func is_moving() -> bool:
	return input != Vector2.ZERO


func is_shooting() -> bool:
	return gamepad.attack.down


func get_upgrade(script: Script) -> Upgrade:
	for upgrade in upgrades:
		if upgrade.get_script() == script:
			return upgrade
	return null


## Takes the upgrade, or levels it up if the player already has it.
func add_upgrade(script: Script) -> Upgrade:
	var upgrade := get_upgrade(script)
	if not upgrade:
		upgrade = script.new()
		upgrade.player = self
		upgrades.append(upgrade)
	upgrade._upgrade()
	upgrades_changed.emit()
	return upgrade
