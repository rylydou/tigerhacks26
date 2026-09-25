extends Control


class Result:
	var command: DEV_Command
	var score := -1.0


const RECENT_COMMANDS_FILE := "user://devtools/history.txt"


@export var recent_command_count := 10

@export var toggle_hkey := ""
@onready var shortcut := DEV_Util.shortcut_from_string(toggle_hkey)


@export_group("References")
@export var input_edit: LineEdit
@export var command_info_container: Control
@export var command_description_container: Control
@export var command_description_label: RichTextLabel
@export var command_shortcut_label: Label
@export var item_list: ItemList
@export var status_label: Label
@export var hkey_wizard: Control
@export var hkey_entry: HKeyEntry


var results: Array[Result] = []
var recent_command_ids: Array[StringName] = []


func _enter_tree() -> void:
	hide()


func _ready() -> void:
	input_edit.text_changed.connect(update.unbind(1))
	input_edit.text_submitted.connect(execute.unbind(1))
	input_edit.gui_input.connect(_input_gui_input)
	
	item_list.item_selected.connect(execute_item)
	item_list.item_activated.connect(execute_item)
	
	DevTools.new_command("Devtools: Clear recent")\
			.describe("Clears the recent command list.")\
			.exec(clear_recent)
	
	DevTools.new_command("Devtools: Rerun last command")\
			.describe("Runs the most recently executed command.")\
			.no_toast()\
			.no_history()\
			.exec(rerun_recent)\
			.hkey('ctrl+tilde')


func _input(event: InputEvent) -> void:
	if DevTools.disabled: return
	
	if visible and shortcut.matches_event(event) and event.is_pressed():
		get_viewport().set_input_as_handled()
		toggle_me()
		return


func _unhandled_input(event: InputEvent) -> void:
	if DevTools.disabled: return
	
	if shortcut.matches_event(event) and event.is_pressed():
		get_viewport().set_input_as_handled()
		toggle_me()
		return


func toggle_me() -> void:
	if visible:
		hide()
		hkey_wizard.hide()
		return
	
	show()
	input_edit.grab_focus()
	hkey_wizard.hide()
	update()


func update() -> void:
	var search := DEV_Util.cleanup_string(input_edit.text)
	
	results.clear()
	
	if search.is_empty():
		for command_name in recent_command_ids:
			# check if command still exists -- if not then delete it
			if not DevTools.commands_by_id.has(command_name):
				recent_command_ids.erase(command_name)
				continue
			
			var command: DEV_Command = DevTools.commands_by_id[command_name]
			var result := Result.new()
			result.command = command
			results.append(result)
		
		_update_results("No recent commands...")
		status_label.text = "(recent commands)"
		return
	
	for command in DevTools.commands_by_id.values():
		var score := DEV_Util.calculate_score(command.id, search, recent_command_ids)
		
		if score > 0:
			var result := Result.new()
			result.command = command
			result.score = score
			_add_result(result)
	
	_update_results("No matching commands...")


func _add_result(result: Result) -> void:
	for index in results.size():
		var result_at_index := results[index]
		if result_at_index.score < result.score:
			results.insert(index, result)
			return
	
	# results.push_front(result)
	results.append(result)


func _update_results(empty_prompt: String) -> void:
	item_list.clear()
	
	if results.is_empty():
		var list_item_id := item_list.add_item(empty_prompt, null, false)
		item_list.set_item_selectable(list_item_id, false)
		item_list.set_item_disabled(list_item_id, true)
		status_label.text = ""
		_update_selected_command()
		return
	
	for result in results:
		# var list_item_id := item_list.add_item("%s (%.2f)" % [result.command.name, result.score])
		var list_item_id := item_list.add_item(result.command.name)
	
	status_label.text = str(results.size())
	if results.size() == 1:
		status_label.text += " match"
	else:
		status_label.text += " matches"
	
	item_list.select(0)
	_update_selected_command()
	
		# item_list.set_item_disabled(list_item_id, true)


func _add_command_entry(command: DEV_Command) -> int:
	var item_id := item_list.add_item(command.name)
	return item_id


func execute() -> void:
	var selection := item_list.get_selected_items()
	
	if selection.size() <= 0:
		execute_item(0)
		return
	
	execute_item(selection[0])


func execute_item(index: int) -> void:
	if index < 0 or index >= results.size(): return
	
	var result := results[index]
	if not result.command.disable_history:
		recent_command_ids.erase(result.command.id)
		recent_command_ids.push_front(result.command.id)
	input_edit.text = ""
	hide()
	
	DevTools.run_command(result.command)


func open_hkey_wizard() -> void:
	var selection := item_list.get_selected_items()
	
	if selection.size() != 1: return
	
	hkey_wizard.show()
	hkey_entry.grab_focus()


func set_hkey() -> void:
	hkey_wizard.hide()
	
	var selection := item_list.get_selected_items()
	
	if selection.size() <= 0:
		set_hkey_for_item(0)
		return
	
	set_hkey_for_item(selection[0])


func set_hkey_for_item(index: int) -> void:
	if index < 0 or index >= results.size(): return
	
	var result := results[index]
	result.command.custom_shortcut = DEV_Util.shortcut_from_string(hkey_entry.text)
	
	input_edit.grab_focus()
	_update_selected_command()


func _input_gui_input(event: InputEvent):
	if not event.is_pressed(): return
	
	if shortcut.matches_event(event):
		get_viewport().set_input_as_handled()
		hide()
		return
	
	var key_event := event as InputEventKey
	if key_event and key_event.keycode == KEY_DOWN:
		get_viewport().set_input_as_handled()
		
		var selection := item_list.get_selected_items()
		if selection.size() <= 0 or selection[0] >= item_list.item_count - 1:
			item_list.select(0)
		else:
			item_list.select(selection[0] + 1)
		
		_update_selected_command()
		return
	
	if key_event and key_event.keycode == KEY_UP:
		get_viewport().set_input_as_handled()
		
		var selection := item_list.get_selected_items()
		if selection.size() <= 0 or selection[0] <= 0:
			item_list.select(item_list.item_count - 1)
		else:
			item_list.select(selection[0] - 1)
		
		_update_selected_command()
		return
	
	if key_event and key_event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		open_hkey_wizard()
		print("tab")
		return
	
	if key_event and key_event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		hide()
		return


func _update_selected_command() -> void:
	var selection := item_list.get_selected_items()
	
	if selection.size() < 1:
		command_info_container.hide()
		return
	
	var result := results[selection[0]]
	var command := result.command
	
	var segs := PackedStringArray()
	
	if not command.description.is_empty():
		segs.append(command.description)
	
	if not command.parameters.is_empty():
		segs.append("Parameters:\n- %s" % "\n- ".join(command.parameters.map(func(x): return x.split("|")[0])))
	
	item_list.ensure_current_is_visible()
	
	if command.custom_shortcut:
		command_shortcut_label.text = "%s (custom)" % command.custom_shortcut.get_as_text().replace("QuoteLeft", "Tilde")
	elif command.shortcut:
		command_shortcut_label.text = command.shortcut.get_as_text().replace("QuoteLeft", "Tilde")
	else:
		command_shortcut_label.text = "<Tab> to set a shortcut"
	
	if segs.size() > 0:
		command_description_label.text = "\n\n".join(segs)
		command_description_container.show()
	else:
		command_description_container.hide()
	
	command_info_container.show()


func rerun_recent() -> void:
	if recent_command_ids.size() <= 0:
		DevTools.toast("No commands have been executed yet.")
		return
	
	var command: DEV_Command
	
	for command_id in recent_command_ids:
		command = DevTools.commands_by_id.get(command_id)
		if command: break
	
	if not command:
		DevTools.toast("None of the most recent commands are not ready.")
		return
	
	print("[Dev Tools] Re-running command %s..." % command.name)
	DevTools.toast("[Rerun: %s]" % command.name)
	
	DevTools.run_command(command, true)


func clear_recent() -> void:
	recent_command_ids.clear()


func load_data() -> void:
	recent_command_ids.clear()
	
	if FileAccess.file_exists(RECENT_COMMANDS_FILE):
		var file := FileAccess.open(RECENT_COMMANDS_FILE, FileAccess.READ)
		while true:
			if file.eof_reached(): break
			
			var line := file.get_line()
			recent_command_ids.append(line)


func save_data() -> void:
	var recents_file := FileAccess.open(RECENT_COMMANDS_FILE, FileAccess.WRITE)
	for index in mini(recent_command_count, recent_command_ids.size()): # only save most recent 10 commands
		var recent_command_name := recent_command_ids[index]
		recents_file.store_line(recent_command_name)
	
	recents_file.close()


func use_pixel_theme() -> void:
	theme = DevTools.PIXEL_THEME


func use_standard_theme() -> void:
	theme = DevTools.STANDARD_THEME
