@tool
class_name IconMarker extends Node2D


@export var icon: Texture2D:
	set(value):
		icon = value
		queue_redraw()

@export var origin := Vector2.ONE / 2.0:
	set(value):
		origin = value
		queue_redraw()


func _enter_tree() -> void:
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint(): return
	if not is_instance_valid(icon): return
	if get_tree().edited_scene_root.scene_file_path != owner.scene_file_path: return
	
	draw_texture_rect(icon, Rect2(-icon.get_size() * origin, icon.get_size()), false, Color(1.0, 1.0, 1.0, 0.5))
