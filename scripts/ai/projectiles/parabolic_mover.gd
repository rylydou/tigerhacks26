extends Node


@export var move_speed:= 2.0
@export var up_speed := 1.0
@export var down_acceleration := 1.0
@export var proj_range := 5.0


@onready var current_up_speed := up_speed


var distance_traveled := 0.0


func _physics_process(delta: float) -> void:
	owner.global_position += owner.global_transform.basis_xform(Vector2.RIGHT) * move_speed * 16 * delta
	owner.global_position += Vector2(0, -abs(cos(owner.global_rotation)) * current_up_speed * 16 * delta)
	distance_traveled += move_speed * 16 * delta
	current_up_speed -= down_acceleration * delta
	if distance_traveled > proj_range * 16:
		owner.queue_free()
