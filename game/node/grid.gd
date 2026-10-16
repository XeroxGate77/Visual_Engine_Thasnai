class_name Grid
extends RefCounted
## NODE-RULES v0.3: the grip axis read as a 0–100% gauge split into 20 cells of 5%.
## gauge% = (grip + 1) * 50. Balance band = cells 9–10 = 45–55% (|grip| < 0.10). Warning line N2 (|grip| 0.5)
## falls on cell boundaries 25% / 75%.

const CELLS := 20
const CELL_PCT := 5.0
const BAND_LO_PCT := 45.0
const BAND_HI_PCT := 55.0
const BAND_HALF := (BAND_HI_PCT - BAND_LO_PCT) / 100.0 # 0.10 in grip units


static func gauge(grip: float) -> float:
	return (grip + 1.0) * 50.0


static func cell(grip: float) -> int:
	return clampi(int(floor(gauge(grip) / CELL_PCT)), 0, CELLS - 1)


## Strictly inside the band, like the engine's |grip| < band test.
static func in_band(grip: float) -> bool:
	return absf(grip) < BAND_HALF
