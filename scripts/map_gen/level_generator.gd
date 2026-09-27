class_name LevelGenerator
extends TileMapLayer
## Runs a pipeline of MapSteps, paints walls as tiles and spawns tumors at arena centers.
## New generation modes = new MapStep subclasses or a different step list.

const SPAWNED_GROUP := &"level_generator_spawned"

## The active level, for systems that need map queries (e.g. enemy pathfinding).
static var current: LevelGenerator

## Pathfinding grid over the generated map, in tile coords. Walls are solid.
var nav := AStarGrid2D.new()

@export var map_size := Vector2i(256, 256)
## 0 = random each run.
@export var rng_seed := 0
@export var steps: Array[MapStep] = [
	PlaceArenasStep.new(),
	NoiseStep.new(),
	CarveTunnelsStep.new(),
	SmoothStep.new(),
	FillIsolatedStep.new(),
]
@export_group("Tiles")
@export var wall_source_id := 0
@export var wall_atlas_coords := Vector2i.ZERO
## Visual layers rebuilt from this layer after generating. Each needs a refresh(world) method.
@export var visual_layers: Array[TileMapLayer] = []
@export_group("Spawns")
## Moved to the open cell nearest the map center after generating.
@export var player: Node2D
@export var tumor_scene: PackedScene = preload("res://scenes/objectives/tumor.tscn")
@export_group("Debug")
@export var save_png := false
@export var output_path := "user://map.png"
## Marks arena centers with red pixels in the saved PNG.
@export var mark_arenas := true


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	generate()


func to_tile(world_position: Vector2) -> Vector2i:
	return local_to_map(to_local(world_position))


func to_world(tile: Vector2i) -> Vector2:
	return to_global(map_to_local(tile))


## True if the world position is inside the map and not in a wall.
func is_open(world_position: Vector2) -> bool:
	var tile := to_tile(world_position)
	return nav.is_in_boundsv(tile) and not nav.is_point_solid(tile)


## Tile path between two world positions. Empty if unreachable.
func get_id_path(from: Vector2, to: Vector2) -> Array[Vector2i]:
	var from_tile := to_tile(from)
	var to_tile_id := to_tile(to)
	if not nav.is_in_boundsv(from_tile) or not nav.is_in_boundsv(to_tile_id):
		return []
	return nav.get_id_path(from_tile, to_tile_id, true)


func generate() -> MapGrid:
	var used_seed := rng_seed if rng_seed != 0 else randi()
	var ctx := MapContext.new(map_size, used_seed)
	for step in steps:
		if step:
			step.apply(ctx)

	_paint_tiles(ctx.grid)
	_build_nav(ctx.grid)
	for layer in visual_layers:
		if layer and layer.has_method(&"refresh"):
			layer.refresh(self)
	_spawn_tumors(ctx)
	if player:
		player.global_position = to_global(map_to_local(_to_cell(ctx.grid, ctx.grid.find_open_cell_near(ctx.grid.size / 2))))
	if save_png:
		_save_png(ctx)
	print("Map generated (seed %d), %d wall tiles" % [used_seed, get_used_cells().size()])
	return ctx.grid


func _paint_tiles(grid: MapGrid) -> void:
	clear()
	for y in grid.size.y:
		for x in grid.size.x:
			if grid.is_wall(x, y):
				set_cell(_to_cell(grid, Vector2i(x, y)), wall_source_id, wall_atlas_coords)


func _build_nav(grid: MapGrid) -> void:
	nav.region = Rect2i(_to_cell(grid, Vector2i.ZERO), grid.size)
	nav.cell_size = tile_set.tile_size
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in grid.size.y:
		for x in grid.size.x:
			if grid.is_wall(x, y):
				nav.set_point_solid(_to_cell(grid, Vector2i(x, y)))


func _spawn_tumors(ctx: MapContext) -> void:
	for child in get_children():
		if child.is_in_group(SPAWNED_GROUP):
			child.free()
	if not tumor_scene:
		return
	for arena in ctx.arenas:
		var tumor: Node2D = tumor_scene.instantiate()
		tumor.position = map_to_local(_to_cell(ctx.grid, Vector2i(arena.center)))
		tumor.add_to_group(SPAWNED_GROUP)
		add_child(tumor)


## Grid coords -> tile coords, centering the map on this node's origin.
func _to_cell(grid: MapGrid, p: Vector2i) -> Vector2i:
	return p - grid.size / 2


func _save_png(ctx: MapContext) -> void:
	var image := ctx.grid.to_image()
	if mark_arenas:
		image.convert(Image.FORMAT_RGB8)
		for arena in ctx.arenas:
			image.set_pixelv(Vector2i(arena.center), Color.RED)
	var err := image.save_png(output_path)
	if err == OK:
		print("Map saved to %s" % ProjectSettings.globalize_path(output_path))
	else:
		push_error("Failed to save map: %s" % error_string(err))
