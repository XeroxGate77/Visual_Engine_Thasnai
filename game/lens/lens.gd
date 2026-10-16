class_name Lens
extends RefCounted
## LENS-RULES v0.1 (owner-approved 2026-10-15) as pure state. Rule ids (L1..L8) refer to LENS-RULES.md.
## LensSim applies this to a game; nothing here touches the locked engine.

const RULES_VERSION := "v0.1"
## L1: three fragments per pole, keyed by the pole being looked INTO (its opposite pole is who sees it, P2).
const FRAGMENTS := {"system": ["order", "output", "control"], "persona": ["autonomy", "belonging", "purpose"]}
## L2: focus levels
const HIDDEN := 0
const BLUR := 1
const CLEAR := 2
const ENERGY_CAP := DialecticSim.BALANCE_HOLD # L3.3
const HALVE_AFTER_OUT := 2 # L3.4
## Replay-code letters for each fragment
const CODES := {"system:order": "O", "system:output": "U", "system:control": "C",
	"persona:autonomy": "A", "persona:belonging": "B", "persona:purpose": "P"}

var energy := 0
var out_streak := 0
var levels := {
	"system": {"order": HIDDEN, "output": HIDDEN, "control": HIDDEN},
	"persona": {"autonomy": HIDDEN, "belonging": HIDDEN, "purpose": HIDDEN},
}


func level(target: String, frag: String) -> int:
	return levels[target][frag]


func can_focus(target: String, frag: String) -> bool:
	return energy >= 1 and FRAGMENTS.has(target) and frag in FRAGMENTS[target] and levels[target][frag] < CLEAR


## L4.1: spend 1 energy, raise one fragment one level. Returns false (and changes nothing) if not allowed.
func focus(target: String, frag: String) -> bool:
	if not can_focus(target, frag):
		return false
	energy -= 1
	levels[target][frag] += 1
	return true


## L3: called once at the end of every beat with the grip after that beat.
## L3.4 reading: energy halves on every 2nd consecutive out-of-band beat (2, 4, 6...).
func end_beat(grip: float) -> void:
	if absf(grip) < DialecticSim.BALANCE_BAND:
		energy = mini(energy + 1, ENERGY_CAP) # L3.1, L3.3
		out_streak = 0
	else:
		out_streak += 1 # L3.2
		if out_streak % HALVE_AFTER_OUT == 0:
			energy /= 2


## L5.1: at least 2 of 3 CLEAR, or all 3 at least BLUR.
func enough(target: String) -> bool:
	var clear := 0
	var seen := 0
	for f in FRAGMENTS[target]:
		if levels[target][f] == CLEAR:
			clear += 1
		if levels[target][f] >= BLUR:
			seen += 1
	return clear >= 2 or seen == 3


## L5.2: both directions must pass.
func both_enough() -> bool:
	return enough("system") and enough("persona")


func disclosed(target: String) -> int:
	var n := 0
	for f in FRAGMENTS[target]:
		n += levels[target][f]
	return n


## L2: what the opposite pole sees of one fragment.
static func view(lvl: int, value: float) -> String:
	match lvl:
		BLUR:
			return "low" if value < 0.34 else ("mid" if value < 0.67 else "high")
		CLEAR:
			return "%.2f" % value
	return "?"


static func code_of(target: String, frag: String) -> String:
	return CODES.get(target + ":" + frag, "-")


static func from_code(ch: String) -> Array:
	for k in CODES:
		if CODES[k] == ch:
			return k.split(":")
	return []
