extends Upgrade


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Damage"

func get_description() -> String:
	return "Increases your damage."

func get_stat_at_level(level: int) -> String:
	return str(level * 10) + " damage"

func get_max_level() -> int:
	return 5


func _activate() -> void:
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		return value + level * 3
	)
