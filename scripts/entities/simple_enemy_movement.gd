extends CharacterBody2D

const SPEED = 0

@export var move_speed: float = 300

@export var player: Player

func _physics_process(_delta: float) -> void:
	var player_position:= player.position
	var direction_to_player:= position.direction_to(player_position)
	
	velocity = direction_to_player * move_speed
	
	move_and_slide()
