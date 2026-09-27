extends Node2D
## Short expanding ring, used for AOE upgrade effects.


var radius := 64.0
var duration := 0.25
var color := Color(0.55, 0.85, 1.0)

var _age := 0.0


func _ready() -> void:
	var sorting := SortingLayer.new()
	sorting.layer_name = &"effect_fg"
	add_child(sorting)


func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / duration
	var r := radius * (1.0 - pow(1.0 - t, 3.0))
	draw_circle(Vector2.ZERO, r, Color(color, 0.25 * (1.0 - t)))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(color, 1.0 - t), 2.0)
