extends CanvasLayer


const ESSENTIAL_COMMANDS := preload("res://addons/devtools/scripts/essential_commands.gd")
const PIXEL_THEME := preload("res://addons/devtools/resources/pixel.tres")
const STANDARD_THEME := preload("res://addons/devtools/resources/standard.tres")

const DIR_PATH := "user://devtools"
const COMMAND_SHORTCUTS_FILE := "user://devtools/shortcuts.txt"


signal command_registered(command: DEV_Command)


@export var register_essential_commands := true
@export var use_pixel_theme := false

@export var sticky_fadeout_time := 5.0
@export var toast_fadeout_time := 0.2

@export var suppress_error_spam := false

@export var ui_root: Control
@export var toasts_container: Control
@export var sticky_toasts_container: Control
@export var shortcut_sound: AudioStreamPlayer
@export var tick_a_sound: AudioStreamPlayer
@export var tick_b_sound: AudioStreamPlayer


var disabled := false

var commands_by_id: Dictionary[StringName, DEV_Command] = {}
var queued_shortcuts_by_id: Dictionary[StringName, Shortcut] = {}

var sticky_labels_by_id: Dictionary[StringName, Array] = {}

var tracked_error_ids: Dictionary[StringName, int] = {}


func _enter_tree() -> void:
	if register_essential_commands:
		ESSENTIAL_COMMANDS.register_my_commands()


func _ready() -> void:
	if use_pixel_theme:
		propagate_call("use_pixel_theme")
	
	propagate_call(&"load_data", [], true)
	
	# get_window().size_changed.connect(update_size)
	# update_size()
	
	DevTools.new_command("Devtools: Reset all shortcuts")\
			.describe("Restores all custom command shortcuts to the original bindings.")\
			.exec(func(): DevTools.reset_all_shortcuts)
	
	DevTools.new_command("Devtools: Disable for this session")\
		.describe("Disables the command picker and all shortcuts for this session.")\
		.exec(disable)


func update_size() -> void:
	var base_size := Vector2(1920, 1080)
	var min_scale = 1.0
	
	var viewport_size := Vector2(get_viewport().size)
	var scale := floorf(viewport_size.y / base_size.y)
	scale = maxf(scale, min_scale)
	
	ui_root.scale = Vector2.ONE * scale
	#control.size = viewport_size / scale
	ui_root.size.y = viewport_size.y / scale
	ui_root.size.x = viewport_size.x / scale
	ui_root.theme.default_base_scale = scale



func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		propagate_call(&"save_data", [], true)


func _shortcut_input(event: InputEvent) -> void:
	if disabled: return
	if not event.is_pressed(): return
	
	for command in DevTools.commands_by_id.values():
		if (
				(command.custom_shortcut and command.custom_shortcut.matches_event(event)) or
				(not command.custom_shortcut and command.shortcut and command.shortcut.matches_event(event))
		):
			get_viewport().set_input_as_handled()
			DevTools.run_command(command)
			if not command.disable_sound:
				shortcut_sound.play()
			continue


func new_command(name: StringName) -> DEV_Command:
	var command := DEV_Command.new()
	command.named(name)
	register_command(command)
	return command


func register_command(command: DEV_Command) -> DEV_Command:
	commands_by_id[command.id] = command
	
	var shortcut := queued_shortcuts_by_id.get(command.id)
	if shortcut:
		queued_shortcuts_by_id.erase(command.id)
		command.custom_shortcut = shortcut
	
	return command


func run_command(command: DEV_Command, disable_toast := false) -> void:
	if not (disable_toast or command.disable_toast):
		print("[Dev Tools] Running command %s..." % command.name)
		toast("[%s]" % command.name)
	command.callback.call()


func reset_all_shortcuts() -> void:
	for command in commands_by_id.values():
		command._reset()
	
	queued_shortcuts_by_id.clear()


func disable() -> void:
	disabled = true
	hide()


func track_error(failure: String, cause: String, track_id := &"") -> Label:
	if track_id and suppress_error_spam:
		if tracked_error_ids.has(track_id): return null
		tracked_error_ids[track_id] = 1
	
	push_error(failure+". - "+cause+".")
	var label := toast("ERROR: %s.\n- %s." % [failure, cause], 10.0 if track_id else 5.0)
	return label


func toast(text: Variant, lifetime := 5.0) -> Label:
	var label := Label.new()
	label.text = _smart_convert_text(text)
	label.theme_type_variation = &"Toast"
	# label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_SHRINK_END
	toasts_container.add_item(label)
	
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 0.0, toast_fadeout_time).set_delay(lifetime)
	tween.tween_callback(label.queue_free)
	
	return label


func sticky_toast(id: StringName, text: Variant = null, lifetime := 5.0) -> void:
	var label: Label
	var tween: Tween
	
	var arr := sticky_labels_by_id.get(id)
	
	if text == null:
		if arr and is_instance_valid(arr[0]):
			label = arr[0]
			tween = arr[1]
			if tween:
				tween.kill()
				label.queue_free()
		return
	
	if not arr or not is_instance_valid(arr[0]):
		label = Label.new()
		label.theme_type_variation = &"StickyToast"
		# label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		sticky_toasts_container.add_item(label)
		if lifetime > 0.0 and lifetime < INF:
			tween = label.create_tween()
			tween\
				.tween_property(label, "modulate:a", 0.0, maxf(lifetime, sticky_fadeout_time))\
				.set_delay(minf(lifetime - sticky_fadeout_time, 0.0))
			tween.tween_callback(func():
					label.queue_free()
					sticky_labels_by_id.erase(id)
			)
		sticky_labels_by_id[id] = [label, tween]
	else:
		label = arr[0]
		tween = arr[1]
	
	label.modulate.a = 1.0
	label.text = str("[",id,"]\n\n",_smart_convert_text(text))
	if tween:
		tween.stop()
		tween.play()


func _smart_convert_text(data: Variant) -> String:
	if typeof(data) == TYPE_DICTIONARY:
		var result := PackedStringArray()
		for key in data:
			result.append(str(key,": ",data[key]))
		return "\n".join(result)
	
	return str(data)


func load_data() -> void:
	print("[Dev Tools] Loading data...")
	DirAccess.make_dir_recursive_absolute(DIR_PATH)
	
	if FileAccess.file_exists(COMMAND_SHORTCUTS_FILE):
		var file := FileAccess.open(COMMAND_SHORTCUTS_FILE, FileAccess.READ)
		while true:
			if file.eof_reached(): break
			
			var line := file.get_line()
			var segs := line.split(" ~ ", false, 2)
			if segs.size() != 2: return
			
			var command_id := StringName(segs[0])
			var command_hkey := String(segs[1])
			
			var shortcut := DEV_Util.shortcut_from_string(command_hkey)
			var prexisting_command: DEV_Command = DevTools.commands_by_id.get(command_id)
			if prexisting_command:
				prexisting_command.custom_shortcut = shortcut
			else:
				DevTools.queued_shortcuts_by_id[command_id] = shortcut


func save_data() -> void:
	print("[Dev Tools] Saving data...")
	DirAccess.make_dir_recursive_absolute(DIR_PATH)
	
	var shortcuts_file := FileAccess.open(COMMAND_SHORTCUTS_FILE, FileAccess.WRITE)
	for command in DevTools.commands_by_id.values():
		if not command.custom_shortcut: continue
		shortcuts_file.store_line("%s ~ %s" % [command.id, command.custom_shortcut.get_as_text().replace("QuoteLeft", "tilde").to_lower()])
	
	shortcuts_file.close()
