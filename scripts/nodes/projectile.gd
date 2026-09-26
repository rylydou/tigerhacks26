class_name PlayerProjectile extends ShapeCast2D


signal impacted()
signal destroyed_from_collision()
signal destroyed_from_range()


@export var damage := 0
@export var damage_variation := 0.15
@export var knockback_strength := 0.0
@export var pierce_count := 0
@export var stun := 0.0
@export var hits_walls := true


@onready var direction := global_transform.basis_xform(Vector2.RIGHT)
@onready var _previous_position := position

@onready var raycast := RayCast2D.new()


var player: Player

var speed_scale := 1.0
var range_scale := 1.0

var distance_traveled := 0.0
var remembered_hits: Array[Node2D] = []


func _ready() -> void:
	add_child(raycast)
	raycast.collision_mask = 0
	if hits_walls:
		raycast.set_collision_mask_value(2, true)
	
	pierce_count = 1
	
	_physics_process(0.0)


func _physics_process(delta: float) -> void:
	var saved_position := position
	
	var motion := saved_position - _previous_position
	var distance := motion.length()
	distance_traveled += distance
	
	raycast.target_position.y = 0
	raycast.target_position.x = distance
	raycast.force_raycast_update()
	
	position = _previous_position
	if raycast.is_colliding():
		target_position.x = to_local(raycast.get_collision_point()).length()
	else:
		target_position.x = distance
	force_shapecast_update()
	
	for collision: Dictionary in collision_result:
		var node: Node2D = collision.collider
		if remembered_hits.has(node): continue
		var has_hit := player.try_attack(node, damage * Math.rand_var(1.0, damage_variation / 2.0), knockback_strength)
		if has_hit:
			remembered_hits.append(node)
			if stun > 0.0 and node.has_method('stun'):
				node.stun(stun)
			pierce_count -= 1
			damage *= 0.5
			knockback_strength *= 0.5
			if pierce_count < 0:
				position = collision.point
				destroy(true)
				return
	
	if raycast.is_colliding():
		global_position = raycast.get_collision_point()
		destroy(true)
	
	position = saved_position
	_previous_position = position


func destroy(from_collision: bool) -> void:
	if from_collision:
		destroyed_from_collision.emit()
	else:
		destroyed_from_range.emit()
	queue_free()
