class_name ObjectivePointer extends Node2D
## Points toward the nearest node in the objective group, ignoring the parent's rotation/flip.
## Hidden when there are no objectives.


func _process(_delta: float) -> void:
	var origin := (get_parent() as Node2D).global_position
	var nearest: Node2D = null
	var nearest_dist := INF
	for node in get_tree().get_nodes_in_group(GameLoop.OBJECTIVE_GROUP):
		if not node is Node2D: continue
		var dist := origin.distance_squared_to((node as Node2D).global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = node
	
	visible = nearest != null
	if not nearest: return
	global_transform = Transform2D(origin.angle_to_point(nearest.global_position), origin)

