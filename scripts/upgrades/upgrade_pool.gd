class_name UpgradePool extends RefCounted
## Every upgrade that can be offered after clearing a level.


const UPGRADES: Array[Script] = [
	# Basic stats
	preload("res://scripts/upgrades/move_speed.gd"),
	preload("res://scripts/upgrades/max_health.gd"),
	preload("res://scripts/upgrades/regen.gd"),
	preload("res://scripts/upgrades/bullet_damage.gd"),
	preload("res://scripts/upgrades/fire_rate.gd"),
	preload("res://scripts/upgrades/projectile_speed.gd"),
	preload("res://scripts/upgrades/objective_damage.gd"),
	# Interesting
	preload("res://scripts/upgrades/static_charge.gd"),
	preload("res://scripts/upgrades/still_healing.gd"),
	preload("res://scripts/upgrades/fairy.gd"),
	preload("res://scripts/upgrades/panic.gd"),
	preload("res://scripts/upgrades/focus.gd"),
	preload("res://scripts/upgrades/super_capacitor.gd"),
	preload("res://scripts/upgrades/objective_healing.gd"),
	preload("res://scripts/upgrades/objective_bonus.gd"),
	preload("res://scripts/upgrades/knockback.gd"),
	preload("res://scripts/upgrades/healing_drops.gd"),
]


## Picks up to `count` different upgrades the player can still take.
static func roll(player: Player, count: int) -> Array[Script]:
	var candidates: Array[Script] = []
	for script in UPGRADES:
		if can_offer(player, script):
			candidates.append(script)
	candidates.shuffle()
	candidates.resize(mini(count, candidates.size()))
	return candidates


static func can_offer(player: Player, script: Script) -> bool:
	var owned := player.get_upgrade(script)
	if owned:
		return not owned.is_maxed()
	
	var group := preview(player, script).get_exclusive_group()
	if group == &"": return true
	for upgrade in player.upgrades:
		if upgrade.get_exclusive_group() == group:
			return false
	return true


## The player's instance of the upgrade, or a fresh level 0 one for reading its info.
static func preview(player: Player, script: Script) -> Upgrade:
	var owned := player.get_upgrade(script)
	if owned: return owned
	return script.new()


## Multi-line label for an upgrade button, describing the next level.
static func describe(player: Player, script: Script) -> String:
	var upgrade := preview(player, script)
	var next_level := upgrade.level + 1
	return "%s (Lv %d)\n%s\n%s" % [
		upgrade.get_name(),
		next_level,
		upgrade.get_description(),
		upgrade.get_stat_at_level(next_level),
	]
