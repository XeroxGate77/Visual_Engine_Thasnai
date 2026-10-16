extends SceneTree
## Era packs in the game (step 2): built-in eras behave EXACTLY as before through the v2 wrappers; pack eras get
## SD7 codes that round-trip, are pinned to the pack content, and rebuild identically to SD6 when the deck is equal.
## Writes only to temp folders. godot --headless --path game -s tests/era_pack_game_test.gd < /dev/null

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	print("ok   " if cond else "FAIL ", label)


func _init() -> void:
	var tmp := ProjectSettings.globalize_path("res://tests/_era_game_out")
	var packs := tmp.path_join("packs")
	DirAccess.make_dir_recursive_absolute(packs)
	_write(packs.path_join("orbital.json"), FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	# a pack whose deck is the industrial deck under another id — for the SD6 <-> SD7 cross-check
	var copy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://era_packs/builtin/industrial.json"))
	copy.id = "indcopy"
	_write(packs.path_join("indcopy.json"), JSON.stringify(copy))
	var reg := EraRegistry.scan([packs])
	check(reg.is_pack("orbital") and reg.is_pack("indcopy") and reg.rejected.is_empty(), "test packs installed")

	# 1. built-in eras: the wrappers return exactly what the locked builders return
	var same := true
	for id in Eras.ORDER:
		for s in range(1, 21):
			var sim := NodeSimV4.new(s * 31, 60, Eras.get_era(id).commands)
			sim.run()
			same = same and EraText.insight(sim, id, reg.get_era(id)) == Insight.build(sim, id)
			same = same and EraText.image_prompt(sim, id, reg.get_era(id)) == ImagePrompt.build(sim, id)
			same = same and JSON.stringify(EraText.grok_chat_body(sim, id, reg.get_era(id))) == JSON.stringify(GrokInsight.build_chat_body(sim, id))
			same = same and ReplayCodePack.encode(sim, id, "persona", reg) == ReplayCode.encode(sim, id, "persona")
	check(same, "built-in eras: insight, image prompt, Grok body and SD6 code identical to the locked code (60 runs)")

	# 2. pack era text
	var orb := reg.get_era("orbital")
	var osim := NodeSimV4.new(77, 60, orb.commands)
	osim.run()
	var ins := EraText.insight(osim, "orbital", orb)
	check(ins.text.ends_with(orb.closing[osim.outcome]) and not ins.text.contains("machine and the hand") and not ins.text.contains("line kept running"), "pack insight ends with the pack's closing line")
	check(EraText.image_prompt(osim, "orbital", orb).contains(orb.image_scene) and not EraText.image_prompt(osim, "orbital", orb).contains("foundry"), "pack image prompt uses image_scene")
	var gb := EraText.grok_chat_body(osim, "orbital", orb)
	check(gb.messages[1].content.begins_with("ERA: ORBITAL\n") and gb.messages[1].content.contains(orb.commands[0].name) == osim.trace.any(func(t): return t.idx == 0), "Grok record names the pack era")

	# 3. SD7 round-trips for every role (human inputs, then AUTO-FINISH)
	var trips := 0
	var ok_trips := 0
	for role in ["audience", "persona", "system"]:
		for s in range(1, 13):
			var sim := _human_game(orb.commands, s * 911, role, s)
			var code := ReplayCodePack.encode(sim, "orbital", role, reg)
			var r := ReplayCodePack.decode(code, reg)
			trips += 1
			if code.begins_with("SD7.orbital~%s." % reg.hashes.orbital.left(8)) and r.ok and r.hash == sim.log_hash() and ReplayCodePack.canonical(code, reg) == code:
				ok_trips += 1
	check(ok_trips == trips, "SD7 round-trips: %d/%d (audience, persona, system)" % [ok_trips, trips])

	# 4. cross-check: same deck under a pack id -> SD7 rebuilds exactly what SD6 rebuilds
	var cross := 0
	for role in ["audience", "persona", "system"]:
		for s in range(1, 9):
			var sim := _human_game(Eras.get_era("industrial").commands, s * 1301, role, s)
			var sd6 := ReplayCode.encode(sim, "industrial", role)
			var sd7 := "SD7.indcopy~%s.%s" % [reg.hashes.indcopy.left(8), sd6.split(".", true, 2)[2]]
			var a := ReplayCode.decode(sd6)
			var b := ReplayCodePack.decode(sd7, reg)
			if a.ok and b.ok and a.hash == b.hash:
				cross += 1
	check(cross == 24, "SD7 decoder == SD6 decoder on the same deck: %d/24" % cross)
	var sd6_ok := ReplayCode.encode(_human_game(Eras.get_era("posttruth").commands, 5, "persona", 5), "posttruth", "persona")
	check(ReplayCodePack.decode(sd6_ok, reg).ok, "an SD6 code still opens through the v2 decoder")

	# 5. pinned to the pack content
	var code7 := ReplayCodePack.encode(osim, "orbital", "persona", reg)
	var bare := EraRegistry.scan([tmp.path_join("none")])
	check(ReplayCodePack.decode(code7, bare).reason.contains("not installed"), "pack missing -> refused (not installed)")
	var changed_dir := tmp.path_join("changed")
	DirAccess.make_dir_recursive_absolute(changed_dir)
	var ch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	ch.era.commands[0].cost = 0.71
	_write(changed_dir.path_join("orbital.json"), JSON.stringify(ch))
	check(ReplayCodePack.decode(code7, EraRegistry.scan([changed_dir])).reason.contains("not the one"), "pack changed -> refused, never rebuilt on another deck")
	check(not ReplayCodePack.decode(code7.replace(".p.", ".s."), reg).ok, "tampered code -> refused")

	# 6. extract a pack piece
	var synth: NodeSimV4 = null
	for s in range(1, 200):
		var sim := NodeSimV4.new(s * 13, 60, orb.commands)
		sim.run()
		if sim.outcome == "synthesis":
			synth = sim
			break
	var root := tmp.path_join("nft")
	var art := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var w := NftPackagePack.write(synth, "orbital", "persona", art, {"text": "T", "dilemma": "D"}, root, reg)
	check(w.ok and w.code.begins_with("SD7.") and ReplayCodePack.decode(w.code, reg).ok, "pack piece extracted with an SD7 code")
	var pack_copy := EraPack.load_file(w.dir.path_join("era_pack.json"))
	check(pack_copy.ok and pack_copy.hash == reg.hashes.orbital, "piece folder carries the exact era pack")
	var md = JSON.parse_string(FileAccess.get_file_as_string(w.dir.path_join("metadata.json")))
	var attrs := {}
	for a in md.attributes:
		attrs[a.trait_type] = a.value
	check(attrs.get("Era") == "ORBITAL" and attrs.get("Era Pack") == "orbital~" + reg.hashes.orbital.left(8), "metadata: Era + Era Pack")
	check(FileAccess.get_file_as_string(w.dir.path_join("replay.txt")).strip_edges() == w.code, "replay.txt holds the SD7 code")
	var isim := NodeSimV4.new(3, 60, Eras.get_era("industrial").commands)
	isim.run()
	if isim.outcome == "synthesis":
		var wi := NftPackagePack.write(isim, "industrial", "persona", art, {"text": "T", "dilemma": "D"}, root, reg)
		check(wi.ok and wi.code.begins_with("SD6.") and not FileAccess.file_exists(wi.dir.path_join("era_pack.json")), "built-in piece: same SD6 package as before")

	_rm(tmp)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)


## A game where a "human" drives the chosen role for `k_human` beats, then the scripted AI finishes.
func _human_game(cmds: Array, seed_v: int, role: String, k_human: int) -> NodeSimV4:
	var sim := NodeSimV4.new(seed_v, 60, cmds)
	var h := RandomNumberGenerator.new()
	h.seed = seed_v + 1
	match role:
		"audience":
			sim.audience_chooser = func(_s: DialecticSim) -> float: return [-0.2, 0.0, 0.2][h.randi() % 3]
			sim.lens_chooser = func(s: DialecticSim) -> Array:
				for t in ["system", "persona"]:
					for f in Lens.FRAGMENTS[t]:
						if (s as LensSim).lens.can_focus(t, f) and h.randf() < 0.5:
							return [t, f]
				return []
		"persona":
			sim.persona_chooser = func(s: DialecticSim, cmd: Dictionary) -> String:
				return ["obey", "negotiate", "defy"][h.randi() % 3] if s.beat <= k_human else s._ai_persona_pick(cmd)
		"system":
			sim.system_chooser = func(s: DialecticSim) -> int:
				if s.beat > k_human:
					return s._ai_system_pick()
				var nsv: NodeSim = s as NodeSim
				if nsv.cond_kind == "sys" and not nsv.allowed.is_empty():
					return nsv.allowed[h.randi() % nsv.allowed.size()]
				return h.randi() % s.commands.size()
	sim.run()
	return sim


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _rm(path: String) -> void:
	for d in DirAccess.get_directories_at(path):
		_rm(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
