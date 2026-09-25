@tool
extends Control


const CONFIG_PATH := "res://.godot/editor/soundscaper_toolbar.cfg"


static var config_file := ConfigFile.new()
static var cfg_play_on_select := true
static var cfg_autoplay_enabled := false
static var cfg_autoplay_rate_index := 4


static func _static_init() -> void:
	config_file.load(CONFIG_PATH)
	
	cfg_play_on_select = config_file.get_value("play", "on_select", cfg_play_on_select)
	cfg_autoplay_enabled = config_file.get_value("autoplay", "enabled", cfg_autoplay_enabled)
	cfg_autoplay_rate_index = config_file.get_value("autoplay", "rate_index", cfg_autoplay_rate_index)


static func save_config() -> void:
	config_file.set_value("play", "on_select", cfg_play_on_select)
	config_file.set_value("autoplay", "enabled", cfg_autoplay_enabled)
	config_file.set_value("autoplay", "rate_index", cfg_autoplay_rate_index)
	
	DirAccess.make_dir_recursive_absolute(CONFIG_PATH.get_base_dir())
	config_file.save(CONFIG_PATH)


const AUTOPLAY_RATE_OPTIONS: Array[Array] = [
	[ "On change",       INF        ],
	[ "every 5 seconds", 5.0        ],
	[ "every 3 seconds", 3.0        ],
	[ "every 2 seconds", 2.0        ],
	[ "every second",    1.0        ],
	[ "2 per second",    1.0 / 2.0  ],
	[ "3 per second",    1.0 / 3.0  ],
	[ "4 per second",    1.0 / 4.0  ],
	[ "5 per second",    1.0 / 5.0  ],
	[ "6 per second",    1.0 / 6.0  ],
	[ "8 per second",    1.0 / 8.0  ],
	[ "10 per second",   1.0 / 10.0 ],
	[ "ASAP",            0.0        ],
]


var sound_event: SoundEvent

@onready var autoplay_enabled := cfg_autoplay_enabled
@onready var autoplay_rate_index := cfg_autoplay_rate_index
var autoplay_duration := INF
var autoplay_timer := 0.0


@onready var play_button: Button = %"Play Button"
@onready var autoplay_button: Button = %"Autoplay Button"
@onready var autoplay_rate_slider: Slider = %"Autoplay Rate Slider"
@onready var autoplay_rate_label: Label = %"Autoplay Rate Label"
@onready var menu_button: MenuButton = %"Menu Button"
@onready var menu_popup: PopupMenu = menu_button.get_popup()


var event_instances: Array[AudioStreamPlayer] = []


func _ready() -> void:
	if not is_instance_valid(sound_event): return
	
	autoplay_rate_slider.set_value_no_signal(autoplay_rate_index + 1)
	set_autoplay_index(autoplay_rate_index)
	autoplay_rate_slider.max_value = AUTOPLAY_RATE_OPTIONS.size()
	
	if is_instance_valid(sound_event):
		sound_event.property_list_changed.connect(_on_change)
	
	menu_popup.index_pressed.connect(_on_menu_item_pressed)
	menu_popup.set_item_checked(0, cfg_play_on_select)
	
	autoplay_button.button_pressed = autoplay_enabled
	
	play_button.gui_input.connect(func(event: InputEvent) -> void:
		if event is not InputEventMouseButton: return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			stop_all_sounds()
	)
	
	if cfg_play_on_select and not (autoplay_enabled and autoplay_duration < INF):
		play()


func play() -> void:
	if not is_instance_valid(sound_event): return
	
	autoplay_timer = 0.0
	
	if sound_event.streams.size() <= 0: return
	
	# Clone the event
	#event = event.duplicate(true)
	
	var rng := RandomNumberGenerator.new()
	var player := AudioStreamPlayer.new()
	sound_event.init_player(player)
	
	add_child(player)
	player.play()
	
	event_instances.append(player)
	play_button.text = "(   )"
	
	await player.finished
	player.queue_free()
	event_instances.erase(player)
	
	if event_instances.size() <= 0:
		play_button.text = ""
		if autoplay_enabled and autoplay_duration <= 0.0:
			play()


func _process(delta: float) -> void:
	if autoplay_enabled and autoplay_duration > 0.0 and autoplay_duration < INF:
		autoplay_timer += delta
		if get_window().has_focus() and autoplay_timer >= autoplay_duration:
			play()


func set_autoplay(toggled_on: bool) -> void:
	autoplay_enabled = toggled_on
	autoplay_button.set_pressed_no_signal(toggled_on)
	autoplay_button.text = "On" if autoplay_enabled else "Off"
	
	if autoplay_enabled:
		autoplay_timer = INF
		
		if autoplay_duration < INF:
			play()


func set_autoplay_index(index: int) -> void:
	autoplay_rate_index = index
	var autoplay_spec: Array = AUTOPLAY_RATE_OPTIONS[index]
	autoplay_rate_label.text = autoplay_spec[0]
	autoplay_duration = autoplay_spec[1]


func _on_autoplay_rate_slider_chaned(value: float) -> void:
	set_autoplay_index(value - 1)
	if not autoplay_enabled or (autoplay_enabled and autoplay_duration <= 0.0):
		set_autoplay(true)


func _on_autoplay_rate_slider_drag_ended(value_changed: bool) -> void:
	_on_autoplay_rate_slider_chaned(autoplay_rate_slider.value)


func _on_change() -> void:
	if is_inf(autoplay_duration):
		play()


func _on_menu_item_pressed(index: int) -> void:
	print(index)
	match index:
		0:
			menu_popup.toggle_item_checked(index)
			cfg_play_on_select = menu_popup.is_item_checked(index)
			save_config()
		2:
			save_autoplay_config()


func save_autoplay_config() -> void:
	cfg_autoplay_enabled = autoplay_enabled
	cfg_autoplay_rate_index = autoplay_rate_index
	save_config()


func stop_all_sounds() -> void:
	set_autoplay(false)
	for instance in event_instances:
		instance.stop()
		instance.finished.emit()
