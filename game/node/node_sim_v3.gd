class_name NodeSimV3
extends NodeSimV2
## NODE-RULES v0.3 = v0.2 on the 20-cell gauge grid: balance band 45–55% (|grip| < 0.10) instead of the
## engine's ±0.15. Built beside v0.2 (no locked file edited):
## - Node ① counts its own grid streak; an engine synthesis without 4 beats inside the grid band is undone.
## - The Lens charges only inside the grid band (GridLens).
## - N2b aims whenever grip is outside the grid band (so also in the 45–42.5 / 55–57.5 strips).

const RULES_VERSION_V3 := "v0.3"

var grid_streak := 0


func _init(seed_value: int, max_beats_value: int = 60, commands_value: Array = COMMANDS) -> void:
	super(seed_value, max_beats_value, commands_value)
	lens = GridLens.new()


func rules_version() -> String:
	return RULES_VERSION_V3


func finish_beat(response: String = "") -> void:
	var before := dominance
	super.finish_beat(response)
	grid_streak = grid_streak + 1 if Grid.in_band(dominance) else 0
	trace[trace.size() - 1]["cell"] = Grid.cell(dominance)
	if ended and outcome == "synthesis" and grid_streak < DialecticSim.BALANCE_HOLD:
		# ① not met on the grid: undo the engine's synthesis (the narrower band is a stricter gate)
		synthesis_type = ""
		if beat >= max_beats:
			outcome = "no_synthesis"
			return
		ended = false
		outcome = ""
		_next_condition(before) # v0.1/v0.2 skipped this because the game looked finished
		return
	if not ended and cond_kind == "" and not Grid.in_band(dominance): # N2b on the grid band
		_aim()


## N2 then N2b, as v0.1/v0.2 would have done for the next beat.
func _next_condition(before: float) -> void:
	cond_kind = ""
	allowed = []
	next_is_aim = false
	var forecast := dominance + (dominance - before)
	if absf(forecast) >= warn:
		_restrict_or_invite()
	elif not Grid.in_band(dominance):
		_aim()


func _aim() -> void:
	_restrict_or_invite()
	next_is_aim = true


func _restrict_or_invite() -> void:
	allowed = []
	for i in commands.size():
		if absf(expected_grip(commands[i])) < absf(dominance):
			allowed.append(i)
	cond_kind = "sys" if not allowed.is_empty() else "invite"
