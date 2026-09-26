@tool
extends Node
class_name map_generator



@export var map_dimensions: Vector2i = Vector2i(10, 10)
@export var fill_chance: float = 0.45
@export var itterations: int = 3
@export var tilemap_layer: TileMapLayer
@export var wall_atlas_coords: Vector2i = Vector2i(1, 1)
@export var floor_atlas_coords: Vector2i = Vector2i(0, 0)
@export var wall_source_id: int = 0 
@export var floor_source_id: int = 0
@export_tool_button("Generate Map") var map_gen_button = generate_map

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_map()

func generate_map() -> void:
	var grid: Array = grid_maker(map_dimensions)
	grid_itterations(grid)
	render_map(grid)

func grid_helper(x_coord: int, y_coord: int, size: int) -> int:
	return y_coord*size+x_coord
	
func grid_maker(dimensions: Vector2i) -> Array:
	var grid: Array = []
	for x in range(dimensions.x):
		for y in range(dimensions.y):
				if randf() < fill_chance:
					grid.append(true)
				elif x==0 or x==dimensions.x-1 or y==0 or y==dimensions.y-1:
					grid.append(true)
				else:
					grid.append(false)
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
	
func grid_itterations(grid: Array)->void:
	var wall_count: int = 0
	var clone_grid: Array = grid.duplicate()
	for i in range(itterations):
		for x in range(1, map_dimensions.x-1):
			for y in range(1, map_dimensions.y-1):
				wall_count = wall_counter(Vector2i(x, y), grid, map_dimensions)
				if grid[grid_helper(x, y, map_dimensions.x)] == true and wall_count > 4:
					clone_grid[grid_helper(x, y, map_dimensions.x)] = false
				elif grid[grid_helper(x, y, map_dimensions.x)] == false and wall_count <= 8:
					clone_grid[grid_helper(x, y, map_dimensions.x)] = true
		grid = clone_grid

func render_map(grid: Array) -> void:
	if !tilemap_layer:
		pass
	tilemap_layer.clear()
	for x in range(map_dimensions.x):
		for y in range(map_dimensions.y):
			if grid[grid_helper(x, y, map_dimensions.x)]==true:
				tilemap_layer.set_cell(Vector2i(x, y), wall_source_id, wall_atlas_coords)
			else:
				tilemap_layer.set_cell(Vector2i(x, y), floor_source_id, floor_atlas_coords)
	
	
