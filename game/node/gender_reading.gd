class_name GenderReading
extends RefCounted
## NODE-RULES G3/G4: the "gendered reading" of one finished NodeSim game. No character gets a gender label;
## the owner's frame (Engine ≈ Male node, Node ≈ Female node) is used to read which register each node played in.

const NAMES := {"command": "Command", "care": "Care", "resistance": "Resistance"}
const TYPES := {"contract": "a CONTRACT synthesis — balance bought through the System's power (Pateman)",
	"care": "a CARE synthesis — balance reached through the Node's invitation to negotiate (Gilligan)",
	"emergent": "an EMERGENT synthesis — no condition from the Node in the final beats"}


static func build(sim: NodeSim) -> String:
	var all := NodeSim.share(sim.registers)
	var lines: Array[String] = []
	lines.append("GENDERED READING — Command %d%% · Care %d%% · Resistance %d%%" % [all.command, all.care, all.resistance])
	if sim.outcome == "synthesis":
		lines.append("This was " + TYPES[sim.synthesis_type] + ".")
	var eng := _top(sim.engine_registers)
	lines.append("Engine (the 'Male node') played mostly in the %s register." % NAMES[eng])
	var n_cmd: int = sim.node_registers.command
	var n_care: int = sim.node_registers.care
	if n_cmd + n_care == 0:
		lines.append("Node (the 'Female node') never intervened.")
	else:
		var node_reg := "command" if n_cmd > n_care else "care"
		lines.append("Node (the 'Female node') intervened %d times, mostly in the %s register." % [n_cmd + n_care, NAMES[node_reg]])
		if node_reg == "command":
			lines.append("The 'Female node' ruled through command — the stereotype inverted.")
	if eng == "care":
		lines.append("The 'Male node' leaned on care — the stereotype inverted.")
	return "\n".join(lines)


static func _top(reg: Dictionary) -> String:
	var best := "command"
	for k in ["command", "care", "resistance"]: # fixed order = stable tie-break
		if reg[k] > reg[best]:
			best = k
	return best
