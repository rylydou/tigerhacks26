class_name Gamepad extends RefCounted


const DEVICE_AUTO = -2
const DEVICE_KEYBOARD = -1


class JoyInfo:
	var id := 0
	var name := ''
	var guid := ''
	var is_known := false
	var connected := false
	
	static func from_id(id: int) -> JoyInfo:
		var info := JoyInfo.new()
		info.id = id
		info.name = Input.get_joy_name(id)
		info.guid = Input.get_joy_guid(id)
		info.is_known = Input.is_joy_known(id)
		return info


static var joys: Dictionary = {}
static var gamepads: Array[Gamepad] = []

static var keyboard := Gamepad.create(DEVICE_KEYBOARD)


static func _static_init() -> void:
	gamepads.append(keyboard)


static func _joy_connection_changed(id: int, connected: bool) -> void:
	if connected:
		var info := JoyInfo.from_id(id)
		info.connected = true
		joys[id] = info
		print('[Input] ',info.name,' connected as ',id)
		var gamepad := Gamepad.create(id)
		gamepads.append(gamepad)
		return
	
	if not joys.has(id): return
	var info: JoyInfo = joys[id]
	info.connected = false
	print('[Input] ',info.name,' disconnected from ',id)
	var index := Util.index_of(gamepads, func(gamepad: Gamepad) -> bool: return gamepad.device == id)
	var gamepad := gamepads[index]
	gamepads.remove_at(index)


static func create(device: int) -> Gamepad:
	var gamepad := Gamepad.new()
	gamepad.device = device
	return gamepad


# ---------------------------------------- #


@export var device := 0
@export var move_deadzone := 0.5
@export var move_snap_amount := 1.3333
@export var aim_deadzone := 0.5
@export var trigger_deadzone := 0.5


var assigned_to: Player

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


func connected() -> bool:
	match device:
		-2: return true
		-1: return true
	if Gamepad.joys.has(device):
		return Gamepad.joys[device].connected
	return false


func get_name() -> String:
	match device:
		-2: return 'Auto'
		-1: return 'Keyboard'
	if not Gamepad.joys.has(device):
		return Gamepad.joys[device].name
	return 'NULL'


func is_mouse_and_keyboard() -> bool:
	if device == DEVICE_AUTO:
		return not joys.has(0)
	if device == DEVICE_KEYBOARD:
		return true
	return false


func poll(delta: float) -> void:
	match device:
		-2:
			if joys.has(0):
				var _device := device
				device = 0
				poll_gamepad(delta)
				device = _device
			else:
				poll_keyboard(delta)
		-1:
			poll_keyboard(delta)
		_:
			poll_gamepad(delta)
	
	aim = aim_only
	if aim == Vector2.ZERO:
		aim = move
		is_aim_fine = false


func poll_gamepad(delta: float) -> void:
	menu_ok.track(Input.is_joy_button_pressed(device, JOY_BUTTON_B), delta)
	menu_back.track(Input.is_joy_button_pressed(device, JOY_BUTTON_A), delta)
	menu_pause.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_A) or
			Input.is_joy_button_pressed(device, JOY_BUTTON_B)
	), delta)
	
	menu_left.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X) <= -move_deadzone
	), delta)
	menu_right.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X) >= +move_deadzone
	), delta)
	menu_up.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) <= -move_deadzone
	), delta)
	menu_down.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN) or
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) >= +move_deadzone
	), delta)
	
	move.x = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	move.y = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	
	if move.length_squared() < move_deadzone ** 2:
		move = Vector2.ZERO
	
	# move = round(move.normalized() * move_snap_amount)
	
	aim_only.x = Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
	aim_only.y = Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
	if aim_only.length_squared() < aim_deadzone ** 2:
		aim_only = Vector2.ZERO
	
	is_aim_fine = true
	
	attack.track(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) >= trigger_deadzone, delta)
	dodge.track(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) >= trigger_deadzone, delta)
	
	equipment_b.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_RIGHT_SHOULDER) or
			Input.is_joy_button_pressed(device, JOY_BUTTON_A) or
			Input.is_joy_button_pressed(device, JOY_BUTTON_B)
	), delta)
	equipment_a.track((
			Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER) or
			Input.is_joy_button_pressed(device, JOY_BUTTON_X) or
			Input.is_joy_button_pressed(device, JOY_BUTTON_Y)
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
