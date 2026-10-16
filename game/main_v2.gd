extends "res://main.gd"
## MAIN v2 — the same game (main.gd, locked, untouched) with ERA PACKS: the era menu lists the built-in eras and
## every valid pack in res://era_packs/ and user://era_packs/. Only the functions that looked an era up in the
## built-in table are overridden here; their bodies are main.gd's with the lookup swapped for the registry.
## On a built-in era every text, code and file is exactly what main.gd produces (EraText / ReplayCodePack /
## NftPackagePack hand built-in eras to the original code).

var era_dirs: Array = EraRegistry.DIRS # tests may point this elsewhere before the node enters the tree
var eras: EraRegistry


func _ready() -> void:
	eras = EraRegistry.scan(era_dirs)
	super._ready()


func _era() -> Dictionary:
	return eras.get_era(era_id)


func _show_era() -> void:
	_clear()
	_title("SUBJUGATED DIALECTICS", 40, C_AMBER)
	_title("CHOOSE THE ERA OF THE DILEMMA", 18, C_STEEL)
	for id in eras.order:
		var e := eras.get_era(id)
		var tag := "   [ERA PACK]" if eras.is_pack(id) else ""
		var b := _button("%s  —  %s%s" % [e.title, e.blurb, tag], _on_era.bind(id))
		b.custom_minimum_size = Vector2(0, 64)
		box.add_child(b)
	if not eras.rejected.is_empty():
		var l := _title("%d era pack file(s) not loaded — check them with tools/check_era_pack.gd" % eras.rejected.size(), 13, C_RUST)
		l.tooltip_text = "\n".join(eras.rejected.map(func(r: Dictionary) -> String: return "%s: %s" % [r.file.get_file(), r.errors[0]]))
		l.mouse_filter = Control.MOUSE_FILTER_PASS


func _show_role() -> void:
	_clear()
	_title(_era().title, 32, C_AMBER)
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


func _show_result() -> void:
	timer.stop()
	_clear()
	var ins := EraText.insight(sim, era_id, _era())
	result_title = _title("INSIGHT — %s" % _era().title, 28, C_AMBER)
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
	var scroll := ScrollContainer.new()
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
	if eras.is_pack(era_id):
		var pk := Label.new()
		pk.text = "ERA PACK: %s · content %s" % [era_id, eras.hashes[era_id].left(8)]
		pk.add_theme_color_override("font_color", C_STEEL)
		col.add_child(pk)
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
	image_prompt = EraText.image_prompt(sim, era_id, _era())
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
	var o := GrokInsightPack.new()
	oracle = o
	add_child(o)
	o.finished.connect(_on_oracle_finished.bind(sim))
	o.image_ready.connect(_on_oracle_image.bind(sim))
	o.image_failed.connect(_on_oracle_image_failed.bind(sim))
	o.request_era(sim, era_id, _era(), ins)


func _on_oracle_finished(r: Dictionary, for_sim: DialecticSim) -> void:
	if for_sim != sim or not is_instance_valid(result_note):
		return
	if r.source == "grok":
		result_text.text = r.text
		result_dilemma.text = "OUTPUT DILEMMA: " + r.dilemma
		if r.title != "":
			result_title.text = "%s — %s" % [_era().title, r.title.to_upper()]
		result_note.text = "insight + art spec by Grok (%s) · painting image…" % GrokInsight.CHAT_MODEL
		art.spec = r.art
		_reveal_art()
	else:
		result_note.text = "(fallback art — scripted insight: %s)" % r.reason


func _extract_from_node(root := "") -> Dictionary:
	var img: Image = await HiresRender.render(get_tree(), sim, HiresRender.DEFAULT_PX, art.spec)
	var r := NftPackagePack.write(sim, era_id, role, img, {"text": result_text.text, "dilemma": result_dilemma.text},
		root if root != "" else NftPackage.default_root(), eras)
	result_note.text = ("extracted → " + r.dir) if r.ok else ("extract failed: " + r.reason)
	if r.ok and is_instance_valid(extract_button):
		extract_button.text = "EXTRACTED ✓"
	return r


func _on_role(r: String) -> void:
	role = r
	node_sim = NodeSimV4.new(int(Time.get_ticks_usec()) & 0x7fffffff, 60, _era().commands) # NODE-RULES v0.4
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
	if sim.ended or role != "system":
		super._next_beat() # audience / persona / end: main.gd's flow (its era lookups go through _show_command / _show_result)
		return
	_clear_children(actions)
	cmd_title.text = "WAITING FOR YOUR ORDER"
	cmd_text.text = "Pick a command. The Persona will answer."
	if node_sim.cond_kind == "sys":
		cmd_text.text += "\nNODE CONDITION: only orders that pull grip back toward balance are open."
	elif node_sim.cond_kind == "invite":
		cmd_text.text += "\nNODE has invited the Persona to negotiate this beat."
	beat_label.text = "%s  ·  SYSTEM  ·  BEAT %d" % [_era().title, sim.beat + 1]
	for i in sim.commands.size():
		var b := _button(sim.commands[i].name, _on_system_order.bind(i))
		b.tooltip_text = sim.commands[i].text
		if node_sim.cond_kind == "sys" and not (i in node_sim.allowed):
			b.disabled = true
			b.tooltip_text = "Node: this order pushes grip away from balance"
		actions.add_child(b)


func _show_command(cmd: Dictionary) -> void:
	beat_label.text = "%s  ·  %s  ·  BEAT %d" % [_era().title, role.to_upper(), sim.beat]
	cmd_title.text = cmd.name
	cmd_text.text = cmd.text
