class_name HealthBar extends Node2D


const FADE_OUT_DELAY := 3.0
const FADE_OUT_SPEED := 1.0

const FLASH_DELAY := 0.5
const FLASH_SMOOTH := 10.0


@export var is_boss := false


@onready var fill: ProgressBar = %"Fill"
@onready var flash: ProgressBar = %"Flash"


@onready var prev_health: int = owner.max_health


var time_with_same_health := 0.0

var flash_timer := 0.0
var flash_target := 0.0


func _ready() -> void:
	# top_level = true
	# position = get_parent().global_position
	
	self_modulate.a = 0.0
	
	if is_boss:
		fill.size.x *= 2.0
		fill.position.x *= 2.0
		flash.size.x *= 2.0
		flash.position.x *= 2.0


func _process(delta: float) -> void:
	# position = get_parent().global_position
	update(delta)


func update(delta: float) -> void:
	var health: int = owner.health * 100
	var max_health: int = owner.max_health * 100
	
	fill.max_value = max_health
	fill.value = health
	flash.max_value = max_health
	
	if prev_health == health:
		time_with_same_health += delta
	else:
		flash_timer = FLASH_DELAY
		time_with_same_health = 0.0
		prev_health = health
	
	if is_boss or health < max_health: # and time_with_same_health < FADE_OUT_DELAY:
		self_modulate.a = 1.0
	else:
		self_modulate.a = move_toward(self_modulate.a, 0.0, delta * FADE_OUT_SPEED)
	
	if health >= flash.value:
		flash.value = health
	
	flash_timer -= delta
	if flash_timer < 0.0:
		flash_target = health
		flash.value = lerpf(flash.value, flash_target, Math.smooth(FLASH_SMOOTH, delta))
		# flash_bar.value = move_toward(flash_bar.value, flash_target, 100 * delta)
