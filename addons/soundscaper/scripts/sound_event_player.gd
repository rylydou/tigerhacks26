class_name SoundEventPlayer extends RefCounted


static func create(parent: Node) -> SoundEventPlayer:
	var instance := SoundEventPlayer.new()
	instance.player = AudioStreamPlayer2D.new()
	parent.add_child(instance.player)
	return instance


var player: AudioStreamPlayer2D

var attached_to: Node2D


func process(delta: float) -> void:
	if not is_instance_valid(attached_to): return
	
	player.position = attached_to.global_position


func reset() -> SoundEventPlayer:
	player.stop()
	attached_to = null
	player.position = Vector2.ZERO
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	player.bus = &"sfx"
	player.max_distance = INF
	player.attenuation = 1.0
	player.panning_strength = 0.0
	return self


## Attaches the sound to play from a given node
func from(node: Node2D) -> SoundEventPlayer:
	attached_to = node
	return self


## Plays the sound at a given position
func at(location: Variant) -> SoundEventPlayer:
	if location is Vector2:
		player.position = location
	elif location is Node2D:
		player.position = location.global_position
	elif location is CanvasItem:
		player.position = location.get_global_rect().get_center()
	else:
		#var vigilant_mode: bool = SoundscaperSettings.get_setting(SoundscaperSettings.VIGILANT_MODE)
		#assert(not vigilant_mode, "Unknown location type: " + str(location))
		push_error("Unknown location type: " + str(location))
	
	player.max_distance = 2000.0
	player.panning_strength = 1.0
	return self


func set_pitch(pitch: float) -> SoundEventPlayer:
	player.pitch_scale = pitch
	return self


## Sets pitch in semitones
func set_semitone(semitones: float) -> SoundEventPlayer:
	player.pitch_scale = SoundscaperUtil.semitone_to_pitch_scale(semitones)
	return self


func vary_semitone(base_semitones: float, range_variation: float) -> SoundEventPlayer:
	set_semitone(SoundscaperUtil.rand_var(base_semitones, range_variation / 2.0))
	return self


func set_volume(linear_volume: float) -> SoundEventPlayer:
	player.volume_db = linear_to_db(linear_volume)
	return self


func set_db(db: float) -> SoundEventPlayer:
	player.volume_db = db
	return self


func vary_db(base_db: float, range_db: float) -> SoundEventPlayer:
	player.volume_db = SoundscaperUtil.rand_var(base_db, range_db / 2.0)
	return self


func set_bus(bus: StringName) -> SoundEventPlayer:
	player.bus = bus
	return self


func set_stream(stream: AudioStream) -> SoundEventPlayer:
	player.stream = stream
	player.bus = stream.get_meta(&"bus", &"sfx")
	return self


func set_event(event: SoundEvent) -> SoundEventPlayer:
	player.stream = event.pick_stream()
	player.bus = event.bus
	player.process_mode = Node.PROCESS_MODE_PAUSABLE if event.pauseable else Node.AUTO_TRANSLATE_MODE_ALWAYS
	player.volume_db = SoundscaperUtil.rand_var(event.volume, event.random_volume_variation / 2.0)
	var semitones := SoundscaperUtil.rand_var(event.pitch, event.random_pitch_variation / 2.0)
	player.pitch_scale = SoundscaperUtil.semitone_to_pitch_scale(semitones)
	return self


func stop() -> SoundEventPlayer:
	player.stop()
	return self


func play() -> SoundEventPlayer:
	player.play()
	return self


func pause() -> SoundEventPlayer:
	player.playing = false
	return self
