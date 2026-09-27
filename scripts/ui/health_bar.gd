extends TextureProgressBar
## Mirrors the player's current and max health, with an "X/Y HP" label centered inside.


## Font size in the bar's local space (the bar itself is scaled up in the scene).
@export var label_font_size := 10

var _label: Label
## Bar width (local space) at the player's base max health; the bar widens proportionally from here.
var _base_width: float


func _ready() -> void:
	_base_width = offset_right - offset_left
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", label_font_size)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 3)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(_delta: float) -> void:
	if not is_instance_valid(Player.instance): return
	max_value = Player.instance.max_health
	value = Player.instance.health
	_resize(Player.instance.max_health / float(Player.instance.base_max_health))
	_label.text = "%d/%d HP" % [Player.instance.health, Player.instance.max_health]


## Widen the bar around its center, keeping its anchored position.
func _resize(ratio: float) -> void:
	var half := _base_width * ratio / 2.0
	offset_left = -half
	offset_right = half
