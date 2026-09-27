extends Upgrade


const HEAL_PER_SECOND_PER_LEVEL := 1.0


func get_icon() -> Texture2D:
	return preload("res://content/art/placeholder.png")

func get_name() -> String:
	return "Regeneration"

func get_description() -> String:
	return "Slowly regenerate health over time."

func get_stat_at_level(level: int) -> String:
	return "%d HP per second" % (level * HEAL_PER_SECOND_PER_LEVEL)

func get_max_level() -> int:
	return 5


func _tick(delta: float) -> void:
	player.heal(level * HEAL_PER_SECOND_PER_LEVEL * delta)
