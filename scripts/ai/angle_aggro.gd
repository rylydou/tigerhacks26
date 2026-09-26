class_name AngleAggro extends Step


func _start() -> int:
	if is_instance_valid(enemy.aggro):
		enemy.angle = enemy.global_position.angle_to_point(enemy.aggro.global_position)
		return DONE
	
	if randf() < 1.0 / 60.0:
		enemy.angle = randf_range(0, TAU)
	
	return DONE
