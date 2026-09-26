@tool
class_name SortingLayer extends Node


const SORTING_LAYERS := [
	&"overlay",
	&"health_bar",
	
	&"effect_fg",
	&"projectile_above",
	
	&"foreground",
	&"effect_mg",
	
	&"projectile",
	
	&"enemy",
	
	&"player",
	&"effect_bg",
	
	&"wall",
	
	&"shadow",
	&"floor",
]


var layer_name := &"":
	set(value):
		layer_name = value
		update_sorting_layer()

@export var bias := 0:
	set(value):
		bias = value
		update_sorting_layer()


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		var root := get_tree().edited_scene_root
		if not (
			root == owner
			or root == self
		): return
	
	update_sorting_layer()


func update_sorting_layer() -> void:
	var layer_index := SORTING_LAYERS.find(layer_name) * -100
	
	if layer_index is not int:
		push_warning("Unknown sorting layer: '",layer_name,"'")
		layer_index = 0
	
	layer_index += bias
	
	if _try_set_z_index(self, layer_index): return
	_try_set_z_index(get_parent(), layer_index)


func _try_set_z_index(node: Node, index: int) -> bool:
	if not is_instance_valid(node): return false
	
	if node.has_method(&"set_z_index"):
		node.call(&"set_z_index", index)
		node.call(&"set_z_as_relative", false)
		return true
	if node.has_method(&"layer"):
		node.call(&"layer", index)
		return true
	return false


func _get_property_list() -> Array[Dictionary]:
	var hint_string := ",".join(SORTING_LAYERS)
	return [
		{
			"name": "layer_name",
			"type": TYPE_STRING_NAME,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM_SUGGESTION,
			"hint_string": hint_string,
		}
	]
