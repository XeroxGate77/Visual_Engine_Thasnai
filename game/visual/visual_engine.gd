class_name VisualEngine
extends RefCounted
## Thasnai Visual Engine v0.1 — renders a finished game's trace as a still or a frame sequence.
## Sits BESIDE the locked engine: ArtView / HiresRender are used as-is. Preset "v1" = ArtView only (identical to
## HiresRender); preset "v2" = ArtView + VisualOverlay. Needs a running SceneTree with a renderer (not --headless).

const PRESETS := ["v1", "v2", "v2a", "v2b", "v2c", "g1", "g2", "g3"] # v2a/b/c, g1/g2/g3 = PROPOSALS (g = Grok visual language)
const GROK := {"g1": "furnace", "g2": "fissure", "g3": "knife"}
const DEFAULT_PX := 2048


## Builds the view for one frame. `reveal` 0..1 = how much of the run is shown (animation time).
static func make_view(sim: DialecticSim, px: int, reveal := 1.0, preset := "v2", spec: Dictionary = {}) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(px, px)
	if GROK.has(preset):
		var st: String = GROK[preset]
		var pal := GrokLayer.palette(st) if spec.is_empty() else spec
		var seed_v := int(("0x" + sim.log_hash().left(8)).hex_to_int())
		for part in ["under", "art", "top"]:
			if part == "art":
				var art_g := ArtView.new()
				art_g.trace = sim.trace
				art_g.synthesis = sim.outcome == "synthesis"
				art_g.reveal = reveal
				art_g.spec = pal.duplicate()
				art_g.spec.bg = Color(0, 0, 0, 0) # the under layer paints the ground
				root.add_child(art_g)
			elif part == "under" or st == "fissure":
				var gl := GrokLayer.new()
				gl.trace = sim.trace
				gl.synthesis = sim.outcome == "synthesis"
				gl.reveal = reveal
				gl.spec = pal
				gl.style = st
				gl.part = part
				gl.seed_v = seed_v
				root.add_child(gl)
		return root
	var art := ArtView.new()
	art.trace = sim.trace
	art.synthesis = sim.outcome == "synthesis"
	art.reveal = reveal
	if not spec.is_empty():
		art.spec = spec
	root.add_child(art)
	if preset.begins_with("v2"):
		var ov := VisualOverlay.new()
		ov.style = preset.substr(2)
		ov.trace = sim.trace
		ov.synthesis = art.synthesis
		ov.reveal = reveal
		ov.spec = art.spec
		root.add_child(ov)
	return root


## await VisualEngine.render_frame(get_tree(), sim, reveal, px, preset) -> Image (square)
static func render_frame(tree: SceneTree, sim: DialecticSim, reveal := 1.0, px := DEFAULT_PX, preset := "v2", spec: Dictionary = {}) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(px, px)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var view := make_view(sim, px, reveal, preset, spec)
	vp.add_child(view)
	tree.root.add_child.call_deferred(vp)
	await tree.process_frame
	for ch in view.get_children():
		ch.size = Vector2(px, px) # after entering the tree, or the Control can keep a zero size
		ch.queue_redraw()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


## Reveal value of frame i of n (1 beat per step of the run, eased out; last frame = exactly 1.0).
static func reveal_at(i: int, n: int) -> float:
	if n <= 1:
		return 1.0
	var x := clampf(float(i) / float(n - 1), 0.0, 1.0)
	return 1.0 - (1.0 - x) * (1.0 - x)


## await VisualEngine.render_sequence(...) -> Array[Image]; write them yourself (PNG) with save_png.
static func render_sequence(tree: SceneTree, sim: DialecticSim, frames := 30, px := 512, preset := "v2", spec: Dictionary = {}) -> Array[Image]:
	var out: Array[Image] = []
	for i in frames:
		out.append(await render_frame(tree, sim, reveal_at(i, frames), px, preset, spec))
	return out
