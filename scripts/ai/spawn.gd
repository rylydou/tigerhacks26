class_name Spawn extends Step


@export var spread := 0.0
@export var scene: PackedScene
@export var spawn_marker: Marker2D


func _start() -> int:
	spawn()
	return DONE


func spawn() -> void:
	var obj: Node2D = scene.instantiate()
	obj.add_to_group(Global.DESPAWN_GROUP)
	obj.global_transform = spawn_marker.global_transform
	obj.global_rotation += deg_to_rad(randf_range(spread / -2.0, spread / +2.0))
	get_tree().current_scene.add_child.call_deferred(obj)
