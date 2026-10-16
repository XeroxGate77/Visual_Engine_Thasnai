class_name ReplayCode
extends RefCounted
## Compact "recipe" of one finished game: seed + era + role + the human inputs.
## Replaying it through the (unchanged) engine reproduces the exact log, so the log hash proves authenticity.
## Format: SD1.<era>.<role>.<seed>.<k>.<inputs>.<hash12>   (engine only, DialecticSim)
##         SD2.<...same...>                                   (Lens layer, LensSim — LENS-RULES v0.1)
##         SD3.<...same as SD2...>                            (Node layer, NodeSim — NODE-RULES v0.1)
##         SD4.<...same as SD2...>                            (Node layer, NodeSimV2 — NODE-RULES v0.2)
##         SD5.<...same as SD2...>                            (Node layer, NodeSimV3 — NODE-RULES v0.3, grid band)
##         SD6.<...same as SD2...>                            (Node layer, NodeSimV4 — NODE-RULES v0.4, micro-nodes)
##   role: a / p / s · inputs: one char per beat (audience l z r · persona o n d · system 0-3)
##   SD2 audience: two chars per beat — pressure, then lens focus (O U C / A B P, or - for none).
##   SD2 persona/system: as SD1 (the Audience is scripted, so its Lens is rebuilt from the seed).
##   k: beats driven by the human; after k the scripted AI played (AUTO-FINISH). Derived, not recorded.
##   Canonical form (2026-10-15): Persona/System codes carry exactly k input chars. Older codes with extra trailing
##   inputs still decode (the extras were always ignored); canonical() rewrites any valid code to the canonical one.
## Built only from the sim's own trace — no change to the engine or to main.gd's game flow.

const PREFIX := "SD1"
const PREFIX_LENS := "SD2"
const PREFIX_NODE := "SD3"
const PREFIX_NODE_V2 := "SD4"
const PREFIX_NODE_V3 := "SD5"
const PREFIX_NODE_V4 := "SD6"
const ROLE_CH := {"audience": "a", "persona": "p", "system": "s"}
const RESP_CH := {"obey": "o", "negotiate": "n", "defy": "d"}
const PRESSURE := {"l": -0.2, "z": 0.0, "r": 0.2} # same values main.gd's audience buttons use


## Returns "" if no replay reproduces the game (should not happen; tested).
static func encode(sim: DialecticSim, era_id: String, role: String) -> String:
	var lens_game := sim is LensSim
	var inputs := _derive_inputs(sim, role, lens_game)
	if inputs == "":
		return ""
	var n := sim.trace.size()
	var tries: Array = [n] if role == "audience" else range(n, -1, -1)
	for k in tries:
		var prefix := PREFIX_NODE_V4 if sim is NodeSimV4 else PREFIX_NODE_V3 if sim is NodeSimV3 else PREFIX_NODE_V2 if sim is NodeSimV2 else PREFIX_NODE if sim is NodeSim else (PREFIX_LENS if lens_game else PREFIX)
		# canonical: Persona/System inputs after k are never read, so they are cut off (one piece = one code string)
		var used := inputs if role == "audience" else inputs.left(k)
		var code := "%s.%s.%s.%d.%d.%s.%s" % [prefix, era_id, ROLE_CH[role], sim.rng.seed, k, used, sim.log_hash().left(12)]
		var r := decode(code)
		if r.ok:
			return code
	return ""


## The single canonical code for whatever piece `code` rebuilds ("" if it is not authentic).
static func canonical(code: String) -> String:
	var r := decode(code)
	return encode(r.sim, r.era, r.role) if r.ok else ""


## {ok, sim, era, role, hash} — sim is a freshly replayed, finished DialecticSim.
static func decode(code: String) -> Dictionary:
	var p := code.strip_edges().split(".")
	if p.size() != 7 or not (p[0] in [PREFIX, PREFIX_LENS, PREFIX_NODE, PREFIX_NODE_V2, PREFIX_NODE_V3, PREFIX_NODE_V4]) or not Eras.DATA.has(p[1]) or not (p[2] in ["a", "p", "s"]) \
			or not p[3].is_valid_int() or not p[4].is_valid_int():
		return {"ok": false, "reason": "malformed code"}
	var era := p[1]
	var role: String = {"a": "audience", "p": "persona", "s": "system"}[p[2]]
	var k := int(p[4])
	var inputs := p[5]
	var lens_game: bool = p[0] != PREFIX # SD2, SD3 and SD4 all carry the Lens
	var cmds: Array = Eras.get_era(era).commands
	var sim: DialecticSim
	match p[0]:
		PREFIX_NODE_V4: sim = NodeSimV4.new(int(p[3]), 60, cmds)
		PREFIX_NODE_V3: sim = NodeSimV3.new(int(p[3]), 60, cmds)
		PREFIX_NODE_V2: sim = NodeSimV2.new(int(p[3]), 60, cmds)
		PREFIX_NODE: sim = NodeSim.new(int(p[3]), 60, cmds)
		PREFIX_LENS: sim = LensSim.new(int(p[3]), 60, cmds)
		_: sim = DialecticSim.new(int(p[3]), 60, cmds)
	match role:
		"audience" when lens_game:
			sim.audience_chooser = func(s: DialecticSim) -> float:
				var i := 2 * (s.beat - 1)
				return PRESSURE.get(inputs[i], 0.0) if i >= 0 and i < inputs.length() else 0.0
			(sim as LensSim).lens_chooser = func(s: DialecticSim) -> Array:
				var i := 2 * s.beat + 1 # called before the beat counter advances
				return Lens.from_code(inputs[i]) if i < inputs.length() else []
		"audience":
			sim.audience_chooser = func(s: DialecticSim) -> float:
				var i := mini(s.beat - 1, inputs.length() - 1)
				return PRESSURE.get(inputs[i], 0.0) if i >= 0 else 0.0
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
	return {"ok": true, "sim": sim, "era": era, "role": role, "hash": sim.log_hash()}


static func _derive_inputs(sim: DialecticSim, role: String, lens_game := false) -> String:
	var out := ""
	var prev_o := 0.0
	for t in sim.trace:
		match role:
			"persona":
				out += RESP_CH[t.response]
			"system":
				out += str(t.idx)
			"audience":
				var found := ""
				for ch in ["z", "r", "l"]: # any delta that reproduces the clamped opinion is equivalent
					if clampf(prev_o + PRESSURE[ch], -1.0, 1.0) == t.o:
						found = ch
						break
				if found == "":
					return ""
				out += found
				if lens_game:
					var ev: String = t.get("lens", "")
					var bits := ev.trim_prefix("lens=").split(":")
					out += Lens.code_of(bits[0], bits[1]) if bits.size() == 3 else "-"
		prev_o = t.o
	return out
