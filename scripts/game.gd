extends Node


@export var pause_menu: Control


func _process(delta: float) -> void:
	if Input.is_action_pressed(&"pause"):
		get_tree().paused = not get_tree().paused
		pause_menu.visible = get_tree().paused
