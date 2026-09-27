extends Node2D


signal damage_taken()
signal died()


const SPAWN_ATTEMPTS := 10


@export var health := 100
@onready var max_health := health

## In Global.UNIT_SCALE. Tumor activates and spawns a wave when the player comes within this radius
@export var activation_radius := 10.0


@export_group("Spawning")
## In Global.UNIT_SCALE
@export var spawn_radius_min := 3.0
## In Global.UNIT_SCALE
@export var spawn_radius_max := 8.0
## In Global.UNIT_SCALE. Spawn radius for the final waves released on death
@export var death_spawn_radius := 1.0
## Number of final waves on death is picked from this (weighted by repeats)
@export var death_wave_counts: Array[int] = [1, 1, 1, 2]
## In Global.UNIT_SCALE. Enemies that would spawn closer than this to the player are dropped
@export var min_player_distance := 2.0
## A new wave won't start while this many of the tumor's enemies are alive (a wave may go over)
@export var max_alive_enemies := 6
## Minimum seconds between any two waves. Interval and milestone waves wait for this
@export var spawn_cooldown := 5.0

@export_subgroup("Interval")
## Seconds between interval waves, counted from activation
@export var interval_time := 10.0
## Total interval waves this tumor can spawn
@export var interval_max_waves := 5

@export_subgroup("Health Milestones")
## A wave spawns once when health drops to or below each of these values
@export var health_milestones: Array[int] = [50]


@export_group("Shake")
@export var shaker: Shaker

@export_subgroup("Buildup")
## Seconds before an interval wave that the shake starts building up
@export var buildup_time := 3.0
## Multipliers reached right before an interval wave spawns
@export var buildup_amplitude_mult := 3.0
@export var buildup_frequency_mult := 2.0

@export_subgroup("Spawn Shake")
## Duration of the intense shake right after a wave spawns
@export var spawn_shake_duration := 0.5
@export var spawn_shake_amplitude_mult := 5.0
@export var spawn_shake_frequency_mult := 3.0
@export_group("")


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
var interval_waves_spawned := 0
var time_since_spawn := INF
## Health milestones crossed but not yet spawned (waiting on spawn_cooldown)
var pending_milestone_waves := 0
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
	
	if damage > 0:
		SFX.event(&"enemy_hit").at(global_position).play()
	
	health -= damage
	activate()
	check_milestones()
	flash()
	damage_taken.emit()
	if health <= 0:
		die()
	return true


func die() -> void:
	SFX.event(&"tumor_death").at(global_position).play()
	#VFX.poof(global_position)
	my_spawns = my_spawns.filter(is_instance_valid)
	for i in death_wave_counts.pick_random():
		spawn_wave(0.0, death_spawn_radius)
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
	
	# Only use up the milestone once it actually spawns (it can fail at the enemy cap)
	if pending_milestone_waves > 0 and time_since_spawn >= spawn_cooldown and spawn_wave():
		pending_milestone_waves -= 1
	
	if interval_waves_spawned >= interval_max_waves: return
	interval_timer += delta
	if interval_timer >= interval_time and time_since_spawn >= spawn_cooldown:
		interval_timer = 0.0
		if spawn_wave():
			interval_waves_spawned += 1


func update_shake(delta: float) -> void:
	if not shaker: return
	spawn_shake_timer -= delta
	
	var amp_mult := 1.0
	var freq_mult := 1.0
	if spawn_shake_timer > 0.0:
		amp_mult = spawn_shake_amplitude_mult
		freq_mult = spawn_shake_frequency_mult
	elif activated and interval_waves_spawned < interval_max_waves and buildup_time > 0.0:
		var time_left := interval_time - interval_timer
		# Also account for the min spawn time holding the interval wave back
		time_left = maxf(time_left, spawn_cooldown - time_since_spawn)
		var t := clampf(1.0 - time_left / buildup_time, 0.0, 1.0)
		t *= t
		amp_mult = lerpf(1.0, buildup_amplitude_mult, t)
		freq_mult = lerpf(1.0, buildup_frequency_mult, t)
	
	shaker.amplitude = base_amplitude * amp_mult
	shaker.amplitude_max = base_amplitude_max * amp_mult
	shaker.frequency = base_frequency * freq_mult


func activate() -> void:
	if activated: return
	activated = true
	spawn_wave()


func check_milestones() -> void:
	for milestone in health_milestones:
		if health <= milestone and milestone not in milestones_hit:
			milestones_hit.append(milestone)
			pending_milestone_waves += 1


## Spawns a random wave. Returns false if at the enemy cap, no waves are defined or there's nowhere to spawn.
func spawn_wave(radius_min := spawn_radius_min, radius_max := spawn_radius_max) -> bool:
	var waves := Game.waves
	
	if waves.is_empty(): return false
	# Allowed to go over the cap with a single wave, but not start one while at it
	if my_spawns.size() >= max_alive_enemies: return false
	
	var candidates := _get_spawn_positions(radius_min, radius_max)
	if candidates.is_empty():
		push_warning("Tumor at %s has no open tiles to spawn on" % global_position)
		return false
	
	SFX.event(&"tumor_spawn").at(global_position).play()
	
	time_since_spawn = 0.0
	spawn_shake_timer = spawn_shake_duration
	# Game.waves already contains each wave repeated by its weight
	var wave: Wave = waves.pick_random()
	var available: Array[Vector2] = []
	for entry in wave.spawns:
		for i in entry.count:
			# Spread enemies over different tiles, only doubling up once every tile is taken
			if available.is_empty():
				available = candidates.duplicate()
			var pos: Vector2 = available.pop_at(randi() % available.size())
			var enemy: Node2D = entry.scene.instantiate()
			enemy.add_to_group(Global.DESPAWN_GROUP)
			enemy.global_position = pos
			get_tree().current_scene.add_child.call_deferred(enemy)
			my_spawns.append(enemy)
	return true


## Open positions to spawn on: the spawn ring away from the player, falling back to looser
## limits when walls or the player leave no room there. Empty if everything nearby is wall.
func _get_spawn_positions(radius_min: float, radius_max: float) -> Array[Vector2]:
	var open: Array[Vector2] = []
	if LevelGenerator.current:
		open = LevelGenerator.current.get_open_positions_near(global_position, radius_max * Global.UNIT_SCALE)
	else:
		# No level to query walls from, so any point in the ring is fine
		for attempt in SPAWN_ATTEMPTS:
			var dist := randf_range(radius_min, radius_max) * Global.UNIT_SCALE
			open.append(global_position + Vector2.from_angle(randf() * TAU) * dist)
	
	# [min distance from tumor, min distance from player], strictest first
	var tiers: Array[Vector2] = [
		Vector2(radius_min, min_player_distance),
		Vector2(0.0, min_player_distance),
		Vector2(0.0, 0.0),
	]
	for tier in tiers:
		var min_self := tier.x * Global.UNIT_SCALE
		var min_player := tier.y * Global.UNIT_SCALE
		var valid := open.filter(func(pos: Vector2) -> bool:
			if pos.distance_to(global_position) < min_self: return false
			if Player.instance and pos.distance_to(Player.instance.global_position) < min_player: return false
			return true)
		if not valid.is_empty():
			var result: Array[Vector2] = []
			result.assign(valid)
			return result
	return []
