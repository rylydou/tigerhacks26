extends Upgrade


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Move Speed"

func get_description() -> String:
	return "Move faster."

func get_stat_at_level(level: int) -> String:
	return "+%d%% move speed" % (level * 15)

func get_max_level() -> int:
	return 5


func _activate() -> void:
	player.stat_move_speed.augment(func(value: float, ctx: Dictionary) -> float:
		return value + ctx['base_value'] * 0.15 * level
	)
