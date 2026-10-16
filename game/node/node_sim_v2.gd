class_name NodeSimV2
extends NodeSim
## NODE-RULES v0.2 = v0.1 + N2b (aim into the band). Built beside v0.1 (NodeSim stays as approved, replay SD3).
## N2b: when the warning (N2) did not fire but grip is still outside the balance band, the Node issues an
## "aim" condition for the next beat through the same channels (N3 restrict orders, else N4 invite).
## Aim conditions count for N6 labels and G2 registers like any other condition; logged with "|aim" (N7).

const RULES_VERSION_V2 := "v0.2"

var aim_history := {} # beat -> true when the condition in force that beat was an aim (N2b)
var next_is_aim := false # the condition set for the next beat is an aim


func rules_version() -> String:
	return RULES_VERSION_V2


func finish_beat(response: String = "") -> void:
	var was_aim := next_is_aim
	var kind := cond_kind
	super.finish_beat(response) # v0.1: logs this beat's condition, labels N6, sets N2 warning condition
	if was_aim and kind != "":
		aim_history[beat] = true
		events[events.size() - 1] += "|aim"
		trace[trace.size() - 1]["node"] += "|aim"
	next_is_aim = false
	if ended or cond_kind != "": # N2 warning already set a condition — it takes precedence (N5: one at a time)
		return
	if absf(dominance) >= DialecticSim.BALANCE_BAND: # N2b
		for i in commands.size():
			if absf(expected_grip(commands[i])) < absf(dominance):
				allowed.append(i)
		cond_kind = "sys" if not allowed.is_empty() else "invite"
		next_is_aim = true
