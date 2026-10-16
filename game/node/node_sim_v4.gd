class_name NodeSimV4
extends NodeSimV3
## NODE-RULES v0.4 (owner-approved 2026-10-15: M2c on, K = 2): v0.3 + micro-nodes. Beside v0.3 (SD5); replay SD6.
## M3: Node ① also needs >= micro_need SYNTHESIS micro-nodes inside the 45–55% band.
## M4: when the Node restricts orders, it also avoids orders expected to land in an unresolved cell
##     (more antitheses than syntheses); if that leaves none, the v0.3 set stands.

const RULES_VERSION_V4 := "v0.4"
const MICRO_NEED := 2

var micro := MicroGrid.new()
var micro_need := MICRO_NEED
var use_m4 := true


func rules_version() -> String:
	return RULES_VERSION_V4


func finish_beat(response: String = "") -> void:
	var before := dominance
	super.finish_beat(response)
	var t: Dictionary = trace[trace.size() - 1]
	var reg: String = {OBEY: "command", NEGOTIATE: "care", DEFY: "resistance"}[t.response]
	micro.update(dominance, reg)
	t["micro_s_band"] = micro.count_in_band(MicroGrid.SYNTHESIS)
	if ended and outcome == "synthesis" and t.micro_s_band < micro_need: # M3
		synthesis_type = ""
		if beat >= max_beats:
			outcome = "no_synthesis"
			return
		ended = false
		outcome = ""
		_next_condition(before)
	if use_m4 and not ended and cond_kind == "sys": # M4
		var calm: Array[int] = []
		for i in allowed:
			if not micro.unresolved(expected_grip(commands[i])):
				calm.append(i)
		if not calm.is_empty():
			allowed = calm
