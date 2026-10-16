class_name NodeSim
extends LensSim
## NODE-RULES v0.1 (owner-approved 2026-10-15) as a new layer over LensSim. Engine and Lens files are not edited.
## Part A: after each beat the Node reads grip, forecasts the next beat, and (if the forecast crosses the
## warning line) sets ONE condition for the next beat: restrict the System's orders (N3), or — when no
## order can help — invite the Persona to negotiate (N4). Part G: counts registers to extract gender-ness.

const RULES_VERSION := "v0.1"
const WARN := 0.5 # N2
const HIGH_CONTROL := 0.5 # G2: an order with control >= this counts in the Command register

var warn := WARN # overridable for tests (a huge value = Node never acts)
var cond_kind := "" # condition in force for the NEXT/current beat: "" | "sys" | "invite"
var allowed: Array[int] = [] # N3: orders the System may give while cond_kind == "sys"
var cond_history := {} # beat -> "sys" | "invite" (conditions actually in force that beat)
var synthesis_type := "" # N6: "contract" | "care" | "emergent" (only when outcome == synthesis)
## G2 registers. overall = whole game; engine = System + Persona actions; node = the Node's own acts
var registers := {"command": 0, "care": 0, "resistance": 0}
var engine_registers := {"command": 0, "care": 0, "resistance": 0}
var node_registers := {"command": 0, "care": 0}


func _init(seed_value: int, max_beats_value: int = 60, commands_value: Array = COMMANDS) -> void:
	super(seed_value, max_beats_value, commands_value)


## N3 for a human System: an order outside the allowed set is replaced by the first allowed one
## (the UI locks those buttons, so this only guards against misuse).
func begin_beat(idx: int = -1) -> Dictionary:
	if cond_kind == "sys" and idx >= 0 and not (idx in allowed):
		idx = allowed[0]
	return super.begin_beat(idx)


func finish_beat(response: String = "") -> void:
	var before := dominance
	var kind := cond_kind
	super.finish_beat(response)
	var t: Dictionary = trace[trace.size() - 1]
	# N7: record the condition that was in force this beat (part of log_hash)
	var ev := ""
	if kind == "sys":
		ev = "node=sys:" + ",".join(allowed.map(func(i: int) -> String: return str(i)))
	elif kind == "invite":
		ev = "node=invite:" + ("accepted" if t.response == NEGOTIATE else "refused")
	if ev != "":
		events[events.size() - 1] += "|" + ev
		cond_history[beat] = kind
	t["node"] = ev
	_count_registers(t, kind)
	# N6
	if ended and outcome == "synthesis":
		synthesis_type = "emergent"
		for b in range(beat, beat - DialecticSim.BALANCE_HOLD, -1):
			if cond_history.has(b):
				synthesis_type = "care" if cond_history[b] == "invite" else "contract"
				break
	# N1/N2: forecast and set the condition for the next beat
	cond_kind = ""
	allowed = []
	if ended:
		return
	var forecast := dominance + (dominance - before)
	if absf(forecast) >= warn:
		for i in commands.size():
			if absf(expected_grip(commands[i])) < absf(dominance):
				allowed.append(i)
		cond_kind = "sys" if not allowed.is_empty() else "invite" # N3, else N4


## The Node's expectation of grip after an order (Persona utilities without noise; v0.1 Node knows everything).
func expected_grip(c: Dictionary) -> float:
	var u_obey: float = persona.belonging * 0.4 - persona.autonomy * c.cost
	var u_neg: float = 0.1 - 0.3 * persona.autonomy * c.cost + opinion * 0.1
	var u_defy: float = persona.autonomy * c.cost - c.control * 0.5 + opinion * 0.3 - 0.2 * persona.belonging
	var d := dominance
	if u_obey >= u_neg and u_obey >= u_defy:
		d += 0.12 * (0.5 + c.cost)
	elif u_neg >= u_defy:
		d += -d * 0.25
	else:
		d -= 0.15
	return clampf(d - 0.06 * opinion, -1.0, 1.0)


## N3 for the scripted System: same scoring as LensSim (incl. L6.2), restricted to allowed orders.
func _ai_system_pick() -> int:
	if cond_kind != "sys":
		return super._ai_system_pick()
	var autonomy_clear := lens.level("persona", "autonomy") == Lens.CLEAR
	var best := allowed[0]
	var best_score := -INF
	for i in commands.size():
		var c: Dictionary = commands[i]
		var score: float = system_obj.order * c.order + system_obj.output * c.output + system_obj.control * c.control
		score -= opinion * c.control * 0.8
		if dominance < 0.0:
			score += -dominance * c.control * 0.5
		if autonomy_clear:
			score -= persona.autonomy * c.cost * 0.5
		score += rng.randf_range(-0.1, 0.1)
		if i in allowed and score > best_score:
			best_score = score
			best = i
	return best


## N4: the scripted Persona accepts the Node's invitation.
func _ai_persona_pick(cmd: Dictionary) -> String:
	if cond_kind == "invite":
		return NEGOTIATE
	return super._ai_persona_pick(cmd)


## G2 (all items weigh 1 in v0.1).
func _count_registers(t: Dictionary, kind: String) -> void:
	var c: Dictionary = commands[t.idx]
	match t.response:
		OBEY:
			_add("command", true)
		NEGOTIATE:
			_add("care", true)
		DEFY:
			_add("resistance", true)
	if c.control >= HIGH_CONTROL:
		_add("command", true)
	if t.get("lens", "") != "":
		registers.care += 1 # the Audience's Lens: care, but not an Engine act
	if kind == "sys":
		registers.command += 1
		node_registers.command += 1
	elif kind == "invite":
		node_registers.care += 1
		if t.response == NEGOTIATE:
			registers.care += 1
		else:
			registers.resistance += 1


func _add(reg: String, engine_act: bool) -> void:
	registers[reg] += 1
	if engine_act:
		engine_registers[reg] += 1


static func share(reg: Dictionary) -> Dictionary:
	var total := 0
	for k in reg:
		total += reg[k]
	var out := {}
	for k in reg:
		out[k] = 0 if total == 0 else roundi(100.0 * reg[k] / total)
	return out
