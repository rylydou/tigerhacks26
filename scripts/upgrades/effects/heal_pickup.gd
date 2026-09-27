extends Area2D
## Heals the player on touch. Waits on the ground while the player is at full health.


const TEXTURE := preload("res://content/art/health_pickup.png")

var amount := 5.0

var _time := randf() * TAU


func _ready() -> void:
	add_to_group(Global.DESPAWN_GROUP)
	
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(6, true) # Player
	
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	
	var sorting := SortingLayer.new()
	sorting.layer_name = &"effect_mg"
	add_child(sorting)


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	
	for body in get_overlapping_bodies():
		var player := body as Player
		if not player: continue
		if player.health >= player.max_health: continue
		player.heal(amount)
		queue_free()
		return


## Pops out from `from` to a random nearby spot.
func pop_from(from: Vector2) -> void:
	var target := global_position
	global_position = from
	var tween := create_tween()
	tween.tween_property(self, ^"global_position", target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var bob := Vector2(0.0, sin(_time * 4.0) * 1.5)
	draw_texture(TEXTURE, bob - TEXTURE.get_size() * 0.5)
