class_name Step extends Node


const CONTINUE = 0
const DONE = 1


@export var enabled := true


var enemy: Enemy


func set_enemy(enemy: Enemy) -> void:
	self.enemy = enemy


func _start() -> int:
	return DONE


func _tick(delta: float) -> int:
	return DONE
