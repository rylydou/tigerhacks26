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
## Disable when something else (e.g. GameLoop) calls generate().
@export var generate_on_ready := true
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
## Tumors (arenas) on level 1. Overrides PlaceArenasStep.count. Negative = use the step's count.
@export var tumors_base := 1
## Extra tumors per level after the first.
@export var tumors_per_level := 1.0
@export var tumors_max := 5
@export_group("Random Waves")
## Waves (picked from Game.waves) scattered over the map at level start, each as a clustered pack.
@export var random_waves_enabled := true
## Waves on level 1.
@export var random_waves_base := 4
## Extra waves per level after the first.
@export var random_waves_per_level := 1.0
@export var random_waves_max := 12
## In Global.UNIT_SCALE. No enemy spawns within this distance of the player's spawn.
@export var player_safe_radius := 12.0
## In Global.UNIT_SCALE. Pack members spawn within this distance of the pack center.
@export var pack_radius := 3.0
## In Global.UNIT_SCALE. Minimum distance between two pack centers.
@export var pack_min_distance := 10.0
## In tiles. Packs keep this far outside tumor arena edges.
@export var arena_margin := 4.0
## Random center picks per wave before giving up on it.
@export var pack_attempts := 30
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
	if generate_on_ready:
		generate()


func to_tile(world_position: Vector2) -> Vector2i:
	return local_to_map(to_local(world_position))


func to_world(tile: Vector2i) -> Vector2:
	return to_global(map_to_local(tile))


## True if the world position is inside the map and not in a wall.
func is_open(world_position: Vector2) -> bool:
	var tile := to_tile(world_position)
	return nav.is_in_boundsv(tile) and not nav.is_point_solid(tile)


## World-space centers of every open tile within max_distance of the world position.
func get_open_positions_near(world_position: Vector2, max_distance: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var center := to_tile(world_position)
	var reach := ceili(max_distance / minf(nav.cell_size.x, nav.cell_size.y)) + 1
	for y in range(center.y - reach, center.y + reach + 1):
		for x in range(center.x - reach, center.x + reach + 1):
			var tile := Vector2i(x, y)
			if not nav.is_in_boundsv(tile) or nav.is_point_solid(tile):
				continue
			var pos := to_world(tile)
			if pos.distance_to(world_position) <= max_distance:
				result.append(pos)
	return result


## Tile path between two world positions. Empty if unreachable.
func get_id_path(from: Vector2, to: Vector2) -> Array[Vector2i]:
	var from_tile := to_tile(from)
	var to_tile_id := to_tile(to)
	if not nav.is_in_boundsv(from_tile) or not nav.is_in_boundsv(to_tile_id):
		return []
	return nav.get_id_path(from_tile, to_tile_id, true)


## level scales the number of tumors and random waves.
func generate(level := 1) -> MapGrid:
	var used_seed := rng_seed if rng_seed != 0 else randi()
	var ctx := MapContext.new(map_size, used_seed)
	if tumors_base >= 0:
		ctx.arena_count = mini(tumors_base + floori(tumors_per_level * (level - 1)), tumors_max)
	for step in steps:
		if step:
			step.apply(ctx)

	_paint_tiles(ctx.grid)
	_build_nav(ctx.grid)
	for layer in visual_layers:
		if layer and layer.has_method(&"refresh"):
			layer.refresh(self)
	_spawn_tumors(ctx)
	var player_spawn := to_world(_to_cell(ctx.grid, ctx.grid.find_open_cell_near(ctx.grid.size / 2)))
	if player:
		player.global_position = player_spawn
	if random_waves_enabled:
		_spawn_random_waves(ctx, player_spawn, level)
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
	# update() is a no-op when region/cell size are unchanged, which would keep the previous
	# level's solid points. clear() forces a full rebuild.
	nav.clear()
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


## Scatters clustered packs from Game.waves over open ground away from the player and arenas.
## Enemies go in the despawn group, so GameLoop clears them between levels.
func _spawn_random_waves(ctx: MapContext, player_spawn: Vector2, level: int) -> void:
	var waves: Array[Wave] = Game.waves
	if waves.is_empty():
		return
	var count := mini(random_waves_base + floori(random_waves_per_level * (level - 1)), random_waves_max)
	if count <= 0:
		return

	var safe_distance := player_safe_radius * Global.UNIT_SCALE
	var centers: Array[Vector2] = []
	for y in ctx.grid.size.y:
		for x in ctx.grid.size.x:
			if ctx.grid.is_wall(x, y):
				continue
			var p := Vector2(x, y)
			if ctx.arenas.any(func(a: MapContext.Arena) -> bool:
					return p.distance_to(a.center) < a.radius + arena_margin):
				continue
			var pos := to_world(_to_cell(ctx.grid, Vector2i(x, y)))
			if pos.distance_to(player_spawn) >= safe_distance:
				centers.append(pos)
	if centers.is_empty():
		push_warning("LevelGenerator: no open ground for random waves")
		return

	var placed: Array[Vector2] = []
	for _i in count:
		var center := _pick_pack_center(ctx.rng, centers, placed)
		if center == Vector2.INF:
			push_warning("LevelGenerator: only placed %d/%d random waves" % [placed.size(), count])
			return
		placed.append(center)
		# Game.waves already contains each wave repeated by its weight
		_spawn_pack(ctx.rng, waves[ctx.rng.randi() % waves.size()], center, player_spawn)


## Random candidate at least pack_min_distance from every placed pack. Vector2.INF if none found.
func _pick_pack_center(rng: RandomNumberGenerator, candidates: Array[Vector2], placed: Array[Vector2]) -> Vector2:
	var min_distance := pack_min_distance * Global.UNIT_SCALE
	for _attempt in pack_attempts:
		var pos := candidates[rng.randi() % candidates.size()]
		if placed.all(func(other: Vector2) -> bool: return pos.distance_to(other) >= min_distance):
			return pos
	return Vector2.INF


func _spawn_pack(rng: RandomNumberGenerator, wave: Wave, center: Vector2, player_spawn: Vector2) -> void:
	var safe_distance := player_safe_radius * Global.UNIT_SCALE
	var spots := get_open_positions_near(center, pack_radius * Global.UNIT_SCALE).filter(
		func(pos: Vector2) -> bool: return pos.distance_to(player_spawn) >= safe_distance)
	if spots.is_empty():
		spots = [center]
	var available: Array = []
	for entry in wave.spawns:
		for _i in entry.count:
			# Spread enemies over different tiles, only doubling up once every tile is taken
			if available.is_empty():
				available = spots.duplicate()
			var enemy: Node2D = entry.scene.instantiate()
			enemy.add_to_group(Global.DESPAWN_GROUP)
			enemy.global_position = available.pop_at(rng.randi() % available.size())
			get_tree().current_scene.add_child.call_deferred(enemy)


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
