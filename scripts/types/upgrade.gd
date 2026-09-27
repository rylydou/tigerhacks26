@abstract
class_name Upgrade extends RefCounted


@abstract func get_icon() -> Texture2D

@abstract func get_name() -> String
@abstract func get_description() -> String
@abstract func get_stat_at_level(level: int) -> String

@abstract func get_max_level() -> int


var level := 0
var player: Player


func _upgrade() -> void:
	if level >= get_max_level(): return
	level += 1
	if level == 1:
		_activate()


func _activate() -> void:
	pass


func _tick(delta: float) -> void:
	pass
