class_name Enemy extends Actor


enum WeightClass {
	Light,
	Heavy,
	Immobile,
}


signal damage_taken()
signal died()


@export var max_health := 100
@onready var health := max_health

@export var weight_class := WeightClass.Light
@export var no_ai := false
@export var stun_scale := 1.0
@export var immune_in_air := false
@export var ignore_nav := false
@export var nav_update_cooldown := 1.0

@export_group("Death")
@export var death_launch_height := 8.0
@export var death_launch_speed := 9.0
@export var death_spin_speed := 12.0
@export var death_fade_time := 0.12
@export var death_ground_friction := 40.0


@onready var ai: Step = %"AI"
var ai_init := false

@onready var los_raycast := RayCast2D.new()


var aggro: Player
var has_line_of_sight := false

var id_path: Array[Vector2i]
var move_angle := 0.0
var nav_update_timer := 0.0 

var stun_timer := 0.0
var flash_timer := 0.0
var knockback_velocity := Vector2.ZERO

var dying := false
var death_velocity := Vector2.ZERO
var death_spin := 0.0


func _ready() -> void:
	#material = material.duplicate()
	rotation = 0.0
	
	add_to_group(Global.ENEMY_GROUP)
	ai.propagate_call(&'set_enemy', [self], true)
	
	los_raycast.collision_mask = 0
	los_raycast.set_collision_mask_value(2, true)
	los_raycast.set_collision_mask_value(3, true)
	
	add_child(los_raycast)


func _physics_process(delta: float) -> void:
	if dying:
		_process_death(delta)
		return
	if health <= 0: return
	
	super._physics_process(delta)
	
	if is_instance_valid(aggro):
		los_raycast.target_position = to_local(aggro.global_position)
		has_line_of_sight = not los_raycast.is_colliding()
	else:
		has_line_of_sight = false
	
	nav_update_timer -= delta
	
	stun_timer -= delta
	flash_timer -= delta
	
	var flash_alpha := 0.0
	var flash_shake := 0.0
	if stun_timer > 0:
		flash_alpha = abs(sin(age * TAU * 4)) * 0.25
		flash_shake = sin(age * TAU * 16) * 0.5
	if flash_timer > 0:
		flash_alpha = 1.0
		flash_shake = 0.0
	material.set_shader_parameter(&'flash_color', Color(1.0, 1.0, 1.0, flash_alpha))
	sprite.position.x = flash_shake
	
	if stun_timer <= 0.0 and not no_ai:
		if ai_init:
			ai._tick(delta)
		else:
			ai_init = true
			ai._start()
	
	_process_knockback(delta)


func _process_knockback(delta: float) -> void:
	if weight_class == WeightClass.Immobile: return
	
	var saved_velocity := velocity
	velocity = knockback_velocity * 16.0
	move_and_slide()
	velocity = saved_velocity
	
	var weight := 20.0
	match weight_class:
		WeightClass.Light:
			weight = 20.0
		WeightClass.Heavy:
			weight = 64.0
	
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, weight * delta)


func take_damage(damage: int, knockback: Vector2) -> bool:
	if health <= 0: return false
	if immune_in_air and height > 0.0: return false
	
	if damage > 0:
		SFX.event(&"enemy_hit").at(global_position).play()
	
	health -= damage
	knockback_velocity += knockback
	flash()
	damage_taken.emit()
	if health <= 0:
		die(knockback)
	return true


func die(knockback := Vector2.ZERO) -> void:
	if dying: return
	dying = true
	health = mini(health, 0)
	SFX.event(&"enemy_death").at(global_position).play()
	
	# Go completely inert
	remove_from_group(Global.ENEMY_GROUP)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	stun_timer = 0.0
	los_raycast.enabled = false
	ai.process_mode = Node.PROCESS_MODE_DISABLED
	_disable_areas(self)
	
	var health_bar := anchor_node.get_node_or_null(^"Health Bar") as CanvasItem
	if health_bar: health_bar.hide()
	
	# Gray out
	flash_timer = 0.0
	sprite.position.x = 0.0
	material.set_shader_parameter(&'flash_color', Color(1.0, 1.0, 1.0, 0.0))
	material.set_shader_parameter(&'desaturate', 1.0)
	
	# Launch up and back along the killing hit
	var direction := knockback.normalized()
	if direction == Vector2.ZERO and is_instance_valid(aggro):
		direction = aggro.global_position.direction_to(global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.from_angle(randf() * TAU)
	death_velocity = direction * death_launch_speed
	death_spin = death_spin_speed * (1.0 if direction.x >= 0.0 else -1.0)
	height_velocity = death_launch_height
	height = maxf(height, 0.01)
	landed.connect(_on_death_landed, CONNECT_ONE_SHOT)
	
	died.emit()


func _process_death(delta: float) -> void:
	super._physics_process(delta)
	global_position += death_velocity * 16.0 * delta
	flip_node.rotation += death_spin * delta
	if height <= 0.0:
		death_velocity = death_velocity.move_toward(Vector2.ZERO, death_ground_friction * delta)
		death_spin = move_toward(death_spin, 0.0, death_spin_speed * 4.0 * delta)


func _on_death_landed() -> void:
	#VFX.poof(global_position)
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, death_fade_time)
	tween.tween_callback(queue_free)


func _disable_areas(node: Node) -> void:
	for child in node.get_children():
		if child is Hurtbox:
			child.active = false
		if child is Area2D:
			child.set_deferred(&"monitoring", false)
			child.set_deferred(&"monitorable", false)
		if child is CollisionObject2D:
			child.collision_layer = 0
			child.collision_mask = 0
		_disable_areas(child)


func stun(time: float) -> void:
	time *= stun_scale
	if time < stun_timer: return
	if height > 0.0: return
	stun_timer = time
	flash()


func flash() -> void:
	flash_timer = 4 / 60.0
	material.set_shader_parameter(&'flash_color', Color.WHITE)


func set_aggro(player: Player) -> void:
	self.aggro = player


func update_nav() -> void:
	nav_update_timer = nav_update_cooldown
	var level := LevelGenerator.current
	if not level or not is_instance_valid(aggro):
		id_path = []
		return
	id_path = level.get_id_path(global_position, aggro.global_position)


func update_move_angle() -> void:
	move_angle = nav_angle()


func nav_angle() -> float:
	var direct := global_position.angle_to_point(aggro.global_position)
	var level := LevelGenerator.current
	if not level or ignore_nav or has_line_of_sight:
		return direct

	if id_path.is_empty() or nav_update_timer <= 0.0:
		update_nav()
	if id_path.is_empty():
		return direct

	# Head toward the path tile after the one we're on, or the closest tile if we've drifted off.
	var my_id := level.to_tile(global_position)
	var target_index := id_path.size() - 1
	var closest_dist_sqr := INF
	for index in id_path.size():
		if id_path[index] == my_id:
			target_index = mini(index + 1, id_path.size() - 1)
			break
		var dist_sqr := (my_id - id_path[index]).length_squared()
		if dist_sqr < closest_dist_sqr:
			closest_dist_sqr = dist_sqr
			target_index = index

	return global_position.angle_to_point(level.to_world(id_path[target_index]))
