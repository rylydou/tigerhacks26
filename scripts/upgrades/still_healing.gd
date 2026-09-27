extends Upgrade


## Seconds without moving before the bonus kicks in
const DELAY := 1.0
const HEAL_PER_SECOND_PER_LEVEL := 10.0


func get_icon() -> Texture2D:
	return preload("res://content/art/still_healing_upgrade.png")

func get_name() -> String:
	return "Rest"

func get_description() -> String:
	return "While standing still, regenerate health and all healing is increased."

func get_stat_at_level(level: int) -> String:
	return "%d HP per second, +%d%% healing while still" % [level * HEAL_PER_SECOND_PER_LEVEL, level * 50]

func get_max_level() -> int:
	return 3


func _activate() -> void:
	player.stat_healing.augment(func(value: float, ctx: Dictionary) -> float:
		if player.still_time < DELAY: return value
		return value * (1.0 + 0.5 * level)
	, Stat.PRIORITY_MULTIPLY)


func _tick(delta: float) -> void:
	if player.still_time < DELAY: return
	player.heal(level * HEAL_PER_SECOND_PER_LEVEL * delta)
