class_name Wave extends RefCounted


class SpawnEntry:
	var count := 1
	var scene: PackedScene
	
	static func from_str(string: String) -> SpawnEntry:
		var segs := string.split(" ", false, 1)
		if segs.size() != 2: return null
		
		var entry := SpawnEntry.new()
		entry.count = segs[0].strip_edges().to_int()
		
		var id := segs[1].strip_edges()
		var res_path := "res://scenes/enemies/%s.tscn" % id
		if (
			not FileAccess.file_exists(res_path) and
			not FileAccess.file_exists(res_path + ".remap")
		):
			printerr("Enemy ",id," does not exists")
			return null
		
		entry.scene = load(res_path)
		if not entry.scene:
			printerr("Failed to load enemy",id)
			return null
		
		return entry


static func from_csv_line(line: PackedStringArray) -> Wave:
	var wave := Wave.new()
	if line.size() < 2: return null
	wave.weight = line[0].to_int()
	for seg in line.slice(1):
		var entry := SpawnEntry.from_str(seg)
		if not entry: continue
		wave.spawns.append(entry)
	return wave


var weight := 6
var spawns: Array[SpawnEntry] = []
