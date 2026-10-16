class_name GaugeGrid
extends Control
## Overlay for the SYSTEM GRIP bar (NODE-RULES v0.3): 20 cells of 5%, the 45–55% balance band, the 50% centre,
## and the 25% / 75% warning lines. Purely visual; mouse passes through.

const C_TICK := Color(0.85, 0.82, 0.77, 0.25)
const C_BAND := Color(0.878, 0.627, 0.188, 0.28)
const C_WARN := Color(0.71, 0.28, 0.16, 0.7)
const C_CENTRE := Color(0.878, 0.627, 0.188, 0.9)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw) # first draw can happen before the bar has its final height


func _draw() -> void:
	var w := size.x
	var h := size.y
	var x := func(pct: float) -> float: return w * pct / 100.0
	draw_rect(Rect2(x.call(Grid.BAND_LO_PCT), 0, x.call(Grid.BAND_HI_PCT) - x.call(Grid.BAND_LO_PCT), h), C_BAND)
	for i in range(1, Grid.CELLS):
		draw_line(Vector2(x.call(i * Grid.CELL_PCT), 0), Vector2(x.call(i * Grid.CELL_PCT), h), C_TICK, 1.0)
	for pct in [25.0, 75.0]:
		draw_line(Vector2(x.call(pct), 0), Vector2(x.call(pct), h), C_WARN, 2.0)
	draw_line(Vector2(x.call(50.0), -3), Vector2(x.call(50.0), h + 3), C_CENTRE, 2.0)
