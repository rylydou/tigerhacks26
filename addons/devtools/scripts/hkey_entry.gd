class_name HKeyEntry extends LineEdit


func _gui_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	
	if event is not InputEventKey: return
	if not event.is_pressed(): return
	
	# Submit
	if (
			event.key_label == KEY_ENTER
			or event.key_label == KEY_KP_ENTER
	):
		text_submitted.emit(text)
		text = ""
		return
	
	# Cancel
	if (
			event.key_label == KEY_ESCAPE
	):
		text = ""
		return
	
	# Delete (but don't submit)
	if (
			event.key_label == KEY_BACKSPACE
			or event.key_label == KEY_DELETE
	):
		text = ""
		return
	
	text = event.as_text_key_label().to_lower()
