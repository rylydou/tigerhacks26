class_name BasicPlayerProjectile extends PlayerProjectile


@export var base_range := 4.0
@export var base_speed := 8.0


func _physics_process(delta: float) -> void:
	position += (
		transform.basis_xform(Vector2.RIGHT) *
		base_speed *
		speed_scale *
		delta * 16.0
	)
	
	super._physics_process(delta)
	
	if distance_traveled > base_range * range_scale * 16.0:
		destroy(false)
		return
