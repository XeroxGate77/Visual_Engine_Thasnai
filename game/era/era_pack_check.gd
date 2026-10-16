class_name EraPackCheck
extends RefCounted
## Playability + balance REPORT for an era deck: runs AI-only games on the current rules (NodeSimV4, NODE-RULES v0.4)
## and compares with the three built-in eras. It never rejects a pack for balance — it gives numbers and warnings;
## balance and taste are the owner's call. Only determinism is a hard check (same seed must give the same run).

const RULES := "NODE-RULES v0.4"


## {deterministic, n, synthesis_rate, mean_beats, responses{obey,negotiate,defy}, picks[], types{}, rarity{}}
static func measure(era: Dictionary, n := 300) -> Dictionary:
	var out := {"n": n, "synth": 0, "beats": 0, "responses": {"obey": 0, "negotiate": 0, "defy": 0},
		"picks": [], "types": {}, "rarity": {}}
	for i in era.commands.size():
		out.picks.append(0)
	for s in range(1, n + 1):
		var sim := NodeSimV4.new(s * 7919, 60, era.commands)
		sim.run()
		out.beats += sim.beat
		for t in sim.trace:
			out.responses[t.response] += 1
			out.picks[t.idx] += 1
		if sim.outcome == "synthesis":
			out.synth += 1
			out.types[sim.synthesis_type] = out.types.get(sim.synthesis_type, 0) + 1
			var tier: String = Rarity.of(sim).tier
			out.rarity[tier] = out.rarity.get(tier, 0) + 1
	var a := NodeSimV4.new(4242, 60, era.commands)
	var b := NodeSimV4.new(4242, 60, era.commands)
	a.run()
	b.run()
	out.deterministic = a.log_hash() == b.log_hash()
	out.synthesis_rate = float(out.synth) / n
	out.mean_beats = float(out.beats) / n
	return out


## Full report: the pack's numbers, the built-in reference range, and warnings for the owner.
static func report(era: Dictionary, n := 300) -> Dictionary:
	var m := measure(era, n)
	var ref := {"rate_min": 1.0, "rate_max": 0.0, "beats_min": 999.0, "beats_max": 0.0}
	for id in Eras.ORDER:
		var r := measure(Eras.get_era(id), n)
		ref.rate_min = minf(ref.rate_min, r.synthesis_rate)
		ref.rate_max = maxf(ref.rate_max, r.synthesis_rate)
		ref.beats_min = minf(ref.beats_min, r.mean_beats)
		ref.beats_max = maxf(ref.beats_max, r.mean_beats)
	var warn: Array[String] = []
	if m.synthesis_rate < ref.rate_min - 0.10 or m.synthesis_rate > ref.rate_max + 0.10:
		warn.append("synthesis rate %.0f%% is far from the built-in eras (%.0f–%.0f%%)" % [m.synthesis_rate * 100, ref.rate_min * 100, ref.rate_max * 100])
	if m.mean_beats < ref.beats_min - 3.0 or m.mean_beats > ref.beats_max + 3.0:
		warn.append("games last %.1f beats on average; built-in eras %.1f–%.1f" % [m.mean_beats, ref.beats_min, ref.beats_max])
	var total := 0
	for p in m.picks:
		total += p
	for i in m.picks.size():
		var share := float(m.picks[i]) / maxi(total, 1)
		if m.picks[i] == 0:
			warn.append("command %d \"%s\" is never chosen by the AI System (dead card)" % [i, era.commands[i].name])
		elif share > 0.70:
			warn.append("command %d \"%s\" takes %.0f%% of all orders (one card dominates)" % [i, era.commands[i].name, share * 100])
	var low_control := false
	for c in era.commands:
		low_control = low_control or c.control <= 0.3
	if not low_control:
		warn.append("no command with control <= 0.3 — the Node has no soft order to restrict to, so it can only invite")
	return {"rules": RULES, "measure": m, "reference": ref, "warnings": warn}


static func format(id: String, rep: Dictionary) -> String:
	var m: Dictionary = rep.measure
	var ref: Dictionary = rep.reference
	var lines := PackedStringArray()
	lines.append("ERA PACK REPORT — %s · %s · %d AI-only games" % [id, rep.rules, m.n])
	lines.append("deterministic: %s" % ("yes" if m.deterministic else "NO — rejected"))
	lines.append("synthesis: %.1f%%  (built-in eras %.1f–%.1f%%)" % [m.synthesis_rate * 100, ref.rate_min * 100, ref.rate_max * 100])
	lines.append("mean beats: %.1f  (built-in %.1f–%.1f)" % [m.mean_beats, ref.beats_min, ref.beats_max])
	lines.append("persona responses: obey %d · negotiate %d · defy %d" % [m.responses.obey, m.responses.negotiate, m.responses.defy])
	lines.append("system picks per command: %s" % str(m.picks))
	lines.append("synthesis types: %s · rarity: %s" % [str(m.types), str(m.rarity)])
	if rep.warnings.is_empty():
		lines.append("warnings: none")
	for w in rep.warnings:
		lines.append("WARNING (owner decides): " + w)
	return "\n".join(lines)
