class_name Move extends Step


enum DirectionMode {
	CurrentAngle,
	Strafe,
	Random,
}


@export var direction_mode := DirectionMode.CurrentAngle
@export var async := false
@export var time := 0.0
@export var speed := 0.0
@export var distance := 0.0
@export var bloackable := true


var timer := 0.0

var angle := 0.0
var move_speed := 0.0


func _start() -> int:
	enemy.update_move_angle()
	angle = enemy.move_angle
	match direction_mode:
		DirectionMode.Strafe:
			angle += (PI / 2.0) * Math.rand_sign()
		DirectionMode.Random:
			angle = randf() * TAU
	
	# Any two of time/speed/distance define the move. A negative speed or
	# distance moves backwards.
	var backwards := speed < 0.0 or distance < 0.0
	timer = time
	move_speed = absf(speed)
	if distance != 0.0:
		if timer <= 0.0 and move_speed > 0.0:
			timer = absf(distance) / move_speed
		elif timer > 0.0:
			move_speed = absf(distance) / timer
	if backwards: move_speed = -move_speed
	
	if move_speed != 0.0:
		enemy.velocity = Vector2.from_angle(angle) * move_speed * 16.0
	if async: return DONE
	return CONTINUE


func _tick(delta: float) -> int:
	if async: return DONE
	return move(delta)


func _physics_process(delta: float) -> void:
	if not async: return
	if timer <= 0.0: return
	move(delta)


func move(delta: float) -> int:
	if not is_instance_valid(enemy): return DONE
	if enemy.stun_timer > 0.0: return CONTINUE
	
	if move_speed != 0.0:
		enemy.velocity = Vector2.from_angle(angle) * move_speed * 16.0
	var hit := enemy.move_and_slide()
	if hit and bloackable:
		return DONE
	
	timer -= delta
	if timer > 0.0:
		return CONTINUE
	return DONE
