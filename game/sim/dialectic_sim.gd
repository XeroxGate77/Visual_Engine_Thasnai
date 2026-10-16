class_name DialecticSim
extends RefCounted
## Seeded command–response simulation (mechanic A).
## System issues a command, Persona obeys / negotiates / defies, Audience pushes opinion.
## Ends when dominance sits near zero (the balance Node) for BALANCE_HOLD beats.
## Same seed + same choosers => identical event log.

const OBEY := "obey"
const NEGOTIATE := "negotiate"
const DEFY := "defy"

const BALANCE_BAND := 0.15
const BALANCE_HOLD := 4

const COMMANDS := [
	{"name": "quota", "order": 0.3, "output": 0.9, "control": 0.3, "cost": 0.5},
	{"name": "curfew", "order": 0.9, "output": 0.1, "control": 0.5, "cost": 0.6},
	{"name": "surveil", "order": 0.5, "output": 0.2, "control": 0.9, "cost": 0.8},
	{"name": "reward", "order": 0.2, "output": 0.4, "control": 0.1, "cost": 0.1},
]

var rng := RandomNumberGenerator.new()
var max_beats: int
var beat := 0
var dominance := 0.0 # -1 Persona leads ... +1 System dominates
var opinion := 0.0 # -1 public backs System ... +1 public backs Persona
var persona := {"autonomy": 0.5, "belonging": 0.5, "purpose": 0.5}
var system_obj := {"order": 0.5, "output": 0.5, "control": 0.5}
var balance_streak := 0
var ended := false
var outcome := "" # "synthesis" or "no_synthesis"
var events: Array[String] = []
var trace: Array[Dictionary] = [] # structured twin of events, for UI/insight/art
var commands: Array = COMMANDS
var pending_cmd: Dictionary = {}
var pending_idx := -1
var counts := {OBEY: 0, NEGOTIATE: 0, DEFY: 0}

## Optional human control. Leave invalid to let the scripted AI decide.
var system_chooser := Callable() # (sim) -> int command index
var persona_chooser := Callable() # (sim, command: Dictionary) -> String
var audience_chooser := Callable() # (sim) -> float opinion delta


func _init(seed_value: int, max_beats_value: int = 60, commands_value: Array = COMMANDS) -> void:
	rng.seed = seed_value
	max_beats = max_beats_value
	commands = commands_value
	for k in system_obj:
		system_obj[k] = rng.randf_range(0.2, 0.9)


func run() -> Dictionary:
	while not ended:
		step()
	return summary()


func step() -> void:
	if ended:
		return
	begin_beat()
	finish_beat()


## First half of a beat: Audience nudges opinion, System picks a command.
## idx >= 0 lets a human System choose; -1 defers to system_chooser or the scripted AI.
func begin_beat(idx: int = -1) -> Dictionary:
	beat += 1
	var delta: float = audience_chooser.call(self) if audience_chooser.is_valid() else rng.randf_range(-0.2, 0.2)
	opinion = clampf(opinion + delta, -1.0, 1.0)
	if idx < 0:
		idx = system_chooser.call(self) if system_chooser.is_valid() else _ai_system_pick()
	pending_idx = idx
	pending_cmd = commands[idx]
	return pending_cmd


## Second half: Persona responds ("" defers to persona_chooser or the scripted AI), then balance is checked.
func finish_beat(response: String = "") -> void:
	var cmd := pending_cmd
	if response == "":
		response = persona_chooser.call(self, cmd) if persona_chooser.is_valid() else _ai_persona_pick(cmd)
	_apply(cmd, response)

	if absf(dominance) < BALANCE_BAND:
		balance_streak += 1
	else:
		balance_streak = 0
	events.append("%d|%s|%s|d=%.3f|o=%.3f" % [beat, cmd.name, response, dominance, opinion])
	trace.append({"beat": beat, "cmd": cmd.name, "idx": pending_idx, "response": response, "d": dominance, "o": opinion})

	if balance_streak >= BALANCE_HOLD:
		ended = true
		outcome = "synthesis"
	elif beat >= max_beats:
		ended = true
		outcome = "no_synthesis"


func _ai_system_pick() -> int:
	var best := 0
	var best_score := -INF
	for i in commands.size():
		var c: Dictionary = commands[i]
		var score: float = system_obj.order * c.order + system_obj.output * c.output + system_obj.control * c.control
		score -= opinion * c.control * 0.8 # public backs Persona => control is costly
		if dominance < 0.0:
			score += -dominance * c.control * 0.5 # losing => reach for control
		score += rng.randf_range(-0.1, 0.1)
		if score > best_score:
			best_score = score
			best = i
	return best


func _ai_persona_pick(cmd: Dictionary) -> String:
	var u_obey: float = persona.belonging * 0.4 - persona.autonomy * cmd.cost
	var u_neg: float = 0.1 - 0.3 * persona.autonomy * cmd.cost + opinion * 0.1
	var u_defy: float = persona.autonomy * cmd.cost - cmd.control * 0.5 + opinion * 0.3 - 0.2 * persona.belonging
	u_obey += rng.randf_range(-0.05, 0.05)
	u_neg += rng.randf_range(-0.05, 0.05)
	u_defy += rng.randf_range(-0.05, 0.05)
	if u_obey >= u_neg and u_obey >= u_defy:
		return OBEY
	if u_neg >= u_defy:
		return NEGOTIATE
	return DEFY


func _apply(cmd: Dictionary, response: String) -> void:
	counts[response] += 1
	match response:
		OBEY:
			dominance += 0.12 * (0.5 + cmd.cost)
			persona.autonomy -= 0.05 * cmd.cost
			persona.belonging += 0.03
		NEGOTIATE:
			dominance += (0.0 - dominance) * 0.25
			persona.purpose += 0.02
		DEFY:
			dominance -= 0.15
			persona.autonomy += 0.05
			persona.belonging -= 0.05
			system_obj.control += 0.05
	dominance -= 0.06 * opinion # Audience pressure
	dominance = clampf(dominance, -1.0, 1.0)
	for k in persona:
		persona[k] = clampf(persona[k], 0.0, 1.0)
	system_obj.control = clampf(system_obj.control, 0.0, 1.0)


func summary() -> Dictionary:
	return {
		"outcome": outcome,
		"beats": beat,
		"dominance": snappedf(dominance, 0.001),
		"opinion": snappedf(opinion, 0.001),
		"counts": counts.duplicate(),
		"hash": log_hash(),
	}


func log_hash() -> String:
	return "\n".join(events).sha256_text()
