extends Area2D

signal is_collected()

@export var move_speed: float = 300

@export var player: Player



func _physics_process(delta: float) -> void:
	var player_position:= player.position
	self.position = player_position
	
	
func _ready() -> void:
	pass




func _on_body_entered(body: Node2D) -> void:
	is_collected.emit()
