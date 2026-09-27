extends Upgrade


const ShockRing := preload("res://scripts/upgrades/effects/shock_ring.gd")

## In Global.UNIT_SCALE. Distance to move to reach a full charge. Power grows smoothly along the way
const FULL_CHARGE_DISTANCE := 10.0
## Ignore tiny taps so brief stutter steps don't shock
const MIN_CHARGE := 0.05
## In Global.UNIT_SCALE. Radius of the weakest shock
const MIN_RADIUS := 1.0
const MAX_KNOCKBACK := 8.0


## 0 to 1
var charge := 0.0
var last_position := Vector2.ZERO


func get_icon() -> Texture2D:
	return preload("res://content/art/static_shock_upgrade.png")

func get_name() -> String:
	return "Static Charge"

func get_description() -> String:
	return "Moving builds up charge. Stopping releases it, shocking nearby enemies. The farther you move, the bigger the shock."

func get_stat_at_level(level: int) -> String:
	return "Up to %d damage in up to a %s tile radius" % [get_max_damage(level), get_max_radius(level)]

func get_max_level() -> int:
	return 3


func get_max_damage(level: int) -> float:
	return 6.0 + 6.0 * level

## In Global.UNIT_SCALE
func get_max_radius(level: int) -> float:
	return 2.5 + 0.5 * level


func _activate() -> void:
	last_position = player.global_position


func _tick(delta: float) -> void:
	# Clamped so teleports (like a new level) don't count as movement
	var moved := minf(player.global_position.distance_to(last_position) / Global.UNIT_SCALE, 1.0)
	last_position = player.global_position
	
	if player.is_moving():
		charge = minf(charge + moved / FULL_CHARGE_DISTANCE, 1.0)
	elif charge > 0.0:
		if charge >= MIN_CHARGE:
			_discharge()
		charge = 0.0


func _discharge() -> void:
	# Everything scales with how far you moved
	var radius := lerpf(MIN_RADIUS, get_max_radius(level), charge) * Global.UNIT_SCALE
	var damage := get_max_damage(level) * charge
	var knockback := MAX_KNOCKBACK * charge
	
	for node in player.get_tree().get_nodes_in_group(Global.ENEMY_GROUP):
		if node is not Node2D: continue
		if node.global_position.distance_to(player.global_position) > radius: continue
		player.try_attack(node, damage, knockback)
	
	var ring := ShockRing.new()
	ring.radius = radius
	ring.global_position = player.global_position
	ring.add_to_group(Global.DESPAWN_GROUP)
	player.get_tree().current_scene.add_child(ring)
