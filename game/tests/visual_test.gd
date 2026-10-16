extends Node
## Run through Godot MCP run_project (needs a renderer): res://tests/visual_test.tscn -> tests/shots_visual/result.txt
## Checks: v1 == HiresRender byte for byte · v2 deterministic · v2 != v1 · partial reveal != full · sequence ends on full frame.

const OUT := "res://tests/shots_visual/"
const PX := 512

var fails: Array[String] = []
var log_lines: Array[String] = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sims: Array[DialecticSim] = []
	var dec := ReplayCode.decode("SD6.prehistoric.p.630470892.0..86a9b6c87654")
	if dec.ok:
		sims.append(dec.sim)
	else:
		fails.append("decode of known code failed")
	for era in ["industrial", "prehistoric", "posttruth"]:
		var s := NodeSimV4.new(7, 60, Eras.get_era(era).commands)
		s.run()
		sims.append(s)
	for si in sims.size():
		var sim := sims[si]
		var base := await HiresRender.render(get_tree(), sim, PX)
		var v1 := await VisualEngine.render_frame(get_tree(), sim, 1.0, PX, "v1")
		var v2a := await VisualEngine.render_frame(get_tree(), sim, 1.0, PX, "v2")
		var v2b := await VisualEngine.render_frame(get_tree(), sim, 1.0, PX, "v2")
		var half := await VisualEngine.render_frame(get_tree(), sim, 0.5, PX, "v2")
		_check(v1.get_data() == base.get_data(), "sim %d: v1 == HiresRender" % si)
		_check(v2a.get_data() == v2b.get_data(), "sim %d: v2 deterministic" % si)
		_check(v2a.get_data() != v1.get_data(), "sim %d: v2 differs from v1" % si)
		_check(half.get_data() != v2a.get_data(), "sim %d: reveal 0.5 differs from 1.0" % si)
		for gp in ["g1", "g2", "g3"]:
			var ga := await VisualEngine.render_frame(get_tree(), sim, 1.0, PX, gp)
			var gb := await VisualEngine.render_frame(get_tree(), sim, 1.0, PX, gp)
			_check(ga.get_data() == gb.get_data(), "sim %d: %s deterministic" % [si, gp])
			_check(ga.get_data() != v1.get_data(), "sim %d: %s differs from v1" % [si, gp])
		v2a.save_png(ProjectSettings.globalize_path(OUT + "sim%d_v2.png" % si))
		v1.save_png(ProjectSettings.globalize_path(OUT + "sim%d_v1.png" % si))
		log_lines.append("sim %d beats=%d outcome=%s v2_hash=%d" % [si, sim.trace.size(), sim.outcome, hash(v2a.get_data())])
	var seq := await VisualEngine.render_sequence(get_tree(), sims[0], 6, 256, "v2")
	var last := await VisualEngine.render_frame(get_tree(), sims[0], 1.0, 256, "v2")
	_check(seq.size() == 6 and seq[5].get_data() == last.get_data(), "sequence last frame == full frame")
	_check(seq[0].get_data() != seq[5].get_data(), "sequence first != last")
	var f := FileAccess.open(OUT + "result.txt", FileAccess.WRITE)
	f.store_string("\n".join(log_lines) + "\nRESULT: " + ("PASS" if fails.is_empty() else "FAIL " + str(fails)) + "\n")
	f.close()
	print("RESULT: ", "PASS" if fails.is_empty() else "FAIL " + str(fails))
	get_tree().quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
