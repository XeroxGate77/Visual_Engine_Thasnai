class_name ImagePrompt
extends RefCounted
## Scripted (free, offline) image prompt the player can paste into Grok Imagine with their own account.
## Deterministic: same finished sim + era => same prompt. Wording is a first pass; tone is the owner's call.

const ERA_SCENE := {
	"industrial": "a vast iron foundry, furnaces, shift bells and riveted gears",
	"prehistoric": "a firelit cave circle at night, hunters, stone tools and ritual smoke",
	"posttruth": "an endless wall of glowing feeds, ranked faces and floating verdict badges",
}

static func build(sim: DialecticSim, era_id: String) -> String:
	var n := maxi(sim.trace.size(), 1)
	var sys_lead := 0
	for t in sim.trace:
		if t.d > 0.0:
			sys_lead += 1
	var top := DialecticSim.OBEY
	for r in [DialecticSim.NEGOTIATE, DialecticSim.DEFY]:
		if sim.counts[r] > sim.counts[top]:
			top = r
	var mood: String = {
		DialecticSim.OBEY: "bowed figures moving in lockstep, quiet compliance",
		DialecticSim.NEGOTIATE: "two forces leaning toward each other across a narrow table",
		DialecticSim.DEFY: "a lone figure pushing back against towering machinery",
	}[top]
	var power := "The System towers over the Persona" if sys_lead * 2 > n else "The Persona stands taller than the System"
	var ending := "A calm glowing amber node at the center where both sides meet in balance" if sim.outcome == "synthesis" \
		else "An unresolved fracture running through the center, no meeting point"
	return "Abstract industrialist painting of %s. %s; %s. %s. Palette of rust red, steel grey and amber on near-black, radial composition, heavy texture, no text, no letters." % [
		ERA_SCENE.get(era_id, ERA_SCENE.industrial), power, mood, ending]
