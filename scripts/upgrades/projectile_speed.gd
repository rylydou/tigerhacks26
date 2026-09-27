extends Upgrade


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Projectile Speed"

func get_description() -> String:
	return "Your shots travel faster."

func get_stat_at_level(level: int) -> String:
	return "+%d%% projectile speed" % (level * 35)

func get_max_level() -> int:
	return 5


func _activate() -> void:
	player.stat_proj_speed_scale.augment(func(value: float, ctx: Dictionary) -> float:
		return value + ctx['base_value'] * 0.35 * level
	)
