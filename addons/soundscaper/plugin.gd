@tool
extends EditorPlugin


var sound_event_inspector: EditorInspectorPlugin
# var editor_panel_instance: Control


func _enter_tree():
	reload(false)
	
	add_tool_menu_item("Reload Soundscaper", reload.bind(false))


func _exit_tree():
	reload(true)


func reload(remove_only: bool) -> void:
	#remove_autoload_singleton("SFX")
	
	# remove custom inspector
	if is_instance_valid(sound_event_inspector):
		remove_inspector_plugin(sound_event_inspector)
		sound_event_inspector = null
	if remove_only: return
	
	# register settings
	SoundscaperSettings.register_settings()
	# add signleton
	add_autoload_singleton("SFX", "res://addons/soundscaper/scripts/sfx.gd")
	sound_event_inspector = load("res://addons/soundscaper/scripts/inspector/sound_event_inspector.gd").new()
	add_inspector_plugin(sound_event_inspector)
