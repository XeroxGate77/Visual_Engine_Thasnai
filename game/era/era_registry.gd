class_name EraRegistry
extends RefCounted
## Every era the game can offer: the built-in eras (locked `sim/eras.gd`, unchanged) + valid era packs found in
## folders (default: res://era_packs/ and user://era_packs/, top level only). Invalid packs are listed, never loaded.

const DIRS := ["res://era_packs", "user://era_packs"]

var eras := {}      # id -> era dictionary (same shape as Eras.DATA[id])
var hashes := {}    # id -> content hash (packs only)
var sources := {}   # id -> file path (packs only)
var order: Array[String] = []
var rejected: Array[Dictionary] = []  # {file, errors}


static func scan(dirs: Array = DIRS) -> EraRegistry:
	var r := EraRegistry.new()
	for id in Eras.ORDER:
		r.eras[id] = Eras.get_era(id)
		r.order.append(id)
	for dir in dirs:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		var files := Array(DirAccess.get_files_at(dir))
		files.sort()
		for f in files:
			if not f.ends_with(".json"):
				continue
			var path: String = dir.path_join(f)
			var p := EraPack.load_file(path)
			if not p.ok:
				r.rejected.append({"file": path, "errors": p.errors})
			elif r.eras.has(p.id):
				r.rejected.append({"file": path, "errors": ["id \"%s\" already used by %s" % [p.id, r.sources.get(p.id, "a built-in era")]]})
			else:
				r.eras[p.id] = p.era
				r.hashes[p.id] = p.hash
				r.sources[p.id] = path
				r.order.append(p.id)
	return r


func has(id: String) -> bool:
	return eras.has(id)


func get_era(id: String) -> Dictionary:
	return eras[id]


func is_pack(id: String) -> bool:
	return hashes.has(id)
