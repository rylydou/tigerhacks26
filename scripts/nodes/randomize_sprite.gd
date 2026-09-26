class_name RandomizeSprite extends Sprite2D


@export var textures: Array[Texture2D] = []


func _ready() -> void:
	texture = textures.pick_random()
