extends Control
## VIEWER: a replay code (from a scanned QR) rebuilds its artwork. Same engine code as the game, so the
## piece re-creates itself beat by beat and its log hash proves it is the authentic run.
## Code source: the URL fragment on the web (https://…/#SD6.…), else user args, else a paste field.

const C_BG := Color("1b1d1f")
const C_STEEL := Color("5c6166")
const C_AMBER := Color("e0a030")
const C_RUST := Color("b5472a")
const C_TEXT := Color("d8d2c4")
const REVEAL_SEC := 6.0
const PUBLIC_KEY_PATH := "res://export/creator_public.pem" # the creator's public key (absent until the key is made)
const REGISTRY_FILE := "registry.json" # published next to the web viewer (from _BLACKBOX/registry_public.json)

var art: ArtView
var title: Label
var body: Label
var verdict: Label
var input: LineEdit
var current: Dictionary = {}
var registry: Dictionary = {}
var _hash_cb: JavaScriptObject # kept alive so the browser callback is not freed


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	title = _label("SUBJUGATED DIALECTICS — VIEWER", 26, C_AMBER)
	root.add_child(title)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	root.add_child(row)
	art = ArtView.new()
	art.custom_minimum_size = Vector2(560, 560)
	art.reveal = 0.0
	row.add_child(art)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	scroll.add_child(col)
	verdict = _label("", 15, C_STEEL)
	col.add_child(verdict)
	body = _label("", 14, C_TEXT)
	col.add_child(body)
	var bar := HBoxContainer.new()
	root.add_child(bar)
	input = LineEdit.new()
	input.placeholder_text = "paste a replay code (SD1… – SD6…)"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(input)
	var go := Button.new()
	go.text = "VIEW"
	go.pressed.connect(func() -> void: show_code(input.text))
	bar.add_child(go)
	if OS.has_feature("web"): # a new #code in an open tab does not reload the page — listen for it
		_hash_cb = JavaScriptBridge.create_callback(func(_args: Array) -> void:
			var c := _incoming_code()
			input.text = c
			show_code(c))
		JavaScriptBridge.get_interface("window").addEventListener("hashchange", _hash_cb)
	_load_registry()
	var code := _incoming_code()
	if code != "":
		input.text = code
		show_code(code)
	else:
		verdict.text = "Scan a Subjugated Dialectics QR, or paste its replay code below."


func _incoming_code() -> String:
	if OS.has_feature("web"):
		var h = JavaScriptBridge.eval("decodeURIComponent(window.location.hash.substring(1))", true)
		return str(h) if h != null else ""
	var args := OS.get_cmdline_user_args()
	return args[0] if args.size() > 0 else ""


## Rebuilds the run from its code. Returns the decode result (for tests).
func show_code(code: String) -> Dictionary:
	current = ReplayCode.decode(code)
	if not current.ok:
		title.text = "NOT AN AUTHENTIC PIECE"
		verdict.text = "This code does not rebuild a game whose log matches it (%s)." % current.reason
		verdict.add_theme_color_override("font_color", C_RUST)
		body.text = ""
		art.trace = []
		art.synthesis = false
		art.queue_redraw()
		return current
	var sim: DialecticSim = current.sim
	var era: Dictionary = Eras.get_era(current.era)
	title.text = "SUBJUGATED DIALECTICS — %s" % era.title
	var rules := "engine only"
	if sim is NodeSim:
		rules = "Node %s + Lens %s" % [(sim as NodeSimV2).rules_version() if sim is NodeSimV2 else NodeSim.RULES_VERSION, Lens.RULES_VERSION]
	elif sim is LensSim:
		rules = "Lens " + Lens.RULES_VERSION
	verdict.text = "AUTHENTIC — rebuilt from its code; log hash %s matches.\nRules: %s · played as %s · %s after %d beats" % [
		current.hash.left(16) + "…", rules, current.role.to_upper(), sim.outcome.replace("_", " ").to_upper(), sim.beat]
	verdict.text += "\n" + signature_status(_public_pem(), registry, current.hash)
	var rar := Rarity.of(sim)
	if rar.tier != "":
		verdict.text += "\nRARITY %s: %s%s (computed from the rebuilt piece)" % [Rarity.VERSION, rar.tier, (" · " + rar.reason) if rar.reason != "" else ""]
	verdict.add_theme_color_override("font_color", C_AMBER)
	var parts: Array[String] = []
	var ins := Insight.build(sim, current.era)
	parts.append(ins.text)
	parts.append(ins.dilemma)
	if sim is NodeSim:
		parts.append(GenderReading.build(sim as NodeSim))
	if sim is NodeSimV4:
		parts.append("MICRO-NODES\n" + (sim as NodeSimV4).micro.to_text())
	body.text = "\n\n".join(parts)
	art.trace = sim.trace
	art.synthesis = sim.outcome == "synthesis"
	art.reveal = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		art.reveal = v
		art.queue_redraw(), 0.0, 1.0, REVEAL_SEC) # the piece re-creates itself beat by beat
	return current


## Creator signature line for a piece (pure; tested offline).
static func signature_status(pem: String, reg: Dictionary, log_hash: String) -> String:
	if pem == "":
		return "Creator signature: no creator key in this build yet."
	if reg.is_empty():
		return "Creator signature: registry not available."
	for p in reg.get("pieces", []):
		if p.get("hash", "") == log_hash:
			if Signer.verify(pem, Signer.message(log_hash, p.code, int(p.edition)), p.signature):
				return "SIGNED BY THE CREATOR · EDITION #%03d" % int(p.edition)
			return "Creator signature INVALID for this piece."
	return "Not in the creator's registry (authentic run, but not an extracted edition)."


func _public_pem() -> String:
	return FileAccess.get_file_as_string(PUBLIC_KEY_PATH) if FileAccess.file_exists(PUBLIC_KEY_PATH) else ""


## Web: fetch registry.json from the viewer's own folder; desktop: res://export/registry.json if present.
func _load_registry() -> void:
	if not OS.has_feature("web"):
		var local := "res://export/registry.json"
		if FileAccess.file_exists(local):
			var j = JSON.parse_string(FileAccess.get_file_as_string(local))
			registry = j if typeof(j) == TYPE_DICTIONARY else {}
		return
	var url = JavaScriptBridge.eval("location.origin + location.pathname.replace(/[^/]*$/, '') + '%s'" % REGISTRY_FILE, true)
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var j = JSON.parse_string(body.get_string_from_utf8())
			registry = j if typeof(j) == TYPE_DICTIONARY else {}
			if current.get("ok", false):
				show_code(input.text)) # refresh the signature line
	http.request(str(url))


func _label(text: String, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
