class_name ArtView
extends Control
## Procedural art: one radial bar per beat around a gear ring, a central balance Node.
## Bar outward = System led that beat, inward = Persona led. Colour = Persona's response.
## `spec` comes from ClaudeInsight (Claude's art spec, or default_art() as the fallback look).

var trace: Array = []
var synthesis := false
var reveal := 1.0 # 0..1, animate by tweening
var spec: Dictionary = ClaudeInsight.default_art()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), spec.bg)
	var c := size / 2.0
	var R := minf(size.x, size.y) * 0.45
	var r0 := R * 0.55
	var rot: float = spec.rotation
	# gear ring + rivets
	draw_arc(c, r0, 0.0, TAU, 96, spec.ring, 3.0, true)
	var teeth: int = spec.teeth
	for i in teeth:
		var a := TAU * i / float(teeth) + rot
		draw_circle(c + Vector2.from_angle(a) * (r0 + 7.0), 2.5, spec.ring)
	var n := trace.size()
	var shown := int(ceil(n * reveal))
	for i in shown:
		var t: Dictionary = trace[i]
		var a := TAU * i / maxf(n, 1.0) - PI / 2.0 + rot
		var col: Color = spec.obey
		if t.response == "negotiate":
			col = spec.negotiate
		elif t.response == "defy":
			col = spec.defy
		var len_: float = (absf(t.d) * R * 0.45 + 4.0) * spec.bar_scale
		var dir := Vector2.from_angle(a)
		var from := c + dir * r0
		var to := c + dir * maxf(r0 * 0.15, r0 + len_ * (1.0 if t.d > 0.0 else -1.0))
		draw_line(from, to, col, maxf(2.0, R * 2.0 * PI / maxf(n, 1.0) * 0.5), true)
	# balance Node
	var last_d: float = trace.back().d if n > 0 else 0.0
	var node_r := R * 0.12 * (1.0 - clampf(absf(last_d), 0.0, 1.0) * 0.5)
	var node_col: Color = spec.node if synthesis else spec.ring
	if synthesis:
		draw_circle(c, node_r * 1.9, Color(node_col, 0.15))
	draw_circle(c, node_r, node_col)
	draw_arc(c, node_r * 1.3, 0.0, TAU, 48, node_col, 2.0, true)
