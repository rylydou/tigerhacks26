class_name FillIsolatedStep
extends MapStep
## Flood fills air from one arena and turns every unreached air cell into wall,
## leaving a single connected cavity.

## Index of the arena to start the fill from.
@export var start_arena := 0


func apply(ctx: MapContext) -> void:
	if ctx.arenas.is_empty():
		return
	var grid := ctx.grid
	var start := Vector2i(ctx.arenas[clampi(start_arena, 0, ctx.arenas.size() - 1)].center)
	var reached := PackedByteArray()
	reached.resize(grid.cells.size())

	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if not grid.in_bounds(p.x, p.y) or grid.is_wall(p.x, p.y):
			continue
		var i := p.y * grid.size.x + p.x
		if reached[i]:
			continue
		reached[i] = 1
		stack.append_array([p + Vector2i.LEFT, p + Vector2i.RIGHT, p + Vector2i.UP, p + Vector2i.DOWN])

	for i in grid.cells.size():
		if not reached[i]:
			grid.cells[i] = 1


func label() -> String:
	return "hole_fill"
