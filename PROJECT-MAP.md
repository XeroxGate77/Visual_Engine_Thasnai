# PROJECT MAP — Subjugated Dialectics (เกม)

## 1. Status
- Canonical version: none yet (ยังไม่มีโค้ด)
- State: active — ช่วงร่างปรัชญา/กลไก
- Last session did: auto กลับมาแสดง insight texts (ยกเลิก 'no insight') · ui_smoke_auto PASS · 4 ชุดหลัก PASS · เกมเว็บ export ใหม่ → `deploy/sd/play/`. Next: push `deploy/sd` · template macOS · ฟอนต์

## 2. Where things are
| What | Path | Notes |
|---|---|---|
| **C.D. kit** (Conjugated Dialectics) | `cd-kit/CD.md` (แหล่งเดียว) · `cd.json` · `studio.html` (แอป local, UI v2 โทนอุ่น 2026-10-16) · `build_studio.py` | ไฟล์เดียวให้ AI ใดก็เข้าใจระบบ + 5 โหมด GAME/ART/CODE/SOUND/BOT · เป็น Agent Skill ได้ · แก้ CD.md แล้ว build Studio ใหม่ แล้วคัดลอกไป `deploy/sd/cd/` |
| **Builds สำหรับคนอื่น** | preset "Web Game" (`custom_features="public"`) → `build/play/` → `deploy/sd/play/` · preset "Web Viewer" → `build/web/` → `deploy/sd/` | public build ซ่อน EXTRACT แสดงรหัส + OPEN IN VIEWER (`auto_mode.gd` `public_build`) · macOS .app ยังไม่มี (ไม่มี template) |
| **Auto mode** (main v3) | `game/auto/auto_mode.gd`+`.tscn` (extends main_v2) · `auto/auto_runner.gd` (seed ต่อรอบ, หมุนยุค, entry) · `auto/auto_gallery.gd` (`user://auto_gallery.json`) | main scene ตั้งแต่ 2026-10-16 · main_v2.tscn / main.tscn ยังรันได้ · ค่าจังหวะเป็น placeholder (`auto_beat`, `auto_pause`) |
| **Game / viewer v2** (era packs) | `game/main_v2.gd`+`.tscn` (extends main.gd) · `viewer/viewer_v2.gd`+`.tscn` (extends viewer.gd) · `era/era_text.gd` · `era/grok_insight_pack.gd` · `era/replay_code_pack.gd` (SD7) · `era/nft_package_pack.gd` | main scene = v2 ตั้งแต่ 2026-10-16 · ของเดิม main.tscn / viewer.tscn ยังรันได้ · ยุคเดิมผ่าน v2 = ผลเหมือนเดิมทุกตัว (เทสต์) |
| **Era packs** (ยุคเป็นไฟล์) | `game/era/era_pack.gd` (อ่าน+ตรวจ) · `era_pack_check.gd` (รายงานสมดุล) · `era_registry.gd` (รวม built-in + pack) · `game/era_packs/` (โหลดเฉพาะชั้นบนสุด) · `era_packs/builtin/` (3 ยุคเดิมเป็นแม่แบบ ไม่โหลด) · `era_packs/examples/orbital.json` (ตัวอย่างที่ Claude เขียน = PROPOSAL ไม่โหลด) | สเปกให้ AI: CD.md §6.1b · ยังไม่ต่อเข้าเกม (ขั้น 2) |
| แกนปรัชญา/กลไก (draft) | `PHILOSOPHY.md` | การตัดสินเชิงรสนิยมเป็นของเจ้าของ |
| กฎ Lens (Disclosure) v0.1 APPROVED | `LENS-RULES.md` + `RULES-LOG.md` | ทุกการแก้กฎลง RULES-LOG |
| Lens layer (อยู่ในเกม) | `game/lens/lens.gd` (กฎล้วน), `game/lens/lens_sim.gd` (`LensSim extends DialecticSim`) | เกมใช้ LensSim; engine เดิมไม่ถูกแก้ · replay code SD2 สำหรับเกม Lens (SD1 ยังอ่านได้) |
| Export จาก Node (QR + NFT-ready) | `game/export/replay_code.gd`, `qr_encoder.gd`, `nft_package.gd` + ปุ่มในหน้า Insight | เฉพาะเกมที่ synthesis; เขียนไป `~/Desktop/Subjugated Dialectics NFT/SD-<ERA>-<hash12>/`; หยุดก่อน mint (ไม่มี wallet/เน็ต) |
| กฎ Node (เงื่อนไขล่วงหน้า + สกัดความเป็นเพศ) v0.1 APPROVED | `NODE-RULES.md` | ทุกการแก้กฎลง RULES-LOG |
| Node layer v0.1 | `game/node/node_sim.gd` (`NodeSim extends LensSim`), `game/node/gender_reading.gd` | คงไว้ ไม่แก้ · replay SD3 |
| Node layer v0.2 | `game/node/node_sim_v2.gd` (`NodeSimV2 extends NodeSim`) | + N2b เล็งเข้าแถบ · replay SD4 |
| Node layer v0.4 (เกมใช้ตัวนี้) | `game/node/micro_grid.gd`, `game/node/node_sim_v4.gd`, UI `game/ui/micro_gauge.gd` | micro-nodes T→A→S, M2c เปิด, K=2 · replay SD6 (SD1–SD5 ยังอ่านได้) |
| Node layer v0.3 | `game/node/node_sim_v3.gd` + `grid.gd` + `grid_lens.gd`, UI `game/ui/gauge_grid.gd` | แถบสมดุลบน grid 20 ช่อง 45–55% · replay SD5 (SD1–SD4 ยังอ่านได้) |
| เรนเดอร์ความละเอียดสูง | `game/export/hires_render.gd` | 2048² จาก trace (= จาก replay) ผ่าน SubViewport · export จาก Node ใช้ตัวนี้แทนภาพแคปหน้าจอ · ต้องมี renderer (ไม่ใช่ --headless) |
| QR หลัก + ภาพพิมพ์รอง | `qr.png` = QR หลัก ดิบขาวดำ (ห้ามแต่ง) · `derivatives/qr_ink|dots|emblem.png` จาก `game/export/qr_art.gd` | ทุกไฟล์อ่านได้เป็นลิงก์เดียวกัน (zxing-cpp) · เครื่องมือทำตัวอย่าง `game/tools/qr_art_samples.tscn` → `docs/qr-art/` |
| มูลค่า: edition / ลายเซ็น / blackbox | `EDITION-RULES.md` (v0.1 DRAFT) · `game/export/signer.gd`, `blackbox.gd` · เครื่องมือกุญแจ `game/tools/make_creator_key.tscn` | รหัส canonical + RSA-2048 ลงนาม + ledger ใน `_BLACKBOX/` (1 hash = 1 edition, ค่าเริ่มต้น) · **กุญแจจริงสร้างแล้ว** (ส่วนตัวใน `~/Desktop/Subjugated Dialectics NFT/_BLACKBOX/`, chmod 600; สาธารณะ `game/export/creator_public.pem` อยู่ใน web build) · นโยบาย E/R รอเจ้าของ |
| Viewer (QR → งานสร้างตัวใหม่จากรหัส) | `game/viewer/viewer.tscn`, `viewer.gd` | อ่านรหัสจาก URL `#…` (+ฟัง hashchange) / user args / ช่องวาง · ตรวจ hash · `NftPackage.VIEWER_URL` = `https://xeroxgate77.github.io/engine77/` → QR = ลิงก์ + `#รหัส` |
| เว็บไซต์ viewer (พร้อม push) | `deploy/sd/` = สำเนา build/web + `.nojekyll` + README | ปลายทาง GitHub Pages `https://xeroxgate77.github.io/engine77/` (repo `XeroxGate77/engine77`) · **LIVE** (เจ้าของ push เอง, ตรวจแล้ว hash ตรง) · อัปเดต: export ใหม่แล้วคัดลอก build/web → deploy/sd |
| Web build ของ viewer | `build/web/` (สร้างใหม่ได้ ไม่ต้องแก้มือ) · preset `game/export_presets.cfg` "Web Viewer" | feature `viewer` → `run/main_scene.viewer` = viewer · ไม่ใช้ threads (โฮสต์ได้ทุกที่) · wasm 39.5 MB · template 4.7.2 (web เท่านั้น) ติดตั้งแล้ว, SHA-512 ตรง |
| Demo เสียง (SOUND mode) | `game/tools/sound_demo.py` → `docs/sound-demo/` (3 WAV + run.json + README) | เกมจริง 1 รอบ × 3 โลกเสียง (A Foundry · B Chamber · C Circuit) · Python ล้วน · seed เดิม = ไฟล์เดิม · **พักไว้ — การบ้านของเจ้าของ** (ยังไม่กำกับด้านเสียง) |
| แผนที่ปรัชญา (MAP, draft 0) | `docs/philosophy-map.html` | แนวคิด ↔ ไฟล์ใน engine + สถานะ (ตัดสินแล้ว/ตีความ/เปิดอยู่) |
| **Thasnai** (Visual Engine builder) | `../thasnai/THASNAI-CONTEXT.md` | context pack ที่ Thasnai เรียนจาก 4 session เก่า + MAP/PHILOSOPHY/CD.md · Visual Engine ยังเป็น PROPOSAL ยังไม่มีโค้ด · ต้องสร้างข้างๆ engine ไม่แก้ engine |
| **Visual Engine v0.1** (Thasnai) | `game/visual/visual_engine.gd` (`VisualEngine`: make_view / render_frame / render_sequence) · `visual_overlay.gd` (`VisualOverlay`: grip seismograph, band guides, opinion dots, synthesis halo) · test `tests/visual_test.tscn` → `tests/shots_visual/result.txt` | ต่อข้างๆ engine: preset `v1` = ArtView เดิม (เทสต์ว่าไบต์เท่า HiresRender) · `v2` = + overlay · ดู `../thasnai/THASNAI-CONTEXT.md` · baseline sha256 ของ .gd เดิม 42 ไฟล์ใน `../thasnai/BASELINE-sha256.txt` (ตรงทุกไฟล์หลังเพิ่ม) · **รูปแบบ v2 = PROPOSAL รอเจ้าของ** (รสนิยม) · ตัวเลือก overlay `v2a` quiet / `v2b` seismic / `v2c` instrument (เทียบที่ `game/tests/shots_visual/options.png`, สร้างด้วย `tests/visual_options.tscn`) · v2 เดิมไม่เปลี่ยน (hash ภาพ 3040746117 / 1927421760 เท่าเดิม) · ตัวเลือกภาษาภาพ Grok (PROPOSAL ยังไม่ตัดสิน): `g1` furnace · `g2` fissure · `g3` knife (`visual/grok_layer.gd`; เทียบที่ `tests/shots_visual/options_grok.png`; สุ่มจาก seed = log hash) · studio web ยังไม่รวม g1–g3 (ต้อง export ใหม่) · **เจ้าของเลือก A (quiet) 2026-10-16** → ค่าเริ่มต้นใน studio = `v2a` (`DEFAULT_PRESET`), export เว็บใหม่แล้ว → `build/visual/` |
| **Visual Studio (.web)** | `game/visual/visual_studio.gd`+`.tscn` · preset export "Web Visual" (`custom_features="visual"`, `run/main_scene.visual` ใน project.godot) → `build/visual/` | เลือกรหัส SD1–SD7 / RANDOM PREVIEW / preset v1·v2·v2a·v2b·v2c (เริ่มที่ v2a) / เลื่อน reveal / PLAY · ทดสอบในเบราว์เซอร์ localhost แล้ว (ไม่มี console error) · ยังไม่ copy เข้า `deploy/` ยังไม่ push |
| Godot project | `game/` | Godot 4.7.2 (/Applications/Godot.app) |
| Sim core (seeded) | `game/sim/dialectic_sim.gd` | ยังไม่มี UI, Audience/Persona/System chooser เป็น Callable |
| UI | `game/main.gd`, `game/main.tscn`, `game/ui/art_view.gd` | สร้าง UI ด้วยโค้ด, สี/ฟอนต์เป็น placeholder |
| ยุค/คำสั่ง (dilemmas) | `game/sim/eras.gd` | ตัวเลขเป็น placeholder |
| Insight (scripted fallback) | `game/sim/insight.gd` | |
| Image prompt (scripted, ฟรี) | `game/sim/image_prompt.gd` | ปุ่ม COPY IMAGE PROMPT / OPEN GROK (https://grok.com) ในหน้า Insight — ผู้เล่นวางใน Grok Imagine ด้วยบัญชีตัวเอง |
| Grok API ตอนจบ (ใช้งานอยู่) | `game/ai/grok_insight.gd` | `grok-4.7` chat (strict json_schema) → `grok-imagine-image-2.0` ภาพ b64 ($0.04/ภาพ); key จาก env `XAI_API_KEY` เท่านั้น; ใช้ schema/prompt/sanitize ร่วมกับ claude_insight.gd |
| Claude API ตอนจบ (ไม่ได้ใช้, `API_ENABLED := false`) | `game/ai/claude_insight.gd` | raw HTTP, `claude-opus-5-5`, effort low, structured JSON, `fallbacks: "default"`; key จาก env `ANTHROPIC_API_KEY` เท่านั้น |
| Tests | `game/tests/run_sim.gd`, `golden.gd`(+`golden.txt`), `claude_insight_test.gd`, `grok_insight_test.gd`, `image_prompt_test.gd`, `export_test.gd`, `lens_test.gd`, `node_test.gd`, `node_v2_test.gd`, `node_v3_test.gd`, `node_v4_test.gd`, `edition_test.gd`, `rarity_test.gd`, `era_pack_test.gd`, `era_pack_game_test.gd`, `ui_smoke_v2.tscn` (→ `tests/shots_v2/`), `auto_test.gd`, `player_extract_test.gd`, `ui_smoke_auto.tscn` (→ `tests/shots_auto/`), `qr_dump.gd`+`qr_crosscheck.py`, `ui_smoke.tscn` | smoke เขียน `game/tests/shots/result.txt` + ภาพ; บังคับไม่มี key ทั้งสองเจ้า (ไม่ยิง API) |

## 3. Commands
Export (นอก sandbox): `cd game && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Web Game" ../build/play/index.html < /dev/null` และ `"Web Viewer" ../build/web/index.html` → คัดลอก `build/play/*` → `deploy/sd/play/`, `build/web/*` → `deploy/sd/` · ทดสอบ: `python3 -m http.server 8790 --bind 127.0.0.1` ใน `build/` (นอก sandbox) แล้วเปิด /play/ และ /web/#<code>
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/run_sim.gd   # expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/golden.gd   # expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/claude_insight_test.gd   # offline, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/grok_insight_test.gd   # offline, expected: RESULT: PASS
```
เล่นจริงพร้อม Grok: export XAI_API_KEY ใน shell แล้ว `/Applications/Godot.app/Contents/MacOS/Godot --path game` (เปิดจาก Finder จะไม่มี env var → fallback)
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/export_test.gd   # 180 replay round-trips + package, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/lens_test.gd   # กฎ L1–L8 + 108 SD2 round-trips, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/node_test.gd   # N1–N7, G1–G4, no-op, 108 SD3 round-trips, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/node_v2_test.gd   # N2b + labels + 72 SD4 round-trips, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/node_v3_test.gd   # grid + v0.2 vs v0.3 numbers + 72 SD5 round-trips, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/node_v4_test.gd   # micro rules M1–M4 + K=2 gate + 72 SD6 round-trips, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/era_pack_test.gd < /dev/null   # pack = built-in (hash 30 รอบ/ยุค), ปฏิเสธ pack เสีย 10 แบบ, registry, expected: RESULT: PASS
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tools/check_era_pack.gd -- /path/pack.json < /dev/null   # ตรวจ pack ใหม่ + รายงานสมดุล 300 เกม
```
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/era_pack_game_test.gd < /dev/null   # v2 = ของเดิมบนยุคเดิม, SD7 round-trip 36, SD7==SD6 บนเด็คเดียวกัน 24, pack หาย/เปลี่ยน → ปฏิเสธ, NFT ของ pack, expected: RESULT: PASS
```
UI v2: Godot MCP `run_project` scene `res://tests/ui_smoke_v2.tscn` → `game/tests/shots_v2/result.txt` (RESULT: PASS)
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/auto_test.gd < /dev/null   # seed/หมุนยุค/ทุกรหัสใน gallery rebuild ได้/canonical/dedupe/persist, expected: RESULT: PASS
```
Auto UI: Godot MCP `run_project` scene `res://tests/ui_smoke_auto.tscn` → `game/tests/shots_auto/result.txt` (RESULT: PASS · extract ลง tests/shots_auto/nft ไม่ใช่ Desktop)
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s tests/edition_test.gd   # canonical + ลายเซ็น + ledger + viewer (กุญแจทิ้งได้), expected: RESULT: PASS
```
QR decode check (ตัวอ่านอิสระ zxing-cpp + pillow): `python tests/qr_decode_check.py <payload> <png…>` (เต็มขนาด + ย่อ 1/4)
QR cross-check (ต้องมี Python `qrcode`): `godot --headless --path game -s tests/qr_dump.gd -- /tmp/qr.json` แล้ว `python tests/qr_crosscheck.py /tmp/qr.json` (11/11 ตรงกับ lib อ้างอิง, v1–v10)
Web export (ต้องปิด sandbox — Godot เขียน temp ของระบบ):
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --export-release "Web Viewer" ../build/web/index.html
```
ทดสอบเว็บ: `python3 -m http.server 8767 --bind 127.0.0.1` ใน build/web แล้วเปิด `http://127.0.0.1:8767/index.html#<รหัส>`
Viewer smoke: รันผ่าน Godot MCP `run_project` scene `res://tests/viewer_smoke.tscn` → `game/tests/shots/viewer_result.txt`
UI smoke: ต้องมีหน้าต่าง — รันผ่าน Godot MCP `run_project` scene `res://tests/ui_smoke.tscn` (ใน sandbox ของ Bash เปิดหน้าต่างไม่ได้ ค้าง)
(รันจากโฟลเดอร์ subjugated-dialectics)

## 4. Invariants
- build สาธารณะ (tag `public`): ผู้เล่น EXTRACT ได้ แต่ **ไม่มีลายเซ็นผู้สร้าง** และติดป้าย 'Extracted by: player' เสมอ (player_extract_test) · ลายเซ็นเกิดได้แค่บนเครื่องเจ้าของที่มีกุญแจใน _BLACKBOX
- เกมเว็บกับ viewer เว็บให้ hash เดียวกัน (ทดสอบ 2026-10-16: SD6.prehistoric.p.630470892.0..86a9b6c87654 AUTHENTIC)
- Auto mode ไม่สร้าง edition เอง: gallery เก็บแค่รหัส · การ EXTRACT (ลง BLACKBOX/ลงนาม) ต้องกดเองเสมอ · ไม่เรียก API ที่เสียเงินอัตโนมัติ
- รอบ auto ที่ AI เล่นทุกที่นั่งใช้รหัส Persona แบบ canonical ของ encoder เดิม (k ใหญ่สุดที่ rebuild ได้ — ไม่บังคับ k=0 เพราะจะได้ 2 รหัสต่อ 1 ชิ้น) · ใครนั่งที่ไหนจริงเก็บใน gallery `seat`
- **SD7** = เกมบน era pack: `SD7.<id>~<packhash8>.…` — pack ต้องตรง hash ไม่งั้นปฏิเสธ (ไม่ rebuild บนเด็คอื่นเด็ดขาด) · SD1–SD6 ไม่เปลี่ยน · ชิ้นงานของ pack มี `era_pack.json` ในโฟลเดอร์ NFT
- v2 บนยุคเดิม = ของเดิมทุกไบต์ (Insight, image prompt, Grok body, รหัส SD6, แพ็กเกจ NFT) — era_pack_game_test · ไฟล์ .gd เดิม 47 ไฟล์ + main.tscn + viewer.tscn ไม่เปลี่ยนหลังขั้น 2 (2026-10-16)
- Era pack ไม่แตะ engine: ไฟล์ .gd เดิม 47 ไฟล์ sha256 ไม่เปลี่ยนหลังเพิ่ม `game/era/` (2026-10-16) · pack ของยุคเดิมให้ log hash เท่ากับ `Eras.DATA` ทุกรอบ (era_pack_test)
- ตัวตนของงาน = log hash; 1 hash = 1 edition (ค่าเริ่มต้น E1 รอยืนยัน) · กุญแจส่วนตัวอยู่ใน `_BLACKBOX/` เท่านั้น ห้ามอยู่ในโปรเจกต์/เว็บ
- `qr.png` ใน package = QR หลักแบบดิบขาวดำเท่านั้น (เจ้าของ 2026-10-15) — ตรวจโดย export_test "canonical qr.png is raw black-and-white"
- ไฟล์ทุกชั้นก่อน v0.4 (16 ไฟล์ รวม v0.3 และ gauge_grid) sha256 ไม่เปลี่ยนหลังเพิ่ม v0.4 (2026-10-15)
- ไฟล์ทุกชั้นก่อน v0.3 (sim/ai/ui/lens/node ทั้ง 12 ไฟล์) sha256 ไม่เปลี่ยนหลังเพิ่ม v0.3 (2026-10-15)
- ไฟล์ engine + Lens + Node v0.1 (`sim/*`, `ai/*`, `ui/art_view.gd`, `lens/*`, `node/node_sim.gd`, `node/gender_reading.gd`) sha256 ไม่เปลี่ยนหลังเพิ่ม v0.2 (2026-10-15)
- ไฟล์ engine + Lens (`sim/*`, `ai/*`, `ui/art_view.gd`, `lens/*`) sha256 ไม่เปลี่ยนหลังเพิ่ม Node (2026-10-15)
- ไฟล์ engine (`sim/*`, `ai/*`, `ui/art_view.gd`) sha256 ไม่เปลี่ยนหลังเพิ่ม Lens — ตรวจด้วย `shasum -a 256` เทียบก่อน/หลัง (2026-10-15)
- **ENGINE ล็อกแล้ว (เจ้าของ 2026-10-15):** `game/sim/*`, `game/ai/*`, `game/ui/art_view.gd`, flow ใน `game/main.gd` — งานใหม่ (เช่น MAP) ต้องต่อข้างๆ ไม่แก้ engine เดิม; ถ้าจำเป็นต้องแก้ ให้บอกสิ่งที่ต้องคงเดิม + พิสูจน์ด้วยเทสต์ทุกชุดใน §3
- seed เดียวกัน + chooser เดียวกัน → hash ของ log เท่ากัน ตรวจโดย `game/tests/run_sim.gd`
- ชุดคำสั่ง default (ไม่มียุค) seed 1..50 → golden hash `819270b3…` ตรวจโดย `game/tests/golden.gd` (ยืนยันหลัง refactor begin/finish_beat แล้ว)

## 5. Decisions (ใหม่สุดก่อน)
- 2026-10-16 เจ้าของ: **ยังไม่ทำ COPY FOR AI** (ปุ่มคัดลอกรหัส + บันทึกการเล่นทีละจังหวะให้ AI) — เก็บไว้ทีหลัง
- 2026-10-16 เจ้าของ (เปลี่ยนใจ): **ให้ auto แสดง insight texts ด้วย** → คืนค่าแล้ว: หน้าจบ auto + gallery แสดง Insight + output dilemma + บรรทัดความหายากเต็ม (type/reason) · gallery entry เก็บ type/reason กลับมา · ui_smoke_auto ตรวจว่า insight แสดง
- 2026-10-16 เจ้าของ (ถูกยกเลิกแล้ว): เลือกความหมาย **'Auto gets no insight'** → ทำแล้ว: หน้าจบของ auto + gallery แสดงแค่ ภาพ · รหัส · ระดับความหายาก · จำนวนจังหวะ · ที่นั่ง (ไม่มี Insight, output dilemma, gendered reading, synthesis type, rarity reason) · gallery entry ไม่เก็บ type/reason แล้ว · insight ยังอยู่ในชิ้นงาน: viewer แสดง และ EXTRACT เขียนลง metadata (คำนวณตอนกดเท่านั้น ไม่แสดงบนจอ auto) · ui_smoke_auto ตรวจว่าไม่มีข้อความ insight บนจอ
- 2026-10-16 เจ้าของ: **ให้ผู้เล่นใน build สาธารณะ extract ได้ (ไม่มีลายเซ็นผู้สร้าง)** → ทำแล้ว: แพ็กเกจปกติ + ป้าย metadata 'Extracted by: player — public build · not a creator edition' + README · เลข edition อยู่ใน ledger ของผู้เล่นเอง · เว็บ = ดาวน์โหลด .zip (Claude เพิ่มป้ายเพื่อไม่ให้สับสนกับ edition ของเจ้าของ)
- 2026-10-16 เจ้าของ (เปลี่ยนใจ): **เอา AUTO MODE + GALLERY กลับเข้าเมนู** เรียง AUTO → PRE-HISTORIC → INDUSTRIAL → POST-TRUTH (GALLERY ท้ายสุด — Claude เลือกตำแหน่ง) · **ไม่มีคำว่า ERA** บนปุ่ม · 'Don't let AUTO mode control and know the dialectic conjugated insight…' → เจ้าของเลือก 'Auto gets no insight' (ดูบรรทัดบน)
- 2026-10-16 เจ้าของ: **ไม่ต้องมีโหมด auto ให้เลือก — ผู้เล่นเลือกเท่านั้น** → ซ่อนปุ่ม AUTO MODE + GALLERY ในเมนู (`auto_mode.gd` `offer_auto = false`; โค้ด auto ยังอยู่ เทสต์เรียกตรง) · **เมนูยุคเรียง PRE-HISTORIC → INDUSTRIAL → POST-TRUTH** (`MENU_ORDER` เฉพาะการแสดงผล; Eras.ORDER, รหัส, เทสต์ไม่เปลี่ยน) · export เกมเว็บใหม่ → `deploy/sd/play/` แล้ว (ตรวจในเบราว์เซอร์)
- 2026-10-16 เจ้าของ: เก็บเมนูไว้เหมือนเดิม (ไม่เข้า auto เอง) · ไปข้อ 3 build ให้คนอื่นเล่น → เว็บทำแล้ว · Claude ตั้งค่าเริ่มต้น: build สาธารณะซ่อน EXTRACT (นโยบายมูลค่า → เจ้าของยืนยัน) · .app รอเจ้าของอนุญาตดาวน์โหลด template macOS · Grok บนเว็บ = fallback เสมอ (ไม่มี env key ในเบราว์เซอร์ — ไม่มีทางรั่ว key)
- 2026-10-16 เจ้าของ: เริ่มข้อ 2 Auto mode → ทำแล้ว · Claude เลือกเชิงเทคนิค: Audience เข้าที่นั่งได้ **ตั้งแต่รอบถัดไป** (กลางรอบทำไม่ได้โดยไม่เพิ่มนโยบาย AI audience ใหม่ เพราะแรงกดสุ่มของ AI audience เขียนเป็นรหัส audience ไม่ได้ → เป็นการตัดสินกฎของเจ้าของ) · ไม่เรียก Grok ใน auto (เสียเงินทุกรอบ) · เกมเปิดมาที่เมนู (AUTO MODE เป็นปุ่มแรก) ไม่เข้า auto เอง — รอเจ้าของตัดสิน
- 2026-10-16 เจ้าของ: อนุมัติขั้น 2 ต่อ era pack เข้าเกม แบบเวอร์ชันใหม่ข้างของเดิม → ทำแล้ว (main/viewer v2 เป็นค่าเริ่มต้น, export filter รวม era_packs/*.json) · ยังไม่มี pack ติดตั้งใน `game/era_packs/` (orbital อยู่ใน examples/ รออนุมัติ)
- 2026-10-16 เจ้าของ: เริ่มข้อ 1 Era packs → ทำขั้น 1 แล้ว (ไฟล์ + ตัวตรวจ + สเปก kit v0.3) · Claude ตั้งกฎแข็งทางเทคนิค (4–10 คำสั่ง, ตัวเลข 0–1, id, ความยาวข้อความ) · **สมดุลไม่ตัดสินอัตโนมัติ** — รายงานเทียบยุคเดิม + คำเตือนให้เจ้าของ · ตัวอย่าง orbital ยังไม่อนุมัติ
- 2026-10-16 เจ้าของ: AI ในเกม AI automation = **scripted เป็นแกน** (ฟรี · ผลซ้ำได้ · ตรวจของแท้ได้) · LLM เป็นชั้นเสริมทีหลัง · งานถัดไปที่เสนอ: era packs → auto mode → build ให้คนอื่นเล่น (ยังไม่เริ่ม รอเจ้าของเลือก)
- 2026-10-16 เจ้าของ: ปรับ **UI** ของ C.D. Studio ให้เป็นมิตร (human persona) แต่ **UX คงเดิม** เพื่อไม่ให้การเรียก AI พัง → ทำแล้ว: เปลี่ยนเฉพาะ CSS + ข้อความช่วย (ขั้น 1–4, คำอธิบายโหมด) · script, id, ข้อความปุ่ม, ตัวเลือก และ brief ที่ได้ เหมือนเดิมทุกตัว (ตรวจด้วยสคริปต์เทียบ) · สำรองแบบเก่าไม่ได้เก็บในโปรเจกต์
- 2026-10-16 เจ้าของ: ยังไม่ใส่เสียง — เก็บด้านเสียงเป็นการบ้าน (demo 3 โลกเสียงอยู่ใน docs/sound-demo/; CD.md §6.4 ยังเป็น PROPOSAL)
- 2026-10-16 เจ้าของมอบให้ Claude ตัดสินความหายาก → **R1.0**: MYTHIC ดูแล · RARE ลึก(≥5 micro S)/ยาว(≥16) · UNCOMMON สัญญา/กลับด้านทั้งคู่/4 micro S · COMMON ที่เหลือ (0.1 / 5.3 / 12.6 / 82%) · อยู่ใน metadata + viewer
- 2026-10-16 เจ้าของ: C.D. มีสองชั้น — **SUBJUGATED** = ชุดย่อยของ Subjugated Dialectics = แกนศิลปะ (Idealist subjugated theorem/artistic) · **FREE** = คู่ขนาน ไม่มีการครอบงำ = environments, fragments, assets · โหมด ART/SOUND/BOT ไม่ต้อง serve ปรัชญาเกมเสมอ → kit v0.2
- 2026-10-16 เจ้าของ: ยืนยันตาราง axiom ของชั้น FREE ตามที่เสนอ (A7·A9·A10·สุนทรียะ เปิด · A2·A8 ไม่บังคับ · A1·A3–A6 ปิด) — เอาป้าย PROPOSAL ออกแล้ว
- 2026-10-15 เจ้าของ: กฎ + อุดมคติสุนทรียะ = หลักปรัชญาชุดย่อยชื่อ **Conjugated Dialectics (C.D.)** · ต้องการ "Mod" (ทางเทคนิค = context pack / Agent Skill) ให้ AI ใดก็เข้าใจ เพื่อสร้าง เกม · ศิลปะ · โค้ด · เสียง · AI bot · และเป็นแอป local ที่เข้าลิงก์แก้ได้ → ทำแล้ว `cd-kit/` (C.D. Studio)
- 2026-10-15 เจ้าของ: อนุญาตรันเครื่องมือสร้างกุญแจผู้สร้างใน _BLACKBOX บน Desktop + export viewer ใหม่ (ทำแล้ว — `deploy/sd/` อัปเดต รอเจ้าของ push)
- 2026-10-15 เจ้าของ: เริ่มข้อ 3 (edition, ความหายาก, ลายเซ็นผู้สร้าง, blackbox) → ส่วนเทคนิคทำแล้ว; นโยบาย E/R ร่างใน EDITION-RULES รออนุมัติ
- 2026-10-15 เจ้าของ (คุยใน session ย่อย แล้วยืนยันใน session หลัก): QR หลักเป็น **ดิบล้วน** (แบบ 1) — ไม่ใช่ดิบ + เลขกำกับนอกขอบ · ink/dots/emblem เป็นภาพพิมพ์รองใน derivatives/ เท่านั้น · เหตุผล: aura อยู่ที่ความแท้ (รหัสเดียวที่สร้างงานได้ + hash + ลายเซ็นข้อ 3) ไม่ใช่การตกแต่ง
- 2026-10-15 เจ้าของ: สแกน QR ตัวอย่างด้วยมือถือจริงแล้ว เปิด viewer ขึ้น AUTHENTIC → เริ่มข้อ 2
- 2026-10-15 เจ้าของ: viewer ขึ้นเว็บแล้วที่ https://xeroxgate77.github.io/engine77/ (repo engine77) → VIEWER_URL ชี้ที่นี่
- 2026-10-15 เจ้าของ: โฮสต์ viewer ที่ GitHub Pages บัญชี XeroxGate77 (URL สั้น ดีต่อความจุ QR); ชื่อ repo ที่เสนอ `sd`
- 2026-10-15 เจ้าของ: อนุญาตดาวน์โหลด export template Godot 4.7.2 จาก GitHub ทางการ และ build viewer เป็นเว็บ (ทำแล้ว)
- 2026-10-15 เจ้าของ: ลำดับงาน 1) QR → viewer บนเว็บ 2) เรนเดอร์ความละเอียดสูง + QR ที่เป็นงานศิลปะ 3) edition/ความหายาก/ลายเซ็น 4) art direction · ถาม: เก็บของมีมูลค่าเป็น blackbox ส่วนตัวในโฟลเดอร์ NFT บน Desktop
- 2026-10-15 เจ้าของ: อนุมัติ NODE-RULES v0.4 แบบ M2c เปิด K=2 และต่อเข้าเกม (ทำแล้ว: NodeSimV4)
- 2026-10-15 เจ้าของ: เก็บ v0.3 ไว้แบบนี้
- 2026-10-15 เจ้าของ: ให้ grid 20 ช่องมี micro grid (micro-nodes T→A→S) ที่คำนวณจากกฎวิภาษวิธีของ Node เพื่อปรับสมดุล และให้เปลี่ยนกฎ Node → ร่าง v0.4 รอเลือก M2c + K
- 2026-10-15 เจ้าของ: เก็บ NODE-RULES v0.3 ไว้ตามนี้ (ถึง Node 65.7% ไม่ได้ยากขึ้น — ยอมรับ)
- 2026-10-15 เจ้าของ: แถบสมดุลเป็น grid บนแกน x เกจ 0–100% — แบบ B ช่องละ 5% (20 ช่อง) แถบ 45–55% → NODE-RULES v0.3 (ทำแล้ว: NodeSimV3)
- 2026-10-15 เจ้าของ: NODE-RULES v0.2 — Node เล็งพา grip เข้าแถบ (N2b) และนับการเล็งใน N6; ให้ป้ายพิเศษยังหายาก (ทำแล้ว: NodeSimV2)
- 2026-10-15 เจ้าของ: ยืนยันการตีความ N3 / N6 / G2 ทั้ง 4 จุด — RULES-LOG N-v0.1-impl CONFIRMED
- 2026-10-15 เจ้าของ: อนุมัติ NODE-RULES v0.1 ตามร่าง ให้ลง RULES-LOG และต่อเข้าเกมเป็นชั้น NodeSim (ทำแล้ว: `game/node/`)
- 2026-10-15 เจ้าของ: กรอบ Male/Female — Engine ≈ Male node, Node ≈ Female node; เลือกแบบวิพากษ์ (สกัดความเป็นเพศจากการเล่น ไม่ติดป้าย) + Node เชิญ Persona มาต่อรอง (ไม่ใช่ผ่าน System อย่างเดียว). ดู PHILOSOPHY §9, NODE-RULES (ร่าง)
- 2026-10-15 เจ้าของ: เสนอให้ Node ออกเงื่อนไขล่วงหน้าจาก grip ที่ engine ส่งมา (ต้นแบบ 300 seed: คำเชิญ Persona ลด grip ติดสุดขั้ว 70.7%→0.4% แต่อัตราถึง Node ยัง ~62%)
- 2026-10-15 เจ้าของ: ยืนยันการตีความ L3.4 (หารครึ่งทุก 2 จังหวะนอกแถบติดกัน) และ L6.1 (noise Persona ±0.05→±0.01) — RULES-LOG v0.1-impl CONFIRMED
- 2026-10-15 เจ้าของ: อนุมัติ LENS-RULES v0.1 ตามร่าง ให้ลง RULES-LOG และต่อเข้าเกมเป็นชั้นใหม่ (ทำแล้ว: `game/lens/`)
- 2026-10-15 เจ้าของ: ทำ QR + NFT ควบคู่; NFT เก็บเป็นไฟล์ในโฟลเดอร์บน Desktop ทำถึงขั้นเตรียม mint เท่านั้น
- 2026-10-15 เจ้าของ: "เปิดเผยมากพอ" — Audience เป็นคนเลือกเปิดเผยผ่านระบบ Lens ที่มีกลไกมาจากข้อจำกัดของ Node; ให้ Claude ร่างกฎ + เก็บเป็น log
- 2026-10-15 เจ้าของ: Node = เงื่อนไขคู่ (C) grip สมดุล + เปิดเผยมากพอ
- 2026-10-15 เจ้าของ: นิยาม Disclosure dialected — เปิดเผยเป้าหมายจริงของ System / ค่านิยมของ Persona (หรืออย่างอื่น) ให้ขั้วตรงข้ามเท่านั้น ทีละน้อยระหว่างเล่น; สัมพันธ์กับ Node = เงื่อนไขคู่ (grip สมดุล และ เปิดเผยมากพอ — ขาดอย่างใดไม่ถึง Node; เจ้าของยืนยัน ไม่ใช่วงวน). ดู PHILOSOPHY §8. ยังไม่ทำใน engine
- 2026-10-15 เจ้าของ: เก็บงานปัจจุบันเป็น engine; งานถัดไปคือ MAP = แผนที่ความคิด/ปรัชญา (ไม่ใช่แผนที่ในเกม); เก็บโปรเจกต์ที่ ~/Documents/Subjugated Dialectics
- 2026-10-15 เจ้าของ: ไม่จ่ายค่า API — ใช้ (1) งานอาร์ต procedural ฟรี + (2) prompt ภาพแบบ scripted ให้ผู้เล่นคัดลอกไปใช้ใน Grok Imagine เอง; fly.io ไม่ทำให้ Grok ฟรี (และไม่มี free tier สำหรับ org ใหม่). Grok client ยังอยู่ ยิงเฉพาะเมื่อตั้ง XAI_API_KEY
- 2026-10-15 เจ้าของ: Grok ใช้งานจริง ไม่มีสวิตช์ปิด; สวิตช์ Claude (`API_ENABLED := false`) คงไว้ตามเดิม
- 2026-10-15 เจ้าของ: ใช้ Grok (xAI) แทน Claude ตอนจบ และให้ Grok สร้างภาพ; Claude client เก็บไว้ข้างกันไม่ลบ
- 2026-10-15 18:54 เจ้าของ: "API ยังไม่ต้องใช้ ใช้แบบ black-boxed source code ไปก่อน" → `ClaudeInsight.API_ENABLED := false` (มาจาก branch ก่อนหน้าของ session นี้ที่ถูกย้อนกลับ ไฟล์ค้างอยู่บนดิสก์) — ต่อมา 19:00 เจ้าของสั่งใช้ Grok แทน
- 2026-10-15 เจ้าของ: ต่อ Claude API ตอนจบ ให้เขียน Insight + ข้อกำหนดงานอาร์ต มี fallback (โมเดล claude-opus-5-5 เป็นค่า default ของ skill — เจ้าของเปลี่ยนได้)
- 2026-10-15 เจ้าของ: UI ธีม Industrialistic; ยุคให้เลือก INDUSTRIAL / PRE-HISTORIC / POST-TRUTH เป็นตัวตั้ง dilemma ให้ System, ผลลัพธ์เป็น Insight + fallback art ให้ Audience
- 2026-10-15 เจ้าของ: เลือก Y Hybrid — เล่นด้วย scripted, เรียก Claude API เฉพาะตอนจบเพื่อเขียน Insight + ข้อกำหนดงานอาร์ต, มี fallback procedural (แก้ข้อขัดด้านล่างแล้ว)
- 2026-10-15 เจ้าของ: Audience = กดดันได้ (ความเห็นสาธารณะ); จบเกมที่ Node แกนกลางสมดุล แล้ว Generate งานอาร์ตจาก Insight ของ AI
- 2026-10-15 เจ้าของ: กลไกปะทะแกนกลาง = A คำสั่ง–การตอบสนอง (System สั่ง → Persona ทำตาม/ต่อรอง/ฝ่าฝืน)
- 2026-10-15 เจ้าของ: AI ในเกมเป็น scripted (GDScript) ไม่เรียก LLM ตอนเล่น
- 2026-10-15 เจ้าของ: ผู้เล่นมี 3 โหมดบทบาท — Audience / Persona / System
- 2026-10-15 เจ้าของ: genre ชื่อ "Subjugated Dialectics" เป็นแกนปรัชญา ไม่ใช่ genre ตลาด

## 6. Ownership
Session ชื่อ Thasnai (Visual Engine) เป็นเจ้าของ `../thasnai/` และ `game/visual/` + `game/tests/visual_test.*` + `game/tests/shots_visual/` · ไม่แก้ไฟล์เดิมอื่น (เทียบ sha256 แล้ว)

## 7. Known traps
- เว็บไม่มีฟอนต์ระบบ → อักษรนอกฟอนต์ default ของ Godot (เช่น → ✓ และไทย) เป็นกล่อง — ต้องฝังฟอนต์ (art direction)
- เปลี่ยนขนาดหน้าต่างระหว่างเกมเว็บเปิดอยู่ (ใน browser pane) canvas ถูกตัดขวา จน reload — ยังไม่รู้ว่าเกิดในเบราว์เซอร์จริงไหม
- `deploy/sd` เป็น git repo ของเจ้าของ (engine77) — Claude วางไฟล์ เจ้าของ push เอง
- tween ของ `_reveal_art` ใน main.gd ผูกกับ node หลัก ไม่ใช่ art → ถ้ากด AGAIN ภายใน 2.5 วิ จะเขียนใส่ art ที่ถูก free (bug แฝงใน main.gd ที่ล็อก; auto mode override แก้แล้วโดยผูก tween กับ art)
- ชิ้นงานที่ AI เล่นเองล้วนส่วนใหญ่หน้าตาคล้ายกัน (สั้น, negotiate เป็นหลัก) — หลักฐานสำหรับ balance/art direction ของเจ้าของ
- Godot headless ตอนนี้รันใน sandbox ไม่ได้ (ล้มที่ get_system_ca_certificates แล้วออกทันที) → รันนอก sandbox · `--import` ใน sandbox ค้าง (เขียน editor settings ไม่ได้)
- สคริปต์ GDScript มี parse error → headless `-s` **ค้างเงียบ** (รอ debugger) — ใส่ `< /dev/null` และตรวจด้วย `--check-only -s file.gd` ก่อน · class_name ใหม่ต้อง `--import` (นอก sandbox) ก่อนใช้
- Studio render หัวข้อได้แค่ `#`–`###` — หัวข้อ `####` ใน CD.md ทำให้หน้า Studio ค้าง (loop ไม่ขยับ)
- 3 ยุคเดิมใช้ตัวเลขชุดเดียวกัน (placeholder) ต่างกันแค่ข้อความ → เล่นเหมือนกันทุกอย่าง (synthesis 66% ทั้งสาม) · ช่วงอ้างอิงของรายงานสมดุลจึงเป็นจุดเดียว
- ไฟล์ที่ไม่ใช่ resource (.pem/.json) ต้องอยู่ใน `include_filter` ของ export preset ไม่งั้นไม่ติดไปกับเว็บ
- HiresRender: ต้อง add SubViewport แบบ deferred (เรียกจาก _ready แล้ว add_child ตรงๆ จะล้มเงียบ ได้ภาพดำสนิท)
- ภาพ Grok (ถ้ามี) ไม่ได้อยู่ใน art.png ความละเอียดสูง — art.png คืองาน procedural (ตาม spec ของ Grok ถ้ามี)
- ไฟล์ index.wasm 39.5 MB อัปผ่านหน้าเว็บ GitHub ไม่ได้ (จำกัด 25 MB) — ต้อง git push
- index.pck บนเว็บมีสคริปต์ของเกมทั้งหมด (อ่านได้สาธารณะ) — ห้ามใส่ของ blackbox ใน project
- ถ้าเปลี่ยนชื่อ repo ต้องแก้ `NftPackage.VIEWER_URL` ด้วย ไม่งั้น QR ชี้ผิดที่
- รหัสไม่ unique: ตัวอักษร inputs หลัง k ไม่มีผล → หลายสตริงได้งานเดียวกัน (ต้องทำ canonical ในข้อ 3 edition)
- preview_start ของแอปยังเปิด launch.json เก่า (docs/8765) — ใช้ python http.server เอง (ต้องปิด sandbox เพื่อ bind port)
- เส้นเตือน 25% บนเกจมองไม่เห็นเมื่อแถบสีแดงทับ (สีเดียวกัน) — ยังไม่ได้แก้
- `sim` ใน main.gd เป็น DialecticSim แต่จริงๆ คือ LensSim — ใช้ `lens_sim` เมื่อต้องการ `.lens` (static typing ไม่ยอมให้เรียกผ่าน `sim`)
- preview_start ของแอปอาจเปิด launch.json เก่า (port 8765 จากโฟลเดอร์เดิม) และ sandbox ห้าม bind port เอง — เช็ก docs ด้วยการ parse SVG หรือเปิดไฟล์เอง
- ห้ามใส่ API key ลงไฟล์ในโปรเจกต์ — อ่านจาก env เท่านั้น
- รัน Godot ใน sandbox แล้วมี ERROR สร้าง user://logs ไม่ได้ — ไม่เกี่ยวกับ sim ดูแค่บรรทัด RESULT
- Godot MCP: `create_scene` ต้องมี `project.godot` อยู่แล้ว; โหนด root ถูกตั้งชื่อ "root"

## 8. Not tested yet
- Visual Engine v0.1: เว็บทดสอบแค่ localhost/Mac (ไม่ใช่มือถือ/โฮสต์จริง) · ไม่ได้กด PLAY / REBUILD ด้วยรหัสอื่นบนเว็บ · ArtView เดิมเปล่ง Node glow ตั้งแต่ reveal ต่ำ (ล็อก ไม่แก้) · render_sequence ได้แค่ภาพ ยังไม่รวมเป็นวิดีโอ/GIF · ไม่ได้ลง export preset include_filter · ยังไม่มีข้อมูล 'big data'
- Player extract บนเว็บ: ยังไม่ได้กด EXTRACT ในเบราว์เซอร์จริง (การกดจะดาวน์โหลดไฟล์ → ต้องขออนุญาต) — การ render 2048 บน WebGL + การดาวน์โหลด .zip จึงยังไม่ verified · ตรรกะป้าย/zip ทดสอบแบบ headless แล้ว
- Build เว็บ: ยังไม่ขึ้นโฮสต์จริง (ทดสอบแค่ localhost) · มือถือ (จอ 1280×800 จะเล็กมาก, wasm 39.5 MB โหลดช้า) · หน้าจบแบบไม่ใช่ auto ใน build สาธารณะ (ปุ่มรหัส) ยังไม่ได้กดดูบนเว็บ · OPEN IN VIEWER เปิดเว็บจริง (ยังเป็น viewer เก่าจนกว่าจะ push)
- Auto mode: รอบที่คนนั่ง Audience แล้ว **ถึง synthesis** ยังไม่เกิดใน smoke (รอบนั้นไม่ synthesis) — โค้ดเส้นเดียวกับเกม Audience ปกติที่เทสต์แล้ว แต่เส้น auto→gallery ของรหัส `a` ยังไม่ได้เห็นจริง · เปิดทิ้งไว้นาน (หลายชั่วโมง / gallery ใหญ่) ยังไม่ทดสอบ · gallery แสดง 36 ชิ้นล่าสุด decode ทุกครั้งที่เปิด (อาจช้าถ้ามีมาก)
- Era pack ขั้น 2: viewer เว็บ **ยังไม่ export ใหม่** (build/web และ deploy/sd ยังเป็น viewer v1 → เปิด SD7 ไม่ได้จนกว่าจะ export + push) · Grok จริงบน pack era ไม่ได้ยิง (เทสต์แค่ body) · ชิ้น pack ที่ลงนามด้วยกุญแจจริงยังไม่มี · viewer เว็บรู้จักเฉพาะ pack ที่ติดมากับ build (ยังไม่ดึง pack จากเว็บ) · ยังไม่ลองให้ AI ภายนอก (Grok/ChatGPT) เขียน pack จริงจาก Studio · `user://era_packs` ยังไม่ทดสอบ
- C.D. Studio UI v2: dark mode (preview แสดงแค่โหมดสว่าง) · บนมือถือจริง · ปุ่ม COPY/DOWNLOAD/EDIT KIT ไม่ได้กดทดสอบรอบนี้ (script ไม่เปลี่ยน)
- ยังไม่เคยลงนามด้วยกุญแจจริง (ยังไม่มีชิ้นที่สกัดจริง) · การดึง registry.json บนเว็บจริงยังไม่ได้ทดสอบ · viewer ใหม่ทดสอบแค่ localhost (ยังไม่ push)
- viewer บนเว็บทดสอบแค่ใน browser pane บน Mac (localhost) — ยังไม่ได้ลองบนมือถือ / โฮสต์จริง · layout 1280×800 บนจอแนวตั้งของมือถือจะเล็ก · wasm 39.5 MB โหลดช้าบนมือถือ
- ความจุ QR: รหัสยาวสุด ~163 byte + URL ≤ ~50 ตัวอักษร พอดี v10-M (213) — QR แบบมีลวดลาย (ข้อ 2) ต้องขยาย encoder เกิน v10
- ข้อความ "micro S in band N (need 2)" แก้หลัง smoke รอบสุดท้าย — ยังไม่ได้ถ่ายภาพหลังแก้
- หน้าคำเชิญของ Node ในโหมด Persona ยังไม่ได้ถ่ายภาพ (smoke ไม่เจอจังหวะที่ Node เชิญตอนผู้เล่นต้องตัดสินใจ) — logic ทดสอบใน node_test แล้ว
- ยังไม่ได้ลองสแกน QR ด้วยกล้องจริง (ตรวจแค่ว่า matrix ตรงกับ lib อ้างอิง) · ยังไม่ได้เขียนลง Desktop จริง (smoke เขียนใน tests/shots/nft) · art.png เป็นสี่เหลี่ยมผืนผ้า 520×683 ไม่ใช่จัตุรัส
- แผง Lens ทดสอบโดยเรียกเมธอดตรง ยังไม่ได้กดด้วยเมาส์จริง
- การกดจริงด้วยเมาส์ (smoke เรียกเมธอดตรง), Claude API ตอนจบ, เสียง, ภาษาไทยใน UI (ฟอนต์ default อาจไม่มีอักษรไทย)
- การเรียก Grok/Claude API จริง (ยังไม่เคยยิง) — ทดสอบแค่ body/parse/fallback แบบ offline. รูปแบบ request/response ของ xAI บางส่วน (aspect_ratio, b64_json) ยืนยันจากเอกสารรอง ไม่ใช่ docs.x.ai โดยตรง
- ความสมดุล: ถ้า Persona ฝ่าฝืนต่อเนื่องจะวิ่งไป grip −1 ค้าง (เห็นใน smoke: defy 56/60) และงานอาร์ตกลายเป็นวงทึบ — ยังไม่ได้ปรับ เป็นการตัดสินของเจ้าของ
