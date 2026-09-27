extends Upgrade


## Seconds of not shooting to reach a full charge
const CHARGE_TIME := 4.0
## Seconds of shooting to fully drain
const DRAIN_TIME := 0.5
const META_BONUS := &"super_capacitor_bonus"


## 0 to 1
var charge := 0.0


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Super Capacitor"

func get_description() -> String:
	return "Slowly build bonus damage while not shooting. Shooting drains it quickly."

func get_stat_at_level(level: int) -> String:
	return "Up to +%d%% damage" % roundi(get_max_bonus(level) * 100.0)

func get_max_level() -> int:
	return 3


func get_max_bonus(level: int) -> float:
	return 0.5 + 0.25 * level


func _activate() -> void:
	player.shot.connect(_on_shot)
	# The bonus is locked in when the bullet is fired, since it hits after the charge has drained
	player.stat_attack_damage_scale.augment(func(value: float, ctx: Dictionary) -> float:
		var source: Node = ctx['source']
		if not is_instance_valid(source) or not source.has_meta(META_BONUS): return value
		return value * (1.0 + source.get_meta(META_BONUS))
	, Stat.PRIORITY_MULTIPLY)


func _tick(delta: float) -> void:
	if player.is_shooting():
		charge = maxf(charge - delta / DRAIN_TIME, 0.0)
	else:
		charge = minf(charge + delta / CHARGE_TIME, 1.0)


func _on_shot(bullet: BasicProjectile) -> void:
	if charge <= 0.0: return
	bullet.set_meta(META_BONUS, charge * get_max_bonus(level))
	bullet.modulate = Color.WHITE.lerp(Color(1.6, 1.4, 0.6), charge)
