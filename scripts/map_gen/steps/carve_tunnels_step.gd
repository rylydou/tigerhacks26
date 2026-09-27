class_name CarveTunnelsStep
extends MapStep
## Connects all arenas via a minimum spanning tree (Prim) and carves wide tunnels.

## Tunnel half-width in cells.
@export var radius := 5.0
## Chance to also carve each non-tree connection (adds loops).
@export_range(0.0, 1.0) var extra_connection_chance := 0.0


func apply(ctx: MapContext) -> void:
	var arenas := ctx.arenas
	if arenas.size() < 2:
		return
	var in_tree: Array[int] = [0]
	var edges := {}
	while in_tree.size() < arenas.size():
		var best := Vector2i(-1, -1)
		var best_dist := INF
		for i in in_tree:
			for j in arenas.size():
				if j in in_tree:
					continue
				var d := arenas[i].center.distance_squared_to(arenas[j].center)
				if d < best_dist:
					best_dist = d
					best = Vector2i(i, j)
		in_tree.append(best.y)
		edges[best] = true
		_carve(ctx.grid, arenas[best.x].center, arenas[best.y].center)

	for i in arenas.size():
		for j in range(i + 1, arenas.size()):
			if not (edges.has(Vector2i(i, j)) or edges.has(Vector2i(j, i))) \
					and ctx.rng.randf() < extra_connection_chance:
				_carve(ctx.grid, arenas[i].center, arenas[j].center)


func _carve(grid: MapGrid, from: Vector2, to: Vector2) -> void:
	var steps := ceili(from.distance_to(to))
	for i in steps + 1:
		grid.fill_circle(from.lerp(to, float(i) / maxi(steps, 1)), radius, false)


func label() -> String:
	return "tunnels"
