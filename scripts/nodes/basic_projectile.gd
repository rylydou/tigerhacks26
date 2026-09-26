class_name BasicProjectile extends Projectile


@export var range := 6.0
@export var speed := 5.0

var speed_scale := 1.0
var range_scale := 1.0


@onready var direction := transform.basis_xform(Vector2.RIGHT)
@onready var starting_position := position


func _step(delta: float) -> void:
	var distance := age * speed * Global.UNIT_SCALE
	
	position = starting_position + direction * distance
	
	# prints("age=", age, "distance=", distance)
	
	if distance >= range * Global.UNIT_SCALE * range_scale:
		die()
