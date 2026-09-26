@tool
extends Node
class_name map_generator

@export var map_dimensions: Vector2i = Vector2i(50, 50)
@export var fill_chance: float = 0.45
@export var itterations: int = 4

@export_group("TileMap Settings")
@export var tilemap_layer: TileMapLayer
@export var wall_atlas_coords: Vector2i = Vector2i(1, 1)
@export var wall_source_id: int = 0

@export_tool_button("Generate Map") var map_gen_button = generate_map

func _ready() -> void:
	generate_map()

func generate_map() -> void:
	var grid: Array = grid_maker(map_dimensions)
	grid = grid_itterations(grid)
	fill_disconnected_pockets(grid)
	render_map(grid)

func grid_helper(x_coord: int, y_coord: int, size: int) -> int:
	return y_coord * size + x_coord

func grid_maker(dimensions: Vector2i) -> Array:
	var grid: Array = []
	grid.resize(dimensions.x * dimensions.y)
	
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var idx: int = grid_helper(x, y, dimensions.x)
			if x == 0 or x == dimensions.x - 1 or y == 0 or y == dimensions.y - 1:
				grid[idx] = true
			else:
				grid[idx] = randf() < fill_chance
				
	return grid

func wall_counter(coords: Vector2i, grid: Array, dimensions: Vector2i) -> int:
	var wall_count: int = 0
	for x in range(coords.x - 1, coords.x + 2):
		for y in range(coords.y - 1, coords.y + 2):
			if x == coords.x and y == coords.y:
				continue
			if x < 0 or y < 0 or x >= dimensions.x or y >= dimensions.y:
				wall_count += 1
			elif grid[grid_helper(x, y, dimensions.x)]:
				wall_count += 1
	return wall_count

func grid_itterations(current_grid: Array) -> Array:
	var read_grid: Array = current_grid
	
	for i in range(itterations):
		var write_grid: Array = read_grid.duplicate()
		for y in range(1, map_dimensions.y - 1):
			for x in range(1, map_dimensions.x - 1):
				var idx: int = grid_helper(x, y, map_dimensions.x)
				var wall_count: int = wall_counter(Vector2i(x, y), read_grid, map_dimensions)
				
				if wall_count >= 5:
					write_grid[idx] = true
				elif wall_count <= 3:
					write_grid[idx] = false
					
		read_grid = write_grid
		
	return read_grid

# --- POCKET FILLING LOGIC ---

func fill_disconnected_pockets(grid: Array) -> void:
	var regions: Array[Array] = get_all_floor_regions(grid)
	if regions.size() <= 1:
		return # 1 or 0 regions means there are no disconnected pockets

	# Find the main (largest) room
	var main_region: Array = regions[0]
	for region in regions:
		if region.size() > main_region.size():
			main_region = region

	# Fill all smaller isolated regions back in with walls
	for region in regions:
		if region == main_region:
			continue
			
		for tile in region:
			var idx: int = grid_helper(tile.x, tile.y, map_dimensions.x)
			grid[idx] = true # Turn floor tile back into wall

func get_all_floor_regions(grid: Array) -> Array[Array]:
	var regions: Array[Array] = []
	var visited: Array[bool] = []
	visited.resize(grid.size())
	visited.fill(false)

	for y in range(1, map_dimensions.y - 1):
		for x in range(1, map_dimensions.x - 1):
			var idx: int = grid_helper(x, y, map_dimensions.x)
			# Find any unvisited floor tile (grid[idx] == false)
			if !visited[idx] and grid[idx] == false:
				var new_region: Array[Vector2i] = get_region_tiles(grid, Vector2i(x, y), visited)
				regions.append(new_region)

	return regions

func get_region_tiles(grid: Array, start: Vector2i, visited: Array[bool]) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	
	visited[grid_helper(start.x, start.y, map_dimensions.x)] = true

	while queue.size() > 0:
		var tile: Vector2i = queue.pop_front()
		tiles.append(tile)

		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor: Vector2i = tile + dir
			if neighbor.x > 0 and neighbor.x < map_dimensions.x - 1 and neighbor.y > 0 and neighbor.y < map_dimensions.y - 1:
				var idx: int = grid_helper(neighbor.x, neighbor.y, map_dimensions.x)
				# Check if neighbor is an unvisited floor tile
				if !visited[idx] and grid[idx] == false:
					visited[idx] = true
					queue.append(neighbor)

	return tiles

# --- RENDERING ---

func render_map(grid: Array) -> void:
	if !tilemap_layer:
		push_warning("map_generator: No TileMapLayer assigned.")
		return
		
	tilemap_layer.clear()
	for y in range(map_dimensions.y):
		for x in range(map_dimensions.x):
			if grid[grid_helper(x, y, map_dimensions.x)] == true:
				tilemap_layer.set_cell(Vector2i(x, y), wall_source_id, wall_atlas_coords)
