extends Node
## MAIN v2 smoke: every era (3 built-in + the example pack "orbital" from a temp folder) x role, screenshots to
## res://tests/shots_v2/, then VIEWER v2 rebuilds an SD7 piece and an SD6 piece. Copy of ui_smoke.gd adapted to v2.
## Run the scene tests/ui_smoke_v2.tscn (needs a window; not --headless).

func _ready() -> void:
	OS.set_environment("ANTHROPIC_API_KEY", "") # never make paid API calls from the smoke test
	OS.set_environment("XAI_API_KEY", "")
	var out_dir := ProjectSettings.globalize_path("res://tests/shots_v2")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var packs := ProjectSettings.globalize_path("res://tests/_smoke_packs")
	DirAccess.make_dir_recursive_absolute(packs)
	var f0 := FileAccess.open(packs + "/orbital.json", FileAccess.WRITE)
	f0.store_string(FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	f0.close()
	var main: Control = load("res://main_v2.tscn").instantiate()
	main.era_dirs = [packs]
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot(out_dir, "01_era")
	var failures := 0
	var lines: Array[String] = []
	var shots_taken := {}
	var sd7 := ""
	var sd6 := ""
	for era in main.eras.order:
		for role in ["audience", "persona", "system"]:
			main._show_era()
			main._on_era(era)
			if era == "orbital" and role == "persona":
				await _shot(out_dir, "02_role_pack")
			main._on_role(role)
			await get_tree().process_frame
			if era == "orbital":
				await _shot(out_dir, "03_play_pack_" + role)
			var guard := 0
			while not main.sim.ended and guard < 200:
				guard += 1
				if role == "persona":
					main._on_persona_response(["obey", "negotiate", "defy"][guard % 3])
				elif role == "system":
					var idx: int = guard % main.sim.commands.size()
					if main.node_sim.cond_kind == "sys" and not (idx in main.node_sim.allowed):
						idx = main.node_sim.allowed[0]
					main._on_system_order(idx)
				else:
					_pick_lens(main, guard)
					main._next_beat()
				main.timer.stop()
				if not main.sim.ended:
					main._next_beat()
				if era == "orbital" and guard == 6 and not main.sim.ended:
					await _shot(out_dir, "05_lens_" + role)
				if not main.sim.ended and not shots_taken.has(role):
					if (role == "persona" and main.node_sim.cond_kind == "invite") or (role == "system" and main.node_sim.cond_kind == "sys"):
						shots_taken[role] = true
						await _shot(out_dir, "06_node_" + role)
			if not main.sim.ended:
				failures += 1
				lines.append("NOT ENDED %s %s" % [era, role])
			main._show_result()
			await get_tree().create_timer(2.8).timeout
			if era == "orbital" or role == "persona":
				await _shot(out_dir, "04_result_%s_%s" % [era, role])
			if not main.result_note.text.contains("fallback") or main.result_note.text.contains("GROK"):
				failures += 1
				lines.append("NO FALLBACK NOTE %s %s" % [era, role])
			if main.sim.outcome == "synthesis" and not main.lens_sim.lens.both_enough():
				failures += 1
				lines.append("SYNTHESIS WITHOUT DISCLOSURE %s %s" % [era, role])
			if main.sim.outcome == "synthesis":
				var ex: Dictionary = await main._extract_from_node(out_dir + "/nft")
				if not ex.ok or not ReplayCodePack.decode(ex.code, main.eras).ok or Image.load_from_file(ex.dir + "/art.png").get_width() != 2048:
					failures += 1
					lines.append("EXTRACT FAILED %s %s: %s" % [era, role, ex.get("reason", "")])
				else:
					lines.append("EXTRACTED %s %s -> %s %s" % [era, role, ex.dir.get_file(), ex.code.left(30)])
					if ex.code.begins_with("SD7."): sd7 = ex.code
					if ex.code.begins_with("SD6."): sd6 = ex.code
			elif is_instance_valid(main.extract_button):
				failures += 1
				lines.append("EXTRACT BUTTON ON NON-SYNTHESIS %s %s" % [era, role])
			if main.sim.outcome == "synthesis" and main.node_sim.synthesis_type == "":
				failures += 1
				lines.append("SYNTHESIS WITHOUT TYPE %s %s" % [era, role])
			if main.image_prompt == "" or not is_instance_valid(main.copy_button):
				failures += 1
				lines.append("NO IMAGE PROMPT %s %s" % [era, role])
			lines.append("OK %s %s beats=%d outcome=%s note=%s" % [era, role, main.sim.beat, main.sim.outcome, main.result_note.text])
	# VIEWER v2
	main.queue_free()
	var viewer: Control = load("res://viewer/viewer_v2.tscn").instantiate()
	viewer.era_dirs = [packs]
	get_tree().root.add_child(viewer)
	await get_tree().process_frame
	for c in [sd7, sd6]:
		if c == "":
			failures += 1
			lines.append("NO PIECE TO VIEW (sd7=%s sd6=%s)" % [sd7, sd6])
			continue
		var r: Dictionary = viewer.show_code(c)
		await get_tree().create_timer(6.5).timeout
		await _shot(out_dir, "07_viewer_" + c.left(3))
		if not (r.ok and viewer.verdict.text.begins_with("AUTHENTIC")):
			failures += 1
			lines.append("VIEWER FAILED " + c)
		else:
			lines.append("VIEWER OK %s · %s" % [c.left(24), viewer.title.text])
	var bad: Dictionary = viewer.show_code(sd7.replace("~", "~0") if sd7 != "" else "SD7.x")
	if bad.ok:
		failures += 1
		lines.append("VIEWER ACCEPTED A BROKEN SD7")
	for fx in DirAccess.get_files_at(packs):
		DirAccess.remove_absolute(packs + "/" + fx)
	DirAccess.remove_absolute(packs)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	var f := FileAccess.open(out_dir + "/result.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\nRESULT: " + ("FAIL (%d)" % failures if failures > 0 else "PASS") + "\n")
	f.close()
	get_tree().quit(1 if failures > 0 else 0)


## Human Audience: alternate Lens direction, first fragment that can still be focused.
func _pick_lens(main: Control, beat: int) -> void:
	var order := ["system", "persona"] if beat % 2 == 0 else ["persona", "system"]
	for t in order:
		for f in Lens.FRAGMENTS[t]:
			if main.lens_sim.lens.can_focus(t, f):
				main._set_lens(t, f)
				return


func _shot(dir: String, name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
