extends Upgrade


const KNOCKBACK_PER_LEVEL := 6.0


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Knockback"

func get_description() -> String:
	return "Your attacks push enemies away."

func get_stat_at_level(level: int) -> String:
	return "+%d knockback" % (level * KNOCKBACK_PER_LEVEL)

func get_max_level() -> int:
	return 3


func _activate() -> void:
	player.stat_knockback_scale.augment(func(value: float, ctx: Dictionary) -> float:
		return value + level * KNOCKBACK_PER_LEVEL
	)
