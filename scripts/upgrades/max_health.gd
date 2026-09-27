extends Upgrade


const HEALTH_PER_LEVEL := 20


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Max HP"

func get_description() -> String:
	return "Increases your max health and heals you by the same amount."

func get_stat_at_level(level: int) -> String:
	return "+%d max HP" % (level * HEALTH_PER_LEVEL)

func get_max_level() -> int:
	return 5


func _activate() -> void:
	player.stat_max_health.augment(func(value: float, ctx: Dictionary) -> float:
		return value + level * HEALTH_PER_LEVEL
	)


func _level_up() -> void:
	player.health = mini(player.health + HEALTH_PER_LEVEL, player.max_health)
