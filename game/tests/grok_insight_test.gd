extends SceneTree
## Offline tests for GrokInsight: request bodies, chat + image parsing, fallback paths. No network.
## godot --headless --path game -s tests/grok_insight_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	print("ok   " if cond else "FAIL ", label)


func chat_body(payload: Dictionary, finish := "stop") -> String:
	return JSON.stringify({"choices": [{"finish_reason": finish, "message": {"role": "assistant", "content": JSON.stringify(payload), "refusal": null}}]})


func good_payload() -> Dictionary:
	return {"insight": "The line bent but held.", "dilemma": "Who sets the pace?", "image_prompt": "rusted gears in amber light",
		"art": {"title": "Rust Accord", "palette": ["#112233", "#445566", "#778899"], "ring_color": "#aabbcc",
			"node_color": "#ddeeff", "background_color": "#0a0a0a", "bar_scale": 1.2, "rotation_deg": 30, "ring_teeth": 20}}


func png_b64() -> String:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.ORANGE)
	return Marshalls.raw_to_base64(img.save_png_to_buffer())


func jpg_b64() -> String:
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	img.fill(Color.ORANGE)
	return Marshalls.raw_to_base64(img.save_jpg_to_buffer())


func _init() -> void:
	var sim := DialecticSim.new(7, 60, Eras.get_era("industrial").commands)
	sim.run()

	var body := GrokInsight.build_chat_body(sim, "industrial")
	check(body.model == "grok-4.7", "chat model id")
	check(body.response_format.type == "json_schema" and body.response_format.json_schema.strict, "strict json_schema")
	check("image_prompt" in body.response_format.json_schema.schema.required, "schema requires image_prompt")
	check(not ("image_prompt" in ClaudeInsight.SCHEMA.required), "Claude schema untouched")
	check(body.messages[1].content.contains("BEATS:"), "record sent")
	check(not JSON.stringify(body).to_lower().contains("bearer"), "no key in body")
	var ib := GrokInsight.build_image_body("x")
	check(ib.model == "grok-imagine-image-2.0" and ib.response_format == "b64_json" and ib.n == 1, "image body")

	var r := GrokInsight.parse_chat_response(200, chat_body(good_payload()))
	check(r.ok and r.image_prompt == "rusted gears in amber light" and r.art.teeth == 20, "parses good chat response")
	check(not GrokInsight.parse_chat_response(200, chat_body(good_payload(), "length")).ok, "length -> fallback")
	var no_prompt := good_payload()
	no_prompt.erase("image_prompt")
	check(not GrokInsight.parse_chat_response(200, chat_body(no_prompt)).ok, "missing image_prompt -> fallback")
	var refused := JSON.stringify({"choices": [{"finish_reason": "stop", "message": {"content": "", "refusal": "no"}}]})
	check(not GrokInsight.parse_chat_response(200, refused).ok, "refusal -> fallback")
	var e401 := GrokInsight.parse_chat_response(401, JSON.stringify({"error": "Incorrect API key provided"}))
	check(not e401.ok and e401.reason.contains("401") and e401.reason.contains("Incorrect"), "401 string error -> reason")
	check(not GrokInsight.parse_chat_response(502, "<html/>").ok, "non-JSON -> fallback")

	var ip := GrokInsight.parse_image_response(200, JSON.stringify({"data": [{"b64_json": png_b64()}]}))
	check(ip.ok and ip.image.get_width() == 4, "decodes PNG")
	var ij := GrokInsight.parse_image_response(200, JSON.stringify({"data": [{"b64_json": jpg_b64()}]}))
	check(ij.ok and ij.image.get_width() == 4, "decodes JPEG")
	check(not GrokInsight.parse_image_response(200, JSON.stringify({"data": [{"url": "https://x"}]})).ok, "url-only -> image fallback")
	check(not GrokInsight.parse_image_response(200, JSON.stringify({"data": [{"b64_json": Marshalls.utf8_to_base64("not an image")}]})).ok, "garbage bytes -> image fallback")
	check(not GrokInsight.parse_image_response(429, JSON.stringify({"error": {"message": "rate limited"}})).ok, "429 -> image fallback")

	OS.set_environment("XAI_API_KEY", "")
	var gi := GrokInsight.new()
	root.add_child(gi)
	var got := {}
	gi.finished.connect(func(res: Dictionary) -> void: got.merge(res))
	gi.request(sim, "industrial", Insight.build(sim, "industrial"))
	await process_frame
	await process_frame
	check(got.get("source") == "fallback" and str(got.get("reason")).contains("XAI_API_KEY"), "no key -> fallback")

	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
