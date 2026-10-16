extends Control
## Industrialistic UI: ERA -> ROLE -> PLAY -> INSIGHT (+ fallback art).
## Colours/typography are first-pass placeholders; look & feel is the owner's call.

const C_BG := Color("1b1d1f")
const C_PANEL := Color("26292c")
const C_STEEL := Color("5c6166")
const C_AMBER := Color("e0a030")
const C_RUST := Color("b5472a")
const C_TEXT := Color("d8d2c4")
const BEAT_DELAY := 1.0
const GROK_WEB_URL := "https://grok.com"

var era_id := ""
var role := ""
var sim: DialecticSim
var pending_audience := 0.0
var box: VBoxContainer
var timer: Timer
var cmd_title: Label
var cmd_text: Label
var beat_label: Label
var bar_sys: ProgressBar
var bar_pub: ProgressBar
var log_label: RichTextLabel
var actions: HBoxContainer
var art: ArtView
var oracle: GrokInsight
var image_prompt := ""
var copy_button: Button
var extract_button: Button
var lens_sim: LensSim # Lens layer (LENS-RULES v0.1); `sim` points at the same object
var pending_lens: Array = [] # human Audience: [target, fragment] for the next beat
var lens_box: VBoxContainer
var micro_gauge: MicroGauge
var node_sim: NodeSim # Node layer (NODE-RULES v0.1); lens_sim and sim point at the same object
var result_title: Label
var result_text: Label
var result_dilemma: Label
var result_note: Label


func _ready() -> void:
	theme = _make_theme()
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_next_beat)
	add_child(timer)
	_show_era()


# ---------- screens ----------

func _show_era() -> void:
	_clear()
	_title("SUBJUGATED DIALECTICS", 40, C_AMBER)
	_title("CHOOSE THE ERA OF THE DILEMMA", 18, C_STEEL)
	for id in Eras.ORDER:
		var e := Eras.get_era(id)
		var b := _button("%s  —  %s" % [e.title, e.blurb], _on_era.bind(id))
		b.custom_minimum_size = Vector2(0, 64)
		box.add_child(b)


func _show_role() -> void:
	_clear()
	_title(Eras.get_era(era_id).title, 32, C_AMBER)
	_title("CHOOSE YOUR POST", 18, C_STEEL)
	var roles := [
		["audience", "AUDIENCE  —  watch, and press with public opinion"],
		["persona", "PERSONA  —  obey, negotiate, or defy"],
		["system", "SYSTEM  —  issue the orders"],
	]
	for r in roles:
		var b := _button(r[1], _on_role.bind(r[0]))
		b.custom_minimum_size = Vector2(0, 64)
		box.add_child(b)
	box.add_child(_button("< BACK", _show_era))


func _show_play() -> void:
	_clear()
	beat_label = _title("", 18, C_STEEL)
	cmd_title = _title("", 30, C_AMBER)
	cmd_text = _title("", 18, C_TEXT)
	cmd_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bar_sys = _bar("SYSTEM GRIP  (grid: 20 cells of 5% · balance band 45–55% · warning lines 25% / 75% · micro-nodes: pale T · rust A · amber S)", C_RUST)
	bar_sys.add_child(GaugeGrid.new())
	micro_gauge = MicroGauge.new()
	if node_sim is NodeSimV4:
		micro_gauge.micro = (node_sim as NodeSimV4).micro
	bar_sys.add_child(micro_gauge)
	bar_pub = _bar("PUBLIC OPINION (toward Persona)", C_STEEL)
	lens_box = VBoxContainer.new()
	lens_box.add_theme_constant_override("separation", 6)
	box.add_child(lens_box)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(log_label)
	box.add_child(_button("AUTO-FINISH (scripted AI plays the rest)", _auto_finish))
	_refresh()
	_next_beat()


func _show_result() -> void:
	timer.stop()
	_clear()
	var ins := Insight.build(sim, era_id)
	result_title = _title("INSIGHT — %s" % Eras.get_era(era_id).title, 28, C_AMBER)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	art = ArtView.new()
	art.custom_minimum_size = Vector2(520, 520)
	art.trace = sim.trace
	art.synthesis = sim.outcome == "synthesis"
	art.reveal = 0.0
	row.add_child(art)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	var scroll := ScrollContainer.new() # the column outgrows 800px once Lens/Node lines are added
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	scroll.add_child(col)
	result_text = Label.new()
	result_text.text = ins.text
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(result_text)
	result_dilemma = Label.new()
	result_dilemma.text = ins.dilemma
	result_dilemma.add_theme_color_override("font_color", C_AMBER)
	result_dilemma.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(result_dilemma)
	result_note = Label.new()
	result_note.text = "CONSULTING GROK…  (showing scripted insight meanwhile)"
	result_note.add_theme_color_override("font_color", C_STEEL)
	result_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(result_note)
	if lens_sim != null:
		var dl := Label.new()
		dl.text = "DISCLOSURE (Lens %s): SYSTEM %d/6 %s · PERSONA %d/6 %s" % [Lens.RULES_VERSION,
			lens_sim.lens.disclosed("system"), "enough" if lens_sim.lens.enough("system") else "not enough",
			lens_sim.lens.disclosed("persona"), "enough" if lens_sim.lens.enough("persona") else "not enough"]
		dl.add_theme_color_override("font_color", C_STEEL)
		col.add_child(dl)
	if node_sim != null:
		var gr := Label.new()
		gr.text = GenderReading.build(node_sim)
		gr.add_theme_color_override("font_color", C_TEXT)
		gr.add_theme_font_size_override("font_size", 14)
		gr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(gr)
	image_prompt = ImagePrompt.build(sim, era_id)
	var pl := Label.new()
	pl.text = "IMAGE PROMPT (paste into Grok Imagine with your own account):\n" + image_prompt
	pl.add_theme_color_override("font_color", C_STEEL)
	pl.add_theme_font_size_override("font_size", 13)
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(pl)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 12)
	col.add_child(prow)
	copy_button = _button("COPY IMAGE PROMPT", _copy_image_prompt)
	prow.add_child(copy_button)
	prow.add_child(_button("OPEN GROK", func() -> void: OS.shell_open(GROK_WEB_URL)))
	if sim.outcome == "synthesis":
		extract_button = _button("EXTRACT FROM NODE → QR + NFT-READY (Desktop)", _extract_from_node)
		col.add_child(extract_button)
	else:
		var nx := Label.new()
		nx.text = "No synthesis — nothing to extract from the Node"
		nx.add_theme_color_override("font_color", C_STEEL)
		col.add_child(nx)
	col.add_child(_button("AGAIN", _show_era))
	_reveal_art()
	if oracle != null:
		oracle.queue_free()
	oracle = GrokInsight.new()
	add_child(oracle)
	oracle.finished.connect(_on_oracle_finished.bind(sim))
	oracle.image_ready.connect(_on_oracle_image.bind(sim))
	oracle.image_failed.connect(_on_oracle_image_failed.bind(sim))
	oracle.request(sim, era_id, ins)


func _on_oracle_finished(r: Dictionary, for_sim: DialecticSim) -> void:
	if for_sim != sim or not is_instance_valid(result_note):
		return # player already moved on
	if r.source == "grok":
		result_text.text = r.text
		result_dilemma.text = "OUTPUT DILEMMA: " + r.dilemma
		if r.title != "":
			result_title.text = "%s — %s" % [Eras.get_era(era_id).title, r.title.to_upper()]
		result_note.text = "insight + art spec by Grok (%s) · painting image…" % GrokInsight.CHAT_MODEL
		art.spec = r.art
		_reveal_art()
	else:
		result_note.text = "(fallback art — scripted insight: %s)" % r.reason


func _on_oracle_image(tex: Texture2D, for_sim: DialecticSim) -> void:
	if for_sim != sim or not is_instance_valid(art):
		return
	var pic := TextureRect.new()
	pic.texture = tex
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.modulate.a = 0.0
	art.add_child(pic)
	create_tween().tween_property(pic, "modulate:a", 1.0, 1.5)
	result_note.text = "insight by Grok (%s) · image by %s" % [GrokInsight.CHAT_MODEL, GrokInsight.IMAGE_MODEL]


func _on_oracle_image_failed(reason: String, for_sim: DialecticSim) -> void:
	if for_sim != sim or not is_instance_valid(result_note):
		return
	result_note.text = "insight by Grok (%s) · procedural art (image failed: %s)" % [GrokInsight.CHAT_MODEL, reason]


## Writes the mint-ready folder (art, QR, replay code, metadata). root "" = Desktop/Subjugated Dialectics NFT.
func _extract_from_node(root := "") -> Dictionary:
	# 2048² render straight from the run's trace (same as rebuilding it from its replay code), not a screen grab
	var img: Image = await HiresRender.render(get_tree(), sim, HiresRender.DEFAULT_PX, art.spec)
	var r := NftPackage.write(sim, era_id, role, img, {"text": result_text.text, "dilemma": result_dilemma.text},
		root if root != "" else NftPackage.default_root())
	result_note.text = ("extracted → " + r.dir) if r.ok else ("extract failed: " + r.reason)
	if r.ok and is_instance_valid(extract_button):
		extract_button.text = "EXTRACTED ✓"
	return r


func _copy_image_prompt() -> void:
	DisplayServer.clipboard_set(image_prompt)
	copy_button.text = "COPIED ✓"


func _reveal_art() -> void:
	art.reveal = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		art.reveal = v
		art.queue_redraw(), 0.0, 1.0, 2.5)


# ---------- flow ----------

func _on_era(id: String) -> void:
	era_id = id
	_show_role()


func _on_role(r: String) -> void:
	role = r
	node_sim = NodeSimV4.new(int(Time.get_ticks_usec()) & 0x7fffffff, 60, Eras.get_era(era_id).commands) # NODE-RULES v0.4 (micro-nodes)
	lens_sim = node_sim
	sim = node_sim
	pending_audience = 0.0
	pending_lens = []
	if role == "audience":
		sim.audience_chooser = func(_s: DialecticSim) -> float: return pending_audience
		lens_sim.lens_chooser = func(_s: DialecticSim) -> Array:
			var p := pending_lens
			pending_lens = []
			return p
	_show_play()


func _next_beat() -> void:
	if sim.ended:
		_show_result()
		return
	_clear_children(actions)
	match role:
		"audience":
			var cmd := sim.begin_beat()
			_show_command(cmd)
			sim.finish_beat()
			_after_beat()
			_audience_buttons()
			timer.start(BEAT_DELAY)
		"persona":
			var cmd := sim.begin_beat()
			_show_command(cmd)
			var invited := node_sim.cond_kind == "invite"
			if invited:
				cmd_text.text += "\nNODE INVITES YOU TO NEGOTIATE — accept with NEGOTIATE, or refuse with OBEY / DEFY."
			actions.add_child(_button("OBEY", _on_persona_response.bind(DialecticSim.OBEY)))
			actions.add_child(_button("NEGOTIATE (accept Node)" if invited else "NEGOTIATE", _on_persona_response.bind(DialecticSim.NEGOTIATE)))
			actions.add_child(_button("DEFY", _on_persona_response.bind(DialecticSim.DEFY)))
		"system":
			cmd_title.text = "WAITING FOR YOUR ORDER"
			cmd_text.text = "Pick a command. The Persona will answer."
			if node_sim.cond_kind == "sys":
				cmd_text.text += "\nNODE CONDITION: only orders that pull grip back toward balance are open."
			elif node_sim.cond_kind == "invite":
				cmd_text.text += "\nNODE has invited the Persona to negotiate this beat."
			beat_label.text = "%s  ·  SYSTEM  ·  BEAT %d" % [Eras.get_era(era_id).title, sim.beat + 1]
			for i in sim.commands.size():
				var b := _button(sim.commands[i].name, _on_system_order.bind(i))
				b.tooltip_text = sim.commands[i].text
				if node_sim.cond_kind == "sys" and not (i in node_sim.allowed):
					b.disabled = true
					b.tooltip_text = "Node: this order pushes grip away from balance"
				actions.add_child(b)


func _on_persona_response(response: String) -> void:
	_clear_children(actions)
	sim.finish_beat(response)
	_after_beat()
	timer.start(BEAT_DELAY)


func _on_system_order(idx: int) -> void:
	_clear_children(actions)
	var cmd := sim.begin_beat(idx)
	_show_command(cmd)
	sim.finish_beat()
	_after_beat()
	timer.start(BEAT_DELAY)


func _audience_buttons() -> void:
	var opts := [["FAVOR SYSTEM", -0.2], ["STAY NEUTRAL", 0.0], ["FAVOR PERSONA", 0.2]]
	for o in opts:
		var b := _button(o[0], _set_pressure.bind(o[1]))
		b.toggle_mode = true
		b.button_pressed = is_equal_approx(pending_audience, o[1])
		actions.add_child(b)


func _set_pressure(v: float) -> void:
	pending_audience = v
	_clear_children(actions)
	_audience_buttons()


func _auto_finish() -> void:
	timer.stop()
	while not sim.ended:
		sim.step()
	_show_result()


func _show_command(cmd: Dictionary) -> void:
	beat_label.text = "%s  ·  %s  ·  BEAT %d" % [Eras.get_era(era_id).title, role.to_upper(), sim.beat]
	cmd_title.text = cmd.name
	cmd_text.text = cmd.text


func _after_beat() -> void:
	var t: Dictionary = sim.trace.back()
	var col := "e0a030" if t.response == "obey" else ("7f95a8" if t.response == "negotiate" else "b5472a")
	var lens_note := ""
	var ev: String = t.get("lens", "")
	if ev != "":
		var bits := ev.trim_prefix("lens=").split(":")
		lens_note = "   LENS → %s %s (%s)" % [bits[0].to_upper(), bits[1].to_upper(), ["hidden", "blur", "clear"][int(bits[2])]]
	var nev: String = t.get("node", "")
	var aim_tag := " (aim)" if nev.ends_with("|aim") else ""
	if nev.begins_with("node=sys"):
		lens_note += "   NODE: orders restricted" + aim_tag
	elif nev != "":
		lens_note += "   NODE: invitation " + nev.trim_suffix("|aim").get_slice(":", 1) + aim_tag
	log_label.append_text("[color=#%s]%02d  %s → %s   grip %d%%   public %+.2f%s[/color]\n" % [col, t.beat, t.cmd, t.response.to_upper(), roundi(Grid.gauge(t.d)), t.o, lens_note])
	_refresh()


# ---------- helpers ----------

func _refresh() -> void:
	bar_sys.value = (sim.dominance + 1.0) * 50.0
	bar_pub.value = (sim.opinion + 1.0) * 50.0
	_refresh_lens()


## Node gate status + the Lens view for this role (L4.3 Audience sees levels only; L7.2 a pole sees the other pole).
func _refresh_lens() -> void:
	if not is_instance_valid(lens_box) or lens_sim == null:
		return
	_clear_children(lens_box)
	var l := lens_sim.lens
	var gate := Label.new()
	gate.text = "NODE GATE   ① grip held %d/%d   ② disclosure: SYSTEM %s  PERSONA %s      LENS ENERGY %d/%d" % [
		mini((node_sim as NodeSimV3).grid_streak if node_sim is NodeSimV3 else sim.balance_streak, DialecticSim.BALANCE_HOLD), DialecticSim.BALANCE_HOLD,
		"ENOUGH" if l.enough("system") else "not yet", "ENOUGH" if l.enough("persona") else "not yet",
		l.energy, Lens.ENERGY_CAP]
	if node_sim is NodeSimV4:
		gate.text = gate.text.replace("   ② disclosure", " + micro S in band %d (need %d)   ② disclosure" % [(node_sim as NodeSimV4).micro.count_in_band(MicroGrid.SYNTHESIS), (node_sim as NodeSimV4).micro_need])
	if is_instance_valid(micro_gauge):
		micro_gauge.queue_redraw()
	if node_sim != null and node_sim.cond_kind != "":
		gate.text += "      NODE NEXT: " + ("restricts orders" if node_sim.cond_kind == "sys" else "invites Persona")
		if node_sim is NodeSimV2 and (node_sim as NodeSimV2).next_is_aim:
			gate.text += " (aiming for balance)"
	gate.add_theme_color_override("font_color", C_STEEL)
	gate.add_theme_font_size_override("font_size", 14)
	lens_box.add_child(gate)
	if role == "audience":
		for target in ["system", "persona"]:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var cap := Label.new()
			cap.text = "LENS → %s" % target.to_upper()
			cap.custom_minimum_size.x = 160
			row.add_child(cap)
			for f in Lens.FRAGMENTS[target]:
				var lv := l.level(target, f)
				var b := _button("%s  %s" % [f.to_upper(), ["hidden", "blur", "clear"][lv]], _set_lens.bind(target, f))
				b.toggle_mode = true
				b.button_pressed = pending_lens == [target, f]
				b.disabled = not l.can_focus(target, f) and not b.button_pressed
				row.add_child(b)
			lens_box.add_child(row)
	else:
		var other := "system" if role == "persona" else "persona"
		var values: Dictionary = sim.system_obj if other == "system" else sim.persona
		var parts: Array[String] = []
		for f in Lens.FRAGMENTS[other]:
			parts.append("%s %s" % [f.to_upper(), Lens.view(l.level(other, f), values[f])])
		var seen := Label.new()
		seen.text = "YOU SEE OF %s (through the Audience's Lens):   %s" % [other.to_upper(), "   ·   ".join(parts)]
		seen.add_theme_color_override("font_color", C_AMBER)
		lens_box.add_child(seen)


func _set_lens(target: String, frag: String) -> void:
	pending_lens = [] if pending_lens == [target, frag] else [target, frag]
	_refresh_lens()


func _clear() -> void:
	_clear_children(box)


func _clear_children(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func _title(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	box.add_child(l)
	return l


func _bar(caption: String, color: Color) -> ProgressBar:
	var l := Label.new()
	l.text = caption
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", C_STEEL)
	box.add_child(l)
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 18)
	b.value = 50.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	b.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = C_PANEL
	back.set_border_width_all(1)
	back.border_color = C_STEEL
	b.add_theme_stylebox_override("background", back)
	box.add_child(b)
	return b


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b


func _make_theme() -> Theme:
	var t := Theme.new()
	t.set_color("font_color", "Label", C_TEXT)
	t.set_font_size("font_size", "Label", 16)
	t.set_font_size("font_size", "Button", 18)
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_AMBER)
	t.set_color("font_pressed_color", "Button", C_AMBER)
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 14)
	t.set_stylebox("normal", "Button", _btn_style(C_PANEL, C_STEEL))
	t.set_stylebox("hover", "Button", _btn_style(C_PANEL, C_AMBER))
	t.set_stylebox("pressed", "Button", _btn_style(Color("33302a"), C_AMBER))
	t.set_stylebox("focus", "Button", _btn_style(C_PANEL, C_AMBER))
	return t


func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(2)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s
