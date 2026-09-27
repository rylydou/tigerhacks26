class_name MapGrid
extends RefCounted
## Boolean grid stored as bytes (Godot has no PackedBoolArray). 1 = wall, 0 = air.

var size: Vector2i
var cells: PackedByteArray


func _init(grid_size: Vector2i) -> void:
	size = grid_size
	cells.resize(size.x * size.y)


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < size.x and y < size.y


func is_wall(x: int, y: int) -> bool:
	return cells[y * size.x + x] == 1


func set_wall(x: int, y: int, wall: bool) -> void:
	cells[y * size.x + x] = int(wall)


## Counts walls among the 8 neighbors. Out-of-bounds counts as wall.
func count_wall_neighbors(x: int, y: int) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if not in_bounds(nx, ny) or is_wall(nx, ny):
				count += 1
	return count


## Air cell closest to target whose 8 neighbors are also air. Returns target if none found.
func find_open_cell_near(target: Vector2i) -> Vector2i:
	var best := target
	var best_dist := INF
	for y in range(1, size.y - 1):
		for x in range(1, size.x - 1):
			var d := target.distance_squared_to(Vector2i(x, y))
			if d < best_dist and not is_wall(x, y) and count_wall_neighbors(x, y) == 0:
				best_dist = d
				best = Vector2i(x, y)
	return best


func fill_circle(center: Vector2, radius: float, wall: bool) -> void:
	var min_p := Vector2i((center - Vector2.ONE * radius).floor()).max(Vector2i.ZERO)
	var max_p := Vector2i((center + Vector2.ONE * radius).ceil()).min(size - Vector2i.ONE)
	for y in range(min_p.y, max_p.y + 1):
		for x in range(min_p.x, max_p.x + 1):
			if center.distance_squared_to(Vector2(x, y)) <= radius * radius:
				set_wall(x, y, wall)


## White = wall, black = air.
func to_image() -> Image:
	var data := PackedByteArray()
	data.resize(cells.size())
	for i in cells.size():
		data[i] = cells[i] * 255
	return Image.create_from_data(size.x, size.y, false, Image.FORMAT_L8, data)
