extends Upgrade


const FairyNode := preload("res://scripts/upgrades/effects/fairy.gd")


var fairy: FairyNode


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Fairy"

func get_description() -> String:
	return "A fairy hovers over random enemies. Marked enemies take increased damage."

func get_stat_at_level(level: int) -> String:
	return "Marked enemies take %d%% damage" % roundi(get_multiplier(level) * 100.0)

func get_max_level() -> int:
	return 3


func get_multiplier(level: int) -> float:
	return 1.5 + 0.25 * (level - 1)


func _activate() -> void:
	fairy = FairyNode.new()
	fairy.player = player
	player.add_child(fairy)
	
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		if not is_instance_valid(fairy): return value
		var marked: Node2D = fairy.get_marked()
		if not marked or ctx['target'] != marked: return value
		return value * get_multiplier(level)
	, Stat.PRIORITY_MULTIPLY)


func _level_up() -> void:
	# Higher levels hop between enemies more often
	fairy.retarget_time = 6.0 - level
