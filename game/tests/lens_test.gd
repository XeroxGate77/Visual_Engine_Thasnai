extends SceneTree
## Offline: LENS-RULES v0.1 as implemented by Lens + LensSim, and SD2 replay codes.
## godot --headless --path game -s tests/lens_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	if not cond:
		print("FAIL ", label)


func lens_rules() -> void:
	var l := Lens.new()
	check(not l.focus("system", "order"), "L4.1 no focus without energy")
	for i in 6:
		l.end_beat(0.0)
	check(l.energy == 4, "L3.1/L3.3 energy +1 per in-band beat, capped at 4")
	l.end_beat(0.5)
	check(l.energy == 4, "L3.2 one out-of-band beat: no gain, no loss")
	l.end_beat(0.5)
	check(l.energy == 2, "L3.4 two out-of-band beats in a row: halved")
	l.end_beat(-0.9)
	l.end_beat(-0.9)
	check(l.energy == 1, "L3.4 halves again on the 4th")
	l.end_beat(0.1)
	check(l.out_streak == 0 and l.energy == 2, "back in band resets the streak")
	check(l.focus("system", "control") and l.level("system", "control") == Lens.BLUR and l.energy == 1, "L4.1 focus: -1 energy, +1 level")
	check(l.focus("system", "control") and l.level("system", "control") == Lens.CLEAR, "BLUR -> CLEAR")
	l.energy = 3
	check(not l.focus("system", "control") and l.energy == 3, "cannot go past CLEAR, no energy spent")
	check(not l.focus("system", "nonsense"), "unknown fragment refused")

	var e := Lens.new()
	e.levels.system = {"order": 2, "output": 2, "control": 0}
	check(e.enough("system"), "L5.1 two CLEAR is enough")
	e.levels.system = {"order": 1, "output": 1, "control": 1}
	check(e.enough("system"), "L5.1 three BLUR is enough")
	e.levels.system = {"order": 2, "output": 1, "control": 0}
	check(not e.enough("system"), "L5.1 one CLEAR + one BLUR is not")
	e.levels.system = {"order": 2, "output": 2, "control": 0}
	check(not e.both_enough(), "L5.2 needs both directions")
	e.levels.persona = {"autonomy": 1, "belonging": 1, "purpose": 1}
	check(e.both_enough(), "L5.2 both directions pass")

	check(Lens.view(Lens.HIDDEN, 0.9) == "?" and Lens.view(Lens.BLUR, 0.2) == "low" and Lens.view(Lens.BLUR, 0.8) == "high" \
		and Lens.view(Lens.CLEAR, 0.723) == "0.72", "L2 views")
	check(Lens.from_code(Lens.code_of("persona", "purpose")) == ["persona", "purpose"], "fragment codes round-trip")


func lens_sim() -> void:
	var synth := 0
	var beats := 0
	for s in range(1, 51):
		var a := LensSim.new(s)
		a.run()
		var b := LensSim.new(s)
		b.run()
		check(a.log_hash() == b.log_hash(), "deterministic seed %d" % s)
		if a.outcome == "synthesis":
			synth += 1
			check(a.lens.both_enough() and a.balance_streak >= DialecticSim.BALANCE_HOLD, "L5.3 synthesis only with both conditions (seed %d)" % s)
		beats += a.beat
		var prev_o := 0.0
		var focus_count := 0
		for t in a.trace:
			check(t.energy <= Lens.ENERGY_CAP, "energy within cap")
			if t.lens != "":
				focus_count += 1
				check(t.o == prev_o, "L4.4 no opinion pressure on a focus beat (seed %d beat %d)" % [s, t.beat])
			prev_o = t.o
		check(focus_count == a.lens.disclosed("system") + a.lens.disclosed("persona"), "every focus logged once (seed %d)" % s)
		check(a.events.any(func(e: String) -> bool: return e.contains("lens=")) == (focus_count > 0), "L8.1 focus in hashed log")
		# no focus ever (grip never in band) => identical to the engine-only game; any focus => different log
		check((a.log_hash() == DialecticSim.new(s).run().hash) == (focus_count == 0), "Lens layer is a no-op without focus (seed %d)" % s)
	print("Lens all-AI over 50 seeds: synthesis %d/50, avg beats %.1f (engine-only baseline 36/50, 19.8)" % [synth, beats / 50.0])


## Mirrors main.gd: human Audience picks pressure + lens; human Persona/System; AUTO-FINISH after `human_beats`.
func play(seed_value: int, era: String, role: String, human_beats: int, pick: RandomNumberGenerator) -> LensSim:
	var sim := LensSim.new(seed_value, 60, Eras.get_era(era).commands)
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
				sim.begin_beat(pick.randi_range(0, 3))
				sim.finish_beat()
	return sim


func replay_sd2() -> void:
	var pick := RandomNumberGenerator.new()
	pick.seed = 7
	var n := 0
	var with_focus := 0
	for era in Eras.ORDER:
		for role in ["audience", "persona", "system"]:
			for s in range(1, 13):
				var hb: int = [999, 0, 4, pick.randi_range(1, 25)][s % 4]
				var sim := play(s * 104729, era, role, hb, pick)
				var code := ReplayCode.encode(sim, era, role)
				var r := ReplayCode.decode(code)
				check(code.begins_with("SD2.") and r.ok and r.hash == sim.log_hash(), "SD2 round-trip %s %s seed %d hb %d" % [era, role, s, hb])
				if role == "audience" and Array(code.split(".")[5].split("")).any(func(c: String) -> bool: return c in "OUCABP"):
					with_focus += 1
				n += 1
	print("SD2 round-trips: %d (%d with human lens focus in the code)" % [n, with_focus])


func _init() -> void:
	lens_rules()
	lens_sim()
	replay_sd2()
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
