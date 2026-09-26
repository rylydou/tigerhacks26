class_name InfLoop extends Group


func _tick(delta: float) -> int:
	var code := super._tick(delta)
	if code == DONE:
		super._start()
	return CONTINUE
