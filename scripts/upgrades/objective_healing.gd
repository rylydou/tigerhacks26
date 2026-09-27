extends Upgrade


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Objective Healing"

func get_description() -> String:
	return "Heal for a portion of the damage you deal to objectives."

func get_stat_at_level(level: int) -> String:
	return "Heal %d%% of objective damage" % (level * 10)

func get_max_level() -> int:
	return 3


func _activate() -> void:
	player.hit_target.connect(_on_hit_target)


func _on_hit_target(target: Node2D, damage: int) -> void:
	if not target.is_in_group(GameLoop.OBJECTIVE_GROUP): return
	player.heal(damage * 0.1 * level)
