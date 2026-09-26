class_name Gamepad extends RefCounted


const DEVICE_AUTO = -2
const DEVICE_KEYBOARD = -1


static func create(device: int) -> Gamepad:
	var gamepad := Gamepad.new()
	gamepad.device = device
	return gamepad


# ---------------------------------------- #


@export var device := 0
@export var move_deadzone := 0.5
@export var aim_deadzone := 0.5
@export var trigger_deadzone := 0.5


var menu_ok := Btn.new()
var menu_back := Btn.new()
var menu_pause := Btn.new()
var menu_left := Btn.turbo()
var menu_right := Btn.turbo()
var menu_up := Btn.turbo()
var menu_down := Btn.turbo()

var move := Vector2.ZERO
var aim := Vector2.ZERO
var aim_only := Vector2.ZERO
var is_aim_fine := false

var attack := Btn.new()
var dodge := Btn.new()

var equipment_a := Btn.new()
var equipment_b := Btn.new()


## Device actually being read when in DEVICE_AUTO mode.
var active_device := DEVICE_KEYBOARD


func is_mouse_and_keyboard() -> bool:
	if device == DEVICE_AUTO:
		return active_device == DEVICE_KEYBOARD
	return device == DEVICE_KEYBOARD


func poll(delta: float) -> void:
	if device == DEVICE_AUTO:
		_update_auto_device()
	else:
		active_device = device
	
	if active_device == DEVICE_KEYBOARD:
		poll_keyboard(delta)
	else:
		poll_gamepad(delta)
	
	aim = aim_only
	if aim == Vector2.ZERO:
		aim = move
		is_aim_fine = false


## Switches to whichever device (keyboard/mouse or a joypad) was used most recently.
func _update_auto_device() -> void:
	var joys := Input.get_connected_joypads()
	if active_device != DEVICE_KEYBOARD and active_device not in joys:
		active_device = DEVICE_KEYBOARD
	
	for joy in joys:
		if joy != active_device and _is_joy_active(joy):
			active_device = joy
			return
	
	if active_device != DEVICE_KEYBOARD and _is_keyboard_active():
		active_device = DEVICE_KEYBOARD


func _is_joy_active(joy: int) -> bool:
	for button in JOY_BUTTON_MAX:
		if Input.is_joy_button_pressed(joy, button):
			return true
	for axis in JOY_AXIS_MAX:
		if absf(Input.get_joy_axis(joy, axis)) >= move_deadzone:
			return true
	return false


func _is_keyboard_active() -> bool:
	for key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
			KEY_SPACE, KEY_SHIFT, KEY_E, KEY_Q, KEY_ENTER, KEY_ESCAPE]:
		if Input.is_key_pressed(key):
			return true
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func poll_gamepad(delta: float) -> void:
	menu_ok.track(Input.is_joy_button_pressed(active_device, JOY_BUTTON_B), delta)
	menu_back.track(Input.is_joy_button_pressed(active_device, JOY_BUTTON_A), delta)
	menu_pause.track((
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_A) or
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_B)
	), delta)
	
	menu_left.track((
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_DPAD_LEFT) or
			Input.get_joy_axis(active_device, JOY_AXIS_LEFT_X) <= -move_deadzone
	), delta)
	menu_right.track((
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_DPAD_RIGHT) or
			Input.get_joy_axis(active_device, JOY_AXIS_LEFT_X) >= +move_deadzone
	), delta)
	menu_up.track((
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_DPAD_UP) or
			Input.get_joy_axis(active_device, JOY_AXIS_LEFT_Y) <= -move_deadzone
	), delta)
	menu_down.track((
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_DPAD_DOWN) or
			Input.get_joy_axis(active_device, JOY_AXIS_LEFT_Y) >= +move_deadzone
	), delta)
	
	move.x = Input.get_joy_axis(active_device, JOY_AXIS_LEFT_X)
	move.y = Input.get_joy_axis(active_device, JOY_AXIS_LEFT_Y)
	
	if move.length_squared() < move_deadzone ** 2:
		move = Vector2.ZERO
	
	aim_only.x = Input.get_joy_axis(active_device, JOY_AXIS_RIGHT_X)
	aim_only.y = Input.get_joy_axis(active_device, JOY_AXIS_RIGHT_Y)
	if aim_only.length_squared() < aim_deadzone ** 2:
		aim_only = Vector2.ZERO
	
	is_aim_fine = true
	
	attack.track(Input.get_joy_axis(active_device, JOY_AXIS_TRIGGER_RIGHT) >= trigger_deadzone, delta)
	dodge.track(Input.get_joy_axis(active_device, JOY_AXIS_TRIGGER_LEFT) >= trigger_deadzone, delta)
	
	equipment_b.track((
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_RIGHT_SHOULDER) or
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_A) or
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_B)
	), delta)
	equipment_a.track((
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_LEFT_SHOULDER) or
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_X) or
			Input.is_joy_button_pressed(active_device, JOY_BUTTON_Y)
	), delta)


func poll_keyboard(delta: float) -> void:
	menu_ok.track((
			Input.is_key_pressed(KEY_E) or
			Input.is_key_pressed(KEY_SPACE) or
			Input.is_key_pressed(KEY_ENTER)
	), delta)
	menu_back.track((
			Input.is_key_pressed(KEY_Q) or
			Input.is_key_pressed(KEY_BACKSPACE) or
			Input.is_key_pressed(KEY_ESCAPE)
	), delta)
	menu_pause.track(Input.is_key_pressed(KEY_ESCAPE), delta)
	
	menu_left.track(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT), delta)
	menu_right.track(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT), delta)
	menu_up.track(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP), delta)
	menu_down.track(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN), delta)
	
	move.x = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	move.y = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	
	aim_only.x = int(Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_LEFT))
	aim_only.y = int(Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_UP))
	
	is_aim_fine = false
	
	attack.track((
			Input.is_key_pressed(KEY_SPACE) or
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	), delta)
	dodge.track(Input.is_key_pressed(KEY_SHIFT), delta)
	
	equipment_b.track(Input.is_key_pressed(KEY_E), delta)
	equipment_a.track(Input.is_key_pressed(KEY_Q), delta)
