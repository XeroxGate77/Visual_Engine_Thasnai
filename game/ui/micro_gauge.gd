class_name MicroGauge
extends Control
## NODE-RULES v0.4 overlay for the SYSTEM GRIP bar: the 100 micro-nodes as a strip along the bar's bottom edge.
## T thesis = pale, A antithesis = rust, S synthesis = amber. Purely visual; sits beside GaugeGrid (v0.3).

const C_T := Color(0.85, 0.82, 0.77, 0.75)
const C_A := Color(0.85, 0.30, 0.18, 1.0)
const C_S := Color(1.0, 0.75, 0.25, 1.0)

var micro: MicroGrid


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	if micro == null:
		return
	var w := size.x / MicroGrid.SIZE
	var h := maxf(4.0, size.y * 0.35)
	for j in MicroGrid.SIZE:
		var st: int = micro.state[j]
		if st == MicroGrid.EMPTY:
			continue
		var col: Color = [C_T, C_T, C_A, C_S][st]
		draw_rect(Rect2(j * w + 0.5, size.y - h, maxf(1.0, w - 1.0), h), col)
