class_name DualGridLayer extends TileMapLayer
## Visual layer for a dual-grid tileset (based on jess-hammer's dual-grid-tilemap-system).
## Each display tile sits on the corner between four world cells and picks one of 16
## tiles from which of those corners match this layer's terrain.
## Use one DualGridLayer per terrain type; stack them for multiple terrains.

## Atlas coords per corner mask (TL*8 + TR*4 + BL*2 + BR), matching the demo's 4x4 layout.
const MASK_TO_ATLAS: Array[Vector2i] = [
	Vector2i(-1, -1), # 0000 none -> empty_atlas_coords
	Vector2i(1, 3), # 0001 outer bottom-right
	Vector2i(0, 0), # 0010 outer bottom-left
	Vector2i(3, 0), # 0011 bottom edge
	Vector2i(0, 2), # 0100 outer top-right
	Vector2i(1, 0), # 0101 right edge
	Vector2i(2, 3), # 0110 bottom-left + top-right
	Vector2i(1, 1), # 0111 inner bottom-right
	Vector2i(3, 3), # 1000 outer top-left
	Vector2i(0, 1), # 1001 top-left + bottom-right
	Vector2i(3, 2), # 1010 left edge
	Vector2i(2, 0), # 1011 inner bottom-left
	Vector2i(1, 2), # 1100 top edge
	Vector2i(2, 2), # 1101 inner top-right
	Vector2i(3, 1), # 1110 inner top-left
	Vector2i(2, 1), # 1111 full
]

## Source id in this layer's TileSet holding the 16 dual-grid tiles.
@export var display_source_id := 0
## World cells with this atlas coord count as this terrain. (-1, -1) = empty cells.
@export var world_atlas_coords := Vector2i.ZERO
## Tile drawn where no corner matches (e.g. a floor). (-1, -1) = leave empty.
@export var empty_atlas_coords := Vector2i(-1, -1)


## Rebuilds every display tile from the given world layer.
func refresh(world: TileMapLayer) -> void:
	clear()
	# Offset by half a tile so display tiles straddle world cell corners.
	#position -= Vector2(tile_set.tile_size) / 2.0
	var rect := world.get_used_rect().grow(1)
	for y in range(rect.position.y, rect.end.y + 1):
		for x in range(rect.position.x, rect.end.x + 1):
			_refresh_cell(world, Vector2i(x, y))


func _refresh_cell(world: TileMapLayer, cell: Vector2i) -> void:
	var mask := (
		int(_matches(world, cell + Vector2i(-1, -1))) << 3
		| int(_matches(world, cell + Vector2i(0, -1))) << 2
		| int(_matches(world, cell + Vector2i(-1, 0))) << 1
		| int(_matches(world, cell))
	)
	var atlas := MASK_TO_ATLAS[mask] if mask != 0 else empty_atlas_coords
	if atlas != Vector2i(-1, -1):
		set_cell(cell, display_source_id, atlas)


func _matches(world: TileMapLayer, cell: Vector2i) -> bool:
	return world.get_cell_atlas_coords(cell) == world_atlas_coords
