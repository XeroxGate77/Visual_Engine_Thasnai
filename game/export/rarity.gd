class_name Rarity
extends RefCounted
## Rarity R1.0 — decided by Claude at the owner's request (2026-10-16): "นายคิดเรื่องความหายากเองเลย".
## Computed only from the piece itself, so anyone who rebuilds it from its code gets the same tier (verifiable,
## nothing to trust). First match wins, top to bottom. Only synthesized pieces have a tier.
##   MYTHIC    CARE synthesis — the philosophy's ideal: balance reached through the Node's invitation (Gilligan);
##             needs a Persona that chooses to accept.
##   RARE      deep synthesis (>= 5 micro S in band) · long siege (>= 16 beats) — the dialectic went deep or long
##   UNCOMMON  CONTRACT synthesis (balance bought through power, Pateman) · both stereotypes inverted at once
##             (the 'Female node' ruled through command AND the 'Male node' leaned on care) · 4 micro S in band
##   COMMON    every other synthesis

const VERSION := "R1.0"
const ORDER := ["MYTHIC", "RARE", "UNCOMMON", "COMMON"]


static func of(sim: DialecticSim) -> Dictionary:
	if sim.outcome != "synthesis":
		return {"tier": "", "reason": "no synthesis"}
	var ns: NodeSim = sim as NodeSim
	var micro_s := (sim as NodeSimV4).micro.count_in_band(MicroGrid.SYNTHESIS) if sim is NodeSimV4 else 0
	if ns != null and ns.synthesis_type == "care":
		return {"tier": "MYTHIC", "reason": "care synthesis"}
	if micro_s >= 5:
		return {"tier": "RARE", "reason": "deep synthesis (%d micro S)" % micro_s}
	if sim.beat >= 16:
		return {"tier": "RARE", "reason": "long siege (%d beats)" % sim.beat}
	if ns != null and ns.synthesis_type == "contract":
		return {"tier": "UNCOMMON", "reason": "contract synthesis"}
	if ns != null and _both_inverted(ns):
		return {"tier": "UNCOMMON", "reason": "both stereotypes inverted"}
	if micro_s == 4:
		return {"tier": "UNCOMMON", "reason": "4 micro S"}
	return {"tier": "COMMON", "reason": ""}


static func _both_inverted(ns: NodeSim) -> bool:
	var female_cmd: bool = ns.node_registers.command > ns.node_registers.care
	var er: Dictionary = ns.engine_registers
	var male_care: bool = er.care > er.command and er.care >= er.resistance
	return female_cmd and male_care
