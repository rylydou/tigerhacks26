class_name Player extends CharacterBody2D


static var instance: Player


signal dealt_damage_to_enemy(damage: int)


@export var health := 100
@onready var max_health := health

@export var move_speed := 4.0

@export var fire_rate := 2.0
var shoot_cooldown := 0.0


@export var bullet_scene: PackedScene
@export var cursor_node: Node2D


var gamepad := Gamepad.create(Gamepad.DEVICE_AUTO)

var angle := 0.0
var use_mouse_aim := false


func _enter_tree() -> void:
	Player.instance = self


func _process(delta: float) -> void:
	gamepad.poll(delta)


func _physics_process(delta: float) -> void:
	_process_movement(delta)
	
	shoot_cooldown -= delta
	if gamepad.attack.down:
		if shoot_cooldown <= 0.0:
			# Perform attack logic here
			shoot_cooldown = 1.0 / fire_rate
			shoot()


func _process_movement(delta: float) -> void:
	var move_input := gamepad.move.normalized()
	
	if gamepad.is_mouse_and_keyboard():
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			use_mouse_aim = true
			# Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
			# cursor_node.show()
		elif gamepad.aim_only != Vector2.ZERO:
			use_mouse_aim = false
			# Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			# cursor_node.hide()
	
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
	
	var speed := move_speed
	velocity = move_input * speed * 16.0
	move_and_slide()


func shoot() -> void:
	if not bullet_scene: return
	var bullet_instance: BasicProjectile = bullet_scene.instantiate()
	bullet_instance.global_position = global_position
	bullet_instance.rotation = angle
	bullet_instance.player = self
	get_tree().current_scene.add_child(bullet_instance)


func try_attack(target: Node2D, damage: int, knockback_strength: float) -> bool:
	if not target.has_method(Hurtbox.METHOD_NAME): return false
	
	var floating_damange := damage
	var real_damage := floori(floating_damange)
	real_damage += int(Math.rand_bool(floating_damange - real_damage))
	
	var real_knockback := knockback_strength
	
	# if real_damage > 0:
	# 	VFX.damage_number(
	# 			target.global_position - Vector2(
	# 					randf_range(-8, 8),
	# 					24.0 + randf_range(-2, 2)
	# 			),
	# 			real_damage,
	# 			crit,
	# 	)
	
	var knockback_vector := global_position.direction_to(target.global_position) * knockback_strength
	
	var did_hit: bool = target.call(Hurtbox.METHOD_NAME, real_damage, knockback_vector)
	if did_hit:
		dealt_damage_to_enemy.emit(int(real_damage))
	
	return did_hit


func take_damage(damage: int, knockback: Vector2) -> bool:
	# Apply damage to the player's health
	health -= damage
	
	# Apply knockback to the player
	velocity += knockback
	
	# Check if the player is dead
	if health <= 0:
		die()
	
	return true


func die() -> void:
	health = max_health
	velocity = Vector2.ZERO
