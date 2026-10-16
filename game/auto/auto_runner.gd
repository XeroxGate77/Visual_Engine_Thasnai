class_name AutoRunner
extends RefCounted
## AUTO MODE logic (no UI): an endless stream of games on the current rules (NodeSimV4) that rotates through every
## era the registry offers (built-in + era packs). Run i of a session gets a seed derived from (session seed, i).
## An untouched run is the scripted AI in every seat — it is written as a Persona code (the canonical one the game's
## encoder gives: the largest k that rebuilds the run; often 0, larger when the AI's picks need no randomness), so it
## rebuilds and verifies like any other piece. Who really sat where is kept in the gallery entry ("seat"). A run with a human Audience is an ordinary Audience game.

var reg: EraRegistry
var session_seed: int
var index := -1  # last run started


func _init(registry: EraRegistry, session_seed_value: int) -> void:
	reg = registry
	session_seed = session_seed_value


static func seed_for(session: int, i: int) -> int:
	return hash([session, i]) & 0x7fffffff


## Starts the next run: {index, era, sim}. No choosers set — the caller adds a human Audience if there is one.
func next_run() -> Dictionary:
	index += 1
	var era_id: String = reg.order[index % reg.order.size()]
	var sim := NodeSimV4.new(seed_for(session_seed, index), 60, reg.get_era(era_id).commands)
	return {"index": index, "era": era_id, "sim": sim}


## Gallery entry for a finished run ({} if it did not synthesize or its code cannot rebuild it).
## role: "auto" (AI in every seat) or "audience" (a human held the Audience seat).
func entry(sim: NodeSimV4, era_id: String, role: String) -> Dictionary:
	if sim.outcome != "synthesis":
		return {}
	var code := ReplayCodePack.encode(sim, era_id, "persona" if role == "auto" else role, reg)
	if code == "":
		return {}
	var rar := Rarity.of(sim)
	return {"code": code, "hash": sim.log_hash(), "era": era_id, "title": reg.get_era(era_id).title,
		"seat": role, "beats": sim.beat, "type": sim.synthesis_type, "rarity": rar.tier, "rarity_reason": rar.reason,
		"at": Time.get_datetime_string_from_system(true)}
