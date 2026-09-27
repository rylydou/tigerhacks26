@abstract
class_name Upgrade extends RefCounted


## Return from `get_max_level()` for upgrades that can be leveled forever.
const INFINITE_LEVELS := -1


@abstract func get_icon() -> Texture2D

@abstract func get_name() -> String
@abstract func get_description() -> String
@abstract func get_stat_at_level(level: int) -> String

@abstract func get_max_level() -> int


## Upgrades sharing a non-empty group are mutually exclusive, only one can be taken.
func get_exclusive_group() -> StringName:
	return &""


var level := 0
var player: Player


func is_maxed() -> bool:
	var max_level := get_max_level()
	return max_level != INFINITE_LEVELS and level >= max_level


func _upgrade() -> void:
	if is_maxed(): return
	level += 1
	if level == 1:
		_activate()
	_level_up()


## Called once when the upgrade is first taken. Hook up stat augments and signals here.
func _activate() -> void:
	pass


## Called every time the upgrade gains a level (including the first, after `_activate()`).
func _level_up() -> void:
	pass


func _tick(delta: float) -> void:
	pass
