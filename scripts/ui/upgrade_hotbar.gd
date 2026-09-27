class_name UpgradeHotbar extends HBoxContainer
## Row of icons for the player's current upgrades, with the stack count when above 1.


@export var icon_size := 64
@export var count_font_size := 28


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Player may not have entered the tree yet when this node is ready.
	_connect_player.call_deferred()


func _connect_player() -> void:
	if not is_instance_valid(Player.instance): return
	Player.instance.upgrades_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	get_parent().visible = not Player.instance.upgrades.is_empty()
	for upgrade in Player.instance.upgrades:
		add_child(_make_slot(upgrade))


func _make_slot(upgrade: Upgrade) -> Control:
	var icon := TextureRect.new()
	icon.texture = upgrade.get_icon()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# PASS so the icon gets hover for its tooltip. Shooting polls Input directly, so it isn't blocked.
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	icon.tooltip_text = "%s\n%s" % [upgrade.get_name(), upgrade.get_description()]

	if upgrade.level > 1:
		var count := Label.new()
		count.text = str(upgrade.level)
		count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		count.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		count.grow_vertical = Control.GROW_DIRECTION_BEGIN
		count.add_theme_font_size_override(&"font_size", count_font_size)
		count.add_theme_color_override(&"font_outline_color", Color.BLACK)
		count.add_theme_constant_override(&"outline_size", 10)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(count)
	
	return icon
