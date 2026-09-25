class_name Math extends RefCounted


const FACTORIALS: Array[int] = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800, 39916800, 479001600, 6227020800, 87178291200, 1307674368000]


static func sample_point_slope(point_slope: Vector3, x: float) -> float:
	return (point_slope.z * (x - point_slope.x)) + point_slope.y


## Samples a up to 15th degree taylor polynomial
static func sample_taylor(coefficents: Array[float], x: float, center := 0.0) -> float:
	var sum := 0.0
	var t := (x - center)
	
	for n in mini(coefficents.size(), FACTORIALS.size()):
		var coefficent := coefficents[n]
		sum += (coefficent / FACTORIALS[n]) * pow(t, n)
	
	return sum


## Sample a 1st degree taylor polynomial. (Position and Velocity)
static func sample_taylor_1(slopes: Vector2, x: float, center := 0.0) -> float:
	var t := (x - center)
	
	return (
			slopes.x +   # Position
			slopes.y * t # Velocity
	)

## Sample a 2nd degree taylor polynomial. (Position, Velocity, and Acceleration)
static func sample_taylor_2(xva: Vector3, x: float, center := 0.0) -> float:
	var t := (x - center)
	
	return (
			xva.x +                    # Position
			xva.y * t +                # Velocity
			(xva.z / 2.0) * (t ** 2.0) # Acceleration
	)

## Sample a 3rd degree taylor polynomial. (Position, Velocity, Acceleration, and Jolt)
static func sample_taylor_3(xvaj: Vector4, x: float, center := 0.0) -> float:
	var t := (x - center)
	
	return (
			xvaj.x +                      # Position
			xvaj.y * t +                  # Velocity
			(xvaj.z / 2.0) * (t ** 2.0) + # Acceleration
			(xvaj.w / 6.0) * (t ** 3.0)   # Jolt
	)

## Sample a 2nd degree taylor polynomial where x is the center of the taylor polynomial. (Center, Position, Velocity, and Acceleration)
static func sample_taylor_2c(cxva: Vector4, x: float) -> float:
	var t := (x - cxva.x)
	
	return (
			cxva.y +
			cxva.z * t +
			(cxva.w / 2.0) * (t ** 2.0)
	)


static func rotate_90deg_left(vec: Vector2) -> Vector2:
	return Vector2(-vec.y, vec.x)


static func rotate_90deg_right(vec: Vector2) -> Vector2:
	return Vector2(vec.y, -vec.x)


static func jump_gravity(height: float, duration: float) -> float:
	return 8.0 * (height / pow(duration, 2.0))


static func jump_velocity(height: float, gravity: float) -> float:
	return sqrt(2.0 * gravity * height)

static func jump_height(y_velocity: float, gravity: float) -> float:
	return (y_velocity ** 2.0) / (2.0 * gravity)


static func smooth(factor: float, delta: float) -> float:
	return 1 - exp(-delta * factor)


static func friction(speed: float, deceleration: float, smoothing: float, delta: float) -> float:
	speed = move_toward(speed, 0.0, deceleration * delta)
	speed = lerp(speed, 0.0, Math.smooth(smoothing, delta))
	return speed


class LineOnGridIter:
	var from: Vector2
	var to: Vector2
	var _length: float
	
	var _step := 0
	var _current_cel: Vector2i
	
	func _init(from: Vector2, to: Vector2) -> void:
		self.from = from
		self.to = to
		_length = Math.diagonal_distance(from, to)
	
	func _iter_init(arg: Variant) -> bool:
		_step = 0
		_current_cel = from.round()
		return true
	
	func _iter_next(arg: Variant) -> bool:
		var t := 0.0 if _length == 0 else (float(_step) / _length)
		_current_cel = Vector2i(from.lerp(to, t).round())
		return _step <= _length

	func _iter_get(arg: Variant) -> Vector2i:
		return _current_cel


static func line_on_grid(from: Vector2, to: Vector2) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	for cel in line_on_grid_iter(from, to):
		points.append(cel)
	return points


static func line_on_grid_iter(from: Vector2, to: Vector2) -> LineOnGridIter:
	return LineOnGridIter.new(from, to)


static func diagonal_distance(a: Vector2, b: Vector2) -> float:
	var dx := b.x - a.x
	var dy := b.y - a.y
	return maxf(absf(dx), absf(dy))


static func rand_sign() -> float:
	return -1.0 if rand_bool() else +1.0


static func rand_bool(prob := 0.5) -> bool:
	return randf() < prob


## Returns default if curve is null, or else samples a random point from 0.0 to 1.0
static func rand_on_curve(curve: Curve, default := 0.0) -> float:
	if not curve: return default
	return curve.sample_baked(randf())


## Random value with variation
static func rand_var(base_value: float, plus_or_minus: float) -> float:
	return base_value + randf_range(-plus_or_minus, plus_or_minus)


static func rand_dir() -> Vector2:
	return Vector2.from_angle(randf() * TAU)
