extends Node

func _ready() -> void:
	if OS.has_feature("web"):
		$"CanvasLayer/Main Menu/Button Container/Quit Button".hide()

func start_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ryly_test.tscn")

func quit_game() -> void:
	get_tree().quit()
