class_name SoundscaperUtil extends RefCounted


const SEMITONES_TO_PITCH_SCALE_CONSTANT := 0.057762265046662105 # = log(2.0) / 12.0

static func semitone_to_pitch_scale(semitones: float) -> float:
	return exp(semitones * SEMITONES_TO_PITCH_SCALE_CONSTANT)


## Random value with variation
static func rand_var(base_value: float, plus_or_minus: float) -> float:
	return base_value + randf_range(-plus_or_minus, plus_or_minus)


static func get_accent_hue(index: int) -> float:
	return fmod(index * 360.0 / 5.0, 360.0) / 360.0
	# return ACCENT_COLOR_HUES[index % ACCENT_COLOR_HUES.size()] / 360.0


static func pluralize(singlular_word: String, count: int) -> String:
	var suffix := singlular_word
	if count != 1:
		suffix += "s"
	
	return str(count," ",suffix)
