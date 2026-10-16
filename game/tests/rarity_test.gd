extends SceneTree
## Offline: Rarity R1.0 — deterministic, rebuild-verifiable, and its distribution over 3000 all-AI runs.
## godot --headless --path game -s tests/rarity_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	if not cond:
		print("FAIL ", label)


func _init() -> void:
	var dist := {"MYTHIC": 0, "RARE": 0, "UNCOMMON": 0, "COMMON": 0}
	var synth := 0
	var mythic_seed := -1
	for era in Eras.ORDER:
		for s in range(1, 1001):
			var seed_v: int = s * 31 + era.length()
			var sim := NodeSimV4.new(seed_v, 60, Eras.get_era(era).commands)
			sim.run()
			var r := Rarity.of(sim)
			if sim.outcome != "synthesis":
				check(r.tier == "", "no tier without synthesis")
				continue
			synth += 1
			dist[r.tier] += 1
			if r.tier == "MYTHIC":
				mythic_seed = seed_v
			if s % 50 == 0: # rebuilt from its replay code -> same tier
				var d := ReplayCode.decode(ReplayCode.encode(sim, era, "persona"))
				check(d.ok and Rarity.of(d.sim).tier == r.tier, "tier survives rebuild (%s seed %d)" % [era, seed_v])
	var line := ""
	for t in Rarity.ORDER:
		line += "%s %d (%.1f%%)  " % [t, dist[t], 100.0 * dist[t] / synth]
	print("R1.0 over %d syntheses: %s" % [synth, line])
	check(dist.MYTHIC < dist.RARE and dist.RARE < dist.UNCOMMON and dist.UNCOMMON < dist.COMMON, "pyramid: MYTHIC < RARE < UNCOMMON < COMMON")
	check(dist.MYTHIC >= 1, "MYTHIC is possible (seed %d)" % mythic_seed)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
