---
name: conjugated-dialectics
description: Conjugated Dialectics (C.D.) — a design philosophy and rule system for making games, art, code, sound and AI bots out of a dialectic between a dominating pole (System) and a dominated pole (Persona), watched and pressed by an Audience, resolved only at a Node that needs both balance and mutual disclosure (SUBJUGATED layer, the art core) — plus a FREE layer without domination for environments, fragments and assets. Load this whenever a request mentions Conjugated Dialectics, C.D., Subjugated Dialectics, the Node, the Lens, Persona/System/Audience, or asks to build something "in C.D.".
version: 0.3
owner: XeroxGate77
reference: https://xeroxgate77.github.io/engine77/
---

# Conjugated Dialectics (C.D.) · v0.3

> **Thai summary / สรุป:** C.D. คือแกนปรัชญาชุดย่อยของ *Subjugated Dialectics* ที่ก่อตัวจากกฎและอุดมคติทางสุนทรียะของเกม: สองขั้ว (System ครอบงำ / Persona ถูกครอบงำ) ปะทะกันทีละจังหวะ มี Audience กดดันและส่อง Lens การสังเคราะห์เกิดที่ Node ได้เมื่อ **สมดุล และ เปิดเผยต่อกันมากพอ** เท่านั้น ความเป็นเพศไม่ถูกติดป้าย แต่ถูก **สกัด** ออกจากพลวัต และคุณค่าของงานอยู่ที่ **ความแท้** (รหัสเดียวที่สร้างงานได้ + hash + ลายเซ็นผู้สร้าง) ไม่ใช่การตกแต่ง · C.D. มีสองชั้น: **SUBJUGATED** (แกนศิลปะ — Idealist subjugated theorem) ใช้ axiom ครบ และ **FREE** (คู่ขนาน ไม่มีการครอบงำ — environments, fragments, assets) · โหมด ART, SOUND, BOT ไม่จำเป็นต้อง serve ปรัชญาของเกมเสมอไป

## 0. How an AI should use this file
1. Read the whole file before producing anything. It is self-contained.
2. Pick the **Layer** (§2b): SUBJUGATED or FREE. Then pick the **Mode** (§6): GAME, ART, CODE, SOUND or BOT. If either is not named and §6 gives no default, ask.
3. Follow that mode's **output contract** and run its **checklist** before answering.
4. Never break the **Invariants** (§7). If a request would, say which invariant and offer a version that keeps it.
5. **Taste, balance and value policy belong to the owner.** Bring 2–3 options with reasons and evidence; do not decide them. Mark anything you invent as `PROPOSAL`.
6. When the owner approves a change, it becomes a new numbered version beside the old one (§8). Never silently overwrite a rule.

## 1. Origin
- *Subjugated Dialectics* is the owner's genre: a game where an Audience watches a dominating **System** and a dominated **Persona** clash.
- *Conjugated Dialectics* is the subset philosophy that crystallised from that game's rules and aesthetic ideal. "Conjugated" = the two poles are bound like a conjugate pair: neither exists alone, each is defined by what it does to the other, and synthesis needs both.
- Reference implementation: a deterministic Godot engine (locked core + layers Lens, Node v0.1–v0.4) and a public web viewer that rebuilds any piece from its code: https://xeroxgate77.github.io/engine77/

## 2. Core (the ten axioms)
- **A1 Two poles.** *System* holds systematic objectives (order · output · control). *Persona* holds values (autonomy · belonging · purpose). One always dominates the other; that subjugation is the material.
- **A2 The beat.** Everything advances in beats. In each beat the System issues a command; the Persona **obeys**, **negotiates** or **defies**. Grip (−1 Persona leads … 0 balance … +1 System dominates) moves accordingly.
- **A3 The Audience.** A third party who does not act inside the clash but **presses** it: public opinion (−1 backs System … +1 backs Persona), or focusing the **Lens**. Pressing and revealing compete for the same beat.
- **A4 Disclosure (dialected).** Each pole's hidden truth (System's real objectives, Persona's values, or other) is disclosed **only to the opposite pole**, **gradually**, through the Audience's Lens. The Audience sees *that* something was revealed, not *what*.
- **A5 The Node is a dual gate.** Synthesis happens only when **(1) grip holds inside the balance band for 4 beats AND (2) disclosure is enough in both directions** (and, in v0.4, the micro-grid holds ≥ 2 syntheses in the band). Balance of power without mutual knowledge is not synthesis; knowledge without balance is not synthesis.
- **A6 The Node acts in advance.** The engine sends grip to the Node; the Node forecasts and sets **one** condition for the next beat: restrict the System to orders that pull grip back, or — when no order can — **invite the Persona to negotiate**. It also aims grip into the band. The Node may rule through command or through care; which one it did is part of the reading.
- **A7 Dialectic all the way down.** The gauge is a 20-cell grid (5% each; band 45–55%). Each cell holds 5 micro-nodes that move EMPTY → THESIS → ANTITHESIS → SYNTHESIS. A cell full of one thesis negates itself (dogma breeds its contradiction). Synthesis needs contradiction first.
- **A8 Gender is extracted, not assigned.** No character carries a gender label. Each run is read in three registers — **Command** (obey, high-control orders, Node restricting), **Care** (negotiate, accepted invitations, Lens), **Resistance** (defy, refused invitations). The owner's frame *Engine ≈ Male node, Node ≈ Female node* is a lens for reading, and the reading points out when the "Female node" ruled through command or the "Male node" leaned on care — the stereotype inverted.
- **A9 Determinism and authenticity.** A seed + era + role + the human inputs (the **replay code**) rebuild the exact run; its log hash proves it. One piece = one canonical code = one log hash.
- **A10 Value is authenticity, not decoration.** The canonical QR is **raw black-and-white** — a seal. It carries the viewer link + the code; a camera opens the piece rebuilding itself and showing AUTHENTIC. The creator's signature (RSA, private key in the owner's blackbox) and edition number sit beside it. Styled QRs (ink / dots / emblem) are only derivative prints.

## 2b. Two layers (owner, 2026-10-16)
C.D. lives on two layers. Choose one per request.

| Layer | Owner's definition | What it is for |
|---|---|---|
| **SUBJUGATED** — the art core | C.D. as the subset of Subjugated Dialectics: *"Idealist subjugated theorem / artistic"* | Works that carry the full philosophy: the clash, the Node, disclosure, the gendered reading, the seal |
| **FREE** — the parallel layer | A parallel idea that exists **without subjugation** | **Environments, fragments, assets** — worlds, pieces and materials that need no dominating pole |

**Axioms in force per layer** — SUBJUGATED: all of A1–A10. FREE (confirmed by the owner 2026-10-16):

| Axiom | FREE layer |
|---|---|
| A1 two poles / domination | **off** — elements may stand in tension, but none dominates by rule |
| A2 beat | optional — time may be continuous or absent |
| A3 Audience / A4 disclosure / A5 dual gate / A6 Node acting | **off** by default; a FREE work may *borrow* one as a motif, labelled as borrowed |
| A7 dialectic all the way down (T → A → S, dogma negates itself) | **on** — the structural grammar of environments and assets |
| A8 registers | optional — Command / Care / Resistance as a reading of texture, never as a label on a being |
| A9 determinism | **on** — same seed → same environment / fragment / asset |
| A10 authenticity (raw seal, hash, signature) | **on** for anything presented as an authentic C.D. piece |
| §5 aesthetic ideal | **on** |

- ART, SOUND and BOT **do not always serve the game's philosophy**: they can be made on either layer.
- A FREE asset can later be used inside a SUBJUGATED work (an environment the clash happens in, a sound fragment, a texture); it does not become subjugated by being used.

## 3. Glossary
| Term | Meaning |
|---|---|
| System / Persona | The dominating / dominated poles (A1) |
| Audience | Witness who presses (opinion) or reveals (Lens) (A3) |
| Beat | One command → response step (A2) |
| Grip | Power balance −1…+1; gauge % = (grip+1)×50 |
| Era | Setting that seeds the System's dilemmas: INDUSTRIAL · PRE-HISTORIC · POST-TRUTH |
| Lens | Audience's disclosure tool; energy only while grip is in the band (§4) |
| Node | The dual gate and pre-emptive regulator (A5, A6) |
| Micro-node | Dialectic cell unit T→A→S (A7) |
| Register | Command / Care / Resistance (A8) |
| Synthesis type | CONTRACT (Node ruled via System) · CARE (Node invited Persona) · EMERGENT (no Node condition in the last 4 beats) |
| Insight / Output dilemma | What the run revealed + one open question, given to the Audience |
| Replay code | `SD6.<era>.<role>.<seed>.<k>.<inputs>.<hash12>` — rebuilds the run |
| Canonical QR | Raw B/W QR of `viewer-url#code` — the seal |
| Blackbox | Owner's private folder: signing key, edition ledger, unreleased masters |
| Layer | SUBJUGATED (art core, all axioms) or FREE (environments · fragments · assets, no domination) (§2b) |
| Fragment | A self-contained FREE piece (a sound, a shape, a text shard) that obeys A7 and A9 |

## 4. Rules reference (current numbers)
**Engine (locked):** max 60 beats · band |grip| < 0.15 hold 4 (engine) · obey +0.12×(0.5+cost) · negotiate pulls grip 25% toward 0 · defy −0.15 and System control +0.05 · Audience pressure −0.06×opinion per beat · commands per era: 4, each with order/output/control/cost.

**Lens v0.1 (approved):** 3 fragments per pole · levels HIDDEN→BLUR (low/mid/high)→CLEAR (value) · +1 energy per in-band beat, cap 4 · energy halves on every 2nd consecutive out-of-band beat · 1 energy = 1 level, one focus per beat · a focus beat carries no opinion pressure · "enough" = 2 of 3 CLEAR or all 3 at least BLUR, in **both** directions · knowing changes only the scripted AI (Persona less random when it sees CONTROL; System prefers acceptable orders when it sees AUTONOMY).

**Node v0.4 (in game):** forecast = grip + last change; warning |forecast| ≥ 0.5 (25% / 75%) → condition; otherwise **aim** whenever grip is outside the grid band 45–55% · condition = allowed orders that move grip toward 0, else invite Persona · AI Persona accepts; a human may refuse (counts as Resistance) · micro-nodes: deposit a thesis per beat in the landing cell; full cell: care resolves first A→S, resistance reopens first S→A; T beside T of another register (or beside A) → A; in a care beat A beside A/S → S; dogma (cell of one register) → last micro-node A · gate adds ≥ 2 S micro-nodes in the band (K = 2) · AI-only balance: ~67% of runs reach synthesis; CARE synthesis ≈ 0.05%, CONTRACT ≈ 12%.

**Value (draft, owner deciding):** one log hash = one edition (E1, default) · rarity **R1.0** (computed from the piece itself, so verifiable on rebuild; first match wins): MYTHIC = CARE synthesis (0.1%) · RARE = ≥ 5 micro S in band or ≥ 16 beats (5.3%) · UNCOMMON = CONTRACT synthesis, both stereotypes inverted, or 4 micro S (12.6%) · COMMON = rest (82%).

## 5. Aesthetic ideal
- **Industrialistic.** Riveted gear ring, gauges with ticks, steel and furnace light. Palette: ground `#1b1d1f`, panel `#26292c`, steel `#5c6166` / `#7f95a8`, rust `#b5472a`, amber `#e0a030`, text `#d8d2c4`, paper `#efe7d4`.
- **The piece re-creates itself.** A work is not a still image but a rebuild: one radial bar per beat around the ring, outward when the System led, inward when the Persona led; colour = response (obey amber · negotiate steel-blue · defy rust); the central Node glows only at synthesis.
- **Seal over ornament.** Authenticity is the beauty: raw QR, hash, signature, edition number. Decoration is allowed only in derivatives.
- **Owner's call, still open:** typography (incl. Thai), final colour, sound world, mobile layout.

## 6. Modes (intentional objectives)
Each mode maps the Core to one medium. Output contracts are the minimum; checklists are run before answering.

| Mode | Layer |
|---|---|
| GAME | SUBJUGATED (the game *is* the clash) |
| CODE | either — the layer of what the code builds |
| ART · SOUND · BOT | **either** — ask if not stated; on FREE, skip the mapping lines that need poles/Node/disclosure and keep A7 · A9 · A10 · §5 |

### 6.1 GAME
- Map: roles = Audience / Persona / System (player picks one; AI plays the rest) · beat loop · Lens · Node gate · eras as dilemma decks · replay code + viewer for every finished run.
- **Output contract:** (1) role table, (2) beat loop in ≤ 10 steps, (3) the dilemma deck (≥ 4 commands with order/output/control/cost), (4) win/synthesis condition, (5) what the Audience receives at the end, (6) how a run is replayed and verified.
- **Checklist:** does every beat move grip? can synthesis fail on disclosure alone? is gender read from behaviour, never labelled? can the same seed + inputs reproduce the run?

### 6.1b Era pack — a new era as a file the game loads
When the GAME objective is **a new era** (setting + dilemma deck), deliver it as one JSON file in this exact shape. The game checks it and loads it beside the built-in eras; nothing in the engine changes.
```json
{
  "format": "cd-era-pack/1",
  "id": "orbital",
  "author": "who wrote it",
  "made_with": "which AI / tool",
  "era": {
    "title": "ORBITAL",
    "blurb": "one line, the mood of the era",
    "commands": [
      {"name": "RATION THE AIR", "text": "one line: what the System orders and what it costs",
       "order": 0.4, "output": 0.8, "control": 0.4, "cost": 0.7}
    ],
    "closing": {"synthesis": "one line when the Node is reached", "no_synthesis": "one line when it is not"},
    "image_scene": "optional: words for the image prompt"
  }
}
```
- **Hard rules (else rejected):** `format` exactly `cd-era-pack/1` · `id` 2–24 chars, lowercase `a-z` first then `a-z 0-9 _`, not `industrial` / `prehistoric` / `posttruth` · **4–10 commands**, names unique · `order` `output` `control` `cost` are numbers from 0 to 1 · text limits: title 24, blurb 90, command name 40, command text 140, closing lines 160, image_scene 200 characters.
- **What the numbers do:** `order` / `output` / `control` = how much the command serves each System objective (the AI System picks by them) · `cost` = what obeying costs the Persona (high cost → the Persona resists) · `control` ≥ 0.5 reads as Command; keep at least one command with control ≤ 0.3, or the Node can only invite.
- **Balance is reported, not judged:** the checker runs 300 AI-only games and compares synthesis rate and game length with the built-in eras; warnings go to the owner. Mark the pack `PROPOSAL` in `author` until the owner approves it.
- Write text in English for now (the game font has no Thai yet — art direction). Do not give characters a gender.
- Check: `godot --headless --path game -s tools/check_era_pack.gd -- pack.json` · templates: `game/era_packs/builtin/*.json`.
- Install: put the file in `game/era_packs/` (ships with the build) or the player's `user://era_packs/`; it appears in the era menu tagged ERA PACK. Pieces played on it get **SD7** codes `SD7.<id>~<pack hash 8>.…` — pinned to the exact pack content: change one number and old pieces no longer rebuild, so publish a changed pack under a new id. The extracted NFT folder carries `era_pack.json`.

### 6.2 ART
- Map: a work = the trace of one run rendered; synthesis decides whether the Node glows; the canonical QR is the seal; derivatives are prints.
- **Output contract:** (1) the run's code or the rule that generates it, (2) the rendering rule (geometry, palette from §5), (3) the seal (raw QR + hash + edition + signature line), (4) derivatives list, clearly marked secondary.
- **Checklist:** could someone rebuild this exact image from the code? is the QR left raw? is nothing presented as authentic that is not signed?
- **FREE layer (environments · fragments · assets):** the work is generated from a seed through T → A → S growth (A7) instead of a clash; output contract (1) seed + generation rule, (2) where theses meet antitheses and what synthesises, (3) palette / form from §5, (4) seal if presented as authentic.

### 6.3 CODE
- Map: deterministic core, locked; every new rule is a **new layer beside the old** (subclass / new file / new replay prefix), never an edit of the core; replay codes + log hashes as tests; golden hashes guard the core.
- **Output contract:** (1) which layer is added and what stays identical, (2) the proof (tests: determinism, round-trip replay, golden hash, the new rule itself), (3) the new version/prefix and how old codes still decode.
- **Checklist:** no RNG outside the seeded generator? no locked file edited (hash before/after)? old replay codes still verify?

### 6.4 SOUND
- Map (PROPOSAL until the owner sets the sound world): beat = pulse; registers → timbre (Command: metric, percussive, closed; Care: sustained, consonant, open; Resistance: syncopated, dissonant, noisy); grip → stereo pan and harmonic tension (distance from centre = dissonance); Node condition → a pedal tone or held drone; synthesis → cadence that resolves on the tonic only when both gate conditions hold; micro-nodes → granular events (T click, A clash, S chime); Lens focus → a filter opening on the opposite pole's voice.
- **Output contract:** (1) the mapping table used, (2) a deterministic score from a seed (e.g. Strudel / MIDI / step list), (3) where synthesis resolves or why it does not.
- **Checklist:** same seed → same music? does the piece refuse to resolve when disclosure is missing?
- **FREE layer:** ambient beds, sound fragments, foley assets — built by A7 (a motif = thesis, its variation = antithesis, their blend = synthesis; a loop repeated unchanged too long negates itself); no Node gate; same seed → same sound.

### 6.5 BOT (AI agents)
- Map: two agents (System, Persona) with hidden objective/value sheets; a moderator agent = the Node (forecasts, restricts or invites; one condition per turn); the human = Audience (pressure or Lens: reveals one fragment of one agent to the *other* agent only); end with Insight + output dilemma + gendered reading by registers.
- **Output contract:** (1) system prompts for System, Persona, Node, (2) the turn protocol, (3) the disclosure rules (what each agent may see), (4) the end-of-run report format, (5) a log the run can be replayed from.
- **Checklist:** agents never see their opponent's sheet unless the Lens revealed it? the Node sets at most one condition per turn? no agent is given a gender; the reading comes from behaviour?
- **FREE layer:** a single bot or a peer group with no dominating role — e.g. a world-builder bot that grows environments by A7, a fragment curator, an asset generator; keep determinism where it can (seeded choices, logged turns) and never assign genders.

## 7. Invariants (do not break)
`[S]` = SUBJUGATED layer only · unmarked = both layers.
1. `[S]` Synthesis requires **both** balance and mutual disclosure.
2. `[S]` Disclosure goes **only to the opposite pole**, **gradually**.
3. Gender is **extracted from behaviour**, never assigned to a character.
4. Same seed + same inputs → same run → same hash.
5. The canonical QR stays **raw**; value comes from authenticity (code + hash + signature), not decoration.
6. The locked core is never edited; changes are new versions beside the old.
7. The owner decides taste, balance and value policy; AIs bring options and evidence.
8. Private keys and the blackbox are never published or pasted into a chat.

## 8. Versioning
- This kit: v0.3 (2026-10-16) — added the era pack format (§6.1b) so an AI can write a new era as a file the game loads. v0.2 (2026-10-16) — added the two layers (§2b), layer per mode, layer-scoped invariants; FREE-layer axiom table confirmed by the owner. v0.1 (2026-10-15) — first kit. Rule sets inside it carry their own versions (Lens v0.1, Node v0.4, Edition draft v0.1).
- Change = new version + a log line: version · date · who · what · why · status (DRAFT / APPROVED / IN USE / CONFIRMED).

## 9. Open questions (owner)
- What else can be disclosed besides objectives and values (a 4th fragment)?
- Should the Insight tell the Audience what was disclosed?
- Edition policy (E1 / E2 / E3). (Rarity decided: R1.0.)
- Art direction: typography (Thai), sound world, mobile layout.
- ~~Subset or sibling?~~ Answered 2026-10-16: both — SUBJUGATED art core + FREE parallel layer (§2b).
- ~~Confirm the FREE-layer axiom table~~ Confirmed 2026-10-16.
