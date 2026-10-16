extends Control
## Thasnai Visual Engine — studio page. Pick a replay code (or a random preview), pick a preset, scrub or play the
## reveal. Pure UI over VisualEngine; nothing in the engine is touched. Text is ASCII only (web build has no system font).

const SAMPLE := "SD6.prehistoric.p.630470892.0..86a9b6c87654"
const PLAY_SEC := 6.0
const DEFAULT_PRESET := "v2a"
const C_BG := Color("1b1d1f")
const C_PANEL := Color("26292c")
const C_TEXT := Color("d8d2c4")
const C_AMBER := Color("e0a030")
const C_RUST := Color("b5472a")

var eras: EraRegistry
var sim: DialecticSim
var holder: Control
var view: Control
var input: LineEdit
var preset_pick: OptionButton
var slider: HSlider
var status: Label
var play_tween: Tween
var reveal := 1.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	eras = EraRegistry.scan(["res://era_packs"])
	rng.randomize()
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 16)
	add_child(row)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(420, 0)
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	side.add_child(_label("THASNAI VISUAL ENGINE v0.1", C_AMBER, 22))
	side.add_child(_label("Rebuilds a piece from its replay code, then renders it. Preset v1 = the locked ArtView; v2 adds the overlay (PROPOSAL, owner decides the look).", C_TEXT, 13))
	input = LineEdit.new()
	input.text = SAMPLE
	input.placeholder_text = "paste a replay code (SD1 - SD7)"
	input.text_submitted.connect(func(_t: String) -> void: _load_code())
	side.add_child(input)
	var b1 := HBoxContainer.new()
	side.add_child(b1)
	b1.add_child(_button("REBUILD", _load_code))
	b1.add_child(_button("RANDOM PREVIEW", _random_preview))
	preset_pick = OptionButton.new()
	for p in VisualEngine.PRESETS:
		preset_pick.add_item(p)
	preset_pick.select(VisualEngine.PRESETS.find(DEFAULT_PRESET)) # owner picked A (quiet) 2026-10-16
	preset_pick.item_selected.connect(func(_i: int) -> void: _rebuild_view())
	side.add_child(_label("PRESET", C_TEXT, 12))
	side.add_child(preset_pick)
	side.add_child(_label("REVEAL", C_TEXT, 12))
	slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.001
	slider.value = 1.0
	slider.value_changed.connect(_on_slider)
	side.add_child(slider)
	var b2 := HBoxContainer.new()
	side.add_child(b2)
	b2.add_child(_button("PLAY", _play))
	b2.add_child(_button("SHOW ALL", func() -> void: _set_reveal(1.0)))
	status = _label("", C_TEXT, 13)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(400, 0)
	side.add_child(status)
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	frame.add_theme_stylebox_override("panel", sb)
	row.add_child(frame)
	holder = Control.new()
	holder.clip_contents = true
	holder.resized.connect(_fit_view)
	frame.add_child(holder)
	_load_code()


func _label(t: String, c: Color, sz: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", c)
	l.add_theme_font_size_override("font_size", sz)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _button(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(cb)
	return b


func _load_code() -> void:
	var r := ReplayCodePack.decode(input.text.strip_edges(), eras)
	if not r.ok:
		status.text = "NOT AN AUTHENTIC PIECE: " + str(r.reason)
		status.add_theme_color_override("font_color", C_RUST)
		return
	sim = r.sim
	status.add_theme_color_override("font_color", C_AMBER)
	status.text = "AUTHENTIC - log hash %s matches.\n%s - played as %s - %s after %d beats" % [
		str(r.hash).left(16), str(r.era).to_upper(), str(r.role).to_upper(), sim.outcome.replace("_", " ").to_upper(), sim.beat]
	_set_reveal(1.0)
	_rebuild_view()


func _random_preview() -> void:
	var ids: Array = Eras.ORDER
	var era_id: String = ids[rng.randi() % ids.size()]
	var seed_v := rng.randi() % 1000000000
	var s := NodeSimV4.new(seed_v, 60, Eras.get_era(era_id).commands)
	s.run()
	sim = s
	status.add_theme_color_override("font_color", C_TEXT)
	status.text = "RANDOM PREVIEW - %s seed %d - %s after %d beats. Not a replay code (no human inputs recorded)." % [
		era_id.to_upper(), seed_v, sim.outcome.replace("_", " ").to_upper(), sim.beat]
	_set_reveal(1.0)
	_rebuild_view()


func _rebuild_view() -> void:
	if sim == null:
		return
	if view != null:
		view.queue_free()
	view = VisualEngine.make_view(sim, 512, reveal, VisualEngine.PRESETS[preset_pick.selected])
	holder.add_child(view)
	_fit_view()


func _fit_view() -> void:
	if view == null:
		return
	var s := minf(holder.size.x, holder.size.y)
	view.position = (holder.size - Vector2(s, s)) / 2.0
	view.size = Vector2(s, s)
	for ch in view.get_children():
		ch.position = Vector2.ZERO
		ch.size = Vector2(s, s)
		ch.queue_redraw()


func _set_reveal(v: float) -> void:
	reveal = v
	if slider != null and not is_equal_approx(slider.value, v):
		slider.set_value_no_signal(v)
	if view != null:
		for ch in view.get_children():
			ch.reveal = v
			ch.queue_redraw()


func _on_slider(v: float) -> void:
	if play_tween != null:
		play_tween.kill()
	_set_reveal(v)


func _play() -> void:
	if play_tween != null:
		play_tween.kill()
	_set_reveal(0.0)
	play_tween = create_tween()
	play_tween.tween_method(_set_reveal, 0.0, 1.0, PLAY_SEC)
