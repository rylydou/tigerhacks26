extends Node

func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/ryly_test.tscn")

func quit_game() -> void:
	get_tree().quit()
