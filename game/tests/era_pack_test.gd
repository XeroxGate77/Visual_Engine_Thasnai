extends SceneTree
## Era packs: the pack format holds an era exactly (same runs as the locked Eras), the validator rejects broken packs,
## the registry loads valid packs beside the built-ins, the balance report runs. Writes only to a temp folder.
## godot --headless --path game -s tests/era_pack_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	print("ok   " if cond else "FAIL ", label)


func _init() -> void:
	# 1. built-in eras as pack files == the locked eras, and run identically
	for id in Eras.ORDER:
		var p := EraPack.load_file("res://era_packs/builtin/%s.json" % id, true)
		check(p.ok, "built-in pack %s parses" % id)
		check(JSON.stringify(p.era, "", true) == JSON.stringify(Eras.get_era(id), "", true), "pack %s == Eras.DATA.%s" % [id, id])
		var same := true
		for s in range(1, 31):
			var a := NodeSimV4.new(s * 101, 60, p.era.commands)
			var b := NodeSimV4.new(s * 101, 60, Eras.get_era(id).commands)
			a.run()
			b.run()
			same = same and a.log_hash() == b.log_hash()
		check(same, "pack %s: 30 runs give the same log hash as the built-in era" % id)
		check(not EraPack.load_file("res://era_packs/builtin/%s.json" % id).ok, "built-in id %s refused as a new pack" % id)

	# 2. the example pack (written by an AI through the kit)
	var ex := EraPack.load_file("res://era_packs/examples/orbital.json")
	check(ex.ok, "example pack 'orbital' is valid %s" % str(ex.get("errors", [])))
	check(ex.hash == EraPack.content_hash(ex.era) and ex.hash.length() == 64, "content hash is sha256 and stable")
	var bumped: Dictionary = ex.era.duplicate(true)
	bumped.commands[0].cost = 0.71
	check(EraPack.content_hash(bumped) != ex.hash, "changing one number changes the hash")
	var rep := EraPackCheck.report(ex.era, 120)
	print(EraPackCheck.format("orbital", rep))
	check(rep.measure.deterministic and rep.measure.n == 120, "balance report runs and is deterministic")

	# 3. broken packs are rejected, each with a reason
	var good: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	var cases := {
		"wrong format": func(d): d.format = "x",
		"id with a dot": func(d): d.id = "or.bital",
		"3 commands": func(d): d.era.commands.resize(3),
		"11 commands": func(d): for i in 6: d.era.commands.append(d.era.commands[0].duplicate()),
		"number 1.5": func(d): d.era.commands[1].control = 1.5,
		"number as text": func(d): d.era.commands[1].cost = "0.5",
		"missing closing": func(d): d.era.erase("closing"),
		"duplicate command name": func(d): d.era.commands[1].name = d.era.commands[0].name,
		"title too long": func(d): d.era.title = "A VERY LONG TITLE THAT NEVER FITS",
		"empty text": func(d): d.era.commands[2].text = "  ",
	}
	for label in cases:
		var d: Dictionary = good.duplicate(true)
		cases[label].call(d)
		var r := EraPack.from_dict(d)
		check(not r.ok and not r.errors.is_empty(), "rejected: %s (%s)" % [label, r.errors[0] if not r.errors.is_empty() else "-"])
	var thai: Dictionary = good.duplicate(true)
	thai.era.blurb = "ยุคอวกาศ"
	var rt := EraPack.from_dict(thai)
	check(rt.ok and str(rt.warnings).contains("non-Latin"), "Thai text is allowed, with a font warning")
	var extra: Dictionary = good.duplicate(true)
	extra.mood = "x"
	check(EraPack.from_dict(extra).ok and str(EraPack.from_dict(extra).warnings).contains("mood"), "unknown keys: warning, not rejection")

	# 4. registry: built-ins first, valid packs added, broken / duplicate packs listed as rejected
	var dir := ProjectSettings.globalize_path("res://tests/_era_out")
	DirAccess.make_dir_recursive_absolute(dir)
	_write(dir.path_join("a_orbital.json"), FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	_write(dir.path_join("b_dupe.json"), FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	_write(dir.path_join("c_broken.json"), "{not json")
	_write(dir.path_join("d_builtin.json"), FileAccess.get_file_as_string("res://era_packs/builtin/industrial.json"))
	var reg := EraRegistry.scan([dir])
	check(reg.order == ["industrial", "prehistoric", "posttruth", "orbital"], "registry order: built-ins then packs (%s)" % str(reg.order))
	check(reg.is_pack("orbital") and not reg.is_pack("industrial") and reg.get_era("industrial") == Eras.get_era("industrial"), "registry: pack vs built-in")
	check(reg.rejected.size() == 3, "registry rejected duplicate, broken and built-in-id files (%d)" % reg.rejected.size())
	var def := EraRegistry.scan()
	check(def.order.size() >= 3 and def.rejected.is_empty(), "default folders: no broken packs (examples/ and builtin/ are not auto-loaded)")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)

	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
