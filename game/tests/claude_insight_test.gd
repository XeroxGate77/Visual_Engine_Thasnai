extends SceneTree
## Offline tests for ClaudeInsight: request body, response parsing, fallback paths. No network.
## godot --headless --path game -s tests/claude_insight_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	if not cond:
		failures += 1
		print("FAIL ", label)
	else:
		print("ok   ", label)


func ok_body(art: Dictionary, stop := "end_turn") -> String:
	var payload := {"insight": "The line bent but held.", "dilemma": "Who sets the pace?", "art": art}
	return JSON.stringify({
		"stop_reason": stop,
		"content": [{"type": "thinking", "thinking": ""}, {"type": "text", "text": JSON.stringify(payload)}],
	})


func good_art() -> Dictionary:
	return {"title": "Rust Accord", "palette": ["#112233", "#445566", "#778899"], "ring_color": "#aabbcc",
		"node_color": "#ddeeff", "background_color": "#0a0a0a", "bar_scale": 5.0, "rotation_deg": 450, "ring_teeth": 100}


func _init() -> void:
	var sim := DialecticSim.new(7, 60, Eras.get_era("industrial").commands)
	sim.run()

	# request body
	var body := ClaudeInsight.build_body(sim, "industrial")
	check(body.model == "claude-opus-5-5", "model id")
	check(body.fallbacks == "default", "server-side fallbacks default")
	check(body.output_config.format.type == "json_schema", "structured output format")
	check(not JSON.stringify(body).contains("x-api-key"), "no key in body")
	check(body.messages[0].content.contains("INDUSTRIAL") and body.messages[0].content.contains("BEATS:"), "record has era + beats")

	# good response, numbers clamped
	var r := ClaudeInsight.parse_response(200, ok_body(good_art()))
	check(r.ok, "parses good response (skips thinking block)")
	if r.ok:
		check(r.art.bar_scale == 2.0, "bar_scale clamped to 2.0")
		check(r.art.teeth == 48, "teeth clamped to 48")
		check(is_equal_approx(r.art.rotation, deg_to_rad(90.0)), "rotation wrapped 450 -> 90")
		check(r.art.obey == Color("#112233"), "palette colour")
		check(r.title == "Rust Accord", "title")

	# failure paths -> ok false with a reason
	var bad_hex := good_art()
	bad_hex.palette = ["red", "#445566", "#778899"]
	check(not ClaudeInsight.parse_response(200, ok_body(bad_hex)).ok, "rejects non-hex colour")
	var short_pal := good_art()
	short_pal.palette = ["#112233"]
	check(not ClaudeInsight.parse_response(200, ok_body(short_pal)).ok, "rejects short palette")
	check(not ClaudeInsight.parse_response(200, ok_body(good_art(), "refusal")).ok, "refusal -> fallback")
	check(not ClaudeInsight.parse_response(200, ok_body(good_art(), "max_tokens")).ok, "max_tokens -> fallback")
	var e401 := ClaudeInsight.parse_response(401, JSON.stringify({"type": "error", "error": {"type": "authentication_error", "message": "invalid x-api-key"}}))
	check(not e401.ok and e401.reason.contains("401"), "HTTP 401 -> fallback with reason")
	check(not ClaudeInsight.parse_response(500, "<html>oops</html>").ok, "non-JSON body -> fallback")
	check(not ClaudeInsight.parse_response(200, JSON.stringify({"stop_reason": "end_turn", "content": [{"type": "text", "text": "not json"}]})).ok, "text not JSON -> fallback")
	check(not ClaudeInsight.parse_response(200, JSON.stringify({"stop_reason": "end_turn", "content": [{"type": "text", "text": "{\"insight\":\"x\"}"}]})).ok, "missing fields -> fallback")

	# no key -> fallback signal, no network
	OS.set_environment("ANTHROPIC_API_KEY", "")
	var ci := ClaudeInsight.new()
	root.add_child(ci)
	var got := {}
	ci.finished.connect(func(res: Dictionary) -> void: got.merge(res))
	ci.request(sim, "industrial", Insight.build(sim, "industrial"))
	await process_frame
	await process_frame
	var want_reason := "ANTHROPIC_API_KEY" if ClaudeInsight.API_ENABLED else "offline"
	check(got.get("source") == "fallback" and str(got.get("reason")).contains(want_reason), "no key / API off -> fallback")
	check(got.get("text", "") != "", "fallback carries scripted text")

	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
