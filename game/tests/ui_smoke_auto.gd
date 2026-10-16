extends Node
## AUTO MODE smoke (needs a window): runs auto mode fast, takes the Audience seat for one run, opens the gallery and a
## piece, extracts one piece into tests/shots_auto/nft (never the Desktop), exits. Screenshots + result.txt in
## res://tests/shots_auto/. Run the scene tests/ui_smoke_auto.tscn.

var lines: Array[String] = []
var failures := 0


func _fail(msg: String) -> void:
	failures += 1
	lines.append("FAIL " + msg)


func _ready() -> void:
	OS.set_environment("XAI_API_KEY", "")
	var out := ProjectSettings.globalize_path("res://tests/shots_auto")
	DirAccess.make_dir_recursive_absolute(out)
	var packs := ProjectSettings.globalize_path("res://tests/_auto_smoke_packs")
	DirAccess.make_dir_recursive_absolute(packs)
	var f := FileAccess.open(packs + "/orbital.json", FileAccess.WRITE)
	f.store_string(FileAccess.get_file_as_string("res://era_packs/examples/orbital.json"))
	f.close()
	var gpath := out + "/gallery.json"
	DirAccess.remove_absolute(gpath)
	var m: Control = load("res://auto/auto_mode.tscn").instantiate()
	m.era_dirs = [packs]
	m.gallery_path = gpath
	m.auto_beat = 0.03
	m.auto_pause = 0.4
	get_tree().root.add_child.call_deferred(m)
	await _frames(3)
	await _shot(out, "01_menu")

	m._auto_start()
	await _frames(3)
	await _wait(func() -> bool: return m.sim.beat >= 4, 5.0)
	await _shot(out, "02_auto_play")
	await _wait(func() -> bool: return is_instance_valid(m.pause_timer) and not m.pause_timer.is_stopped(), 20.0)
	await _shot(out, "03_auto_result")
	# the auto result shows the insight texts (owner 2026-10-16)
	var shown := _visible_text(m)
	var ins := EraText.insight(m.sim, m.era_id, m._era())
	if not (shown.contains(ins.text) and shown.contains(ins.dilemma)):
		_fail("auto result does not show the insight")
	else:
		lines.append("auto result: insight shown")
	await _wait(func() -> bool: return m.runner.index >= 8, 60.0)
	lines.append("auto runs started: %d · gallery: %d" % [m.runner.index + 1, m.gallery.entries.size()])
	if m.runner.index < 8:
		_fail("auto mode did not keep running")

	# take the seat: the next run is a human Audience run
	m._toggle_seat()
	await _wait(func() -> bool: return m.role == "audience" and m.sim.beat >= 1, 30.0)
	if m.role != "audience":
		_fail("seat not taken")
	else:
		m._set_pressure(0.2)
		for t in ["system", "persona"]:
			for fr in Lens.FRAGMENTS[t]:
				if m.lens_sim.lens.can_focus(t, fr):
					m._set_lens(t, fr)
					break
		await _shot(out, "04_audience_seat")
		await _wait(func() -> bool: return m.sim.beat >= 3, 8.0)
		var seat_run: int = m.runner.index
		m._toggle_seat() # hand the seat back from the next run
		m._auto_finish()
		await _frames(3)
		lines.append("audience run %d: %s, entry %s" % [seat_run + 1, m.sim.outcome, m.last_entry.get("code", "-")])
		if m.sim.outcome == "synthesis" and not (m.last_entry.seat == "audience" and m.last_entry.code.split(".")[2] == "a"):
			_fail("audience run not recorded as an Audience code")
	await _wait(func() -> bool: return m.role == "auto" and m.sim.beat >= 1, 30.0)
	if m.role != "auto":
		_fail("seat not handed back to the AI")

	# every gallery code rebuilds
	var ok := 0
	for e in m.gallery.entries:
		var r := ReplayCodePack.decode(e.code, m.eras)
		if r.ok and r.hash == e.hash:
			ok += 1
	lines.append("gallery codes rebuilt: %d/%d" % [ok, m.gallery.entries.size()])
	if ok != m.gallery.entries.size() or ok == 0:
		_fail("gallery code does not rebuild")

	m._show_gallery(true)
	await _frames(3)
	await _shot(out, "05_gallery")
	if m.timer.time_left > 0 or not m.pause_timer.is_stopped() or m.in_auto:
		_fail("gallery did not pause auto mode")
	var pick: Dictionary = m.gallery.entries[0]
	for e in m.gallery.entries:
		if e.code.begins_with("SD7."):
			pick = e
	m._open_piece(pick)
	await _frames(3)
	await _shot(out, "06_piece")
	if not (_visible_text(m).contains("VERDICT") and _visible_text(m).contains("OUTPUT DILEMMA")):
		_fail("gallery piece does not show the insight")
	var ex: Dictionary = await m._extract_from_node(out + "/nft")
	lines.append("extract %s: %s" % [pick.code.left(30), ex.get("dir", ex.get("reason", "")).get_file()])
	if not ex.ok or ReplayCodePack.decode(ex.code, m.eras).hash != pick.hash:
		_fail("extract from gallery piece")
	elif not FileAccess.get_file_as_string(ex.dir + "/metadata.json").contains("VERDICT"):
		_fail("extracted package lost its insight")
	m._auto_start()
	await _wait(func() -> bool: return m.sim.beat >= 2, 5.0)
	m._auto_stop()
	await _frames(3)
	await _shot(out, "07_menu_after")
	if m.in_auto or m.timer.time_left > 0:
		_fail("EXIT AUTO did not stop the loop")

	for x in DirAccess.get_files_at(packs):
		DirAccess.remove_absolute(packs + "/" + x)
	DirAccess.remove_absolute(packs)
	var res := "FAIL (%d)" % failures if failures > 0 else "PASS"
	print("RESULT: ", res)
	var w := FileAccess.open(out + "/result.txt", FileAccess.WRITE)
	w.store_string("\n".join(lines) + "\nRESULT: " + res + "\n")
	w.close()
	get_tree().quit(1 if failures > 0 else 0)


## Text of every visible Label under the main node.
func _visible_text(n: Node) -> String:
	var out := ""
	for c in n.get_children():
		if c is CanvasItem and not (c as CanvasItem).visible:
			continue
		if c is Label:
			out += (c as Label).text + "\n"
		out += _visible_text(c)
	return out


func _wait(cond: Callable, max_sec: float) -> void:
	var t := 0.0
	while not cond.call() and t < max_sec:
		await get_tree().create_timer(0.05).timeout
		t += 0.05


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(dir: String, shot_name: String) -> void:
	await _frames(2)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, shot_name])
