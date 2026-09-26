class_name WaitUntilGrounded extends Step


func _start() -> int:
	return check()


func _tick(delta: float) -> int:
	return check()


func check() -> int:
	if enemy.height <= 0.0 and enemy.height_velocity <= 0.0:
		return DONE
	else:
		return CONTINUE
