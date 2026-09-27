extends Node


@export var pause_menu: Control


var waves: Array[Wave] = []

func resume_game() -> void:
	get_tree().paused = not get_tree().paused
	pause_menu.hide()

func quit_game() -> void:
	get_tree().quit()

func _ready() -> void:
	waves = load_waves("res://resources/waves.csv")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"pause"):
		get_tree().paused = not get_tree().paused
		pause_menu.visible = get_tree().paused


func load_waves(path: String) -> Array[Wave]:
	var waves: Array[Wave] = []
	var file := FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() == 0: continue
		if line[0].begins_with("#"): continue
		var wave := Wave.from_csv_line(line)
		if not wave: continue
		for i in wave.weight:
			waves.append(wave)
	
	return waves
