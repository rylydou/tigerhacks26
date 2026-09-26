class_name Random extends Group


@export var numerator := 1
@export var denominator := 1


func _start() -> int:
	if randi_range(1, denominator) > numerator:
		return DONE
	return super._start()
