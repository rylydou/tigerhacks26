class_name GameLoop extends Node2D
## Generate level -> play until every `objective` is dead -> win screen -> pick upgrade -> repeat.
## Player death returns to the main (title) scene.

enum State { GENERATING, PLAYING, WON, CHOOSING_UPGRADE }

const OBJECTIVE_GROUP := &"objective"

@export var level_generator: LevelGenerator
@export var player: Player

@export_group("Win Screen")
## Shown when a level is cleared. Set its process_mode to Always so it animates while paused.
@export var win_screen: Control
## Optional. Played when the win screen opens; the loop waits for it to finish.
@export var win_animation_player: AnimationPlayer
@export var win_animation := &"win"

@export_group("Upgrades")
## Shown after the win animation. Set its process_mode to Always.
@export var upgrade_screen: Control
## One button per upgrade choice (placeholder: just labeled, picking does nothing yet).
@export var upgrade_buttons: Array[Button] = []

var state := State.GENERATING
var level := 0

signal upgrade_picked(index: int)


func _ready() -> void:
	# Keep running while the tree is paused on the win/upgrade screens.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not level_generator:
		level_generator = LevelGenerator.current
	if not player:
		player = Player.instance
	player.died.connect(_on_player_died)
	for i in upgrade_buttons.size():
		upgrade_buttons[i].pressed.connect(func() -> void: upgrade_picked.emit(i))
	_hide_ui()
	_start_level.call_deferred()


func _process(_delta: float) -> void:
	if state == State.PLAYING and get_tree().get_nodes_in_group(OBJECTIVE_GROUP).is_empty():
		_win_level()


func _start_level() -> void:
	state = State.GENERATING
	level += 1
	_despawn_all()
	# generate() also respawns tumors and moves the player to the map center.
	level_generator.generate()
	player.health = player.max_health
	player.velocity = Vector2.ZERO
	_hide_ui()
	get_tree().paused = false
	print("Level %d started, %d objectives" % [level, get_tree().get_nodes_in_group(OBJECTIVE_GROUP).size()])
	state = State.PLAYING


func _win_level() -> void:
	state = State.WON
	get_tree().paused = true
	_despawn_all()

	if win_screen:
		win_screen.show()
	if win_animation_player and win_animation_player.has_animation(win_animation):
		win_animation_player.play(win_animation)
		await win_animation_player.animation_finished
	if win_screen:
		win_screen.hide()

	state = State.CHOOSING_UPGRADE
	var choice := await _choose_upgrade()
	print("Picked upgrade %d (placeholder)" % choice)
	# TODO: apply the real upgrade here.

	_start_level()


func _choose_upgrade() -> int:
	if not upgrade_screen or upgrade_buttons.is_empty():
		push_warning("GameLoop: no upgrade UI assigned, skipping upgrade pick")
		return -1
	for i in upgrade_buttons.size():
		upgrade_buttons[i].text = "Upgrade %d\n(placeholder)" % (i + 1)
	upgrade_screen.show()
	upgrade_buttons[0].grab_focus()
	var index: int = await upgrade_picked
	upgrade_screen.hide()
	return index


func _despawn_all() -> void:
	for node in get_tree().get_nodes_in_group(Global.DESPAWN_GROUP):
		node.queue_free()


func _hide_ui() -> void:
	if win_screen:
		win_screen.hide()
	if upgrade_screen:
		upgrade_screen.hide()


func _on_player_died() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(ProjectSettings.get_setting("application/run/main_scene"))
