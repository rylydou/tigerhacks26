extends Upgrade


## In Global.UNIT_SCALE. Full bonus within NEAR, falling off to nothing at FAR.
const NEAR := 2.0
const FAR := 5.0


func get_icon() -> Texture2D:
	return preload("res://content/art/panic_upgrade.png")

func get_name() -> String:
	return "Self-Defense Protocol"

func get_description() -> String:
	return "Deal more damage to nearby enemies. Can't be taken with Focus Protocol."

func get_stat_at_level(level: int) -> String:
	return "Up to +%d%% damage up close" % (level * 40)

func get_max_level() -> int:
	return 3

func get_exclusive_group() -> StringName:
	return &"range_damage"


func _activate() -> void:
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		var t := 1.0 - clampf(inverse_lerp(NEAR, FAR, ctx['distance']), 0.0, 1.0)
		return value * (1.0 + 0.4 * level * t)
	, Stat.PRIORITY_MULTIPLY)
