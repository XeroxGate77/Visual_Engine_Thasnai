extends Node
## Contact sheet of overlay styles from one code: tests/shots_visual/options_grok.png (needs a renderer; run via MCP run_project).
const CODE := "SD6.prehistoric.p.630470892.0..86a9b6c87654"
const PX := 512
func _ready() -> void:
	var dec := ReplayCode.decode(CODE)
	var sims: Array[DialecticSim] = [dec.sim]
	var s := NodeSimV4.new(7, 60, Eras.get_era("industrial").commands)
	s.run()
	sims.append(s)
	var presets := ["v1", "v2a", "g1", "g2", "g3"]
	var sheet := Image.create(PX * presets.size(), PX * sims.size(), false, Image.FORMAT_RGBA8)
	for r in sims.size():
		for c in presets.size():
			var img := await VisualEngine.render_frame(get_tree(), sims[r], 1.0, PX, presets[c])
			img.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(img, Rect2i(0, 0, PX, PX), Vector2i(c * PX, r * PX))
	sheet.save_png(ProjectSettings.globalize_path("res://tests/shots_visual/options_grok.png"))
	print("OPTIONS DONE")
	get_tree().quit()
