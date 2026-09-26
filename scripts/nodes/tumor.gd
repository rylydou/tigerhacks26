extends Node2D


signal damage_taken()
signal died()


@export var health := 100
@onready var max_health := health


## In Global.UNIT_SCALE
@export var spawn_radius_max := 8.0
@export var spawn_radius_min := 3.0

## In Global.UNIT_SCALE. Tumor activates and spawns a wave when the player comes within this radius
@export var activation_radius := 10.0

## Maxinum number of alive enemies that this tumor can have at any given time
@export var max_tumor_enemies := 6
## Health milestone for spawning waves
@export var tumor_spawn_at_health: Array[int] = [50]
## Timer interval for spawning waves
@export var tumor_spawn_interval := 10.0
## The maximum number of waves that can spawn in total from interval-based spawning
@export var tumor_max_interval_spawns := 5
## Minimum time between any wave spawn, prevents interval and health-based spawns from happening too quickly
@export var tumor_min_spawn_time := 5.0


## List of waves of enemies that can be picked and spawned by this tumor
@export_group("Shake")
@export var shaker: Shaker
## Seconds before an interval wave that the shake starts building up
@export var shake_buildup_time := 3.0
## Amplitude/frequency multipliers reached right before an interval wave spawns
@export var shake_buildup_amplitude_mult := 3.0
@export var shake_buildup_frequency_mult := 2.0
## Duration of the intense shake right after a wave spawns
@export var spawn_shake_duration := 0.5
@export var spawn_shake_amplitude_mult := 5.0
@export var spawn_shake_frequency_mult := 3.0
@export_group("")

@export var waves: Array[EnemyWave] = []


## For tracking the enemies spawned by this tumor for spawn limit
var my_spawns: Array[Node2D] = []


var flash_timer := 0.0

var spawn_shake_timer := 0.0
var base_amplitude := 0.0
var base_amplitude_max := 0.0
var base_frequency := 0.0

## Tumor stays dormant (no interval spawns) until damaged or the player gets close
var activated := false
var interval_timer := 0.0
var interval_spawns := 0
var time_since_spawn := INF
## Health milestones crossed but not yet spawned (waiting on tumor_min_spawn_time)
var pending_milestone_spawns := 0
var milestones_hit: Array[int] = []


func _ready() -> void:
	if shaker:
		base_amplitude = shaker.amplitude
		base_amplitude_max = shaker.amplitude_max
		base_frequency = shaker.frequency


func _physics_process(delta: float) -> void:
	if health <= 0: return
	
	flash_timer -= delta
	
	update_spawning(delta)
	update_shake(delta)
	
	var flash_alpha := 0.0
	var flash_shake := 0.0
	if flash_timer > 0:
		flash_alpha = 1.0
		flash_shake = 0.0
	material.set_shader_parameter(&'flash_color', Color(1.0, 1.0, 1.0, flash_alpha))


func take_damage(damage: int, knockback: Vector2) -> bool:
	if health <= 0: return false
	
	#if damage > 0:
	#	SFX.play(&'hit_enemy', global_position).volume_db = 5.0
	
	health -= damage
	activate()
	check_milestones()
	flash()
	damage_taken.emit()
	if health <= 0:
		die()
	return true


func die() -> void:
	#SFX.play(&'death_enemy', global_position).volume_db = 0.0
	#VFX.poof(global_position)
	died.emit()
	queue_free()


func flash() -> void:
	flash_timer = 4 / 60.0
	material.set_shader_parameter(&'flash_color', Color.WHITE)


func update_spawning(delta: float) -> void:
	time_since_spawn += delta
	
	if not activated:
		if Player.instance and global_position.distance_to(Player.instance.global_position) <= activation_radius * Global.UNIT_SCALE:
			activate()
		return
	
	my_spawns = my_spawns.filter(is_instance_valid)
	
	if pending_milestone_spawns > 0 and time_since_spawn >= tumor_min_spawn_time:
		pending_milestone_spawns -= 1
		spawn_wave()
	
	if interval_spawns >= tumor_max_interval_spawns: return
	interval_timer += delta
	if interval_timer >= tumor_spawn_interval and time_since_spawn >= tumor_min_spawn_time:
		interval_timer = 0.0
		if spawn_wave():
			interval_spawns += 1


func update_shake(delta: float) -> void:
	if not shaker: return
	spawn_shake_timer -= delta
	
	var amp_mult := 1.0
	var freq_mult := 1.0
	if spawn_shake_timer > 0.0:
		amp_mult = spawn_shake_amplitude_mult
		freq_mult = spawn_shake_frequency_mult
	elif activated and interval_spawns < tumor_max_interval_spawns and shake_buildup_time > 0.0:
		var time_left := tumor_spawn_interval - interval_timer
		# Also account for the min spawn time holding the interval wave back
		time_left = maxf(time_left, tumor_min_spawn_time - time_since_spawn)
		var t := clampf(1.0 - time_left / shake_buildup_time, 0.0, 1.0)
		t *= t
		amp_mult = lerpf(1.0, shake_buildup_amplitude_mult, t)
		freq_mult = lerpf(1.0, shake_buildup_frequency_mult, t)
	
	shaker.amplitude = base_amplitude * amp_mult
	shaker.amplitude_max = base_amplitude_max * amp_mult
	shaker.frequency = base_frequency * freq_mult


func activate() -> void:
	if activated: return
	activated = true
	spawn_wave()


func check_milestones() -> void:
	for milestone in tumor_spawn_at_health:
		if health <= milestone and milestone not in milestones_hit:
			milestones_hit.append(milestone)
			pending_milestone_spawns += 1


## Spawns a random wave. Returns false if at the enemy cap or no waves are defined.
func spawn_wave() -> bool:
	if waves.is_empty(): return false
	# Allowed to go over the cap with a single wave, but not start one while at it
	if my_spawns.size() >= max_tumor_enemies: return false
	
	SFX.event(&"tumor_spawn").at(self).play()
	
	time_since_spawn = 0.0
	spawn_shake_timer = spawn_shake_duration
	for scene: PackedScene in waves.pick_random().enemies:
		var enemy: Node2D = scene.instantiate()
		enemy.add_to_group(Global.DESPAWN_GROUP)
		var dist := randf_range(spawn_radius_min, spawn_radius_max) * Global.UNIT_SCALE
		enemy.global_position = global_position + Vector2.from_angle(randf() * TAU) * dist
		get_tree().current_scene.add_child.call_deferred(enemy)
		my_spawns.append(enemy)
	return true
