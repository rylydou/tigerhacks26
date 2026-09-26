class_name Breakable extends Area2D


signal impacted()


var has_impacted := false


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void: impact())
	area_entered.connect(func(area: Area2D) -> void: impact())
	
	if get_child_count() <= 0:
		var parent_collision: Node2D = get_parent().find_child("Collision*")
		add_child(parent_collision.duplicate())


func impact() -> void:
	if has_impacted: return
	has_impacted = true
	impacted.emit()
	
	owner.queue_free()
