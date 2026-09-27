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
	
	if pending_milestone_waves > 0 and time_since_spawn >= spawn_cooldown:
		pending_milestone_waves -= 1
		spawn_wave()
	
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


## Spawns a random wave. Returns false if at the enemy cap or no waves are defined.
func spawn_wave() -> bool:
	var waves := Game.waves
	
	if waves.is_empty(): return false
	# Allowed to go over the cap with a single wave, but not start one while at it
	if my_spawns.size() >= max_alive_enemies: return false
	
	SFX.event(&"tumor_spawn").at(global_position).play()
	
	time_since_spawn = 0.0
	spawn_shake_timer = spawn_shake_duration
	# Game.waves already contains each wave repeated by its weight
	var wave: Wave = waves.pick_random()
	for entry in wave.spawns:
		for i in entry.count:
			var pos := _find_spawn_position()
			if pos == Vector2.INF:
				continue
			var enemy: Node2D = entry.scene.instantiate()
			enemy.add_to_group(Global.DESPAWN_GROUP)
			enemy.global_position = pos
			get_tree().current_scene.add_child.call_deferred(enemy)
			my_spawns.append(enemy)
	return true


## Random point in the spawn ring that's not in a wall or too close to the player. Vector2.INF if none found.
func _find_spawn_position() -> Vector2:
	for attempt in SPAWN_ATTEMPTS:
		var dist := randf_range(spawn_radius_min, spawn_radius_max) * Global.UNIT_SCALE
		var pos := global_position + Vector2.from_angle(randf() * TAU) * dist
		if LevelGenerator.current and not LevelGenerator.current.is_open(pos):
			continue
		if Player.instance and pos.distance_to(Player.instance.global_position) < min_player_distance * Global.UNIT_SCALE:
			continue
		return pos
	return Vector2.INF
