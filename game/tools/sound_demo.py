"""C.D. SOUND demo: renders ONE real run (docs/sound-demo/run.json) through the same mapping in three sound worlds.
Deterministic: the noise seed comes from the run's log hash, so the same run always gives the same files.
Pure Python (wave + math), no extra packages.
    python3 game/tools/sound_demo.py docs/sound-demo/run.json docs/sound-demo/

Mapping (C.D. kit §6.4, same for every world):
  beat                -> one pulse (0.55 s)
  obey / negotiate / defy -> Command / Care / Resistance voice of the world
  grip                -> stereo pan (System leads = right, Persona leads = left) + detune of the second voice
                         (farther from balance = more dissonant)
  Node condition      -> a pedal drone under that beat (aim = softer)
  Lens focus          -> a short bright shimmer on the opposite side
  micro S in band up  -> a chime
  synthesis           -> cadence at the end (CONTRACT: heavy unison then tonic; CARE: open chord; EMERGENT: plain tonic)
"""
import json, math, random, struct, sys, wave
from pathlib import Path

SR = 44100
BEAT = 0.55
CODA = 3.2


class Mix:
    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.l = [0.0] * self.n
        self.r = [0.0] * self.n

    def add(self, start, dur, fn, pan=0.0, gain=1.0):
        a = max(0, int(start * SR))
        b = min(self.n, int((start + dur) * SR))
        gl = gain * math.cos((pan + 1) * math.pi / 4)
        gr = gain * math.sin((pan + 1) * math.pi / 4)
        for i in range(a, b):
            t = (i - a) / SR
            v = fn(t, dur)
            self.l[i] += v * gl
            self.r[i] += v * gr

    def write(self, path):
        peak = max(1e-9, max(max(abs(x) for x in self.l), max(abs(x) for x in self.r)))
        k = 0.89 / peak
        with wave.open(str(path), "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(b"".join(struct.pack("<hh", int(self.l[i] * k * 32767), int(self.r[i] * k * 32767)) for i in range(self.n)))


def env(t, dur, a=0.005, rel=0.08):
    if t < a:
        return t / a
    if t > dur - rel:
        return max(0.0, (dur - t) / rel)
    return 1.0


def expdec(t, rate):
    return math.exp(-t * rate)


# ---------------- the three worlds ----------------

def world_foundry(rng):
    base = 55.0
    def command(det):  # anvil strike: inharmonic partials, fast decay
        ps = [(1.0, 1.0), (2.76, 0.6), (5.40, 0.4), (8.93, 0.25)]
        return lambda t, d: sum(a * math.sin(2 * math.pi * base * 4 * p * det ** k * t) for k, (p, a) in enumerate(ps)) * expdec(t, 9) * 0.5
    def care(det):     # bowed metal: slow attack, consonant fifth
        return lambda t, d: (math.sin(2 * math.pi * base * 3 * t) + 0.7 * math.sin(2 * math.pi * base * 4.5 * det * t)) * min(1, t / 0.25) * env(t, d, rel=0.2) * 0.35
    def resist(det):   # noise burst + detuned clang
        return lambda t, d: ((rng.random() * 2 - 1) * expdec(t, 14) * 0.6 + math.sin(2 * math.pi * base * 6.1 * det * t) * math.sin(2 * math.pi * base * 6.5 * t) * expdec(t, 6)) * 0.55
    def drone(soft):
        return lambda t, d: sum(math.sin(2 * math.pi * base * h * t) / h for h in range(1, 7)) * env(t, d, a=0.05, rel=0.1) * (0.12 if soft else 0.2)
    def chime():
        return lambda t, d: math.sin(2 * math.pi * 1760 * t) * expdec(t, 5) * 0.25
    def cadence(kind):
        if kind == "contract":
            return lambda t, d: (sum(math.sin(2 * math.pi * base * h * t) / h for h in (1, 2, 3, 4)) * (1 if t < 1.2 else 0.6)) * env(t, d, a=0.01, rel=1.4) * 0.6
        return lambda t, d: (math.sin(2 * math.pi * base * 2 * t) + math.sin(2 * math.pi * base * 3 * t)) * env(t, d, rel=1.4) * 0.4
    return command, care, resist, drone, chime, cadence


def world_chamber(rng):
    root = 98.0  # G2
    def pluck(freq, decay):
        # small Karplus-Strong style: decaying harmonics
        return lambda t, d: sum(math.sin(2 * math.pi * freq * h * t) * expdec(t, decay * h) / h for h in range(1, 6)) * 0.6
    def command(det):
        return pluck(root * 2, 4.0)
    def care(det):     # soft major third, strings-like attack
        return lambda t, d: (math.sin(2 * math.pi * root * 4 * t) + 0.8 * math.sin(2 * math.pi * root * 5 * det * t) + 0.6 * math.sin(2 * math.pi * root * 6 * t)) * min(1, t / 0.12) * env(t, d, rel=0.15) * 0.25
    def resist(det):   # minor-second cluster with tremolo
        return lambda t, d: (math.sin(2 * math.pi * root * 4 * t) + math.sin(2 * math.pi * root * 4 * 1.0595 * det * t)) * (0.6 + 0.4 * math.sin(2 * math.pi * 11 * t)) * env(t, d, rel=0.1) * 0.35
    def drone(soft):
        return lambda t, d: (math.sin(2 * math.pi * root * t) + 0.5 * math.sin(2 * math.pi * root * 2 * t)) * env(t, d, a=0.08, rel=0.1) * (0.12 if soft else 0.2)
    def chime():
        return lambda t, d: math.sin(2 * math.pi * root * 16 * t) * expdec(t, 4) * 0.2
    def cadence(kind):
        def f(t, d):  # V -> I
            fifth = [root * 3, root * 3 * 1.26, root * 3 * 1.5]
            tonic = [root * 2, root * 2 * 1.26, root * 2 * 1.5, root * 4]
            notes = fifth if t < 1.1 else tonic
            heavy = 1.4 if (kind == "contract" and t >= 1.1) else 1.0
            return sum(math.sin(2 * math.pi * n * t) for n in notes) * env(t, d, rel=1.3) * 0.18 * heavy
        return f
    return command, care, resist, drone, chime, cadence


def world_circuit(rng):
    base = 110.0
    def sq(f, t):
        return 1.0 if math.sin(2 * math.pi * f * t) >= 0 else -1.0
    def command(det):  # kick + square bleep
        return lambda t, d: (math.sin(2 * math.pi * (50 + 120 * expdec(t, 30)) * t) * expdec(t, 10) + 0.25 * sq(base * 4, t) * expdec(t, 18)) * 0.6
    def care(det):     # consonant arpeggio blips
        def f(t, d):
            step = int(t / (d / 4))
            ratios = [1, 1.25, 1.5, 2][step % 4]
            return math.sin(2 * math.pi * base * 4 * ratios * det * t) * expdec(t % (d / 4), 12) * 0.35
        return f
    def resist(det):   # distorted detuned saw buzz
        def f(t, d):
            saw = ((base * 2 * t) % 1) * 2 - 1
            saw2 = ((base * 2 * det * 1.03 * t) % 1) * 2 - 1
            return math.tanh(3 * (saw + saw2)) * env(t, d, rel=0.05) * 0.3
        return f
    def drone(soft):
        return lambda t, d: math.sin(2 * math.pi * base / 2 * t) * env(t, d, a=0.03, rel=0.1) * (0.18 if soft else 0.3)
    def chime():
        return lambda t, d: sq(base * 16, t) * expdec(t, 20) * 0.15
    def cadence(kind):
        def f(t, d):
            ratios = [1.5, 1.25, 1, 2] if kind == "contract" else [1, 1.25, 1.5, 2]
            step = min(3, int(t / 0.35))
            hold = 1.0 if t < 1.4 else 1.0
            return (math.sin(2 * math.pi * base * 2 * ratios[step] * t) + 0.5 * math.sin(2 * math.pi * base * t)) * env(t, d, rel=1.3) * 0.35 * hold
        return f
    return command, care, resist, drone, chime, cadence


WORLDS = {"A_foundry": world_foundry, "B_chamber": world_chamber, "C_circuit": world_circuit}


def render(run, world_name):
    rng = random.Random(int(run["hash"][:12], 16))
    command, care, resist, drone, chime, cadence = WORLDS[world_name](rng)
    beats = run["beats"]
    mix = Mix(len(beats) * BEAT + CODA)
    prev_s = 0
    for i, b in enumerate(beats):
        t0 = i * BEAT
        grip = max(-1.0, min(1.0, b["grip"]))
        det = 1.0 + abs(grip) * 0.06  # farther from balance = more dissonant
        voice = {"obey": command, "negotiate": care, "defy": resist}[b["response"]](det)
        mix.add(t0, BEAT, voice, pan=grip * 0.85)
        if b["node"]:
            mix.add(t0, BEAT, drone(b["node"].endswith("|aim")), pan=0.0)
        if b["lens"]:
            side = 0.9 if "lens=system" in b["lens"] else -0.9  # the opposite pole hears it
            mix.add(t0 + BEAT * 0.5, 0.25, chime(), pan=-side, gain=0.7)
        if b["micro_s_band"] > prev_s:
            mix.add(t0 + BEAT * 0.75, 0.4, chime(), pan=0.0)
        prev_s = b["micro_s_band"]
    mix.add(len(beats) * BEAT, CODA, cadence(run["synthesis_type"]), pan=0.0)
    return mix


if __name__ == "__main__":
    run = json.loads(Path(sys.argv[1]).read_text())
    out = Path(sys.argv[2])
    for name in WORLDS:
        m = render(run, name)
        m.write(out / f"world_{name}.wav")
        print("wrote", out / f"world_{name}.wav", f"{m.n / SR:.1f}s")
