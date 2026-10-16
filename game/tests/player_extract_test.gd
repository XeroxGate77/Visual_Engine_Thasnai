extends SceneTree
## Player extracts (public build): the normal package, labelled "Extracted by: player", unsigned, zipped for the web.
## Temp folders only. godot --headless --path game -s tests/player_extract_test.gd < /dev/null

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	print("ok   " if cond else "FAIL ", label)


func _init() -> void:
	var root := ProjectSettings.globalize_path("res://tests/_player_out")
	var reg := EraRegistry.scan([root.path_join("none")])
	var sim: NodeSimV4 = null
	for s in range(1, 100):
		var t := NodeSimV4.new(s * 17, 60, Eras.get_era("prehistoric").commands)
		t.run()
		if t.outcome == "synthesis":
			sim = t
			break
	var art := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var w := NftPackagePack.write(sim, "prehistoric", "persona", art, {"text": "T", "dilemma": "D"}, root, reg)
	check(w.ok and not w.signed, "player package written, unsigned (no creator key)")
	PlayerExtract.mark(w.dir)
	PlayerExtract.mark(w.dir) # idempotent
	var md = JSON.parse_string(FileAccess.get_file_as_string(w.dir.path_join("metadata.json")))
	var labels: Array = md.attributes.filter(func(a): return a.trait_type == "Extracted by")
	check(labels.size() == 1 and labels[0].value == PlayerExtract.LABEL, "metadata says 'Extracted by: player' once")
	check(md.attributes.any(func(a): return a.trait_type == "Creator Signature" and a.value == "unsigned"), "metadata keeps 'Creator Signature: unsigned'")
	check(FileAccess.get_file_as_string(w.dir.path_join("README-MINT.md")).contains("not an edition of the creator"), "README says it is not a creator edition")
	var zp := root.path_join("zip/" + str(w.dir).get_file() + ".zip")
	var bytes := PlayerExtract.zip_folder(w.dir, zp)
	check(bytes.size() > 1000, "zip built (%d bytes)" % bytes.size())
	var zr := ZIPReader.new()
	zr.open(zp)
	var files := zr.get_files()
	var top: String = str(w.dir).get_file()
	var need := ["art.png", "qr.png", "replay.txt", "metadata.json", "README-MINT.md", "derivatives/qr_ink.png"]
	check(need.all(func(n): return (top + "/" + n) in files), "zip holds the whole piece folder (%d files)" % files.size())
	check(zr.read_file(top + "/replay.txt").get_string_from_utf8().strip_edges() == w.code, "zip replay.txt = the piece code")
	zr.close()
	_rm(root)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)


func _rm(path: String) -> void:
	for d in DirAccess.get_directories_at(path):
		_rm(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
