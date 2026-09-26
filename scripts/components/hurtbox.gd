class_name Hurtbox extends Area2D


const METHOD_NAME := &'take_damage'


signal attacked(damage: int, knockback: Vector2)


@export var active := true


func take_damage(damage: int, knockback: Vector2) -> bool:
	if not active: return false
	attacked.emit(damage, knockback)
	return true
