class_name Repeat extends Group


@export var count := 1
@export var count_max := 0


var counter := 0


func _start() -> int:
	if count_max > 0:
		counter = randi_range(count, count_max)
	else:
		counter = count
	
	return iterate()


func _tick(delta: float) -> int:
	var code := super._tick(delta)
	if code == DONE:
		return iterate()
	return CONTINUE


func iterate() -> int:
	for i in 50:
		counter -= 1
		if counter < 0:
			return DONE
		var code := super._start()
		if code == CONTINUE: return CONTINUE
	assert(not OS.is_debug_build(), "Oops!")
	return DONE
