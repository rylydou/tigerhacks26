extends Node


@export var move_speed:= 2.0
@export var proj_range := 5.0


var distance_traveled := 0.0


func _physics_process(delta: float) -> void:
	owner.global_position += owner.global_transform.basis_xform(Vector2.RIGHT) * move_speed * 16.0 * delta
	distance_traveled += move_speed * 16.0 * delta
	if distance_traveled > proj_range * 16.0:
		owner.queue_free()
