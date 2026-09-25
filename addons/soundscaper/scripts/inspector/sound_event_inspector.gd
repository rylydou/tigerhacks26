@tool
extends EditorInspectorPlugin

const Toolbar: Script = preload("res://addons/soundscaper/scripts/toolbar.gd")


const TOOLBAR_SCENE: PackedScene = preload("res://addons/soundscaper/scenes/toolbar.tscn")


var toolbar: Toolbar


func _can_handle(object: Object) -> bool:
	if object is SoundEvent: return true
	return false


func _parse_begin(object: Object) -> void:
	if is_instance_valid(toolbar):
		toolbar.queue_free()
	
	if object is SoundEvent:
		toolbar = TOOLBAR_SCENE.instantiate()
		toolbar.sound_event = object
		add_custom_control(toolbar)
