@tool
extends Node


@export var target: Node
@export var style_box_name := &""
@export var theme_type := &"EditorStyles"

@export var margin_left := -1
@export var margin_top := -1
@export var margin_right := -1
@export var margin_bottom := -1


func _ready() -> void:
	if is_part_of_edited_scene(): return
	
	update_styles()
	get_window().theme_changed.connect(update_styles)


func update_styles() -> void:
	var target := self.target
	
	if not target:
		target = get_parent()
	
	var style_box := EditorInterface.get_editor_theme().get_stylebox(style_box_name, theme_type).duplicate()
	
	if margin_left >= 0:
		style_box.content_margin_left = margin_left
	if margin_top >= 0:
		style_box.content_margin_top = margin_top
	if margin_right >= 0:
		style_box.content_margin_right = margin_right
	if margin_bottom >= 0:
		style_box.content_margin_bottom = margin_bottom
	
	target.add_theme_stylebox_override(&"panel", style_box)
