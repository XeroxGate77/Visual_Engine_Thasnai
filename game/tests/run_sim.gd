extends SceneTree
## Headless: godot --headless --path game -s tests/run_sim.gd
## Checks: same seed twice => same log hash; reports outcome spread over seeds 1..SEEDS.

const Sim := preload("res://sim/dialectic_sim.gd")
const SEEDS := 50

func _init() -> void:
	var failures := 0
	var tally := {"synthesis": 0, "no_synthesis": 0}
	var beats_total := 0
	var hashes := {}
	for s in range(1, SEEDS + 1):
		var a: Dictionary = Sim.new(s).run()
		var b: Dictionary = Sim.new(s).run()
		if a.hash != b.hash:
			failures += 1
			print("NONDETERMINISTIC seed=", s)
		tally[a.outcome] += 1
		beats_total += a.beats
		hashes[a.hash] = true
	if hashes.size() < SEEDS * 0.9:
		failures += 1
		print("LOW VARIETY: ", hashes.size(), " distinct logs of ", SEEDS)
	print("seeds=", SEEDS, " tally=", tally, " avg_beats=", snappedf(float(beats_total) / SEEDS, 0.1), " distinct_logs=", hashes.size())
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
