@tool
extends Node


@export var target: Control
@export var target_prop := &""
@export var target_style := &""
@export var color_name := &""
@export var theme_type := &""


func _ready() -> void:
	if is_part_of_edited_scene(): return
	
	update_styles()
	get_window().theme_changed.connect(update_styles)


func update_styles() -> void:
	var target := self.target
	
	if not target:
		target = get_parent()
	
	var color := EditorInterface.get_editor_theme().get_color(color_name, theme_type)
	if target_style:
		target.add_theme_color_override(target_prop, color)
	
	if target_prop:
		target.set(target_prop, color)
