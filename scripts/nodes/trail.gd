class_name Trail extends Line2D


@export var trail_count := 10
@export var time_btw := 0.2


var timer := 0.0


func _ready() -> void:
	top_level = true
	for count in trail_count:
		add_point(get_parent().global_position)


func _process(delta: float) -> void:
	timer -= delta
	if timer < 0.0:
		timer = time_btw
		push_point()


func push_point() -> void:
	add_point(get_parent().global_position)
	remove_point(0)
