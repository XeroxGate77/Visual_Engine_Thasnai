class_name QrArt
extends RefCounted
## QR as part of the artwork. Every style keeps what a camera needs: dark modules on a light ground, square finder
## patterns, a quiet zone. Colours/shapes come from the piece itself. DRAFT styles for the owner to choose from.
##   "ink"     — square modules inked with the piece's colours, picked by the micro-node / register under each column
##   "dots"    — round modules (finder patterns stay square), same ink
##   "emblem"  — the QR set inside the piece's own gear ring: art around, QR at the centre

const PAPER := Color("efe7d4")
const INKS := [Color("2a2d31"), Color("7a2f1d"), Color("3a4a58"), Color("6a4a12")] # steel-black, rust, slate, umber (all dark)


static func render(q: QrEncoder, sim: DialecticSim, style: String, px: int, art: Image = null) -> Image:
	match style:
		"emblem":
			return _emblem(q, sim, px, art)
		_:
			return _modules(q, sim, style == "dots", px)


## Ink for module column x: from the micro-node under that part of the gauge (v0.4), else the beat register.
static func _ink(sim: DialecticSim, x: int, y: int, size: int) -> Color:
	if sim is NodeSimV4:
		var m: MicroGrid = (sim as NodeSimV4).micro
		var j := int(float(x) / size * MicroGrid.SIZE)
		var st: int = m.state[clampi(j, 0, MicroGrid.SIZE - 1)]
		if st != MicroGrid.EMPTY:
			return INKS[st] # T slate-black, A rust, S umber
	var t: Dictionary = sim.trace[(x + y) % sim.trace.size()] if sim.trace.size() > 0 else {"response": "obey"}
	return INKS[{"obey": 0, "negotiate": 2, "defy": 1}.get(t.response, 0)]


static func _is_finder(x: int, y: int, size: int) -> bool:
	return (x < 8 and y < 8) or (x >= size - 8 and y < 8) or (x < 8 and y >= size - 8)


static func _modules(q: QrEncoder, sim: DialecticSim, dots: bool, px: int) -> Image:
	var border := 4
	var cell := px / (q.size + border * 2)
	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	img.fill(PAPER)
	var off := (px - cell * q.size) / 2
	var m := q.matrix()
	for y in q.size:
		for x in q.size:
			if not m[y][x]:
				continue
			var col := INKS[0] if _is_finder(x, y, q.size) else _ink(sim, x, y, q.size)
			var r := Rect2i(off + x * cell, off + y * cell, cell, cell)
			if dots and not _is_finder(x, y, q.size):
				_circle(img, r.get_center(), cell * 0.46, col)
			else:
				img.fill_rect(r, col)
	return img


static func _emblem(q: QrEncoder, sim: DialecticSim, px: int, art: Image) -> Image:
	var img: Image
	if art != null:
		img = art.duplicate()
		img.resize(px, px, Image.INTERPOLATE_LANCZOS)
		img.convert(Image.FORMAT_RGB8)
	else:
		img = Image.create(px, px, false, Image.FORMAT_RGB8)
		img.fill(Color("141618"))
	# QR on a paper plate inside the ring (ArtView ring radius = 0.45 * 0.55 * px)
	var plate := int(px * 0.33)
	var qr := _modules(q, sim, false, plate)
	var at := Vector2i((px - plate) / 2, (px - plate) / 2)
	img.blit_rect(qr, Rect2i(Vector2i.ZERO, qr.get_size()), at)
	return img


static func _circle(img: Image, c: Vector2i, r: float, col: Color) -> void:
	var ri := int(ceil(r))
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			if dx * dx + dy * dy <= r * r:
				img.set_pixel(c.x + dx, c.y + dy, col)
