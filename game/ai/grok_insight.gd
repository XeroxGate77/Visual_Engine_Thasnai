class_name GrokInsight
extends Node
## End-of-game Insight + art spec + generated image from the xAI (Grok) API. Sits beside ClaudeInsight.
## Stage 1: chat completion (structured JSON) -> `finished` (same shape as ClaudeInsight.finished).
## Stage 2: image generation from the returned image_prompt -> `image_ready(tex)` or `image_failed(reason)`.
## Every failure keeps the scripted Insight / procedural art. Key: XAI_API_KEY env var only; never stored or logged.

signal finished(result: Dictionary)
signal image_ready(texture: Texture2D)
signal image_failed(reason: String)

const CHAT_URL := "https://api.x.ai/v1/chat/completions"
const IMAGE_URL := "https://api.x.ai/v1/images/generations"
const CHAT_MODEL := "grok-4.7"
const IMAGE_MODEL := "grok-imagine-image-2.0" # $0.04 per image (docs.x.ai, 2026-10)
const TIMEOUT_SEC := 60.0

const SYSTEM_PROMPT := ClaudeInsight.SYSTEM_PROMPT + """
- image_prompt: a prompt (at most 60 words) for an image model to paint this game's outcome as an abstract industrial-era artwork in the same mood and palette. No text or letters in the image."""

var _key := ""
var _fallback: Dictionary


func request(sim: DialecticSim, era_id: String, fallback: Dictionary) -> void:
	_fallback = fallback
	_key = OS.get_environment("XAI_API_KEY")
	if _key == "":
		_finish_fallback.call_deferred("no XAI_API_KEY set")
		return
	var err := _post(CHAT_URL, build_chat_body(sim, era_id), _on_chat_done)
	if err != OK:
		_finish_fallback("request not sent (error %d)" % err)


func _post(url: String, body: Dictionary, cb: Callable) -> int:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SEC
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _h: PackedStringArray, data: PackedByteArray) -> void:
		http.queue_free()
		cb.call(result, code, data))
	return http.request(url, PackedStringArray([
		"content-type: application/json",
		"authorization: Bearer " + _key,
	]), HTTPClient.METHOD_POST, JSON.stringify(body))


func _on_chat_done(result: int, code: int, data: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_finish_fallback("network failure (result %d)" % result)
		return
	var p := parse_chat_response(code, data.get_string_from_utf8())
	if not p.ok:
		_finish_fallback(p.reason)
		return
	finished.emit({"source": "grok", "text": p.insight, "dilemma": p.dilemma, "art": p.art, "title": p.title, "reason": ""})
	var err := _post(IMAGE_URL, build_image_body(p.image_prompt), _on_image_done)
	if err != OK:
		image_failed.emit("image request not sent (error %d)" % err)


func _on_image_done(result: int, code: int, data: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		image_failed.emit("image network failure (result %d)" % result)
		return
	var p := parse_image_response(code, data.get_string_from_utf8())
	if not p.ok:
		image_failed.emit(p.reason)
		return
	image_ready.emit(ImageTexture.create_from_image(p.image))


func _finish_fallback(reason: String) -> void:
	finished.emit({"source": "fallback", "text": _fallback.text, "dilemma": _fallback.dilemma, "art": ClaudeInsight.default_art(), "title": "", "reason": reason})


# ---------- pure functions (tested offline in tests/grok_insight_test.gd) ----------

const SCHEMA_EXTRA := {"image_prompt": {"type": "string"}}

static func schema() -> Dictionary:
	var s: Dictionary = ClaudeInsight.SCHEMA.duplicate(true)
	s.properties.merge(SCHEMA_EXTRA)
	s.required = s.required + ["image_prompt"]
	return s


static func build_chat_body(sim: DialecticSim, era_id: String) -> Dictionary:
	var record: String = ClaudeInsight.build_body(sim, era_id).messages[0].content
	return {
		"model": CHAT_MODEL,
		"messages": [{"role": "system", "content": SYSTEM_PROMPT}, {"role": "user", "content": record}],
		"response_format": {"type": "json_schema", "json_schema": {"name": "dialectic_insight", "schema": schema(), "strict": true}},
	}


static func build_image_body(prompt: String) -> Dictionary:
	return {"model": IMAGE_MODEL, "prompt": prompt, "n": 1, "response_format": "b64_json", "aspect_ratio": "1:1"}


## {ok, insight, dilemma, title, art, image_prompt} or {ok: false, reason}
static func parse_chat_response(code: int, text: String) -> Dictionary:
	var j = JSON.parse_string(text)
	if typeof(j) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "HTTP %d, unreadable body" % code}
	if code != 200:
		return {"ok": false, "reason": "HTTP %d %s" % [code, _err_msg(j)]}
	var choices = j.get("choices")
	if typeof(choices) != TYPE_ARRAY or choices.is_empty() or typeof(choices[0]) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "no choices"}
	var c: Dictionary = choices[0]
	if c.get("finish_reason") == "length":
		return {"ok": false, "reason": "response cut off (length)"}
	var msg = c.get("message", {})
	if typeof(msg) != TYPE_DICTIONARY or str(msg.get("refusal", "")) not in ["", "<null>"]:
		return {"ok": false, "reason": "model declined"}
	var data = JSON.parse_string(str(msg.get("content", "")))
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "no JSON in response"}
	var insight := str(data.get("insight", "")).strip_edges()
	var dilemma := str(data.get("dilemma", "")).strip_edges()
	var image_prompt := str(data.get("image_prompt", "")).strip_edges()
	if insight == "" or dilemma == "" or image_prompt == "" or typeof(data.get("art")) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "missing fields"}
	var art := ClaudeInsight.sanitize_art(data.art)
	if art.is_empty():
		return {"ok": false, "reason": "invalid art spec"}
	return {"ok": true, "insight": insight, "dilemma": dilemma, "title": str(data.art.get("title", "")).left(60), "art": art, "image_prompt": image_prompt.left(1000)}


## {ok, image: Image} or {ok: false, reason}. Accepts PNG, JPEG or WebP base64.
static func parse_image_response(code: int, text: String) -> Dictionary:
	var j = JSON.parse_string(text)
	if typeof(j) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "image HTTP %d, unreadable body" % code}
	if code != 200:
		return {"ok": false, "reason": "image HTTP %d %s" % [code, _err_msg(j)]}
	var items = j.get("data")
	if typeof(items) != TYPE_ARRAY or items.is_empty() or typeof(items[0]) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "image: no data"}
	var b64 := str(items[0].get("b64_json", ""))
	if b64 == "" or b64 == "<null>":
		return {"ok": false, "reason": "image: no b64_json"}
	var bytes := Marshalls.base64_to_raw(b64)
	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if bytes.size() > 4 and bytes[0] == 0x89 and bytes[1] == 0x50:
		err = img.load_png_from_buffer(bytes)
	elif bytes.size() > 3 and bytes[0] == 0xFF and bytes[1] == 0xD8:
		err = img.load_jpg_from_buffer(bytes)
	elif bytes.size() > 12 and bytes.slice(8, 12).get_string_from_ascii() == "WEBP":
		err = img.load_webp_from_buffer(bytes)
	if err != OK or img.is_empty():
		return {"ok": false, "reason": "image: undecodable"}
	return {"ok": true, "image": img}


static func _err_msg(j: Dictionary) -> String:
	var e = j.get("error")
	if typeof(e) == TYPE_DICTIONARY:
		return str(e.get("message", ""))
	if typeof(e) == TYPE_STRING:
		return e
	return ""
