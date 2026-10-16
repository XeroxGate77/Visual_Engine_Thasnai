class_name EraPack
extends RefCounted
## ERA PACK — an era (setting + dilemma deck) as a data file, so any AI can write one with the C.D. kit (GAME mode)
## and drop it into the game. Sits BESIDE the locked `sim/eras.gd`: the era dictionary it yields has exactly the
## shape of Eras.DATA[id], so the engine runs it unchanged.
##
## File (JSON):
##   { "format": "cd-era-pack/1", "id": "deepsea", "author": "...", "made_with": "Claude",
##     "era": { "title", "blurb", "commands": [ {name, text, order, output, control, cost} x 4..10 ],
##              "closing": {"synthesis", "no_synthesis"}, "image_scene": "(optional) words for the image prompt" } }
##
## Hard rules (a pack that breaks one is rejected): see validate(). Balance is NOT judged here — EraPackCheck
## reports numbers and warnings; balance and taste are the owner's call.

const FORMAT := "cd-era-pack/1"
const NUM_KEYS := ["order", "output", "control", "cost"]
const MIN_COMMANDS := 4   # CD.md §6.1 output contract: at least 4 commands
const MAX_COMMANDS := 10  # replay codes store a System choice as one digit 0-9
const TOP_KEYS := ["format", "id", "author", "made_with", "era"]
const ERA_KEYS := ["title", "blurb", "commands", "closing", "image_scene"]
const CMD_KEYS := ["name", "text", "order", "output", "control", "cost"]
const LIMITS := {"title": 24, "blurb": 90, "name": 40, "text": 140, "closing": 160, "image_scene": 200}


## {ok, errors, warnings, id, era, hash}
static func parse(text: String, allow_builtin_id := false) -> Dictionary:
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "errors": ["not a JSON object"], "warnings": []}
	return from_dict(data, allow_builtin_id)


static func load_file(path: String, allow_builtin_id := false) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["file not found: %s" % path], "warnings": []}
	return parse(FileAccess.get_file_as_string(path), allow_builtin_id)


static func from_dict(data: Dictionary, allow_builtin_id := false) -> Dictionary:
	var v := validate(data, allow_builtin_id)
	if not v.errors.is_empty():
		return {"ok": false, "errors": v.errors, "warnings": v.warnings}
	var era := _clean_era(data.era)
	return {"ok": true, "errors": [], "warnings": v.warnings, "id": data.id, "era": era, "hash": content_hash(era)}


## {errors: Array[String], warnings: Array[String]}
static func validate(data: Dictionary, allow_builtin_id := false) -> Dictionary:
	var e: Array[String] = []
	var w: Array[String] = []
	if data.get("format") != FORMAT:
		e.append("format must be \"%s\"" % FORMAT)
	var id = data.get("id")
	if typeof(id) != TYPE_STRING or not _id_ok(id):
		e.append("id must be 2-24 chars: lowercase a-z first, then a-z 0-9 _ (no dots, no spaces)")
	elif Eras.DATA.has(id) and not allow_builtin_id:
		e.append("id \"%s\" is a built-in era — pick another id" % id)
	for k in data:
		if not k in TOP_KEYS:
			w.append("unknown key \"%s\" is ignored" % k)
	var era = data.get("era")
	if typeof(era) != TYPE_DICTIONARY:
		e.append("era must be an object")
		return {"errors": e, "warnings": w}
	for k in era:
		if not k in ERA_KEYS:
			w.append("unknown key era.%s is ignored" % k)
	_text(era, "title", "era.title", e, w)
	_text(era, "blurb", "era.blurb", e, w)
	if era.has("image_scene"):
		_text(era, "image_scene", "era.image_scene", e, w)
	var closing = era.get("closing")
	if typeof(closing) != TYPE_DICTIONARY:
		e.append("era.closing must be an object with \"synthesis\" and \"no_synthesis\"")
	else:
		for k in ["synthesis", "no_synthesis"]:
			_text(closing, k, "era.closing.%s" % k, e, w, LIMITS.closing)
	var cmds = era.get("commands")
	if typeof(cmds) != TYPE_ARRAY or cmds.size() < MIN_COMMANDS or cmds.size() > MAX_COMMANDS:
		e.append("era.commands must be a list of %d-%d commands" % [MIN_COMMANDS, MAX_COMMANDS])
		return {"errors": e, "warnings": w}
	var names := {}
	for i in cmds.size():
		var c = cmds[i]
		var at := "era.commands[%d]" % i
		if typeof(c) != TYPE_DICTIONARY:
			e.append("%s must be an object" % at)
			continue
		for k in c:
			if not k in CMD_KEYS:
				w.append("unknown key %s.%s is ignored" % [at, k])
		_text(c, "name", at + ".name", e, w)
		_text(c, "text", at + ".text", e, w)
		if typeof(c.get("name")) == TYPE_STRING:
			if names.has(c.name):
				e.append("%s.name repeats \"%s\"" % [at, c.name])
			names[c.name] = true
		for k in NUM_KEYS:
			var x = c.get(k)
			if not (typeof(x) in [TYPE_FLOAT, TYPE_INT]) or x < 0.0 or x > 1.0:
				e.append("%s.%s must be a number from 0 to 1" % [at, k])
	return {"errors": e, "warnings": w}


## sha256 of the canonical era (sorted keys) — the identity of the deck. Same content => same hash.
static func content_hash(era: Dictionary) -> String:
	return JSON.stringify(era, "", true).sha256_text()


## A pack file for an era dictionary (used to write the built-in eras as templates).
static func to_json(id: String, era: Dictionary, author := "", made_with := "") -> String:
	return JSON.stringify({"format": FORMAT, "id": id, "author": author, "made_with": made_with, "era": era}, "  ", false) + "\n"


static func _clean_era(era: Dictionary) -> Dictionary:
	var cmds: Array = []
	for c in era.commands:
		var d := {"name": c.name, "text": c.text}
		for k in NUM_KEYS:
			d[k] = float(c[k])
		cmds.append(d)
	var out := {"title": era.title, "blurb": era.blurb, "commands": cmds,
		"closing": {"synthesis": era.closing.synthesis, "no_synthesis": era.closing.no_synthesis}}
	if era.has("image_scene"):
		out.image_scene = era.image_scene
	return out


static func _id_ok(id: String) -> bool:
	var re := RegEx.create_from_string("^[a-z][a-z0-9_]{1,23}$")
	return re.search(id) != null


static func _text(d: Dictionary, key: String, at: String, e: Array[String], w: Array[String], limit := -1) -> void:
	var s = d.get(key)
	if typeof(s) != TYPE_STRING or s.strip_edges() == "":
		e.append("%s must be non-empty text" % at)
		return
	var lim: int = limit if limit > 0 else LIMITS.get(key, 200)
	if s.length() > lim:
		e.append("%s is %d chars; max %d (it must fit the game screen)" % [at, s.length(), lim])
	for ch: String in s:
		var u: int = ch.unicode_at(0)
		if u > 0x024F and not (u >= 0x2000 and u <= 0x206F): # beyond Latin, except punctuation like — … ·
			w.append("%s has non-Latin text — the game font may not show it yet (art direction: Thai font)" % at)
			return
