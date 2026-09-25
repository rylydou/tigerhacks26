class_name FileIO


## Saves all fields marked with "@export_storage"
static func save_storage_simple(obj: Object, path: String, keep_unused := false, header_comment := "") -> Error:
	var dict: Dictionary[StringName, Variant] = {}
	
	if keep_unused:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			while not file.eof_reached() and file.get_position() < file.get_length():
				var line := file.get_line()
				if line.begins_with("#"): continue
				
				var segs := line.split(":", true, 1)
				if segs.size() != 2: continue
				
				var key: StringName = StringName(segs[0])
				var value := str_to_var(segs[1])
				
				dict[key] = value
			
			file.close()
	
	for prop in obj.get_property_list():
		var name: StringName = StringName(prop.name)
		var usage: PropertyUsageFlags = prop.usage
		
		if not (
			usage & PROPERTY_USAGE_STORAGE &&
			usage & PROPERTY_USAGE_SCRIPT_VARIABLE
			): continue
		
		dict[name] = obj.get(name)
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	if not file:
		var error := FileAccess.get_open_error()
		push_error("[File IO] Failed to save file '%s' (%s)" % [path, error_string(error)])
		return error
	
	file.store_string("# ")
	file.store_line(header_comment.replace("\n", "\n# "))
	
	for key in dict:
		var value: Variant = dict[key]
		file.store_string(key)
		file.store_string(": ")
		file.store_line(var_to_str(value))
	
	file.close()
	
	return OK


static func load_storage_simple(obj: Object, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	
	if not file:
		var error := FileAccess.get_open_error()
		print("[File IO] Failed to load file '%s' (%s)" % [path, error_string(error)])
		return error
	
	while not file.eof_reached() and file.get_position() < file.get_length():
		var line := file.get_line()
		if line.begins_with("#"): continue
		
		print(line)
		
		var segs := line.split(":", true, 1)
		if segs.size() != 2: continue
		
		var value_string := segs[1].strip_edges()
		if value_string.is_empty(): continue
		
		var key := StringName(segs[0])
		var value := str_to_var(value_string)
		
		obj.set(key, value)
	
	return OK
