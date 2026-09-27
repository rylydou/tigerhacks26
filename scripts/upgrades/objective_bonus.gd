extends Upgrade


## Seconds the bonus lasts after hitting an objective
const DURATION := 3.0


var timer := 0.0


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Objective Frenzy"

func get_description() -> String:
	return "Hitting an objective increases all your damage for %d seconds." % DURATION

func get_stat_at_level(level: int) -> String:
	return "+%d%% damage" % (level * 20)

func get_max_level() -> int:
	return 3


func _activate() -> void:
	player.hit_target.connect(_on_hit_target)
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		if timer <= 0.0: return value
		return value * (1.0 + 0.2 * level)
	, Stat.PRIORITY_MULTIPLY)


func _tick(delta: float) -> void:
	timer -= delta


func _on_hit_target(target: Node2D, damage: int) -> void:
	if target.is_in_group(GameLoop.OBJECTIVE_GROUP):
		timer = DURATION
