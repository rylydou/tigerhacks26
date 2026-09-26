class_name Cooldown extends Group


@export var time := 0.0


var timer := 0.0



func _start() -> int:
	if timer > 0.0: return DONE
	timer = time
	return super._start()


func _physics_process(delta: float) -> void:
	timer = move_toward(timer, 0.0, delta)
