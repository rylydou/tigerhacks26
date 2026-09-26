extends Node

@export var Health = 100

func _process(delta: float) -> void:
	if Health <= 0:
		owner.queue_free()
