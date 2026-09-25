@tool
@icon("res://addons/soundscaper/content/icons/sound_event.svg")
class_name SoundEvent extends Resource


@export var streams: Array[AudioStream] = []

@export var bus := &""
@export var pauseable := false

@export_range(-80.0, 20.0, 0.2, "suffix:dB") var volume := 0.0
@export_range(-48.0, 48.0, 0.2, "suffix:semitones") var pitch := 0.0

@export_group("Randomization", "random_")
## Plus or minus the base [code]volume[/code]
@export_range(0.0, 20.0, 0.2, "suffix:dB") var random_volume_variation := 0.0
## Plus or minus the base [code]pitch[/code]
@export_range(0.0, 6.0, 0.2, "suffix:semitones") var random_pitch_variation := 0.0


var last_stream_index := -1


func pick_stream() -> AudioStream:
	var index := randi() % streams.size()
	if index == last_stream_index:
		index += 1
		if index >= streams.size():
			index = 0
	
	last_stream_index = index
	return streams[index]


func init_player(player: AudioStreamPlayer) -> void:
	player.stream = pick_stream()
	player.volume_db = SoundscaperUtil.rand_var(volume, random_volume_variation / 2.0)
	var semitones := SoundscaperUtil.rand_var(pitch, random_pitch_variation / 2.0)
	player.pitch_scale = SoundscaperUtil.semitone_to_pitch_scale(semitones)
