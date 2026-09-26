class_name Shaker extends Node


@export var amplitude := 1.0
@export var amplitude_max := 0.0
@export var frequency := 6.0


var target: Node


var timer := 0.0
var base_position := Vector2.ZERO


func _ready() -> void:
	if self.has_method(&"set_position"):
		target = self
	else:
		target = get_parent()
	
	base_position = target.position


func _process(delta: float) -> void:
	timer += delta
	var shake_time := 1.0 / frequency
	if timer < shake_time: return
	timer -= shake_time
	
	var amp := amplitude
	if amplitude_max > 0.0:
		amp = randf_range(amplitude, amplitude_max)
	
	var pos := Math.rand_dir() * amp
	target.call(&"set_position", base_position + pos)
