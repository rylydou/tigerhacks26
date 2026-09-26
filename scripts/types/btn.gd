class_name Btn extends RefCounted


static func turbo(delay := 0.5, rate := 6.0) -> Btn:
	var btn := Btn.new()
	btn.turbo_delay = delay
	btn.turbo_rate = rate
	return btn


var down := false
var down_time := 0.0
var pressed := false
var released := false

var turbo_delay := 0.0
var turbo_rate := 0.0
var _turbo_remainder := 0.0

var _was_down := false


func track(down: bool, delta: float) -> void:
	_was_down = self.down
	self.down = down
	
	pressed = not _was_down and down
	released = _was_down and not down
	
	if not down:
		down_time = 0
		return
	
	down_time += delta
	
	if turbo_rate <= 0: return
	
	if pressed:
		_turbo_remainder = turbo_delay
	
	_turbo_remainder -= delta
	if _turbo_remainder <= 0:
		_turbo_remainder = 1.0 / turbo_rate
		pressed = true
		released = true


func handle() -> void:
	pressed = false
