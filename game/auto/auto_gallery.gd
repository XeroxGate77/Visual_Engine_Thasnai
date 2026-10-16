class_name AutoGallery
extends RefCounted
## Every synthesis auto mode reaches, kept as replay codes in one JSON file (default user://auto_gallery.json).
## Codes only — the art is rebuilt from the code when shown. Nothing here is an edition: extracting a piece into the
## owner's BLACKBOX stays a deliberate act (EXTRACT button), never automatic.

const DEFAULT_PATH := "user://auto_gallery.json"

var path: String
var entries: Array = []  # newest last


func _init(path_value := DEFAULT_PATH) -> void:
	path = path_value
	if FileAccess.file_exists(path):
		var j = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(j) == TYPE_DICTIONARY and typeof(j.get("pieces")) == TYPE_ARRAY:
			entries = j.pieces


func has(log_hash: String) -> bool:
	return entries.any(func(e: Dictionary) -> bool: return e.hash == log_hash)


## Adds and saves; false if empty or already there (one log hash = one gallery piece).
func add(e: Dictionary) -> bool:
	if e.is_empty() or has(e.hash):
		return false
	entries.append(e)
	save()
	return true


func save() -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"format": "sd-auto-gallery/1", "pieces": entries}, "  ") + "\n")
	f.close()


func count_by(key: String) -> Dictionary:
	var out := {}
	for e in entries:
		out[e[key]] = out.get(e[key], 0) + 1
	return out
