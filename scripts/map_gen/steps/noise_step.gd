class_name NoiseStep
extends MapStep
## Random static: denser near map edges, sparser near arenas, empty at arena cores.

@export_range(0.0, 1.0) var center_density := 0.5
@export_range(0.0, 1.0) var edge_density := 0.75
## Distance (cells) over which density ramps from edge to center value.
@export var edge_falloff := 32.0
## Fraction of arena radius that is guaranteed empty.
@export_range(0.0, 1.0) var arena_clear_ratio := 0.6
## Multiple of arena radius where the arena stops thinning the noise.
@export var arena_influence := 1.5


func apply(ctx: MapContext) -> void:
	var grid := ctx.grid
	for y in grid.size.y:
		for x in grid.size.x:
			var edge_dist := mini(mini(x, y), mini(grid.size.x - 1 - x, grid.size.y - 1 - y))
			if edge_dist == 0:
				grid.set_wall(x, y, true)
				continue
			var density := lerpf(edge_density, center_density, clampf(edge_dist / edge_falloff, 0.0, 1.0))
			density *= _arena_factor(ctx.arenas, Vector2(x, y))
			grid.set_wall(x, y, ctx.rng.randf() < density)


## 0 inside an arena's clear core, ramping to 1 at its influence radius.
func _arena_factor(arenas: Array[MapContext.Arena], p: Vector2) -> float:
	var factor := 1.0
	for a in arenas:
		var t := inverse_lerp(a.radius * arena_clear_ratio, a.radius * arena_influence, p.distance_to(a.center))
		factor = minf(factor, clampf(t, 0.0, 1.0))
	return factor
