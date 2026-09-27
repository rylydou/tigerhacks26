extends Upgrade


func get_icon() -> Texture2D:
	return preload("res://content/art/attack_speed_upgrade.png")

func get_name() -> String:
	return "Fire Rate"

func get_description() -> String:
	return "Shoot faster."

func get_stat_at_level(level: int) -> String:
	return "+%d%% fire rate" % (level * 25)

func get_max_level() -> int:
	return 5


func _activate() -> void:
	player.stat_attack_speed_scale.augment(func(value: float, ctx: Dictionary) -> float:
		return value + ctx['base_value'] * 0.25 * level
	)
