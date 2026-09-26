class_name Player extends CharacterBody2D

static var instance: Player

@export var move_speed: float = 200.0

func _enter_tree() -> void:
	Player.instance = self
	
func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	velocity = input_vector * move_speed
	move_and_slide()
