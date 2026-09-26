class_name Actor extends CharacterBody2D


@onready var anchor_node: Node2D = %"Anchor"
@onready var flip_node: Node2D = %"Flip"
@onready var aim_node: Node2D = %"Aim"
@onready var sprite: Sprite2D = %"Sprite"


var age := 0.0
var height := 0.0
var height_velocity := 0.0
var angle := 0.0
var input := Vector2.ZERO


func _physics_process(delta: float) -> void:
	age += delta
	
	# Update rotations
	var flip := absf(angle) < PI / 2.0
	aim_node.scale.x = +1.0 if flip else -1.0
	aim_node.rotation = angle + (0.0 if flip else PI)
	flip_node.scale.x = +1.0 if flip else -1.0
	
	# Update height
	if height > 0.0:
		height_velocity -= Global.gravity * delta
	
	height += height_velocity * delta
	
	if height_velocity < 0.0 and height <= 0.0:
		height = 0.0
		height_velocity = 0.0
		#VFX.land_impact(global_position, 32.0)
	
	anchor_node.position.y = -height * 16.0
	anchor_node.z_index = 200 if height > 0.0 else 0
