extends Upgrade


const HealPickup := preload("res://scripts/upgrades/effects/heal_pickup.gd")

const HEAL_PER_PICKUP := 5.0
## Pixels
const SCATTER_RADIUS := 12.0


func get_icon() -> Texture2D:
	return preload("res://content/art/health_drop_upgrade.png")

func get_name() -> String:
	return "Biomass Converter"

func get_description() -> String:
	return "Enemies drop healing orbs when killed (%d HP each)." % HEAL_PER_PICKUP

func get_stat_at_level(level: int) -> String:
	return "0 to %d orbs per kill" % level

func get_max_level() -> int:
	return INFINITE_LEVELS


func _activate() -> void:
	player.killed_enemy.connect(_on_killed_enemy)


func _on_killed_enemy(enemy: Enemy) -> void:
	for i in randi_range(0, level):
		var pickup := HealPickup.new()
		pickup.amount = HEAL_PER_PICKUP
		pickup.global_position = enemy.global_position + Vector2.from_angle(randf() * TAU) * randf() * SCATTER_RADIUS
		# Deferred since kills can happen during physics callbacks
		player.get_tree().current_scene.add_child.call_deferred(pickup)
		pickup.pop_from.call_deferred(enemy.global_position)
