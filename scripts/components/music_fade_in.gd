extends AudioStreamPlayer

@export var fade_duration := 1.0

func _ready() -> void:
	var target_db := volume_db
	volume_db = -80.0
	if not playing:
		play()
	create_tween().tween_property(self, "volume_db", target_db, fade_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
