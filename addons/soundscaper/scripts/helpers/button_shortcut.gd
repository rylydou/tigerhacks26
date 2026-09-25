@tool

extends Button


func _shortcut_input(event: InputEvent) -> void:
	if is_part_of_edited_scene(): return
	
	if not shortcut: return
	
	if shortcut.matches_event(event):
		get_viewport().set_input_as_handled()
		
		if toggle_mode:
			button_pressed = !button_pressed
		else:
			pressed.emit()
