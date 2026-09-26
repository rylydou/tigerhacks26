extends CharacterBody2D

@export var move_speed: float = 300
@export var aggro_range: float = 400
@export var attack_range: float = 200
@export var movement_margin_range: float = 30

@export var player: Player

func _physics_process(delta: float) -> void:
	var player_position:= player.position
	var direction_to_player:= position.direction_to(player_position)
	
	if position.distance_to(player_position) < aggro_range:
		if position.distance_to(player_position) > attack_range:
			velocity = direction_to_player * move_speed
		else:
			velocity = Vector2.ZERO
			#add shooting script
		
	move_and_slide()
