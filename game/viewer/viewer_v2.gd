extends "res://viewer/viewer.gd"
## VIEWER v2 — viewer.gd (locked, untouched) + ERA PACKS: also rebuilds SD7 codes (games played on an era pack).
## The pack must be in this build (res://era_packs/, top level) with the same content hash the code names;
## otherwise the code is refused, never rebuilt on a different deck. SD1–SD6 behave exactly as in viewer.gd.

var era_dirs: Array = ["res://era_packs"] # packs shipped with this build; tests may point this elsewhere
var eras: EraRegistry


func _ready() -> void:
	eras = EraRegistry.scan(era_dirs)
	super._ready()
	input.placeholder_text = "paste a replay code (SD1… – SD7…)"


func show_code(code: String) -> Dictionary:
	current = ReplayCodePack.decode(code, eras)
	if not current.ok:
		title.text = "NOT AN AUTHENTIC PIECE"
		verdict.text = "This code does not rebuild a game whose log matches it (%s)." % current.reason
		verdict.add_theme_color_override("font_color", C_RUST)
		body.text = ""
		art.trace = []
		art.synthesis = false
		art.queue_redraw()
		return current
	var sim: DialecticSim = current.sim
	var era: Dictionary = eras.get_era(current.era)
	title.text = "SUBJUGATED DIALECTICS — %s" % era.title
	var rules := "engine only"
	if sim is NodeSim:
		rules = "Node %s + Lens %s" % [(sim as NodeSimV2).rules_version() if sim is NodeSimV2 else NodeSim.RULES_VERSION, Lens.RULES_VERSION]
	elif sim is LensSim:
		rules = "Lens " + Lens.RULES_VERSION
	if eras.is_pack(current.era):
		rules += " · era pack %s (%s)" % [current.era, eras.hashes[current.era].left(8)]
	verdict.text = "AUTHENTIC — rebuilt from its code; log hash %s matches.\nRules: %s · played as %s · %s after %d beats" % [
		current.hash.left(16) + "…", rules, current.role.to_upper(), sim.outcome.replace("_", " ").to_upper(), sim.beat]
	verdict.text += "\n" + signature_status(_public_pem(), registry, current.hash)
	var rar := Rarity.of(sim)
	if rar.tier != "":
		verdict.text += "\nRARITY %s: %s%s (computed from the rebuilt piece)" % [Rarity.VERSION, rar.tier, (" · " + rar.reason) if rar.reason != "" else ""]
	verdict.add_theme_color_override("font_color", C_AMBER)
	var parts: Array[String] = []
	var ins := EraText.insight(sim, current.era, era)
	parts.append(ins.text)
	parts.append(ins.dilemma)
	if sim is NodeSim:
		parts.append(GenderReading.build(sim as NodeSim))
	if sim is NodeSimV4:
		parts.append("MICRO-NODES\n" + (sim as NodeSimV4).micro.to_text())
	body.text = "\n\n".join(parts)
	art.trace = sim.trace
	art.synthesis = sim.outcome == "synthesis"
	art.reveal = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		art.reveal = v
		art.queue_redraw(), 0.0, 1.0, REVEAL_SEC)
	return current
