class_name MicroGrid
extends RefCounted
## NODE-RULES v0.4 (owner-approved 2026-10-15, M2c on, K = 2): each of the 20 gauge cells holds 5 micro-nodes (100 in all).
## A micro-node moves through a dialectic: EMPTY -> THESIS (with a register) -> ANTITHESIS -> SYNTHESIS.
## Updated once per beat, deterministically, inside the cell where grip landed.

const CELLS := 20
const PER_CELL := 5
const SIZE := CELLS * PER_CELL
const EMPTY := 0
const THESIS := 1
const ANTITHESIS := 2
const SYNTHESIS := 3
const BAND_CELLS := [9, 10] # 45–55%
const CH := [".", "T", "A", "S"]

var self_negation := true # M2c — owner: on
var state: Array[int] = []
var tag: Array[String] = [] # register carried by a THESIS


func _init() -> void:
	state.resize(SIZE)
	state.fill(EMPTY)
	tag.resize(SIZE)
	tag.fill("")


## One beat in the cell where grip landed.
func update(grip: float, register: String) -> void:
	var c := Grid.cell(grip)
	var base := c * PER_CELL
	# M1 deposit: the beat leaves a thesis in the cell's first empty micro-node.
	# M1' a full cell: care resolves its first contradiction; resistance reopens its first synthesis.
	var placed := false
	for k in PER_CELL:
		if state[base + k] == EMPTY:
			state[base + k] = THESIS
			tag[base + k] = register
			placed = true
			break
	if not placed:
		var want := ANTITHESIS if register == "care" else (SYNTHESIS if register == "resistance" else -1)
		for k in PER_CELL:
			if state[base + k] == want:
				state[base + k] = SYNTHESIS if register == "care" else ANTITHESIS
				break
	# M2c self-negation: a cell filled with theses of one register (dogma) negates itself at its last micro-node
	if self_negation:
		var dogma := true
		for k in PER_CELL:
			if state[base + k] != THESIS or tag[base + k] != tag[base]:
				dogma = false
				break
		if dogma:
			state[base + PER_CELL - 1] = ANTITHESIS
	# M2 dialectic between neighbours inside the cell (on a snapshot, so order does not matter):
	var snap := state.duplicate()
	var stag := tag.duplicate()
	for k in PER_CELL:
		var j := base + k
		var l := j - 1 if k > 0 else -1
		var r := j + 1 if k < PER_CELL - 1 else -1
		var nb: Array[int] = []
		for n in [l, r]:
			if n >= 0:
				nb.append(n)
		match snap[j]:
			THESIS: # M2a: a thesis beside a thesis of another register (or beside a contradiction) -> antithesis
				for n in nb:
					if (snap[n] == THESIS and stag[n] != stag[j]) or snap[n] == ANTITHESIS:
						state[j] = ANTITHESIS
						break
			ANTITHESIS: # M2b: in a beat of care, a contradiction beside a contradiction or a synthesis -> synthesis
				if register == "care":
					for n in nb:
						if snap[n] == ANTITHESIS or snap[n] == SYNTHESIS:
							state[j] = SYNTHESIS
							break


func count_in_band(s: int) -> int:
	var n := 0
	for c in BAND_CELLS:
		for k in PER_CELL:
			if state[c * PER_CELL + k] == s:
				n += 1
	return n


## Node M4: a cell with more contradictions than syntheses is unresolved ground.
func unresolved(grip: float) -> bool:
	var base := Grid.cell(grip) * PER_CELL
	var a := 0
	var s := 0
	for k in PER_CELL:
		a += 1 if state[base + k] == ANTITHESIS else 0
		s += 1 if state[base + k] == SYNTHESIS else 0
	return a > s


func to_text() -> String:
	var out := ""
	for j in SIZE:
		out += CH[state[j]]
		if j % PER_CELL == PER_CELL - 1 and j < SIZE - 1:
			out += "|"
	return out
