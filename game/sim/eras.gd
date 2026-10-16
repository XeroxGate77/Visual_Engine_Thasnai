class_name Eras
extends RefCounted
## Era = the setting that seeds the System's dilemmas. Same command shape as DialecticSim.COMMANDS.
## Numbers are PLACEHOLDERS (same ranges as the default set); balance/flavour is the owner's call.

const ORDER := ["industrial", "prehistoric", "posttruth"]

const DATA := {
	"industrial": {
		"title": "INDUSTRIAL",
		"blurb": "Furnaces, shift bells, the foreman's eye.",
		"commands": [
			{"name": "RAISE THE QUOTA", "text": "Output up by a fifth. The line is already hot.", "order": 0.3, "output": 0.9, "control": 0.3, "cost": 0.5},
			{"name": "RING THE SHIFT BELL", "text": "Bells at dawn, bells at dusk. Rest is a rented hour.", "order": 0.9, "output": 0.1, "control": 0.5, "cost": 0.6},
			{"name": "INSTALL THE FOREMAN'S EYE", "text": "Every bench watched. Trust becomes a line item.", "order": 0.5, "output": 0.2, "control": 0.9, "cost": 0.8},
			{"name": "OFFER THE BONUS", "text": "A coin for a faster hand. Who counts the missing fingers?", "order": 0.2, "output": 0.4, "control": 0.1, "cost": 0.1},
		],
		"closing": {
			"synthesis": "The machine and the hand found a pace neither owns.",
			"no_synthesis": "The line kept running. Nobody agreed to it.",
		},
	},
	"prehistoric": {
		"title": "PRE-HISTORIC",
		"blurb": "Fire, hunt, taboo, the circle at night.",
		"commands": [
			{"name": "DEMAND THE HUNT TRIBUTE", "text": "Half the kill to the fire. The young go hungry first.", "order": 0.3, "output": 0.9, "control": 0.3, "cost": 0.5},
			{"name": "ENFORCE THE FIRE TABOO", "text": "No one tends the flame but the chosen. Cold is the price of order.", "order": 0.9, "output": 0.1, "control": 0.5, "cost": 0.6},
			{"name": "NAME THE OUTCAST", "text": "One voice is cut from the circle so the rest may sleep.", "order": 0.5, "output": 0.2, "control": 0.9, "cost": 0.8},
			{"name": "SHARE THE FEAST", "text": "Bellies full tonight. Tomorrow's debt is not spoken.", "order": 0.2, "output": 0.4, "control": 0.1, "cost": 0.1},
		],
		"closing": {
			"synthesis": "The circle and the wanderer agreed on where the fire sits.",
			"no_synthesis": "The fire burned on. The circle quietly split.",
		},
	},
	"posttruth": {
		"title": "POST-TRUTH",
		"blurb": "Feeds, verdicts, the ranking of facts.",
		"commands": [
			{"name": "PUBLISH THE APPROVED FACTS", "text": "One account, repeated until it echoes as memory.", "order": 0.3, "output": 0.9, "control": 0.3, "cost": 0.5},
			{"name": "BOOST THE LOYAL FEED", "text": "What is agreed with rises. What is doubted sinks quietly.", "order": 0.9, "output": 0.1, "control": 0.5, "cost": 0.6},
			{"name": "FLAG THE DISSENTERS", "text": "A badge for the doubters. Visibility as a leash.", "order": 0.5, "output": 0.2, "control": 0.9, "cost": 0.8},
			{"name": "GRANT VERIFIED STATUS", "text": "Trust, sold at a discount to the compliant.", "order": 0.2, "output": 0.4, "control": 0.1, "cost": 0.1},
		],
		"closing": {
			"synthesis": "A shared claim survived being questioned. Rare, and fragile.",
			"no_synthesis": "Every side kept its facts. Nothing joined them.",
		},
	},
}

static func get_era(id: String) -> Dictionary:
	return DATA[id]
