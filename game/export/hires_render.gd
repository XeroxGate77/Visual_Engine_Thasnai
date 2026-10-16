class_name HiresRender
extends RefCounted
## Renders a finished game's artwork offscreen at high resolution, straight from its trace (so from its replay
## code), instead of capturing the screen. Uses the locked ArtView as-is. Needs a running SceneTree with a renderer
## (windowed or web; not --headless).

const DEFAULT_PX := 2048


## await HiresRender.render(get_tree(), sim) -> Image (square, px × px)
static func render(tree: SceneTree, sim: DialecticSim, px := DEFAULT_PX, spec: Dictionary = {}) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(px, px)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var art := ArtView.new()
	art.custom_minimum_size = Vector2(px, px)
	art.trace = sim.trace
	art.synthesis = sim.outcome == "synthesis"
	art.reveal = 1.0
	if not spec.is_empty():
		art.spec = spec
	vp.add_child(art)
	tree.root.add_child.call_deferred(vp) # deferred: root may be busy adding children (e.g. called from _ready)
	await tree.process_frame
	art.size = Vector2(px, px) # set after entering the tree, or the Control can keep a zero size
	art.queue_redraw()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img
