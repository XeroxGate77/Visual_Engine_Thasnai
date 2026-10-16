class_name ReplayCodePack
extends RefCounted
## Replay codes for games played on an ERA PACK — beside the locked ReplayCode (SD1–SD6 unchanged).
##   SD7.<id>~<packhash8>.<role>.<seed>.<k>.<inputs>.<hash12>     (NodeSimV4 — NODE-RULES v0.4 — on an era pack)
## The pack hash pins the exact deck: a piece rebuilds only with the same pack content, so changing a pack can never
## silently change an old piece. Built-in eras keep SD6 codes (ReplayCode). Inputs / k / roles: same as SD6.

const PREFIX := "SD7"


static func encode(sim: DialecticSim, era_id: String, role: String, reg: EraRegistry) -> String:
	if not reg.is_pack(era_id):
		return ReplayCode.encode(sim, era_id, role)
	if not sim is NodeSimV4:
		return ""
	var inputs := ReplayCode._derive_inputs(sim, role, true)
	if inputs == "":
		return ""
	var n := sim.trace.size()
	var tries: Array = [n] if role == "audience" else range(n, -1, -1)
	for k in tries:
		var used := inputs if role == "audience" else inputs.left(k) # canonical, as SD6
		var code := "%s.%s~%s.%s.%d.%d.%s.%s" % [PREFIX, era_id, reg.hashes[era_id].left(8), ReplayCode.ROLE_CH[role],
			sim.rng.seed, k, used, sim.log_hash().left(12)]
		if decode(code, reg).ok:
			return code
	return ""


static func canonical(code: String, reg: EraRegistry) -> String:
	var r := decode(code, reg)
	return encode(r.sim, r.era, r.role, reg) if r.ok else ""


## {ok, sim, era, role, hash} like ReplayCode.decode; SD1–SD6 are passed to ReplayCode unchanged.
static func decode(code: String, reg: EraRegistry) -> Dictionary:
	var p := code.strip_edges().split(".")
	if p.size() == 0 or p[0] != PREFIX:
		return ReplayCode.decode(code)
	if p.size() != 7 or not (p[2] in ["a", "p", "s"]) or not p[3].is_valid_int() or not p[4].is_valid_int() or p[1].count("~") != 1:
		return {"ok": false, "reason": "malformed code"}
	var era := p[1].get_slice("~", 0)
	var pack_h := p[1].get_slice("~", 1)
	if not reg.is_pack(era):
		return {"ok": false, "reason": "era pack \"%s\" is not installed here" % era}
	if pack_h.length() != 8 or not reg.hashes[era].begins_with(pack_h):
		return {"ok": false, "reason": "era pack \"%s\" here is not the one this piece was made with" % era}
	var role: String = {"a": "audience", "p": "persona", "s": "system"}[p[2]]
	var k := int(p[4])
	var inputs := p[5]
	var sim := NodeSimV4.new(int(p[3]), 60, reg.get_era(era).commands)
	match role: # same readers as ReplayCode.decode for a Lens game (SD2–SD6)
		"audience":
			sim.audience_chooser = func(s: DialecticSim) -> float:
				var i := 2 * (s.beat - 1)
				return ReplayCode.PRESSURE.get(inputs[i], 0.0) if i >= 0 and i < inputs.length() else 0.0
			sim.lens_chooser = func(s: DialecticSim) -> Array:
				var i := 2 * s.beat + 1
				return Lens.from_code(inputs[i]) if i < inputs.length() else []
		"persona":
			sim.persona_chooser = func(s: DialecticSim, cmd: Dictionary) -> String:
				if s.beat <= k and s.beat <= inputs.length():
					return {"o": "obey", "n": "negotiate", "d": "defy"}.get(inputs[s.beat - 1], "obey")
				return s._ai_persona_pick(cmd)
		"system":
			sim.system_chooser = func(s: DialecticSim) -> int:
				if s.beat <= k and s.beat <= inputs.length():
					return clampi(int(inputs[s.beat - 1]), 0, s.commands.size() - 1)
				return s._ai_system_pick()
	sim.run()
	if not sim.log_hash().begins_with(p[6]):
		return {"ok": false, "reason": "hash mismatch"}
	return {"ok": true, "sim": sim, "era": era, "role": role, "hash": sim.log_hash(), "pack_hash": reg.hashes[era]}
