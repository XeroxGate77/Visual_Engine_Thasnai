extends "res://main_v2.gd"
## MAIN v3 = main_v2 (unchanged) + AUTO MODE + GALLERY.
## AUTO MODE: the game runs itself — run after run, rotating through every era (built-in + era packs), the scripted
## AI in every seat. Anyone watching can TAKE THE AUDIENCE SEAT: from the next run they press and focus the Lens as in
## an Audience game; LEAVE THE SEAT hands it back to the AI. Every synthesis goes to the GALLERY (codes only).
## Extracting a piece (QR + NFT-ready, BLACKBOX edition) stays a deliberate click — never automatic.
## Grok is NOT called in auto mode (one paid call per run).
## Owner 2026-10-16: the auto result and the gallery show the insight texts (Insight + output dilemma) with the art,
## code and rarity. (A "no insight" version was tried the same day and reverted by the owner.)
## Pacing numbers are first-pass placeholders — feel is the owner's call.

var auto_beat := 0.6    # seconds per beat while the AI plays every seat
var auto_pause := 6.0   # seconds a finished run stays on screen before the next one
var gallery_path := AutoGallery.DEFAULT_PATH # tests may point this elsewhere before the node enters the tree
var in_auto := false
var human_seat := false # takes effect at the start of the next run
var runner: AutoRunner
var gallery: AutoGallery
var run_info: Dictionary = {}
var last_entry: Dictionary = {}
var pause_timer: Timer
var seat_button: Button

## PUBLIC build (export feature tag "public" — the builds other people play). Owner 2026-10-16: players MAY extract,
## without the creator signature: their pieces are labelled "Extracted by: player" (PlayerExtract) and numbered in
## their own ledger. On the web the piece folder is downloaded as a .zip. Players also get the code + OPEN IN VIEWER.
const PUBLIC_FEATURE := "public"
var public_build := OS.has_feature(PUBLIC_FEATURE) # tests may set it before the node enters the tree

## Owner 2026-10-16 (second call): AUTO MODE and GALLERY are back in the menu — AUTO first, GALLERY last.
var offer_auto := true
## Owner 2026-10-16: menu order AUTO -> PRE-HISTORIC -> INDUSTRIAL -> POST-TRUTH (display only — Eras.ORDER, codes
## and the auto rotation are unchanged).
const MENU_ORDER := ["prehistoric", "industrial", "posttruth"]


func _ready() -> void:
	gallery = AutoGallery.new(gallery_path)
	pause_timer = Timer.new()
	pause_timer.one_shot = true
	pause_timer.timeout.connect(_auto_next)
	add_child(pause_timer)
	super._ready()


# ---------- menu ----------

func _show_era() -> void:
	_clear()
	_title("SUBJUGATED DIALECTICS", 40, C_AMBER)
	_title("CHOOSE THE ERA OF THE DILEMMA", 18, C_STEEL)
	if offer_auto:
		var a := _button("AUTO MODE  —  the AI plays every seat, run after run · take the Audience seat any time", _auto_start)
		a.custom_minimum_size = Vector2(0, 64)
		box.add_child(a)
	var ids: Array = MENU_ORDER.filter(func(id: String) -> bool: return eras.has(id))
	for id in eras.order:
		if not id in ids:
			ids.append(id) # era packs after the built-in eras, in registry order
	for id in ids:
		var e := eras.get_era(id)
		var tag := "   [ERA PACK]" if eras.is_pack(id) else ""
		var b := _button("%s  —  %s%s" % [e.title, e.blurb, tag], _on_era.bind(id))
		b.custom_minimum_size = Vector2(0, 64)
		box.add_child(b)
	if not eras.rejected.is_empty():
		var l := _title("%d era pack file(s) not loaded — check them with tools/check_era_pack.gd" % eras.rejected.size(), 13, C_RUST)
		l.tooltip_text = "\n".join(eras.rejected.map(func(r: Dictionary) -> String: return "%s: %s" % [r.file.get_file(), r.errors[0]]))
		l.mouse_filter = Control.MOUSE_FILTER_PASS
	if offer_auto:
		var g := _button("GALLERY  —  %d syntheses reached in auto mode" % gallery.entries.size(), _show_gallery.bind(false))
		box.add_child(g)


# ---------- auto loop ----------

func _auto_start() -> void:
	in_auto = true
	if runner == null:
		runner = AutoRunner.new(eras, int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec())
	_auto_next()


func _auto_stop() -> void:
	in_auto = false
	timer.stop()
	pause_timer.stop()
	_show_era()


func _auto_next() -> void:
	timer.stop()
	pause_timer.stop()
	if not in_auto:
		return
	run_info = runner.next_run()
	era_id = run_info.era
	role = "audience" if human_seat else "auto"
	node_sim = run_info.sim
	lens_sim = node_sim
	sim = node_sim
	pending_audience = 0.0
	pending_lens = []
	if role == "audience": # same wiring as an Audience game (main.gd _on_role)
		sim.audience_chooser = func(_s: DialecticSim) -> float: return pending_audience
		lens_sim.lens_chooser = func(_s: DialecticSim) -> Array:
			var p := pending_lens
			pending_lens = []
			return p
	_show_play()
	_auto_bar(0)


## AUTO status line + controls, inserted at `at` in the screen.
func _auto_bar(at: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var st := Label.new()
	st.text = "AUTO · RUN #%d · %s · AUDIENCE: %s · GALLERY %d" % [run_info.index + 1, _era().title,
		"YOU" if role == "audience" else "AI", gallery.entries.size()]
	st.add_theme_color_override("font_color", C_AMBER)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(st)
	seat_button = _button("", _toggle_seat)
	_seat_text()
	row.add_child(seat_button)
	row.add_child(_button("GALLERY", _show_gallery.bind(true)))
	row.add_child(_button("EXIT AUTO", _auto_stop))
	box.add_child(row)
	box.move_child(row, at)


func _toggle_seat() -> void:
	human_seat = not human_seat
	_seat_text()


func _seat_text() -> void:
	if not is_instance_valid(seat_button):
		return
	if human_seat:
		seat_button.text = "LEAVE THE SEAT" + ("" if role == "audience" else "  (you hold it from the next run)")
	else:
		seat_button.text = "TAKE THE AUDIENCE SEAT" + ("  (AI takes it from the next run)" if role == "audience" else "  (from the next run)")


## The AI in every seat: one beat per tick. Everything else is main.gd's flow.
func _next_beat() -> void:
	if not (in_auto and role == "auto") or sim.ended:
		super._next_beat()
		return
	_clear_children(actions)
	var cmd := sim.begin_beat()
	_show_command(cmd)
	sim.finish_beat()
	_after_beat()
	timer.start(auto_beat)


## A spectator sees the Lens as the Audience does (levels only), without buttons to press.
func _refresh_lens() -> void:
	if role != "auto":
		super._refresh_lens()
		return
	role = "audience"
	super._refresh_lens()
	role = "auto"
	if is_instance_valid(lens_box):
		for row in lens_box.get_children():
			for c in row.get_children():
				if c is Button:
					c.disabled = true


func _show_result() -> void:
	if not in_auto:
		super._show_result()
		if public_build:
			if is_instance_valid(extract_button) and OS.has_feature("web"):
				extract_button.text = "EXTRACT FROM NODE → QR + NFT-READY (download .zip)"
			_share_row(result_note.get_parent() as VBoxContainer, ReplayCodePack.encode(sim, era_id, role, eras))
		return
	timer.stop()
	last_entry = runner.entry(sim as NodeSimV4, era_id, role)
	var added := gallery.add(last_entry)
	_piece_screen(sim, last_entry, "ADDED TO THE GALLERY" if added else ("already in the gallery" if not last_entry.is_empty() else "no synthesis — nothing for the gallery"), true)
	pause_timer.start(auto_pause)


# ---------- piece screen (auto result and gallery) ----------

func _piece_screen(s: DialecticSim, e: Dictionary, note: String, live: bool) -> void:
	_clear()
	if live:
		_auto_bar(0)
	var ins := EraText.insight(s, era_id, _era())
	result_title = _title("%s — %s" % [_era().title, "SYNTHESIS" if s.outcome == "synthesis" else "NO SYNTHESIS"], 26, C_AMBER)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	art = ArtView.new()
	art.custom_minimum_size = Vector2(480, 480)
	art.trace = s.trace
	art.synthesis = s.outcome == "synthesis"
	row.add_child(art)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	scroll.add_child(col)
	result_text = _col_label(col, ins.text, C_TEXT, 15)
	result_dilemma = _col_label(col, ins.dilemma, C_AMBER, 15)
	if not e.is_empty():
		var rar := Rarity.of(s) # computed from the piece (older gallery entries may lack type / reason)
		_col_label(col, "RARITY %s: %s%s · %s synthesis · %d beats · audience: %s\n%s" % [Rarity.VERSION, rar.tier,
			(" · " + rar.reason) if rar.reason != "" else "", (s as NodeSim).synthesis_type.to_upper(), e.beats,
			"human" if e.seat == "audience" else "AI", e.code], C_STEEL, 13)
	result_note = _col_label(col, note, C_STEEL, 13)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	col.add_child(btns)
	extract_button = null
	if public_build:
		_share_row(col, e.get("code", "") if not e.is_empty() else ReplayCodePack.encode(sim, era_id, "persona" if role == "auto" else role, eras))
	if s.outcome == "synthesis":
		extract_button = _button("EXTRACT → QR + NFT-READY (%s)" % ("download .zip" if OS.has_feature("web") else "Desktop"), _extract_piece)
		btns.add_child(extract_button)
	if live:
		btns.add_child(_button("STAY ON THIS PIECE", func() -> void:
			pause_timer.stop()
			result_note.text += "  ·  paused — press NEXT RUN to continue"))
		btns.add_child(_button("NEXT RUN", _auto_next))
	else:
		btns.add_child(_button("< GALLERY", _show_gallery.bind(false)))
	art.reveal = 1.0 if not live else 0.0
	if live:
		_reveal_art()


## main.gd's reveal, but the tween belongs to the art node, so it dies with it (auto mode moves on mid-reveal).
func _reveal_art() -> void:
	art.reveal = 0.0
	var a := art
	var tw := a.create_tween()
	tw.tween_method(func(v: float) -> void:
		a.reveal = v
		a.queue_redraw(), 0.0, 1.0, 2.5)


## Public builds: the replay code and a link that opens the piece rebuilding itself in the web viewer.
func _share_row(col: VBoxContainer, code: String) -> void:
	if code == "" or col == null:
		return
	_col_label(col, "REPLAY CODE (anyone can rebuild and verify this run in the viewer):\n" + code, C_STEEL, 13)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_button("OPEN IN VIEWER", func() -> void: OS.shell_open(NftPackage.qr_payload(code))))
	row.add_child(_button("COPY CODE", func() -> void: DisplayServer.clipboard_set(code)))
	col.add_child(row)


func _col_label(col: VBoxContainer, text: String, color: Color, size_px: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size_px)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(l)
	return l


## main_v2's extract; an auto run is written as its canonical Persona code (see AutoRunner).
func _extract_piece() -> void:
	pause_timer.stop()
	await _extract_from_node()


func _extract_from_node(root := "") -> Dictionary:
	var saved := role
	if role == "auto": # an auto run is written as its canonical Persona code
		role = "persona"
	if root == "" and OS.has_feature("web"):
		root = PlayerExtract.WEB_ROOT # a browser cannot write to the Desktop
	var r: Dictionary = await super._extract_from_node(root)
	role = saved
	if r.ok and public_build:
		PlayerExtract.mark(r.dir)
	if r.ok and OS.has_feature("web"):
		var zip_name: String = str(r.dir).get_file() + ".zip"
		var bytes := PlayerExtract.zip_folder(r.dir, "user://_zip".path_join(zip_name))
		if bytes.is_empty():
			r = {"ok": false, "reason": "could not pack the .zip"}
		else:
			JavaScriptBridge.download_buffer(bytes, zip_name, "application/zip")
			r.dir = zip_name
	if is_instance_valid(result_note):
		result_note.text = (("downloaded " if OS.has_feature("web") else "extracted → ") + r.dir) if r.ok else ("extract failed: " + r.reason)
		if r.ok and public_build:
			result_note.text += "  ·  player extract, unsigned (not a creator edition)"
	return r


# ---------- gallery ----------

func _show_gallery(from_auto: bool) -> void:
	timer.stop()
	pause_timer.stop()
	in_auto = false # leaving a run; BACK resumes auto with a new run if we came from it
	_clear()
	_title("GALLERY — %d syntheses" % gallery.entries.size(), 30, C_AMBER)
	_title("by rarity %s · by era %s · newest first · codes are rebuilt when shown" % [str(gallery.count_by("rarity")), str(gallery.count_by("title"))], 13, C_STEEL)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	var shown := 0
	for i in range(gallery.entries.size() - 1, -1, -1):
		if shown >= 36:
			break
		shown += 1
		var e: Dictionary = gallery.entries[i]
		var cell := VBoxContainer.new()
		var r := ReplayCodePack.decode(e.code, eras)
		if r.ok:
			var thumb := ArtView.new()
			thumb.custom_minimum_size = Vector2(170, 170)
			thumb.trace = r.sim.trace
			thumb.synthesis = true
			thumb.reveal = 1.0
			cell.add_child(thumb)
			var b := _button("%s · %s" % [e.title, e.rarity], _open_piece.bind(e))
			b.add_theme_font_size_override("font_size", 13)
			cell.add_child(b)
		else:
			var l := Label.new()
			l.text = "%s\ncannot rebuild: %s" % [e.title, r.reason]
			l.custom_minimum_size = Vector2(170, 170)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cell.add_child(l)
		grid.add_child(cell)
	var back := HBoxContainer.new()
	back.add_theme_constant_override("separation", 12)
	box.add_child(back)
	if from_auto:
		back.add_child(_button("< BACK TO AUTO (new run)", _auto_start))
	back.add_child(_button("MENU", _show_era))


func _open_piece(e: Dictionary) -> void:
	var r := ReplayCodePack.decode(e.code, eras)
	if not r.ok:
		return
	sim = r.sim
	node_sim = r.sim
	lens_sim = r.sim
	era_id = r.era
	role = r.role
	_piece_screen(sim, e, "rebuilt from its code · log hash %s…" % r.hash.left(16), false)
