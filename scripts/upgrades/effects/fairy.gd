extends Node2D
## Flies to a random nearby enemy and hovers over it. The Fairy upgrade boosts damage against the marked enemy.


## In Global.UNIT_SCALE
const SEARCH_RADIUS := 10.0
## Pixels above the target's origin to hover at
const HOVER_HEIGHT := 30.0
## Pixels from the hover point to count as arrived
const ARRIVE_RADIUS := 8.0
const FOLLOW_SMOOTHING := 6.0
const COLOR := Color(1.0, 0.75, 0.95)


var player: Player
## Seconds before switching to a different enemy
var retarget_time := 6.0

var target: Node2D
var retarget_timer := 0.0
var arrived := false

var _time := 0.0


func _ready() -> void:
	top_level = true
	global_position = player.global_position
	
	var sorting := SortingLayer.new()
	sorting.layer_name = &"overlay"
	add_child(sorting)


func _physics_process(delta: float) -> void:
	_time += delta
	retarget_timer -= delta
	
	if not _is_valid_target(target) or retarget_timer <= 0.0:
		_pick_target()
	
	var destination := player.global_position + Vector2(-14.0, -26.0)
	if target:
		destination = target.global_position + Vector2(0.0, -HOVER_HEIGHT)
	destination.y += sin(_time * 3.0) * 3.0
	
	global_position = global_position.lerp(destination, Math.smooth(FOLLOW_SMOOTHING, delta))
	arrived = target != null and global_position.distance_to(destination) <= ARRIVE_RADIUS
	
	queue_redraw()


## The enemy currently being marked, or null while the fairy is still flying.
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


func _draw() -> void:
	var flap := absf(sin(_time * 20.0))
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2.ZERO,
			Vector2(side * 7.0, -5.0 * flap - 2.0),
			Vector2(side * 6.0, 2.0),
		])
		draw_colored_polygon(wing, Color(1.0, 1.0, 1.0, 0.7))
	draw_circle(Vector2.ZERO, 5.0, Color(COLOR, 0.35))
	draw_circle(Vector2.ZERO, 2.5, COLOR)
	
	var marked := get_marked()
	if marked:
		var mark_pos := to_local(marked.global_position)
		var pulse := 0.5 + 0.5 * sin(_time * 8.0)
		draw_arc(mark_pos, 16.0 + pulse * 2.0, 0.0, TAU, 32, Color(COLOR, 0.6 + 0.4 * pulse), 1.5)
		draw_dashed_line(Vector2.ZERO, mark_pos, Color(COLOR, 0.3), 1.0, 3.0)
