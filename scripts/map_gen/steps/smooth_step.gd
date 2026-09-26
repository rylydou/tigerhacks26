class_name SmoothStep
extends MapStep
## Cellular automata smoothing based on the 8-neighbor wall count.

@export var iterations := 6
## Fewer wall neighbors than this -> air.
@export var air_below := 4
## More wall neighbors than this -> wall.
@export var fill_above := 4


func apply(ctx: MapContext) -> void:
	var grid := ctx.grid
	for _i in iterations:
		var next := grid.cells.duplicate()
		for y in grid.size.y:
			for x in grid.size.x:
				var walls := grid.count_wall_neighbors(x, y)
				if walls < air_below:
					next[y * grid.size.x + x] = 0
				elif walls > fill_above:
					next[y * grid.size.x + x] = 1
		grid.cells = next
