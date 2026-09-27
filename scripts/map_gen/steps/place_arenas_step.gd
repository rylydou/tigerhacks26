class_name PlaceArenasStep
extends MapStep
## Picks non-overlapping arena circles away from the map edge (rejection sampling).

@export var count := 5
@export var radius_range := Vector2(14.0, 24.0)
@export var edge_margin := 10.0
## Minimum empty distance between two arena edges.
@export var min_gap := 20.0
@export var max_attempts := 1000


func apply(ctx: MapContext) -> void:
	var size := Vector2(ctx.grid.size)
	var target := ctx.arena_count if ctx.arena_count >= 0 else count
	for _i in max_attempts:
		if ctx.arenas.size() >= target:
			return
		var radius := ctx.rng.randf_range(radius_range.x, radius_range.y)
		var pad := radius + edge_margin
		if pad * 2.0 >= size.x or pad * 2.0 >= size.y:
			continue
		var center := Vector2(ctx.rng.randf_range(pad, size.x - pad), ctx.rng.randf_range(pad, size.y - pad))
		if ctx.arenas.all(func(a: MapContext.Arena) -> bool:
				return center.distance_to(a.center) >= radius + a.radius + min_gap):
			ctx.arenas.append(MapContext.Arena.new(center, radius))
	push_warning("PlaceArenasStep: only placed %d/%d arenas" % [ctx.arenas.size(), target])


func label() -> String:
	return "arenas"
