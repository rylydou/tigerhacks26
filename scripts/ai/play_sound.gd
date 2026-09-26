class_name PlaySound extends Step


@export var sound_name := &""
@export var volume := 0.0
@export var pitch := 1.0


func _start() -> int:
	SFX.event(sound_name).at(enemy.global_position).play()
	# player.volume_db = volume
	# player.pitch_scale = pitch
	return DONE
