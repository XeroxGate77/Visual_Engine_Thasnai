class_name GridLens
extends Lens
## Lens for NODE-RULES v0.3: L3 energy follows the Node's band, so with the grid band (45–55%) the Lens
## charges only inside that band. Every other Lens rule is inherited unchanged (lens.gd is not edited).

func end_beat(grip: float) -> void:
	if Grid.in_band(grip):
		energy = mini(energy + 1, ENERGY_CAP) # L3.1, L3.3
		out_streak = 0
	else:
		out_streak += 1 # L3.2
		if out_streak % HALVE_AFTER_OUT == 0: # L3.4 (confirmed reading)
			energy /= 2
