extends SceneTree
## Auto mode logic: seeds, era rotation (built-in + a pack), every gallery code rebuilds its piece, AI-only runs get
## the canonical Persona code, the gallery dedupes and persists. Temp folders only.
## godot --headless --path game -s tests/auto_test.gd < /dev/null

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	print("ok   " if cond else "FAIL ", label)


func _init() -> void:
	var tmp := ProjectSettings.globalize_path("res://tests/_auto_out")
	DirAccess.make_dir_recursive_absolute(tmp.path_join("packs"))
	var f := FileAccess.open(tmp.path_join("packs/orbital.json"), FileAccess.WRITE)
	f.store_string(FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	f.close()
	var reg := EraRegistry.scan([tmp.path_join("packs")])

	check(AutoRunner.seed_for(7, 3) == AutoRunner.seed_for(7, 3) and AutoRunner.seed_for(7, 3) != AutoRunner.seed_for(7, 4), "seeds: same (session, i) -> same seed")
	var a := AutoRunner.new(reg, 12345)
	var b := AutoRunner.new(reg, 12345)
	var eras_seen: Array[String] = []
	var same := true
	var gallery := AutoGallery.new(tmp.path_join("gallery.json"))
	var synth := 0
	var rebuilt := 0
	var k0 := 0
	var sd7 := 0
	var n := 40
	for i in n:
		var ra := a.next_run()
		var rb := b.next_run()
		ra.sim.run()
		rb.sim.run()
		same = same and ra.sim.log_hash() == rb.sim.log_hash() and ra.era == rb.era
		eras_seen.append(ra.era)
		var e := a.entry(ra.sim, ra.era, "auto")
		if ra.sim.outcome == "synthesis":
			synth += 1
			var r := ReplayCodePack.decode(e.code, reg)
			if r.ok and r.hash == ra.sim.log_hash() and r.role == "persona":
				rebuilt += 1
			if e.code == ReplayCodePack.canonical(e.code, reg) and e.code.split(".")[2] == "p":
				k0 += 1
			if e.code.begins_with("SD7."):
				sd7 += 1
			var added := gallery.add(e)
			if synth <= 2:
				check(added, "gallery adds synthesis run %d" % i)
		elif i < 6:
			check(e.is_empty(), "no-synthesis run %d -> no gallery entry" % i)
	check(same, "two runners with the same session seed play the same %d games" % n)
	check(eras_seen.slice(0, 4) == ["industrial", "prehistoric", "posttruth", "orbital"] and eras_seen[4] == "industrial", "era rotation includes the pack (%s)" % str(eras_seen.slice(0, 5)))
	check(synth > 0 and rebuilt == synth, "every synthesis code rebuilds its piece: %d/%d" % [rebuilt, synth])
	check(k0 == synth, "AI-only runs get the canonical Persona code (same encoder as the game): %d/%d" % [k0, synth])
	check(sd7 > 0, "pack runs get SD7 codes (%d)" % sd7)
	check(gallery.entries.size() == synth, "gallery holds every synthesis once (%d)" % gallery.entries.size())
	check(not gallery.add(gallery.entries[0].duplicate()), "same log hash is not added twice")
	var again := AutoGallery.new(tmp.path_join("gallery.json"))
	check(again.entries.size() == synth and again.entries[0].code == gallery.entries[0].code, "gallery persists and reloads")
	check(gallery.entries.all(func(e: Dictionary) -> bool: return e.rarity in Rarity.ORDER and e.seat == "auto"), "entries carry rarity tier and seat")

	for x in DirAccess.get_files_at(tmp.path_join("packs")):
		DirAccess.remove_absolute(tmp.path_join("packs").path_join(x))
	DirAccess.remove_absolute(tmp.path_join("packs"))
	DirAccess.remove_absolute(tmp.path_join("gallery.json"))
	DirAccess.remove_absolute(tmp)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
