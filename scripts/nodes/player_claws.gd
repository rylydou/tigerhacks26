class_name PlayerClaws extends Node2D
## Purely visual trailing claws for the player.
##
## Each claw is simulated as an angle around the head attach point driven by a
## damped spring toward "behind the aim direction", plus drag from movement,
## soft separation from neighbouring claws, and a small idle wobble.
## Place under a non-rotating node (e.g. Anchor) so the aim rotation is felt as lag.


@export var aim_node: Node2D
## Where the arms connect to the head.
@export var head_attach: Node2D

@export_group("Visuals")
@export var claw_texture: Texture2D
@export var arm_texture: Texture2D
@export var claw_scale := 0.5
@export var arm_width := 7.0
## Distance from the end of the arm to the claw sprite's center.
@export var claw_offset := 7.0

@export_group("Layout")
@export_range(1, 8) var claw_count := 3
## Total fan angle across all claws, in degrees.
@export var fan_degrees := 60.0
@export var arm_length := 15.0

@export_group("Spring")
@export var stiffness := 60.0
@export var damping := 7.0
@export var max_angular_speed := 30.0

@export_group("Movement Drag")
## How strongly movement swings the claws away from the travel direction.
@export var drag_strength := 1.2
## Fraction of extra length gained per pixel/sec of speed.
@export var stretch_per_speed := 0.0004
@export var max_stretch := 0.15
@export var stretch_smoothing := 8.0

@export_group("Separation")
@export var min_separation_degrees := 22.0
@export var separation_strength := 250.0

@export_group("Arm Bend")
## How much the arm midpoint bows sideways per rad/sec of swing.
@export var bend_per_angular_speed := 0.8
@export var max_bend := 5.0
@export var bend_smoothing := 12.0

@export_group("Idle Wobble")
@export var wobble_degrees := 4.0
@export var wobble_speed := 3.0

@export_group("Individuality")
## How much each claw's spring, drag, length and wobble differ from the others (0 = identical).
@export_range(0.0, 1.0) var trait_variation := 0.35
## Each claw drifts toward a new random offset from its fan slot every so often.
@export var wander_degrees := 12.0
@export var wander_interval_min := 0.6
@export var wander_interval_max := 2.2
@export var wander_smoothing := 2.5
## Random little flicks of angular velocity, per claw per second.
@export var twitch_chance := 0.25
@export var twitch_strength := 4.0


class Claw:
	var angle := 0.0
	var angular_velocity := 0.0
	var bend := 0.0
	var phase := 0.0
	var fan_offset := 0.0
	# Personality multipliers, rolled once
	var stiffness_mul := 1.0
	var damping_mul := 1.0
	var drag_mul := 1.0
	var length_mul := 1.0
	var wobble_mul := 1.0
	var wobble_speed_mul := 1.0
	# Wandering target offset
	var wander := 0.0
	var wander_target := 0.0
	var wander_timer := 0.0
	var line: Line2D
	var sprite: Sprite2D


var _claws: Array[Claw] = []
var _prev_attach := Vector2.ZERO
var _stretch := 0.0
var _time := 0.0
var _initialized := false


func _ready() -> void:
	for i in claw_count:
		var claw := Claw.new()
		var t := 0.5 if claw_count == 1 else float(i) / (claw_count - 1)
		claw.fan_offset = deg_to_rad(lerpf(-fan_degrees, fan_degrees, t) * 0.5)
		claw.phase = randf() * TAU
		claw.stiffness_mul = _roll()
		claw.damping_mul = _roll()
		claw.drag_mul = _roll()
		claw.length_mul = 1.0 + randf_range(-0.12, 0.12) * trait_variation / 0.35
		claw.wobble_mul = _roll()
		claw.wobble_speed_mul = _roll()
		claw.wander_timer = randf_range(0.0, wander_interval_max)

		claw.line = Line2D.new()
		claw.line.width = arm_width
		claw.line.texture = arm_texture
		claw.line.texture_mode = Line2D.LINE_TEXTURE_TILE
		claw.line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		claw.line.joint_mode = Line2D.LINE_JOINT_ROUND
		claw.line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		claw.line.z_index = -1 # Arm below claw end
		add_child(claw.line)

		claw.sprite = Sprite2D.new()
		claw.sprite.texture = claw_texture
		claw.sprite.scale = Vector2.ONE * claw_scale
		add_child(claw.sprite)

		_claws.append(claw)


func _physics_process(delta: float) -> void:
	if not aim_node or not head_attach or delta <= 0.0: return

	var attach := head_attach.global_position
	var aim_angle := aim_node.global_rotation
	var behind := aim_angle + PI

	if not _initialized:
		_initialized = true
		_prev_attach = attach
		for claw in _claws:
			claw.angle = behind + claw.fan_offset

	var attach_velocity := (attach - _prev_attach) / delta
	_prev_attach = attach
	_time += delta

	var target_stretch := clampf(attach_velocity.length() * stretch_per_speed, 0.0, max_stretch)
	_stretch = lerpf(_stretch, target_stretch, 1.0 - exp(-stretch_smoothing * delta))
	var length := arm_length * (1.0 + _stretch)

	var min_sep := deg_to_rad(min_separation_degrees)
	var wobble := deg_to_rad(wobble_degrees)

	for i in _claws.size():
		var claw := _claws[i]
		_update_wander(claw, delta)
		var rest := behind + claw.fan_offset + claw.wander + _wobble(claw) * wobble * claw.wobble_mul
		var accel := -stiffness * claw.stiffness_mul * angle_difference(rest, claw.angle) \
				- damping * claw.damping_mul * claw.angular_velocity

		# Tip experiences the opposite of the attach point's motion
		var tangent := Vector2.from_angle(claw.angle).orthogonal()
		accel += (-attach_velocity).dot(tangent) * drag_strength * claw.drag_mul / (length * claw.length_mul)

		for j in _claws.size():
			if i == j: continue
			var diff := angle_difference(_claws[j].angle, claw.angle)
			if absf(diff) < min_sep:
				# Push away from the neighbour; tie-break by index so they never stack
				var dir := signf(diff) if diff != 0.0 else signf(i - j)
				accel += dir * (min_sep - absf(diff)) * separation_strength

		if randf() < twitch_chance * delta:
			claw.angular_velocity += randf_range(-1.0, 1.0) * twitch_strength

		claw.angular_velocity = clampf(claw.angular_velocity + accel * delta, -max_angular_speed, max_angular_speed)

	for claw in _claws:
		claw.angle = wrapf(claw.angle + claw.angular_velocity * delta, -PI, PI)
		var target_bend := clampf(-claw.angular_velocity * bend_per_angular_speed, -max_bend, max_bend)
		claw.bend = lerpf(claw.bend, target_bend, 1.0 - exp(-bend_smoothing * delta))
		_update_visuals(claw, attach, length * claw.length_mul)


func _update_visuals(claw: Claw, attach: Vector2, length: float) -> void:
	var dir := Vector2.from_angle(claw.angle)
	var mid := attach + dir * length * 0.5 + dir.orthogonal() * claw.bend
	var end := attach + dir * length

	claw.line.set_point_position(0, to_local(attach))
	claw.line.set_point_position(1, to_local(mid))
	claw.line.set_point_position(2, to_local(end))

	# Claw sprite art points along +Y; face it along the arm direction
	claw.sprite.position = to_local(end + dir * claw_offset)
	claw.sprite.global_rotation = claw.angle - PI * 0.5


## Two layered sines at unrelated frequencies so the drift never looks periodic.
func _wobble(claw: Claw) -> float:
	var t := _time * wobble_speed * claw.wobble_speed_mul
	return sin(t + claw.phase) * 0.65 + sin(t * 0.37 + claw.phase * 2.3) * 0.35


func _update_wander(claw: Claw, delta: float) -> void:
	claw.wander_timer -= delta
	if claw.wander_timer <= 0.0:
		claw.wander_timer = randf_range(wander_interval_min, wander_interval_max)
		claw.wander_target = deg_to_rad(randf_range(-wander_degrees, wander_degrees))
	claw.wander = lerpf(claw.wander, claw.wander_target, 1.0 - exp(-wander_smoothing * delta))


func _roll() -> float:
	return 1.0 + randf_range(-trait_variation, trait_variation)
