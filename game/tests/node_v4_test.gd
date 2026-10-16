extends SceneTree
## Offline: NODE-RULES v0.4 (micro-nodes, M2c on, K = 2) as MicroGrid + NodeSimV4. SD6 replay codes.
## godot --headless --path game -s tests/node_v4_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	if not cond:
		print("FAIL ", label)


func cell_text(m: MicroGrid, c: int) -> String:
	return m.to_text().split("|")[c]


func micro_rules() -> void:
	var g := 0.0 # grip 0 = gauge 50% = cell 10
	var m := MicroGrid.new()
	m.update(g, "command")
	check(cell_text(m, 10) == "T....", "M1 deposit a thesis in the first empty micro-node")
	m.update(g, "care")
	check(cell_text(m, 10) == "AA...", "M2a a thesis beside a thesis of another register -> both antithesis")
	m.update(g, "care")
	check(cell_text(m, 10) == "SSA..", "M2b in a care beat a contradiction beside a contradiction -> synthesis (and the new thesis meets an antithesis -> A)")
	var d := MicroGrid.new()
	for i in 5:
		d.update(g, "care")
	check(cell_text(d, 10) == "TTTAA", "M2c dogma negates its last micro-node, then M2a spreads to its neighbour in the same beat")
	var f := MicroGrid.new()
	f.state.fill(MicroGrid.EMPTY)
	for k in 5:
		f.state[50 + k] = [MicroGrid.SYNTHESIS, MicroGrid.ANTITHESIS, MicroGrid.SYNTHESIS, MicroGrid.SYNTHESIS, MicroGrid.SYNTHESIS][k]
	f.update(g, "resistance")
	check(cell_text(f, 10) == "AAASS" or cell_text(f, 10).begins_with("A"), "M1' resistance on a full cell reopens its first synthesis")
	var c := MicroGrid.new()
	for k in 5:
		c.state[50 + k] = MicroGrid.ANTITHESIS
	c.update(g, "care")
	check(c.count_in_band(MicroGrid.SYNTHESIS) == 5, "M1' care on a full cell resolves a contradiction, M2b spreads it")
	check(MicroGrid.new().unresolved(g) == false and c.unresolved(g) == false, "M4 unresolved = more A than S")


func _init() -> void:
	micro_rules()
	var N := 300
	var synth := 0
	var beats := 0
	var types := {"contract": 0, "care": 0, "emergent": 0}
	for s in range(1, N + 1):
		var a := NodeSimV4.new(s)
		a.run()
		var b := NodeSimV4.new(s)
		b.run()
		check(a.log_hash() == b.log_hash() and a.micro.to_text() == b.micro.to_text(), "deterministic seed %d" % s)
		check(a.micro_need == 2 and a.micro.self_negation, "owner settings K = 2, M2c on")
		beats += a.beat
		if a.outcome == "synthesis":
			synth += 1
			types[a.synthesis_type] += 1
			check(a.micro.count_in_band(MicroGrid.SYNTHESIS) >= 2 and a.grid_streak >= DialecticSim.BALANCE_HOLD and a.lens.both_enough(),
				"M3 synthesis needs >= 2 S in band + grid streak + disclosure (seed %d)" % s)
	print("v0.4 all-AI %d seeds: synthesis %.1f%%, avg beats %.1f, labels %s (v0.3 was 65.7%%, 26.0)" % [N, 100.0 * synth / N, float(beats) / N, types])

	var pick := RandomNumberGenerator.new()
	pick.seed = 41
	var n := 0
	for era in Eras.ORDER:
		for role in ["audience", "persona", "system"]:
			for s in range(1, 9):
				var sim := NodeSimV4.new(s * 5003, 60, Eras.get_era(era).commands)
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
				check(code.begins_with("SD6.") and r.ok and r.hash == sim.log_hash() and (r.sim as NodeSimV4).micro.to_text() == sim.micro.to_text(),
					"SD6 round-trip incl. micro grid %s %s seed %d" % [era, role, s])
				n += 1
	print("SD6 round-trips: %d" % n)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
