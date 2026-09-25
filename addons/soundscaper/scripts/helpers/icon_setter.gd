@tool
extends Node


@export var target: Node
@export var icon_name := &""
@export var icon: Texture2D


func _ready() -> void:
	if is_part_of_edited_scene(): return
	
	update_styles()
	get_window().theme_changed.connect(update_styles)


func update_styles() -> void:
	var target := self.target
	
	if not target:
		target = get_parent()
	
	var icon := self.icon
	
	if not icon:
		icon = EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons")
	
	if target is Button:
		target.icon = icon
		return
	
	if target is TabContainer:
		target.set_tab_icon(get_parent().get_index(), icon)
		return
	
