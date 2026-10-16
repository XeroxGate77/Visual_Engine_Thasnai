class_name Insight
extends RefCounted
## Scripted (offline) Insight built from a finished sim's trace. This is the fallback path;
## the Claude API version (later) would replace build() output with richer text + art spec.

static func build(sim: DialecticSim, era_id: String) -> Dictionary:
	var era := Eras.get_era(era_id)
	var n := sim.trace.size()
	var sys_lead := 0
	var defied := {}
	var obeyed := {}
	for t in sim.trace:
		if t.d > 0.0:
			sys_lead += 1
		if t.response == DialecticSim.DEFY:
			defied[t.cmd] = defied.get(t.cmd, 0) + 1
		elif t.response == DialecticSim.OBEY:
			obeyed[t.cmd] = obeyed.get(t.cmd, 0) + 1
	var most_defied := _top(defied)
	var most_obeyed := _top(obeyed)
	var lines: Array[String] = []
	if sim.outcome == "synthesis":
		lines.append("VERDICT: SYNTHESIS at beat %d. The Node held for %d beats." % [sim.beat, DialecticSim.BALANCE_HOLD])
	else:
		lines.append("VERDICT: NO SYNTHESIS after %d beats. The dilemma outlasted the dialectic." % sim.beat)
	lines.append("System led %d of %d beats; Persona led %d." % [sys_lead, n, n - sys_lead])
	lines.append("Obeyed %d / negotiated %d / defied %d." % [sim.counts.obey, sim.counts.negotiate, sim.counts.defy])
	lines.append("Most defied: %s." % (most_defied if most_defied != "" else "nothing"))
	lines.append("Most obeyed: %s." % (most_obeyed if most_obeyed != "" else "nothing"))
	lines.append("")
	lines.append(era.closing[sim.outcome])
	var dilemma := "OUTPUT DILEMMA: if \"%s\" is the price of order, who is it paid by, and who decides it is fair?" % (most_defied if most_defied != "" else most_obeyed)
	return {"text": "\n".join(lines), "dilemma": dilemma}


static func _top(counts: Dictionary) -> String:
	var best := ""
	var best_n := 0
	var keys := counts.keys()
	keys.sort() # stable tie-break
	for k in keys:
		if counts[k] > best_n:
			best_n = counts[k]
			best = k
	return best
