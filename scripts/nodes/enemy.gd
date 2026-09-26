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
	
	#if damage > 0:
	#	SFX.play(&'hit_enemy', global_position).volume_db = 5.0
	
	health -= damage
	knockback_velocity += knockback
	flash()
	damage_taken.emit()
	if health <= 0:
		die()
	return true


func die() -> void:
	#SFX.play(&'death_enemy', global_position).volume_db = 0.0
	#VFX.poof(global_position)
	died.emit()
	queue_free()


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
	return
	# if not is_instance_valid(Map.room): return
	# if not is_instance_valid(aggro): return
	# id_path = Map.room.data.nav.get_id_path(Map.room.to_tile(global_position), Map.room.to_tile(aggro.global_position))
	# nav_update_timer = nav_update_cooldown


func update_move_angle() -> void:
	move_angle = nav_angle()


func nav_angle() -> float:
	return global_position.angle_to_point(aggro.global_position)
	
	# if (
	# 	not is_instance_valid(Map.room) or
	# 	is_instance_valid(aggro) and (
	# 		ignore_nav or
	# 		has_line_of_sight
	# )):
	# 	return global_position.angle_to_point(aggro.global_position)
	
	# if not id_path or id_path.is_empty() or nav_update_timer <= 0.0:
	# 	update_nav()
	
	# if not id_path or id_path.is_empty():
	# 	update_nav()
	# 	die()
	# 	return angle
	
	# var my_id := Map.room.to_tile(global_position)
	
	# var closest_id: Vector2i = id_path.back()
	# var closest_id_dist_sqr := INF
	# for index in id_path.size():
	# 	var id := id_path[index]
	# 	if my_id == id:
	# 		if index >= id_path.size() - 1: return angle
	# 		var next_id := id_path[index + 1]
	# 		return Vector2(my_id).angle_to_point(next_id)
		
	# 	var distance_sqr := (my_id - id).length_squared()
	# 	if distance_sqr <= closest_id_dist_sqr:
	# 		closest_id_dist_sqr = distance_sqr
	# 		closest_id = id
	
	# return Vector2(my_id).angle_to_point(closest_id)
