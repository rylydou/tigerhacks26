extends Node


signal unimplemented_event(event_name: StringName)


# Settings
@onready var todo_file_path: String = SoundscaperSettings.get_setting(SoundscaperSettings.TODO_FILE)
@onready var event_dir: String = SoundscaperSettings.get_setting(SoundscaperSettings.SOUNDBANK_DIR)
@onready var fallback_event_path: String = SoundscaperSettings.get_setting(SoundscaperSettings.FALLBACK_EVENT_PATH)
@onready var sfx_pool_size: int = SoundscaperSettings.get_setting(SoundscaperSettings.SFX_POOL_SIZE)
@onready var event_spec_meta_key: StringName = SoundscaperSettings.get_setting(SoundscaperSettings.EVENT_SPECIFIER_METADATA_KEY)

@onready var fallback_event: SoundEvent = load(fallback_event_path)


var events: Dictionary = {}
var event_cache: Dictionary = {}

var todo_cache: Array[StringName] = []

var pool_index := 0
var player_pool: Array[AudioStreamPlayer2D] = []

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	
	reload_events()
	
	load_todo()
	save_todo()


func _exit_tree() -> void:
	save_todo()


func reload_events() -> void:
	events.clear()
	event_cache.clear()
	
	for dir_name in DirAccess.get_directories_at(event_dir):
		var dir_path := event_dir.path_join(dir_name)
		for file_name in DirAccess.get_files_at(dir_path):
			file_name = file_name.replace(".remap", "")
			if not (
				file_name.ends_with(".tres")
				or file_name.ends_with(".res")
			): continue
			
			var file_path := dir_path.path_join(file_name)
			
			var event: SoundEvent = load(file_path)
			if not event:
				push_error("Failed to load event: ",file_path)
				continue
			
			event.bus = dir_name
			var event_name := StringName(file_name.get_basename())
			events[event_name] = event
			event_cache[event_name] = event


func clear_todo() -> void:
	todo_cache.clear()


func load_todo() -> void:
	if not todo_file_path: return
	print("[Soundscaper] Using TODO file in ",todo_file_path)
	
	if not FileAccess.file_exists(todo_file_path): return
	
	var todo_file := FileAccess.open(todo_file_path, FileAccess.READ)
	while not todo_file.eof_reached():
		var line := todo_file.get_line().strip_edges()
		if not line: continue
		if events.has(line): continue
		add_todo(StringName(line))


func save_todo() -> void:
	if not todo_file_path: return
	print("[Soundscaper] Saving TODO file to ",todo_file_path)
	
	DirAccess.make_dir_recursive_absolute(todo_file_path.get_base_dir())
	var todo_file := FileAccess.open(todo_file_path, FileAccess.WRITE)
	# todo_cache.sort_custom(func(a: StringName, b: StringName) -> void: a.naturalcasecmp_to(b) < 0)
	# print(todo_cache)
	for item in todo_cache:
		todo_file.store_line(item)


func add_todo(event_name: StringName) -> void:
	if todo_cache.has(event_name): return
	
	var index := 0
	for item in todo_cache:
		if event_name.naturalcasecmp_to(item) < 0: break
		index += 1
	
	todo_cache.insert(index, event_name)


func grow_pool_by(count: int) -> void:
	for index in count:
		var player := AudioStreamPlayer2D.new()
		add_child(player)
		player_pool.append(player)


func get_player() -> AudioStreamPlayer2D:
	if player_pool.is_empty():
		grow_pool_by(sfx_pool_size)
	
	pool_index += 1
	if pool_index >= player_pool.size():
		pool_index = 0
	return player_pool[pool_index]


func get_event(event_name: StringName) -> SoundEvent:
	var event: SoundEvent = events.get(event_name)
	
	if not event:
		push_warning("[Soundscaper] Unimplemented sound event: ",event_name)
		event = fallback_event
		unimplemented_event.emit(event_name)
		add_todo(event_name)
		if event_name.contains("."):
			event = get_event(StringName(event_name.get_basename()))
	
	return event


func event(event_name: StringName, specifier: Variant = null) -> SoundEventPlayer:
	#return SoundEventPlayer.new() # DELETE ME
	
	if specifier is Node2D:
		specifier = specifier.get_meta(event_spec_meta_key)
	
	if specifier and (specifier is String or specifier is StringName):
		event_name = StringName(event_name + "." + specifier)
	
	var event: SoundEvent = event_cache.get(event_name)
	if not event:
		event = get_event(event_name)
		event_cache[event_name] = event
	
	var player := SoundEventPlayer.new()
	player.player = get_player()
	
	return player.set_event(event)
