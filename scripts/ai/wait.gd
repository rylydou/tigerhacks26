class_name Wait extends Step


@export var duration := 0.0
@export var duration_max := 0.0


var timer := 0.0


func _start() -> int:
	if duration_max > 0.0:
		timer = randf_range(duration, duration_max)
	else:
		timer = duration
	
	# If timer is 0 then wait 1 tick. If it is less than zero then move on now!
	if timer < 0.0:
		return DONE
	
	return CONTINUE


func _tick(delta: float) -> int:
	timer -= delta
	if timer > 0.0:
		return CONTINUE
	return DONE
