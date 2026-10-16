# C.D. sound demo — one real run, three sound worlds

**The run:** INDUSTRIAL · seed 35 · 17 beats (negotiate 13 · obey 2 · defy 2) · the Node acted 8 times · the Lens focused 8 times · **CONTRACT synthesis** · rarity **RARE** (long siege ≥ 16 beats).
Rebuild it in the viewer: the code is in `run.json`.

All three files use **the same mapping** (C.D. kit §6.4). Only the sound world changes.

| In the game | In the sound |
|---|---|
| each beat | one pulse (0.55 s) |
| obey (Command) | A: anvil strike · B: low pluck · C: kick + square bleep |
| negotiate (Care) | A: bowed metal, open fifth · B: soft major chord · C: consonant arpeggio |
| defy (Resistance) | A: noise burst + clang · B: minor-second cluster with tremolo · C: distorted detuned buzz |
| grip | left/right: System leads → right, Persona leads → left · farther from balance → more detuned (dissonant) |
| Node condition | a pedal drone under that beat (quieter when it is only "aiming") |
| Lens focus | a short bright shimmer, heard on the side of the pole that gets the disclosure |
| a new micro synthesis in the band | a chime |
| synthesis (end) | cadence · CONTRACT = heavy, held resolution (balance bought through power) |

| File | Sound world |
|---|---|
| `world_A_foundry.wav` | **A · FOUNDRY** — metal, noise, low drone (industrialistic) |
| `world_B_chamber.wav` | **B · CHAMBER** — plucked and bowed tones, harmony and cadence (acoustic-like) |
| `world_C_circuit.wav` | **C · CIRCUIT** — synth pulses, arpeggios, buzz (electronic) |

Checked (not by ear): same run → identical files · no silent beat · no clipping · panning follows grip on every beat where |grip| > 0.2.
Rebuild: `python3 game/tools/sound_demo.py docs/sound-demo/run.json docs/sound-demo/`
