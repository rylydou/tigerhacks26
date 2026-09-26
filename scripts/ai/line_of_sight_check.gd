class_name LineOfSightCheck extends Group


@export var invert := false


func _start() -> int:
	if not is_instance_valid(enemy.aggro): return DONE
	
	var distance_to_aggro := enemy.global_position.distance_squared_to(enemy.aggro.global_position)
	
	if enemy.has_line_of_sight != invert:
		return super._start()
	
	return DONE
