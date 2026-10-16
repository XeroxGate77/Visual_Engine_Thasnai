extends SceneTree
## Offline: scripted image prompt is deterministic, era-specific and outcome-aware.
## godot --headless --path game -s tests/image_prompt_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	print("ok   " if cond else "FAIL ", label)


func run(seed_value: int, era: String) -> DialecticSim:
	var s := DialecticSim.new(seed_value, 60, Eras.get_era(era).commands)
	s.run()
	return s


func _init() -> void:
	var a := ImagePrompt.build(run(3, "industrial"), "industrial")
	var b := ImagePrompt.build(run(3, "industrial"), "industrial")
	check(a == b, "same seed + era -> same prompt")
	check(a.contains("foundry"), "industrial scene")
	check(ImagePrompt.build(run(3, "prehistoric"), "prehistoric").contains("cave"), "prehistoric scene")
	check(ImagePrompt.build(run(3, "posttruth"), "posttruth").contains("feeds"), "post-truth scene")
	check(a.contains("no text"), "asks for no text")
	var synth := false
	var nosynth := false
	for s in range(1, 40):
		var sim := run(s, "industrial")
		var p := ImagePrompt.build(sim, "industrial")
		if sim.outcome == "synthesis":
			synth = synth or p.contains("balance")
		else:
			nosynth = nosynth or p.contains("fracture")
	check(synth and nosynth, "outcome changes ending line")
	check(a.length() < 600, "prompt is paste-sized (%d chars)" % a.length())
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
