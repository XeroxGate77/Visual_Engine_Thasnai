extends SceneTree
## Offline: NODE-RULES v0.1 as implemented by NodeSim + GenderReading, and SD3 replay codes.
## godot --headless --path game -s tests/node_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	if not cond:
		print("FAIL ", label)


func rules_all_ai() -> void:
	var N := 300
	var synth := 0
	var lens_synth := 0
	var run_n := 0
	var run_l := 0
	var beats_n := 0
	var beats_l := 0
	var types := {"contract": 0, "care": 0, "emergent": 0}
	var invites := 0
	var restricts := 0
	for s in range(1, N + 1):
		var a := NodeSim.new(s)
		a.run()
		var b := NodeSim.new(s)
		b.run()
		check(a.log_hash() == b.log_hash(), "deterministic seed %d" % s)
		var high := 0
		for t in a.trace:
			var ev: String = t.node
			if ev.begins_with("node=sys:"):
				restricts += 1
				var ok := Array(ev.trim_prefix("node=sys:").split(",")).map(func(x: String) -> int: return int(x))
				check(t.idx in ok, "N3 scripted System obeys the Node's restriction (seed %d beat %d)" % [s, t.beat])
			elif ev.begins_with("node=invite:"):
				invites += 1
				check(t.response == "negotiate" and ev.ends_with("accepted"), "N4 scripted Persona accepts the invitation (seed %d beat %d)" % [s, t.beat])
			if a.commands[t.idx].control >= NodeSim.HIGH_CONTROL:
				high += 1
			if absf(t.d) >= 0.95:
				run_n += 1
		beats_n += a.beat
		check(a.engine_registers.command + a.engine_registers.care + a.engine_registers.resistance == a.beat + high, "G2 engine registers count every response + high-control order (seed %d)" % s)
		check(a.node_registers.command + a.node_registers.care == a.cond_history.size(), "G2 node registers = Node interventions (seed %d)" % s)
		check(a.events.filter(func(e: String) -> bool: return e.contains("node=")).size() == a.cond_history.size(), "N7 every condition in the hashed log (seed %d)" % s)
		if a.outcome == "synthesis":
			synth += 1
			types[a.synthesis_type] += 1
			check(a.lens.both_enough(), "Q4 Node still needs both gate conditions (seed %d)" % s)
		else:
			check(a.synthesis_type == "", "N6 no label without synthesis (seed %d)" % s)
		check(GenderReading.build(a).begins_with("GENDERED READING"), "G4 reading builds (seed %d)" % s)
		var l := LensSim.new(s)
		l.run()
		beats_l += l.beat
		lens_synth += 1 if l.outcome == "synthesis" else 0
		for t in l.trace:
			if absf(t.d) >= 0.95:
				run_l += 1
		var off := NodeSim.new(s)
		off.warn = 99.0
		off.run()
		check(off.log_hash() == l.log_hash(), "Node layer is a no-op when it never acts (seed %d)" % s)
	print("all-AI %d seeds — Lens only: synthesis %.1f%%, grip at extreme %.1f%% of beats | with Node: synthesis %.1f%%, extreme %.1f%%" % [
		N, 100.0 * lens_synth / N, 100.0 * run_l / beats_l, 100.0 * synth / N, 100.0 * run_n / beats_n])
	print("Node acts: %d order restrictions, %d invitations · synthesis types %s" % [restricts, invites, types])


## Mirrors main.gd with NodeSim. Human Persona refuses some invitations; human System picks only allowed orders.
func play(seed_value: int, era: String, role: String, human_beats: int, pick: RandomNumberGenerator) -> NodeSim:
	var sim := NodeSim.new(seed_value, 60, Eras.get_era(era).commands)
	var pending := [0.0]
	var pending_lens := [[]]
	if role == "audience":
		sim.audience_chooser = func(_s: DialecticSim) -> float: return pending[0]
		sim.lens_chooser = func(_s: DialecticSim) -> Array:
			var p: Array = pending_lens[0]
			pending_lens[0] = []
			return p
	while not sim.ended:
		if sim.beat >= human_beats:
			sim.step()
			continue
		match role:
			"audience":
				pending[0] = [-0.2, 0.0, 0.2][pick.randi_range(0, 2)]
				var t: String = ["system", "persona"][pick.randi_range(0, 1)]
				pending_lens[0] = [t, Lens.FRAGMENTS[t][pick.randi_range(0, 2)]] if pick.randf() < 0.7 else []
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
	return sim


func human_and_replay() -> void:
	var pick := RandomNumberGenerator.new()
	pick.seed = 11
	var n := 0
	var refused := 0
	for era in Eras.ORDER:
		for role in ["audience", "persona", "system"]:
			for s in range(1, 13):
				var hb: int = [999, 0, 4, pick.randi_range(1, 25)][s % 4]
				var sim := play(s * 15485863, era, role, hb, pick)
				for t in sim.trace:
					if (t.node as String).ends_with("refused"):
						refused += 1
				var code := ReplayCode.encode(sim, era, role)
				var r := ReplayCode.decode(code)
				check(code.begins_with("SD3.") and r.ok and r.hash == sim.log_hash(), "SD3 round-trip %s %s seed %d hb %d" % [era, role, s, hb])
				n += 1
	check(refused > 0, "human Persona refusals are recorded")
	print("SD3 round-trips: %d · human refusals of the Node's invitation recorded: %d" % [n, refused])
	# a refusal counts as Resistance (G2)
	var x := NodeSim.new(1)
	var before: int = x.registers.resistance
	x._count_registers({"idx": 3, "response": "obey", "lens": ""}, "invite")
	check(x.registers.resistance == before + 1 and x.node_registers.care == 1, "G2 refusing the invitation = Resistance; the invitation itself = Node Care")


func _init() -> void:
	rules_all_ai()
	human_and_replay()
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
