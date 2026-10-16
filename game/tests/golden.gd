extends SceneTree
## Regression: combined hash of default-sim logs for seeds 1..50.
## godot --headless --path game -s tests/golden.gd            -> prints GOLDEN <hash>
## Compared against tests/golden.txt (captured before the era/UI change).

const Sim := preload("res://sim/dialectic_sim.gd")

func _init() -> void:
	var parts: Array[String] = []
	for s in range(1, 51):
		parts.append(Sim.new(s).run().hash)
	var combined := "\n".join(parts).sha256_text()
	print("GOLDEN ", combined)
	var f := FileAccess.open("res://tests/golden.txt", FileAccess.READ)
	if f == null:
		print("RESULT: NO GOLDEN FILE")
		quit(2)
		return
	var expected := f.get_as_text().strip_edges()
	print("RESULT: ", "PASS" if expected == combined else "FAIL (expected %s)" % expected)
	quit(0 if expected == combined else 1)
