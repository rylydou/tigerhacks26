extends Upgrade


## Each level multiplies damage by this, so levels compound
const MULTIPLIER_PER_LEVEL := 1.25


func get_icon() -> Texture2D:
	return preload("res://content/art/damage_upgrade.png")

func get_name() -> String:
	return "Damage"

func get_description() -> String:
	return "Increases your damage."

func get_stat_at_level(level: int) -> String:
	return "+%d%% damage" % roundi((pow(MULTIPLIER_PER_LEVEL, level) - 1.0) * 100.0)

func get_max_level() -> int:
	return 5


func _activate() -> void:
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		return value * pow(MULTIPLIER_PER_LEVEL, level)
	, Stat.PRIORITY_MULTIPLY)
