class_name SideWallLayer
extends TileMapLayer
## Visual layer for wall faces: every world wall cell with open space directly below
## gets a left, center or right tile depending on whether solid cells sit beside it.

## Source id in this layer's TileSet holding the side wall tiles.
@export var display_source_id := 0
## World cells with this atlas coord count as wall.
@export var world_atlas_coords := Vector2i.ZERO
@export var left_atlas_coords := Vector2i(0, 0)
@export var center_atlas_coords := Vector2i(1, 0)
@export var right_atlas_coords := Vector2i(2, 0)
## Used for 1-wide faces. (-1, -1) = use center.
@export var single_atlas_coords := Vector2i(-1, -1)


## Rebuilds every side wall tile from the given world layer.
func refresh(world: TileMapLayer) -> void:
	clear()
	for cell in world.get_used_cells():
		if not _is_face(world, cell):
			continue
		var has_left := _is_wall(world, cell + Vector2i.LEFT)
		var has_right := _is_wall(world, cell + Vector2i.RIGHT)
		var atlas := center_atlas_coords
		if not has_left and not has_right:
			if single_atlas_coords != Vector2i(-1, -1):
				atlas = single_atlas_coords
		elif not has_left:
			atlas = left_atlas_coords
		elif not has_right:
			atlas = right_atlas_coords
		set_cell(cell, display_source_id, atlas)


## A wall cell whose bottom side is exposed.
func _is_face(world: TileMapLayer, cell: Vector2i) -> bool:
	return _is_wall(world, cell) and not _is_wall(world, cell + Vector2i.DOWN)


func _is_wall(world: TileMapLayer, cell: Vector2i) -> bool:
	return world.get_cell_atlas_coords(cell) == world_atlas_coords
