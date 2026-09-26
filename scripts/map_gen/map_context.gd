class_name MapContext
extends RefCounted
## Shared state passed through every MapStep.

class Arena:
	var center: Vector2
	var radius: float

	func _init(arena_center: Vector2, arena_radius: float) -> void:
		center = arena_center
		radius = arena_radius


var grid: MapGrid
var rng: RandomNumberGenerator
var arenas: Array[Arena] = []


func _init(grid_size: Vector2i, rng_seed: int) -> void:
	grid = MapGrid.new(grid_size)
	rng = RandomNumberGenerator.new()
	rng.seed = rng_seed
