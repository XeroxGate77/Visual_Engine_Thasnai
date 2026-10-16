extends SceneTree
## Offline: NODE-RULES v0.3 (grid band 45–55%) as NodeSimV3, compared with v0.2. SD5 replay codes.
## godot --headless --path game -s tests/node_v3_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	if not cond:
		print("FAIL ", label)


func stats(make: Callable, n: int) -> Dictionary:
	var synth := 0
	var beats := 0
	var types := {"contract": 0, "care": 0, "emergent": 0}
	var acts := 0
	for s in range(1, n + 1):
		var sim: NodeSim = make.call(s)
		sim.run()
		beats += sim.beat
		acts += sim.cond_history.size()
		if sim.outcome == "synthesis":
			synth += 1
			types[sim.synthesis_type] += 1
	return {"synth": 100.0 * synth / n, "beats": float(beats) / n, "acts": 100.0 * acts / beats, "types": types}


func _init() -> void:
	# grid mapping
	check(Grid.gauge(0.0) == 50.0 and Grid.gauge(-1.0) == 0.0 and Grid.gauge(1.0) == 100.0, "gauge mapping")
	check(Grid.cell(-1.0) == 0 and Grid.cell(1.0) == 19 and Grid.cell(-0.05) == 9 and Grid.cell(0.05) == 10, "20 cells, band = cells 9–10")
	check(Grid.in_band(0.099) and not Grid.in_band(0.10) and not Grid.in_band(-0.12), "band 45–55% = |grip| < 0.10")

	var N := 300
	for s in range(1, N + 1):
		var a := NodeSimV3.new(s)
		a.run()
		var b := NodeSimV3.new(s)
		b.run()
		check(a.log_hash() == b.log_hash(), "deterministic seed %d" % s)
		var prev_energy := 0
		var streak := 0
		for t in a.trace:
			if t.energy > prev_energy:
				check(Grid.in_band(t.d), "Lens charges only inside the grid band (seed %d beat %d)" % [s, t.beat])
			prev_energy = t.energy
			streak = streak + 1 if Grid.in_band(t.d) else 0
		if a.outcome == "synthesis":
			check(streak >= DialecticSim.BALANCE_HOLD and a.lens.both_enough() and a.synthesis_type != "", "① on the grid + ② + label (seed %d)" % s)
		else:
			check(a.synthesis_type == "", "no label without synthesis (seed %d)" % s)
	var v2 := stats(func(s: int) -> NodeSim: return NodeSimV2.new(s), N)
	var v3 := stats(func(s: int) -> NodeSim: return NodeSimV3.new(s), N)
	print("v0.2 (band ±0.15 = 42.5–57.5%%): synthesis %.1f%%, avg beats %.1f, Node acts %.0f%% of beats, labels %s" % [v2.synth, v2.beats, v2.acts, v2.types])
	print("v0.3 (grid band 45–55%%):       synthesis %.1f%%, avg beats %.1f, Node acts %.0f%% of beats, labels %s" % [v3.synth, v3.beats, v3.acts, v3.types])

	# v0.2 untouched beside v0.3
	check(NodeSimV2.new(9).lens.get_script() == Lens, "v0.2 still uses the original Lens")

	# SD5 replay with human choices + AUTO-FINISH
	var pick := RandomNumberGenerator.new()
	pick.seed = 31
	var n := 0
	for era in Eras.ORDER:
		for role in ["audience", "persona", "system"]:
			for s in range(1, 9):
				var sim := NodeSimV3.new(s * 6301, 60, Eras.get_era(era).commands)
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
				check(code.begins_with("SD5.") and r.ok and r.hash == sim.log_hash(), "SD5 round-trip %s %s seed %d" % [era, role, s])
				n += 1
	print("SD5 round-trips: %d" % n)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
