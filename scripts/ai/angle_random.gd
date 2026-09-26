class_name AngleRandom extends Step


func _start() -> int:
	enemy.angle = randf_range(0, TAU)
	return DONE
