extends SceneTree
## Offline: NODE-RULES v0.2 (N2b aim into the band) as NodeSimV2, beside v0.1. SD4 replay codes.
## godot --headless --path game -s tests/node_v2_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	if not cond:
		print("FAIL ", label)


func _init() -> void:
	var N := 300
	var synth := 0
	var types := {"contract": 0, "care": 0, "emergent": 0}
	var aims := 0
	var beats := 0
	for s in range(1, N + 1):
		var a := NodeSimV2.new(s)
		a.run()
		var b := NodeSimV2.new(s)
		b.run()
		check(a.log_hash() == b.log_hash(), "deterministic seed %d" % s)
		beats += a.beat
		aims += a.aim_history.size()
		for i in a.trace.size():
			var t: Dictionary = a.trace[i]
			var ev: String = t.node
			if ev.ends_with("|aim"):
				# N2b: aim only when the previous beat ended outside the band and the N2 warning did not fire
				var prev_d: float = a.trace[i - 1].d if i > 0 else 0.0
				var prev2_d: float = a.trace[i - 2].d if i > 1 else 0.0
				check(absf(prev_d) >= DialecticSim.BALANCE_BAND, "N2b aims only from outside the band (seed %d beat %d)" % [s, t.beat])
				check(absf(prev_d + (prev_d - prev2_d)) < NodeSim.WARN, "N2b only when N2 did not fire (seed %d beat %d)" % [s, t.beat])
				if ev.begins_with("node=sys:"):
					var ok := Array(ev.trim_prefix("node=sys:").trim_suffix("|aim").split(",")).map(func(x: String) -> int: return int(x))
					check(t.idx in ok, "aim restriction obeyed (seed %d beat %d)" % [s, t.beat])
		if a.outcome == "synthesis":
			synth += 1
			types[a.synthesis_type] += 1
			var has_cond := false
			for bt in range(a.beat, a.beat - DialecticSim.BALANCE_HOLD, -1):
				has_cond = has_cond or a.cond_history.has(bt)
			check((a.synthesis_type != "emergent") == has_cond, "N6 counts aim conditions (seed %d)" % s)
		check(a.node_registers.command + a.node_registers.care == a.cond_history.size(), "G2 counts aims (seed %d)" % s)
	print("v0.2 all-AI %d seeds: synthesis %.1f%%, aims %d (%.0f%% of beats), labels %s" % [N, 100.0 * synth / N, aims, 100.0 * aims / beats, types])
	check(types.contract + types.care > 0 and types.emergent > types.contract + types.care, "labels exist but stay rare")

	# v0.1 is untouched beside v0.2
	var v1 := NodeSim.new(5)
	v1.run()
	check(v1.events.all(func(e: String) -> bool: return not e.ends_with("|aim")), "v0.1 never aims")

	# SD4 replay, every role, with AUTO-FINISH midway
	var pick := RandomNumberGenerator.new()
	pick.seed = 23
	var n := 0
	for era in Eras.ORDER:
		for role in ["audience", "persona", "system"]:
			for s in range(1, 9):
				var sim := NodeSimV2.new(s * 7727, 60, Eras.get_era(era).commands)
				var pending := [0.0]
				var pl := [[]]
				if role == "audience":
					sim.audience_chooser = func(_s: DialecticSim) -> float: return pending[0]
					sim.lens_chooser = func(_s: DialecticSim) -> Array:
						var p: Array = pl[0]
						pl[0] = []
						return p
				var hb: int = [999, 0, 5, pick.randi_range(1, 20)][s % 4]
				while not sim.ended:
					if sim.beat >= hb:
						sim.step()
						continue
					match role:
						"audience":
							pending[0] = [-0.2, 0.0, 0.2][pick.randi_range(0, 2)]
							var tg: String = ["system", "persona"][pick.randi_range(0, 1)]
							pl[0] = [tg, Lens.FRAGMENTS[tg][pick.randi_range(0, 2)]]
							sim.begin_beat()
							sim.finish_beat()
						"persona":
							sim.begin_beat()
							sim.finish_beat(["obey", "negotiate", "defy"][pick.randi_range(0, 2)])
						"system":
							var idx := pick.randi_range(0, 3)
							if sim.cond_kind == "sys":
								idx = sim.allowed[pick.randi_range(0, sim.allowed.size() - 1)]
							sim.begin_beat(idx)
							sim.finish_beat()
				var code := ReplayCode.encode(sim, era, role)
				var r := ReplayCode.decode(code)
				check(code.begins_with("SD4.") and r.ok and r.hash == sim.log_hash(), "SD4 round-trip %s %s seed %d" % [era, role, s])
				n += 1
	print("SD4 round-trips: %d" % n)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
