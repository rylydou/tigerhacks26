class_name Jump extends Step


@export var force := 0.0
@export var additive := false


func _start() -> int:
	if additive:
		enemy.height_velocity += force
	else:
		enemy.height_velocity = force
	return DONE
