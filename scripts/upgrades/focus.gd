extends Upgrade


## In Global.UNIT_SCALE. No bonus within NEAR, rising to the full bonus at FAR.
const NEAR := 4.0
const FAR := 9.0


func get_icon() -> Texture2D:
	return preload("res://content/art/focus_upgrade.png")

func get_name() -> String:
	return "Focus Protocol"

func get_description() -> String:
	return "Deal more damage to far away enemies. Can't be taken with Self Defense-Protocol."

func get_stat_at_level(level: int) -> String:
	return "Up to +%d%% damage at range" % (level * 40)

func get_max_level() -> int:
	return 3

func get_exclusive_group() -> StringName:
	return &"range_damage"


func _activate() -> void:
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		var t := clampf(inverse_lerp(NEAR, FAR, ctx['distance']), 0.0, 1.0)
		return value * (1.0 + 0.4 * level * t)
	, Stat.PRIORITY_MULTIPLY)
