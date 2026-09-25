class_name Util extends RefCounted



static func noop() -> void:
	pass


static func queue_free_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


static func wait(node: Node, delay: float, use_physics := true) -> void:
	var tween := node.create_tween()
	if use_physics:
		tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_callback(noop).set_delay(delay)
	await tween.finished


static func get_children_in_group(node: Node, group: StringName) -> Array[Node]:
	var children: Array[Node] = []
	
	for child in node.get_children():
		if child.is_in_group(group):
			children.append(child)
		children.append_array(get_children_in_group(child, group))
	
	return children


static func clamp_str(string: String, max_length: int) -> String:
	return string.substr(0, mini(string.length(), max_length))


## Stripes the string of everything except standard ascii chars a-Z + symbols + space
## See https://en.wikipedia.org/wiki/ASCII#Character_set
static func clear_special_chars(string: String) -> String:
	const START_CODE := ord(" ")
	const END_CODE := ord("~")
	
	var out := PackedByteArray()
	
	for index in string.length():
		var ch := string.unicode_at(index)
		if ch >= START_CODE && ch <= END_CODE:
			out.append(ch)
	
	return out.get_string_from_ascii()


static func index_of(arr: Array, f: Callable) -> int:
	for index in arr.size():
		var item: Variant = arr[index]
		if f.call(item):
			return index
	return -1


static func print_dir(path: String, indent := 0) -> void:
	print("\t".repeat(indent) + path.get_file() + "/")
	for dirname in DirAccess.get_directories_at(path):
		print_dir(path.path_join(dirname), indent + 1)
	
	for filename in DirAccess.get_files_at(path):
		print("\t".repeat(indent + 1) + filename)


static func alpha(color: Color, a: float) -> Color:
	return Color(color.r, color.g, color.b, a)


## Returns default if curve is null
static func sample_curve(curve: Curve, offset: float, default := 0.0) -> float:
	if not curve: return default
	return curve.sample_baked(offset)


static func format_stack_trace(trace_line: Dictionary) -> String:
	var source: String = trace_line[&"source"]
	var line: int = trace_line[&"line"]
	# var function: String = trace_line[&"function"]
	return str(source.get_file(),":",line)


static func format_stack_trace_full(trace_line: Dictionary) -> String:
	var source: String = trace_line[&"source"]
	var line: String = trace_line[&"line"]
	var function: String = trace_line[&"function"]
	return str(source,":",line,":",function,"()")


static func get_lines(file: FileAccess) -> PackedStringArray:
	var lines := PackedStringArray()
	while not file.eof_reached():
		lines.append(file.get_line())
	return lines


static func get_wsv_lines(file: FileAccess) -> Array[Array]:
	var lines: Array[Array] = []
	while true:
		var line := get_wsv_line(file)
		if line.is_empty(): break
		lines.append(line)
	return lines


static func get_wsv_line(file: FileAccess) -> PackedStringArray:
	var line := ""
	
	while line.is_empty():
		if file.eof_reached():
			return PackedStringArray()
		
		line = file.get_line().strip_edges()
		
		if line.begins_with("#"):
			continue
	
	var parts := PackedStringArray()
	var start_index := 0
	var in_whitespace := false
	for index in line.length():
		var char := line[index]
		var is_whitepace := char.strip_edges().is_empty()
		
		if is_whitepace:
			if not in_whitespace:
				parts.append(line.substr(start_index, index))
				in_whitespace = true
			continue
		
		if in_whitespace:
			in_whitespace = false
			start_index = index
	
	if not in_whitespace:
		parts.append(line.substr(start_index))
	
	return parts


static func parse_based_number(based_number: String, base: int, separator := "'") -> int:
	var parts := based_number.split(separator, true, 2)
	
	var tens_place := 0
	var ones_place := 0
	
	if parts.size() == 2:
		tens_place = int(parts[0].to_int())
		ones_place = int(parts[1].to_int())
	else:
		# Parse in standard base 10 as a fallback
		ones_place = int(parts[0].to_int())
	
	return tens_place * base + ones_place


# static func remap_dict(dict: Dictionary, key_as_sub_value_key: Variant, sub_value_as_key: Variant) -> Dictionary:
# 	var out_dict := {}
	
# 	for key in dict:
# 		var in_sub_dict: Dictionary = dict[key]
# 		var out_sub_dict := dic
		
# 		sub_dict[key_as_sub_value_key] = key
		
# 		if sub_value_as_key != null:
# 			pass
	
# 	return out_dict


static func mapify(text: String, separator_btw_entries: String, separator_btw_kv: String) -> Dictionary[StringName, String]:
	var dict: Dictionary[StringName, String] = {}
	
	var entries := text.split(separator_btw_entries, false)
	for entry in entries:
		var segs := entry.split(separator_btw_kv, false, 2)
		if segs.size() != 2: continue
		var key := StringName(segs[0])
		var value := segs[1]
		dict[key] = value
	
	return dict


static func int_to_icon(icon_code: int, image: Image):
	for y in range(8):
		for x in range(8):
			image.set_pixel(7 - x, 7 - y, Color.WHITE if (icon_code & 1) else Color.BLACK)
			icon_code >>= 1


static func icon_to_int(image: Image) -> int:
	var icon_code := 0
	
	for y in 8:
		for x in 8:
			var color := image.get_pixel(x, y)
			icon_code <<= 1
			if color == Color.WHITE:
				icon_code = (icon_code | 1)
	
	return icon_code


static func is_valid_ipv4(ip: String) -> bool:
	var parts := ip.split(".", true, 3)
	if parts.size() != 4: return false
	
	for part in parts:
		if not part.is_valid_int(): return false
		var byte := part.to_int()
		if byte < 0 or byte >= 255: return false
	
	return true


static func ipv4_string_to_int(ip: String) -> int:
	var parts := ip.split(".", true, 3)
	if parts.size() != 4: return false
	
	var bytes := PackedByteArray()
	bytes.resize(4)
	
	for index in 4:
		var part := parts[index]
		if not part.is_valid_int(): return 0
		var byte := part.to_int()
		if byte < 0 or byte >= 255: return 0
		bytes.encode_u8(index, byte)
	
	return bytes.decode_u32(0)


static func ipv4_int_to_string(ip: int) -> String:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, ip)
	return ".".join(PackedStringArray(bytes))


## Parses a string of flags in the style of URL query params
static func parse_flags(string: String, property_separator := ";", kv_separator := "=") -> Dictionary[StringName, String]:
	var dict: Dictionary[StringName, Variant] = {}
	
	var props := string.split(property_separator)
	
	for prop in props:
		var kv_split_index := prop.find(kv_separator)
		if kv_split_index < 0:
			dict[StringName(prop)] = true
			continue
		
		var key := StringName(kv_separator.substr(0, kv_split_index - 1))
		var value := kv_separator.substr(kv_split_index + 1)
		
		dict[key] = value
	
	return dict


## Turns a dictionary into a string in the style of URL query params
static func stringify_flags(dict: Dictionary, item_separator := ";", kv_separator := "=") -> String:
	var props: Array[String] = []
	
	for key in dict:
		var value: Variant = dict[key]
		
		if value is bool:
			if value:
				props.append(key)
		elif value:
			props.append(key + kv_separator + value)
	
	return item_separator.join(props)


static func ensure_packed_by_array_size(bytes: PackedByteArray, size: int) -> void:
	if bytes.size() < size:
		bytes.resize(nearest_po2(size))


static func encode_bytes_as_keyed_dict(schema: Dictionary[StringName, Dictionary], dict: Dictionary[StringName, Variant]) -> PackedByteArray:
	var bytes := PackedByteArray()
	var ptr := 0
	
	for key in dict:
		var value: Variant = dict[key]
		var prop: Dictionary = schema.get(key)
		if not prop:
			push_warning("Dictionary key '%s' not found in schema", key)
			continue
		
		var id: int = prop[&"id"]
		
		ensure_packed_by_array_size(bytes, ptr + 1)
		bytes.encode_u8(0, id)
		ptr += 1
		
		var type: StringName = prop[&"type"]
		
		match type:
			&"u8":
				ensure_packed_by_array_size(bytes, ptr + 1)
				bytes.encode_u8(ptr, value)
				ptr += 1
			&"u16":
				ensure_packed_by_array_size(bytes, ptr + 2)
				bytes.encode_u16(ptr, value)
				ptr += 2
			&"u32":
				ensure_packed_by_array_size(bytes, ptr + 4)
				bytes.encode_u32(ptr, value)
				ptr += 4
			&"u64":
				ensure_packed_by_array_size(bytes, ptr + 8)
				bytes.encode_u64(ptr, value)
				ptr += 8
			&"ipv4":
				ensure_packed_by_array_size(bytes, ptr + 4)
				bytes.encode_u32(ptr, Util.ipv4_string_to_int(value))
				ptr += 4
			&"utf8":
				var utf8_string := (value as String).to_utf8_buffer()
				ensure_packed_by_array_size(bytes, ptr + utf8_string.size() + 4)
				
				bytes.encode_u32(ptr, utf8_string.size())
				ptr += 4
				
				for index in utf8_string.size():
					bytes[ptr + index] = utf8_string[index]
				ptr += utf8_string.size()
			&"bytes":
				value = value as PackedByteArray
				ensure_packed_by_array_size(bytes, ptr + value.size() + 4)
				
				bytes.encode_u32(ptr, value.size())
				ptr += 4
				
				for index in value.size():
					bytes[ptr + index] = value[index]
				ptr += value.size()
	
	return bytes


static func decode_bytes_as_keyed_dict(schema: Dictionary[StringName, Dictionary], bytes: PackedByteArray, dict: Dictionary) -> void:
	var ptr := 0
	
	var schema_values := schema.values()
	var schema_keys := schema.keys()
	
	while true:
		if ptr >= bytes.size():
			# Finished without error
			return
		
		var id := bytes[ptr]
		ptr += 1
		
		var index := schema_values.find_custom(func(x): return x.id == id)
		var prop: Dictionary = schema_values[index]
		var key: StringName = schema_keys[index]
		var type: StringName = prop[&"type"]
		
		match type:
			&"u8":
				if ptr >= bytes.size() - 1: break
				dict[key] = bytes.decode_u8(ptr)
				ptr += 1
			&"u8":
				if ptr >= bytes.size() - 2: break
				dict[key] = bytes.decode_u8(ptr)
				ptr += 2
			&"u32":
				if ptr >= bytes.size() - 4: break
				dict[key] = bytes.decode_u32(ptr)
				ptr += 4
			&"u64":
				if ptr >= bytes.size() - 8: break
				dict[key] = bytes.decode_u64(ptr)
				ptr += 8
			&"ipv4":
				if ptr >= bytes.size() - 4: break
				dict[key] = Util.ipv4_int_to_string(bytes.decode_u32(ptr))
				ptr += 4
			&"utf8":
				if ptr >= bytes.size() - 4: break
				var size = bytes.decode_u32(ptr)
				ptr += 4
				
				if ptr >= bytes.size() - size: break
				var string_bytes := bytes.slice(ptr, ptr + size)
				dict[key] = string_bytes.get_string_from_utf8()
				ptr += size
			&"bytes":
				if ptr >= bytes.size() - 4: break
				var size = bytes.decode_u32(ptr)
				ptr += 4
				
				if ptr >= bytes.size() - size: break
				dict[key] = bytes.slice(ptr, ptr + size)
				ptr += size
	
	printerr("Failed to fully decode binary data - Ran out of data earlier than expected")
