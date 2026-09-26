class_name AngleStrafe extends Step


func _start() -> int:
	enemy.angle += (PI / 2.0) * Math.rand_sign()
	return DONE
