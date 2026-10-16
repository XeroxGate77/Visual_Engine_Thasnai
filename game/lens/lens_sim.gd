class_name LensSim
extends DialecticSim
## New layer over the locked engine (dialectic_sim.gd is not edited): applies LENS-RULES v0.1.
## - Audience focuses the Lens at the start of a beat (L4); a focus beat carries no opinion pressure (L4.4).
## - Lens energy comes from the Node's own limits (L3).
## - Node becomes a dual condition: grip held AND disclosure enough (L5.3).
## - Knowing changes scripted AI behaviour only (L6). Focus events go into the hashed log (L8.1).

var lens := Lens.new()
## Human Audience: (sim) -> [target, fragment] or []. Invalid = scripted Audience policy (L7.1).
var lens_chooser := Callable()
var _lens_event := ""


func _init(seed_value: int, max_beats_value: int = 60, commands_value: Array = COMMANDS) -> void:
	super(seed_value, max_beats_value, commands_value)


func begin_beat(idx: int = -1) -> Dictionary:
	_lens_event = ""
	var pick: Array = lens_chooser.call(self) if lens_chooser.is_valid() else ai_lens_pick()
	if pick.size() == 2 and lens.focus(pick[0], pick[1]): # L4.1 · one call per beat = L4.2
		_lens_event = "lens=%s:%s:%d" % [pick[0], pick[1], lens.level(pick[0], pick[1])]
		var saved := audience_chooser
		audience_chooser = func(_s: DialecticSim) -> float: return 0.0 # L4.4
		var cmd := super.begin_beat(idx)
		audience_chooser = saved
		return cmd
	return super.begin_beat(idx)


func finish_beat(response: String = "") -> void:
	super.finish_beat(response)
	lens.end_beat(dominance) # L3
	if _lens_event != "":
		events[events.size() - 1] += "|" + _lens_event # L8.1 — part of log_hash()
	trace[trace.size() - 1]["lens"] = _lens_event
	trace[trace.size() - 1]["energy"] = lens.energy
	if ended and outcome == "synthesis" and not lens.both_enough(): # L5.3
		if beat >= max_beats:
			outcome = "no_synthesis"
		else:
			ended = false
			outcome = ""


## L7.1: scripted Audience — look into the less-disclosed pole, first hidden fragment, else first blurred.
func ai_lens_pick() -> Array:
	if lens.energy < 1:
		return []
	var order := ["system", "persona"] if lens.disclosed("system") <= lens.disclosed("persona") else ["persona", "system"]
	for target in order:
		for want in [Lens.HIDDEN, Lens.BLUR]:
			for f in Lens.FRAGMENTS[target]:
				if lens.level(target, f) == want:
					return [target, f]
	return []


## L6.1: Persona sees the System's CONTROL clearly -> less guesswork when weighing defiance (noise 0.05 -> 0.01).
func _ai_persona_pick(cmd: Dictionary) -> String:
	if lens.level("system", "control") < Lens.CLEAR:
		return super._ai_persona_pick(cmd)
	var u_obey: float = persona.belonging * 0.4 - persona.autonomy * cmd.cost
	var u_neg: float = 0.1 - 0.3 * persona.autonomy * cmd.cost + opinion * 0.1
	var u_defy: float = persona.autonomy * cmd.cost - cmd.control * 0.5 + opinion * 0.3 - 0.2 * persona.belonging
	u_obey += rng.randf_range(-0.01, 0.01)
	u_neg += rng.randf_range(-0.01, 0.01)
	u_defy += rng.randf_range(-0.01, 0.01)
	if u_obey >= u_neg and u_obey >= u_defy:
		return OBEY
	if u_neg >= u_defy:
		return NEGOTIATE
	return DEFY


## L6.2: System sees the Persona's AUTONOMY clearly -> prefers commands the Persona can accept.
func _ai_system_pick() -> int:
	if lens.level("persona", "autonomy") < Lens.CLEAR:
		return super._ai_system_pick()
	var best := 0
	var best_score := -INF
	for i in commands.size():
		var c: Dictionary = commands[i]
		var score: float = system_obj.order * c.order + system_obj.output * c.output + system_obj.control * c.control
		score -= opinion * c.control * 0.8
		if dominance < 0.0:
			score += -dominance * c.control * 0.5
		score -= persona.autonomy * c.cost * 0.5 # L6.2
		score += rng.randf_range(-0.1, 0.1)
		if score > best_score:
			best_score = score
			best = i
	return best
