class_name GameLoop extends Node2D
## Generate level -> play until every `objective` is dead -> win screen -> pick upgrade -> repeat.
## Player death returns to the main (title) scene.

enum State { GENERATING, PLAYING, WON, CHOOSING_UPGRADE }

const OBJECTIVE_GROUP := &"objective"


static var current: GameLoop


@export var level_generator: LevelGenerator
@export var player: Player

@export_group("Difficulty")
## Enemies gain enemy_health_bonus (of their base HP) every this many levels.
@export var enemy_health_interval := 5
## 0.5 = +50% base HP per interval (levels 1-5: 100%, 6-10: 150%, 11-15: 200%...).
@export var enemy_health_bonus := 0.5

@export_group("HUD")
## Optional. Shows how many tumors are left this level.
@export var tumors_label: Label
@export var tumors_label_format := "Tumors left: %d"

@export_group("Win Screen")
## Shown when a level is cleared. Set its process_mode to Always so it animates while paused.
@export var win_screen: Control
## Optional. Played when the win screen opens; the loop waits for it to finish.
@export var win_animation_player: AnimationPlayer
@export var win_animation := &"win"

@export_group("Upgrades")
## Shown after the win animation. Set its process_mode to Always.
@export var upgrade_screen: Control
## One button per upgrade choice. Each clear offers as many upgrades as there are buttons.
@export var upgrade_buttons: Array[Button] = []

var state := State.GENERATING
var level := 0

signal upgrade_picked(index: int)


func _enter_tree() -> void:
	GameLoop.current = self


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
	Cheats.register()
	_start_level.call_deferred()


func _process(_delta: float) -> void:
	var remaining := get_remaining_objectives()
	if tumors_label:
		tumors_label.text = tumors_label_format % remaining
	if state == State.PLAYING and remaining == 0:
		_win_level()


## Let a controller confirm the focused upgrade button (A / bottom face button).
func _input(event: InputEvent) -> void:
	if state != State.CHOOSING_UPGRADE:
		return
	var joy := event as InputEventJoypadButton
	if not joy or not joy.pressed or joy.button_index != JOY_BUTTON_A:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and focused in upgrade_buttons and focused.visible:
		get_viewport().set_input_as_handled()
		(focused as Button).pressed.emit()


## Objective count, ignoring non-2D helper nodes that share the group (e.g. the tumor's AI node).
func get_remaining_objectives() -> int:
	return get_tree().get_nodes_in_group(OBJECTIVE_GROUP).filter(
		func(node: Node) -> bool: return node is Node2D).size()


## Multiplier for enemy max health at the current level. 1.0 when no GameLoop is running.
static func enemy_health_multiplier() -> float:
	if not is_instance_valid(current) or current.enemy_health_interval <= 0:
		return 1.0
	@warning_ignore("integer_division")
	var tiers := maxi(current.level - 1, 0) / current.enemy_health_interval
	return 1.0 + current.enemy_health_bonus * tiers


func _start_level() -> void:
	state = State.GENERATING
	level += 1
	_despawn_all()
	# generate() also respawns tumors, moves the player to the map center and spawns random waves.
	level_generator.generate(level)
	player.health = player.max_health
	player.velocity = Vector2.ZERO
	_hide_ui()
	get_tree().paused = false
	print("Level %d started, %d objectives, enemy HP x%.2f" % [level, get_remaining_objectives(), enemy_health_multiplier()])
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
	if choice:
		var upgrade := player.add_upgrade(choice)
		print("Picked upgrade %s (Lv %d)" % [upgrade.get_name(), upgrade.level])

	_start_level()


## Returns the picked upgrade script, or null if there was nothing to pick.
func _choose_upgrade() -> Script:
	if not upgrade_screen or upgrade_buttons.is_empty():
		push_warning("GameLoop: no upgrade UI assigned, skipping upgrade pick")
		return null
	var offers := UpgradePool.roll(player, upgrade_buttons.size())
	if offers.is_empty():
		return null
	for i in upgrade_buttons.size():
		var button := upgrade_buttons[i]
		button.visible = i < offers.size()
		if button.visible:
			button.text = UpgradePool.describe(player, offers[i])
			button.icon = UpgradePool.preview(player, offers[i]).get_icon()
	upgrade_screen.show()
	upgrade_buttons[0].grab_focus()
	var index: int = await upgrade_picked
	upgrade_screen.hide()
	return offers[index]


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
