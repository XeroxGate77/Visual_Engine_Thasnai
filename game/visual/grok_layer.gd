class_name GrokLayer
extends Control
## Visual Engine layers that translate the visual language seen in the Grok images (furnace light, rust ground,
## palette-knife grain, a fissure splitting the frame) into deterministic drawing. PROPOSALS — the owner picks.
## All randomness comes from a RandomNumberGenerator seeded with the piece's log hash, so same code => same pixels.
## `part` "under" is drawn BEFORE ArtView (ground, grain, glow); "top" after it (fissure).

var trace: Array = []
var synthesis := false
var reveal := 1.0
var spec: Dictionary = ClaudeInsight.default_art() # the real palette (ArtView gets a transparent bg)
var style := "furnace" # furnace · fissure · knife
var part := "under"
var seed_v := 1


static func palette(style_id: String) -> Dictionary:
	var s := ClaudeInsight.default_art()
	match style_id:
		"furnace":
			s.bg = Color("120d0b"); s.ring = Color("6b4632"); s.obey = Color("e0a030")
			s.negotiate = Color("c9b08a"); s.defy = Color("a8341f"); s.node = Color("ffb040")
		"knife":
			s.bg = Color("16110d"); s.ring = Color("7a5a45"); s.obey = Color("d98e2b")
			s.negotiate = Color("8c8f8a"); s.defy = Color("9c3a22"); s.node = Color("f0a63a")
		_: # fissure keeps the original steel/amber palette on a deeper ground
			s.bg = Color("0f1011")
	return s


func _draw() -> void:
	var n := trace.size()
	var c := size / 2.0
	var R := minf(size.x, size.y) * 0.45
	var p := clampf(float(int(ceil(n * reveal))) / maxf(n, 1.0), 0.0, 1.0) if n > 0 else 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	if part == "under":
		draw_rect(Rect2(Vector2.ZERO, size), spec.bg)
		if style == "knife":
			_knife(c, R, rng)
		if style != "fissure":
			_embers(c, R, rng, p)
		_glow(c, R, p)
	elif style == "fissure":
		_fissure(c, R, rng, n)


# furnace light behind the Node: many soft concentric discs; stronger at synthesis
func _glow(c: Vector2, R: float, p: float) -> void:
	var power := (1.0 if synthesis else 0.75) * p # g1 edit: a run that never reached the Node still keeps a warm light
	for k in 28:
		var f := 1.0 - float(k) / 28.0
		draw_circle(c, R * (0.10 + 0.034 * k), Color(spec.node, 0.045 * f * f * (0.3 + power)))


# sparks rising around the ring; count grows with the reveal
func _embers(c: Vector2, R: float, rng: RandomNumberGenerator, p: float) -> void:
	var total := 90
	for i in total:
		var a := rng.randf() * TAU
		var r := R * (0.5 + rng.randf() * 0.75)
		var sz := R * (0.003 + rng.randf() * 0.006)
		var al := 0.25 + rng.randf() * 0.6
		var pos := c + Vector2.from_angle(a) * r + Vector2(0, -R * 0.1 * rng.randf())
		if float(i) / total <= p:
			draw_circle(pos, sz, Color(spec.node, al))


# palette-knife grain: short flat strokes, mostly tangential, in ground / rust / dim amber
func _knife(c: Vector2, R: float, rng: RandomNumberGenerator) -> void:
	var tones: Array[Color] = [Color("2a1d15"), Color("3a2619"), Color(spec.defy, 0.8), Color(spec.obey, 0.6), Color("0c0907")]
	for i in 900:
		var a := rng.randf() * TAU
		var r := R * 1.3 * sqrt(rng.randf())
		var pos := c + Vector2.from_angle(a) * r
		var ang := a + PI / 2.0 + (rng.randf() - 0.5) * 0.3 # g3 edit: follow the ring
		var len_ := R * (0.025 + rng.randf() * 0.05)
		var w := R * (0.012 + rng.randf() * 0.03)
		var col: Color = tones[rng.randi() % tones.size()]
		col.a = 0.35 + rng.randf() * 0.3 # g3 edit: denser, more opaque
		var d := Vector2.from_angle(ang) * len_ * 0.5
		draw_line(pos - d, pos + d, col, w)


# a crack running top to bottom; its sideways offset is the grip of each beat; every defy throws a splinter
func _fissure(c: Vector2, R: float, rng: RandomNumberGenerator, n: int) -> void:
	var shown := int(ceil(n * reveal))
	if shown < 2:
		return
	var pts := PackedVector2Array()
	for i in shown:
		var t: Dictionary = trace[i]
		var y := c.y - R * 1.1 + 2.2 * R * float(i) / maxf(n - 1, 1.0)
		pts.append(Vector2(c.x + clampf(t.d, -1.0, 1.0) * R * 0.4 + (rng.randf() - 0.5) * R * 0.04, y))
	var w := maxf(1.0, R * 0.006)
	# colour sides: left of the crack = Persona (negotiate tone), right = System (obey tone), low alpha over the whole frame
	var y0 := pts[0].y
	var y1 := pts[pts.size() - 1].y
	var left := PackedVector2Array([Vector2(c.x - R * 1.6, y0)])
	var right := PackedVector2Array([Vector2(c.x + R * 1.6, y0)])
	left.append_array(pts)
	right.append_array(pts)
	left.append(Vector2(c.x - R * 1.6, y1))
	right.append(Vector2(c.x + R * 1.6, y1))
	if Geometry2D.triangulate_polygon(left).size() > 0:
		draw_colored_polygon(left, Color(spec.negotiate, 0.10))
	if Geometry2D.triangulate_polygon(right).size() > 0:
		draw_colored_polygon(right, Color(spec.obey, 0.10))
	draw_polyline(pts, Color(spec.bg, 0.85), w * 6.0, true)
	draw_polyline(pts, Color(spec.node, 0.85), w * 1.3, true)
	for i in shown:
		var resp: String = trace[i].response
		if resp == "defy" or (resp == "negotiate" and rng.randf() < 0.25):
			var strong := resp == "defy"
			var dir := Vector2(1.0 if rng.randf() < 0.5 else -1.0, (rng.randf() - 0.5) * 0.8).normalized()
			var len_ := R * ((0.08 + rng.randf() * 0.1) if strong else (0.03 + rng.randf() * 0.04))
			var tip := pts[i] + dir * len_
			draw_line(pts[i], tip, Color(spec.defy, 0.9 if strong else 0.45), w * (1.4 if strong else 0.8), true)
			if strong: # two sub-branches fork from the tip
				for k in 2:
					var d2 := dir.rotated((rng.randf() - 0.5) * 1.6)
					draw_line(tip, tip + d2 * len_ * (0.35 + rng.randf() * 0.4), Color(spec.defy, 0.7), w * 0.9, true)
