class_name ClaudeInsight
extends Node
## End-of-game Insight + art spec from the Claude API (raw HTTP; GDScript has no official SDK).
## Every failure path (no key, network, HTTP error, refusal, bad JSON, invalid spec, timeout)
## emits `finished` with source "fallback" and the scripted Insight, so the game never blocks on it.
## Key: read from the ANTHROPIC_API_KEY environment variable only. Never stored or logged.

signal finished(result: Dictionary)

## Owner decision 2026-10-15: API not in use yet; the scripted (black-boxed) Insight is the only source.
## Flip to true to re-enable the Claude call. Nothing below changes when it is false.
const API_ENABLED := false

const API_URL := "https://api.anthropic.com/v1/messages"
const MODEL := "claude-opus-5-5"
const TIMEOUT_SEC := 45.0
const MAX_TOKENS := 4000

const SYSTEM_PROMPT := """You are the closing voice of a game built on a design philosophy called Subjugated Dialectics.
Two poles clash every beat: a SYSTEM issues commands from its systematic objectives, a PERSONA obeys, negotiates or defies, and an AUDIENCE presses with public opinion.
The game ends either in synthesis (the tension held near a central balance Node) or without it.
You receive the record of one finished game. Write for the Audience:
- insight: 3 to 5 sentences interpreting what this particular clash revealed about subjugation and resistance in its era. Refer to concrete moments from the record. No bullet points.
- dilemma: one open question the outcome leaves unresolved, phrased so it cannot be answered with yes or no.
- art: a specification for an abstract radial artwork the game will draw. One bar per beat around a gear ring; bars point outward when the System led and inward when the Persona led; a central Node shows the balance.
  palette: exactly 3 hex colours (#RRGGBB) for obey, negotiate, defy, in that order.
  ring_color and node_color: hex colours. background_color: a dark hex colour.
  bar_scale: 0.3 to 2.0. rotation_deg: 0 to 360. ring_teeth: 8 to 48. title: a short title for the piece, at most 6 words.
Choose colours and parameters that express this game's mood. Write in English."""


var _http: HTTPRequest
var _fallback: Dictionary


## Fallback dictionary shape: {"text": String, "dilemma": String} from Insight.build().
func request(sim: DialecticSim, era_id: String, fallback: Dictionary) -> void:
	_fallback = fallback
	if not API_ENABLED:
		_finish_fallback.call_deferred("offline")
		return
	var key := OS.get_environment("ANTHROPIC_API_KEY")
	if key == "":
		_finish_fallback.call_deferred("no ANTHROPIC_API_KEY set")
		return
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SEC
	add_child(_http)
	_http.request_completed.connect(_on_completed)
	var headers := PackedStringArray([
		"content-type: application/json",
		"x-api-key: " + key,
		"anthropic-version: 2023-06-01",
		"anthropic-beta: server-side-fallback-2026-07-01",
	])
	var err := _http.request(API_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(build_body(sim, era_id)))
	if err != OK:
		_finish_fallback("request not sent (error %d)" % err)


func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		_finish_fallback("network failure (result %d)" % result)
		return
	var parsed := parse_response(code, body.get_string_from_utf8())
	if not parsed.ok:
		_finish_fallback(parsed.reason)
		return
	finished.emit({"source": "claude", "text": parsed.insight, "dilemma": parsed.dilemma, "art": parsed.art, "title": parsed.title, "reason": ""})


func _finish_fallback(reason: String) -> void:
	finished.emit({"source": "fallback", "text": _fallback.text, "dilemma": _fallback.dilemma, "art": default_art(), "title": "", "reason": reason})


# ---------- pure functions (tested offline in tests/claude_insight_test.gd) ----------

static func build_body(sim: DialecticSim, era_id: String) -> Dictionary:
	var rows: Array[String] = []
	for t in sim.trace:
		rows.append("%d %s %s grip=%+.2f public=%+.2f" % [t.beat, t.cmd, t.response, t.d, t.o])
	var record := "ERA: %s\nOUTCOME: %s after %d beats\nCOUNTS: obey %d, negotiate %d, defy %d\nFINAL: grip %+.2f (positive = System dominates), public %+.2f (positive = backs Persona)\nBEATS:\n%s" % [
		Eras.get_era(era_id).title, sim.outcome, sim.beat,
		sim.counts.obey, sim.counts.negotiate, sim.counts.defy,
		sim.dominance, sim.opinion, "\n".join(rows)]
	return {
		"model": MODEL,
		"max_tokens": MAX_TOKENS,
		"fallbacks": "default",
		"system": SYSTEM_PROMPT,
		"output_config": {"effort": "low", "format": {"type": "json_schema", "schema": SCHEMA}},
		"messages": [{"role": "user", "content": record}],
	}


const SCHEMA := {
	"type": "object",
	"additionalProperties": false,
	"required": ["insight", "dilemma", "art"],
	"properties": {
		"insight": {"type": "string"},
		"dilemma": {"type": "string"},
		"art": {
			"type": "object",
			"additionalProperties": false,
			"required": ["title", "palette", "ring_color", "node_color", "background_color", "bar_scale", "rotation_deg", "ring_teeth"],
			"properties": {
				"title": {"type": "string"},
				"palette": {"type": "array", "items": {"type": "string"}},
				"ring_color": {"type": "string"},
				"node_color": {"type": "string"},
				"background_color": {"type": "string"},
				"bar_scale": {"type": "number"},
				"rotation_deg": {"type": "number"},
				"ring_teeth": {"type": "integer"},
			},
		},
	},
}


## Returns {ok: true, insight, dilemma, title, art} or {ok: false, reason}.
static func parse_response(code: int, text: String) -> Dictionary:
	var j = JSON.parse_string(text)
	if typeof(j) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "HTTP %d, unreadable body" % code}
	if code != 200:
		var msg: String = j.get("error", {}).get("message", "") if typeof(j.get("error")) == TYPE_DICTIONARY else ""
		return {"ok": false, "reason": "HTTP %d %s" % [code, msg]}
	var stop: String = str(j.get("stop_reason", ""))
	if stop == "refusal":
		return {"ok": false, "reason": "model declined (refusal)"}
	if stop == "max_tokens":
		return {"ok": false, "reason": "response cut off (max_tokens)"}
	var out_text := ""
	for block in j.get("content", []):
		if typeof(block) == TYPE_DICTIONARY and block.get("type") == "text":
			out_text += str(block.get("text", ""))
	var data = JSON.parse_string(out_text)
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "no JSON in response"}
	var insight := str(data.get("insight", "")).strip_edges()
	var dilemma := str(data.get("dilemma", "")).strip_edges()
	if insight == "" or dilemma == "" or typeof(data.get("art")) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "missing fields"}
	var art := sanitize_art(data.art)
	if art.is_empty():
		return {"ok": false, "reason": "invalid art spec"}
	return {"ok": true, "insight": insight, "dilemma": dilemma, "title": str(data.art.get("title", "")).left(60), "art": art}


## Validates colours, clamps numbers. Returns {} if colours are unusable.
static func sanitize_art(a: Dictionary) -> Dictionary:
	var pal = a.get("palette")
	if typeof(pal) != TYPE_ARRAY or pal.size() < 3:
		return {}
	var colors: Array[Color] = []
	for i in 3:
		if not _is_hex(pal[i]):
			return {}
		colors.append(Color(pal[i]))
	for k in ["ring_color", "node_color", "background_color"]:
		if not _is_hex(a.get(k)):
			return {}
	return {
		"obey": colors[0], "negotiate": colors[1], "defy": colors[2],
		"ring": Color(a.ring_color), "node": Color(a.node_color), "bg": Color(a.background_color),
		"bar_scale": clampf(float(a.get("bar_scale", 1.0)), 0.3, 2.0),
		"rotation": deg_to_rad(fposmod(float(a.get("rotation_deg", 0.0)), 360.0)),
		"teeth": clampi(int(a.get("ring_teeth", 24)), 8, 48),
	}


static func default_art() -> Dictionary:
	return {
		"obey": Color("e0a030"), "negotiate": Color("7f95a8"), "defy": Color("b5472a"),
		"ring": Color("5c6166"), "node": Color("e0a030"), "bg": Color("141618"),
		"bar_scale": 1.0, "rotation": 0.0, "teeth": 24,
	}


static func _is_hex(v) -> bool:
	if typeof(v) != TYPE_STRING:
		return false
	var s: String = v
	if not s.begins_with("#") or s.length() != 7:
		return false
	return s.substr(1).is_valid_hex_number()
