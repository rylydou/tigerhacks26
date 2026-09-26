@tool
extends Node
class_name map_generator

@export var map_dimensions: Vector2i = Vector2i(50, 50) # Increased size for better caves
@export var fill_chance: float = 0.45
@export var itterations: int = 4
@export var tilemap_layer: TileMapLayer
@export var wall_atlas_coords: Vector2i = Vector2i(1, 1)
@export var wall_source_id: int = 0

@export_tool_button("Generate Map") var map_gen_button = generate_map

func _ready() -> void:
	generate_map()

func generate_map() -> void:
	var grid: Array = grid_maker(map_dimensions)
	grid = grid_itterations(grid)
	render_map(grid)

func grid_helper(x_coord: int, y_coord: int, size: int) -> int:
	return y_coord * size + x_coord

func grid_maker(dimensions: Vector2i) -> Array:
	var grid: Array = []
	grid.resize(dimensions.x * dimensions.y)
	
	# Loop y outer, x inner to match y * size + x indexing
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
				
				# Proper Cave Automata Rules:
				# - 5 or more neighbor walls: becomes solid rock (connects walls together)
				# - 3 or fewer neighbor walls: clears into open cave space
				if wall_count >= 5:
					write_grid[idx] = true
				elif wall_count <= 3:
					write_grid[idx] = false
					
		read_grid = write_grid
		
	return read_grid

func render_map(grid: Array) -> void:
	if !tilemap_layer:
		push_warning("map_generator: No TileMapLayer assigned.")
		return
		
	tilemap_layer.clear()
	for y in range(map_dimensions.y):
		for x in range(map_dimensions.x):
			if grid[grid_helper(x, y, map_dimensions.x)] == true:
				tilemap_layer.set_cell(Vector2i(x, y), wall_source_id, wall_atlas_coords)
