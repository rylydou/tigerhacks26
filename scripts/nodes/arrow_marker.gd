@tool
class_name ArrowMarker2D extends Node2D


@export var length := 8.0:
	set(value):
		length = value
		queue_redraw()

@export var color := Color(0.96, 0.20, 0.32):
	set(value):
		color = value
		queue_redraw()


func _enter_tree() -> void:
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint(): return
	if get_tree().edited_scene_root.scene_file_path != owner.scene_file_path: return
	
	var end_point := Vector2.RIGHT * length
	var head_size := maxf(absf(length) * 0.125, 1.0)
	
	draw_line(Vector2.ZERO, end_point, color)
	draw_line(end_point, end_point + Vector2(-head_size, -head_size), color)
	draw_line(end_point, end_point + Vector2(-head_size, +head_size), color)
