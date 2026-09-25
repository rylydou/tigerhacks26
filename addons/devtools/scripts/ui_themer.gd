extends Node


@export var target: Control

@export var is_root := false
@export var pixel_size := Vector2.ZERO


var standard_size := Vector2.ZERO


func _ready() -> void:
	if not target:
		target = get_parent()
	
	standard_size = target.custom_minimum_size


func use_pixel_theme() -> void:
	target.custom_minimum_size = pixel_size
	target.size = Vector2.ZERO
	
	if is_root:
		target.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func use_standard_theme() -> void:
	target.custom_minimum_size = standard_size
	target.size = standard_size
	
	if is_root:
		target.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
