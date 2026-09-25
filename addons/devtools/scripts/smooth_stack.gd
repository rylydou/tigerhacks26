class_name SmoothStack extends Control


@export var smoothing := 10.0


@onready var container: Control = get_parent()


var y_offset := 0.0


func _process(delta: float) -> void:
	container.position.y = lerpf(container.position.y, 0.0, Math.smooth(smoothing, delta))


func add_item(control: Control) -> void:
	add_child(control)
	move_child(control, 0)
	var height := control.size.y
	container.position.y -= height
