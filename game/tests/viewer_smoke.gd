extends Node
## Windowed: the viewer rebuilds real games from their codes (and rejects a tampered one). Screenshots to res://tests/shots/.
## Run the scene tests/viewer_smoke.tscn.

func _ready() -> void:
	var out := ProjectSettings.globalize_path("res://tests/shots")
	DirAccess.make_dir_recursive_absolute(out)
	var v: Control = load("res://viewer/viewer.tscn").instantiate()
	get_tree().root.add_child.call_deferred(v)
	await get_tree().process_frame
	await get_tree().process_frame
	var lines: Array[String] = []
	var fails := 0
	var shot := 0
	for s in [3, 11, 27]:
		var sim := NodeSimV4.new(s, 60, Eras.get_era(Eras.ORDER[s % 3]).commands)
		sim.run()
		var code := ReplayCode.encode(sim, Eras.ORDER[s % 3], "persona")
		var r: Dictionary = v.show_code(code)
		var ok: bool = r.ok and r.hash == sim.log_hash() and v.title.text.contains(Eras.get_era(Eras.ORDER[s % 3]).title) and v.verdict.text.begins_with("AUTHENTIC")
		fails += 0 if ok else 1
		lines.append("%s %s %s" % ["OK  " if ok else "FAIL", code.left(40), sim.outcome])
		await get_tree().create_timer(1.0).timeout
		if shot == 0:
			get_viewport().get_texture().get_image().save_png(out + "/viewer_mid.png")
		await get_tree().create_timer(5.5).timeout
		get_viewport().get_texture().get_image().save_png(out + "/viewer_%d.png" % shot)
		shot += 1
	var bad: Dictionary = v.show_code("SD6.industrial.p.123.4.ndon.ffffffffffff")
	var rejected: bool = not bad.ok and v.title.text == "NOT AN AUTHENTIC PIECE"
	fails += 0 if rejected else 1
	lines.append(("OK  " if rejected else "FAIL") + " tampered code rejected")
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out + "/viewer_tampered.png")
	var f := FileAccess.open(out + "/viewer_result.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\nRESULT: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails) + "\n")
	f.close()
	get_tree().quit(1 if fails else 0)
