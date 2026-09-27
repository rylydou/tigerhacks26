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
## Overrides PlaceArenasStep.count when >= 0 (e.g. to scale tumors with level).
var arena_count := -1
## When true, snapshot() records images of the grid for debugging/presentation.
var record_snapshots := false
var snapshots: Dictionary[String, Image] = {}


func _init(grid_size: Vector2i, rng_seed: int) -> void:
	grid = MapGrid.new(grid_size)
	rng = RandomNumberGenerator.new()
	rng.seed = rng_seed


## Records the grid (white = wall) with arena centers as red pixels.
func snapshot(label: String) -> void:
	if not record_snapshots or label.is_empty():
		return
	var image := grid.to_image()
	image.convert(Image.FORMAT_RGB8)
	for arena in arenas:
		image.set_pixelv(Vector2i(arena.center), Color.RED)
	snapshots[label] = image
