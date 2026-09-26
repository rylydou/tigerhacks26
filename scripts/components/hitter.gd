class_name Hitter extends Area2D


signal attacked(player: Player)


@export var auto_attack := false


func _enter_tree() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(9, true)
	
	if not auto_attack: return
	body_entered.connect(_body_entered)


func _body_entered(body: Node2D) -> void:
	var player := body as Player
	if not player: return
	if owner is Enemy and owner.height > 0.0: return
	player.take_hit()
	attacked.emit(player)
