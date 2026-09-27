extends Upgrade


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Objective Damage"

func get_description() -> String:
	return "Deal more damage to objectives, like tumors."

func get_stat_at_level(level: int) -> String:
	return "+%d%% damage to objectives" % (level * 50)

func get_max_level() -> int:
	return 5


func _activate() -> void:
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		var target: Node2D = ctx['target']
		if not target.is_in_group(GameLoop.OBJECTIVE_GROUP): return value
		return value * (1.0 + 0.5 * level)
	, Stat.PRIORITY_MULTIPLY)
