class_name Projectile extends Hitbox


signal impacted()
signal destroyed_from_collision()
signal destroyed_from_range()


@export var microsteps_per_frame := 1
@export var blocked_on_wall := true

@export var pierce_count := 0


@onready var _previous_position := position

@onready var raycast := RayCast2D.new()


var age := 0.0
var is_dead := false


func _ready() -> void:
	add_child(raycast)
	raycast.top_level = true
	raycast.collision_mask = 0
	raycast.enabled = false
	if blocked_on_wall:
		raycast.set_collision_mask_value(2, true)
	
	pierce_count = 1
	
	attack_overlap()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var saved_position := position
	
	for microstep in microsteps_per_frame:
		var micro_delta := delta / microsteps_per_frame
		do_step(micro_delta)
		attack_overlap()
		if is_dead:
			return
	
	if blocked_on_wall and position.is_equal_approx(saved_position):
		raycast.position = saved_position
		raycast.target_position = position
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			global_position = raycast.get_collision_point()
			destroy(true)
	
	_previous_position = position


func do_step(delta: float) -> void:
	age += delta
	var continue_running := _step(delta)
	
	if not continue_running:
		print("die eol")
		die()


## Return false when the projectile should stop die
func _step(delta: float) -> bool:
	return true


func _on_attacked(node: Node2D) -> void:
	if is_dead: return
	
	pierce_count -= 1
	if pierce_count < 0:
		print("die from attack")
		destroy(true)


func die() -> void:
	destroy(false)


func destroy(from_collision: bool) -> void:
	if is_dead: return
	is_dead = true
	
	auto_attack = false
	
	if from_collision:
		destroyed_from_collision.emit()
	else:
		destroyed_from_range.emit()
	queue_free()
