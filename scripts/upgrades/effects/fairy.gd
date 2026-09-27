extends Node2D
## Targeting reticle that flies out from the player to a random nearby enemy and locks on.
## The Fairy upgrade boosts damage against the locked enemy. Hidden while there's no target.


## In Global.UNIT_SCALE
const SEARCH_RADIUS := 10.0
## Pixels from the target to count as locked on
const ARRIVE_RADIUS := 4.0
const FOLLOW_SMOOTHING := 8.0
const SPIN_SPEED := 1.5
const TEXTURE := preload("res://content/art/target_reticle.png")


var player: Player
## Seconds before switching to a different enemy
var retarget_time := 6.0

var target: Node2D
var retarget_timer := 0.0
var arrived := false

var _time := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	top_level = true
	global_position = player.global_position
	visible = false
	
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	add_child(_sprite)
	
	var sorting := SortingLayer.new()
	sorting.layer_name = &"overlay"
	add_child(sorting)


func _physics_process(delta: float) -> void:
	_time += delta
	retarget_timer -= delta
	
	if not _is_valid_target(target) or retarget_timer <= 0.0:
		_pick_target()
	
	if not target:
		# Park on the player so the next lock-on flies out from them
		visible = false
		arrived = false
		global_position = player.global_position
		return
	
	visible = true
	var destination := target.global_position
	global_position = global_position.lerp(destination, Math.smooth(FOLLOW_SMOOTHING, delta))
	arrived = global_position.distance_to(destination) <= ARRIVE_RADIUS
	
	# Spin while seeking, settle and pulse once locked on
	if arrived:
		var pulse := 0.5 + 0.5 * sin(_time * 8.0)
		_sprite.scale = Vector2.ONE * (1.0 + 0.1 * pulse)
		_sprite.modulate.a = 0.8 + 0.2 * pulse
		_sprite.rotation = lerp_angle(_sprite.rotation, 0.0, Math.smooth(FOLLOW_SMOOTHING, delta))
	else:
		_sprite.rotation += SPIN_SPEED * TAU * delta
		_sprite.scale = Vector2.ONE * 1.3
		_sprite.modulate.a = 0.6


## The enemy currently being marked, or null while the reticle is still seeking.
func get_marked() -> Node2D:
	if not arrived or not _is_valid_target(target): return null
	return target


func _pick_target() -> void:
	retarget_timer = retarget_time
	arrived = false
	
	var candidates: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(Global.ENEMY_GROUP):
		if not _is_valid_target(node): continue
		if is_instance_valid(target) and node == target: continue
		if node.global_position.distance_to(player.global_position) > SEARCH_RADIUS * Global.UNIT_SCALE: continue
		candidates.append(node)
	
	# Stay on the current target if it's the only one around
	if candidates.is_empty() and _is_valid_target(target):
		return
	target = candidates.pick_random() if not candidates.is_empty() else null


## Untyped so freed instances can be passed in safely.
func _is_valid_target(node) -> bool:
	if not is_instance_valid(node): return false
	if node is not Node2D: return false
	if not node.has_method(Hurtbox.METHOD_NAME): return false
	if node is Enemy and node.dying: return false
	return true
