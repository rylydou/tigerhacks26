class_name Instantiate extends Node


@export var scene: PackedScene
@export var marker: Marker2D


func _trigger() -> void:
	var node: Node2D = scene.instantiate()
	node.transform = marker.global_transform
	get_tree().current_scene.add_child(node)
