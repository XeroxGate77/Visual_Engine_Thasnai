class_name VisualOverlay
extends Control
## Visual Engine v2 overlay: extra layers drawn ON TOP of the locked ArtView, same geometry, same trace.
## Pure function of (trace, synthesis, reveal, spec, size) — no RNG, so same code => same pixels.
## Layers: grip seismograph (inside the gear ring) · balance-band guides · public-opinion dots · synthesis halo.

const BAND := 0.15 # engine balance band |grip| (CD.md §4)

var trace: Array = []
var synthesis := false
var reveal := 1.0
var spec: Dictionary = ClaudeInsight.default_art()
var style := "" # "" = v2 as first shown; "a" quiet · "b" seismic · "c" instrument (PROPOSALS, owner picks)


func _draw() -> void:
	var n := trace.size()
	if n == 0:
		return
	var c := size / 2.0
	var R := minf(size.x, size.y) * 0.45
	var r0 := R * 0.55
	var rot: float = spec.rotation
	var base := r0 * 0.82
	var amp := r0 * 0.12
	var w := maxf(1.0, R * 0.006)
	var ring: Color = spec.ring
	# balance band guides (grip within ±BAND)
	draw_arc(c, base + amp * BAND, 0.0, TAU, 128, Color(ring, 0.35), w, true)
	draw_arc(c, base - amp * BAND, 0.0, TAU, 128, Color(ring, 0.35), w, true)
	var shown := int(ceil(n * reveal))
	match style:
		"a": _style_a(c, R, base, amp, rot, n, shown, w)
		"b": _style_b(c, R, base, amp, rot, n, shown, w)
		"c": _style_c(c, R, r0, base, amp, rot, n, shown, w)
		_: _style_v2(c, R, base, amp, rot, n, shown, w)
	# synthesis halo: only when the Node was reached and the reveal has finished the run
	if synthesis and shown >= n:
		for k in 3:
			draw_arc(c, R * (0.16 + 0.07 * k), 0.0, TAU, 64, Color(spec.node, 0.35 - 0.1 * k), w * 1.5, true)


func _ang(i: int, n: int, rot: float) -> float:
	return TAU * i / maxf(n, 1.0) - PI / 2.0 + rot


func _grip_pts(c: Vector2, base: float, amp: float, rot: float, n: int, shown: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in shown:
		pts.append(c + Vector2.from_angle(_ang(i, n, rot)) * (base + clampf(trace[i].d, -1.0, 1.0) * amp))
	return pts


# v2 as first shown: grip line + big opinion dots at R*1.07 (dot size grows with |opinion|)
func _style_v2(c: Vector2, R: float, base: float, amp: float, rot: float, n: int, shown: int, w: float) -> void:
	var pts := _grip_pts(c, base, amp, rot, n, shown)
	if pts.size() >= 2:
		draw_polyline(pts, Color(spec.node, 0.85), w * 1.6, true)
	for i in shown:
		var t: Dictionary = trace[i]
		var o := clampf(t.o, -1.0, 1.0)
		var col: Color = spec.negotiate if o > 0.0 else spec.obey
		draw_circle(c + Vector2.from_angle(_ang(i, n, rot)) * (R * 1.07), w * (1.0 + absf(o) * 3.0), Color(col, 0.35 + 0.65 * absf(o)))


# A quiet: same grip line; opinion = small dots on one fixed circle, only opacity carries the value
func _style_a(c: Vector2, R: float, base: float, amp: float, rot: float, n: int, shown: int, w: float) -> void:
	var pts := _grip_pts(c, base, amp, rot, n, shown)
	if pts.size() >= 2:
		draw_polyline(pts, Color(spec.node, 0.85), w * 1.6, true)
	draw_arc(c, R * 1.05, 0.0, TAU, 128, Color(spec.ring, 0.2), w, true)
	for i in shown:
		var o := clampf(trace[i].o, -1.0, 1.0)
		var col: Color = spec.negotiate if o > 0.0 else spec.obey
		draw_circle(c + Vector2.from_angle(_ang(i, n, rot)) * (R * 1.05), w * 1.6, Color(col, 0.2 + 0.8 * absf(o)))


# B seismic: grip becomes a filled area against the band; opinion is a second wave line outside the ring
func _style_b(c: Vector2, R: float, base: float, amp: float, rot: float, n: int, shown: int, w: float) -> void:
	var pts := _grip_pts(c, base, amp, rot, n, shown)
	if pts.size() >= 3:
		var poly := PackedVector2Array()
		for i in shown:
			poly.append(c + Vector2.from_angle(_ang(i, n, rot)) * base)
		for i in range(shown - 1, -1, -1):
			poly.append(pts[i])
		for i in shown - 1:
			var quad := PackedVector2Array([c + Vector2.from_angle(_ang(i, n, rot)) * base, c + Vector2.from_angle(_ang(i + 1, n, rot)) * base, pts[i + 1], pts[i]])
			if Geometry2D.triangulate_polygon(quad).size() > 0:
				draw_colored_polygon(quad, Color(spec.node, 0.28))
		draw_polyline(pts, Color(spec.node, 0.9), w * 1.4, true)
	var wave := PackedVector2Array()
	for i in shown:
		wave.append(c + Vector2.from_angle(_ang(i, n, rot)) * (R * 1.08 + clampf(trace[i].o, -1.0, 1.0) * R * 0.07))
	if wave.size() >= 2:
		draw_polyline(wave, Color(spec.negotiate, 0.8), w * 1.2, true)
	draw_arc(c, R * 1.08, 0.0, TAU, 128, Color(spec.ring, 0.2), w, true)


# C instrument: grip as per-beat gauge cells inside the ring; opinion as radial ticks outside (length = |opinion|)
func _style_c(c: Vector2, R: float, r0: float, base: float, amp: float, rot: float, n: int, shown: int, w: float) -> void:
	var step := TAU / maxf(n, 1.0)
	for i in shown:
		var a := _ang(i, n, rot)
		var d := clampf(trace[i].d, -1.0, 1.0)
		var inner := base
		var outer := base + d * amp
		draw_arc(c, (inner + outer) / 2.0, a - step * 0.4, a + step * 0.4, 6, Color(spec.node, 0.9), maxf(w, absf(outer - inner)), true)
		var o := clampf(trace[i].o, -1.0, 1.0)
		var col: Color = spec.negotiate if o > 0.0 else spec.obey
		var dir := Vector2.from_angle(a)
		draw_line(c + dir * R * 1.02, c + dir * (R * 1.02 + absf(o) * R * 0.12 + w), Color(col, 0.85), w * 1.2, true)
