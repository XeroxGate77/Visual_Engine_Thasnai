class_name NftPackage
extends RefCounted
## "Extract from the Node": writes a mint-ready folder for one synthesized game. Stops BEFORE minting —
## no wallet, no network, no blockchain call. The owner uploads and mints by hand (README-MINT.md).
## Folder: <root>/SD-<ERA>-<hash12>/ art.png · qr.png · replay.txt · metadata.json · README-MINT.md · derivatives/
## qr.png is the CANONICAL QR: raw black-and-white modules, untouched (owner, 2026-10-15). Styled QRs are only
## derivative prints in derivatives/ and never replace it.

const ROOT_NAME := "Subjugated Dialectics NFT"
## Public address of the web viewer. Empty = the QR holds only the replay code (no viewer hosted yet).
## When set, the QR holds VIEWER_URL + "#" + code, so a phone camera opens the rebuilt piece.
const VIEWER_URL := "https://xeroxgate77.github.io/engine77/" # GitHub Pages, repo "engine77" of XeroxGate77 (owner, 2026-10-15, live)


static func qr_payload(code: String) -> String:
	return code if VIEWER_URL == "" else VIEWER_URL + "#" + code


static func default_root() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).path_join(ROOT_NAME)


## Returns {ok, dir, code} or {ok: false, reason}. Only synthesized games can be extracted.
static func write(sim: DialecticSim, era_id: String, role: String, art: Image, insight: Dictionary, root: String) -> Dictionary:
	if sim.outcome != "synthesis":
		return {"ok": false, "reason": "no synthesis — the Node has nothing to extract"}
	var code := ReplayCode.encode(sim, era_id, role)
	if code == "":
		return {"ok": false, "reason": "replay code could not reproduce this game"}
	var qr := QrEncoder.encode(qr_payload(code).to_utf8_buffer())
	if qr == null:
		return {"ok": false, "reason": "replay code too long for QR"}
	var h := sim.log_hash()
	var era_title: String = Eras.get_era(era_id).title
	var dir := root.path_join("SD-%s-%s" % [era_id.to_upper(), h.left(12)])
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return {"ok": false, "reason": "cannot create folder (error %d)" % err}
	if art.save_png(dir.path_join("art.png")) != OK or qr.to_image(10, 4).save_png(dir.path_join("qr.png")) != OK:
		return {"ok": false, "reason": "cannot write images"}
	# edition + creator signature, recorded in the owner's private BLACKBOX (one log hash = one edition)
	var ed := Blackbox.record(Blackbox.dir_for(root), sim, era_id, role, code)
	_write_text(dir.path_join("replay.txt"), code + "\n")
	_write_text(dir.path_join("metadata.json"), JSON.stringify(metadata(sim, era_title, role, code, h, insight, ed), "  ") + "\n")
	_write_text(dir.path_join("README-MINT.md"), readme(era_title, h))
	var der := dir.path_join("derivatives")
	DirAccess.make_dir_recursive_absolute(der)
	for style in ["ink", "dots", "emblem"]: # derivative prints only
		QrArt.render(qr, sim, style, 1600, art).save_png(der.path_join("qr_%s.png" % style))
	return {"ok": true, "dir": dir, "code": code, "edition": ed.edition, "signed": ed.signature != "", "duplicate": ed.duplicate}


## ERC-721 metadata (OpenSea-style). `image` is a placeholder until art.png is pinned to IPFS.
static func metadata(sim: DialecticSim, era_title: String, role: String, code: String, h: String, insight: Dictionary, ed: Dictionary = {}) -> Dictionary:
	var edition_attrs: Array = []
	if not ed.is_empty():
		edition_attrs = [{"trait_type": "Edition", "value": "#%03d" % ed.edition},
			{"trait_type": "Creator Signature", "value": ed.signature if ed.signature != "" else "unsigned"}]
	return {
		"name": "Subjugated Dialectics — %s #%s" % [era_title, h.left(8)],
		"description": "%s\n\n%s\n\nReplay: %s" % [insight.get("text", ""), insight.get("dilemma", ""), code],
		"image": "ipfs://REPLACE_WITH_IMAGE_CID/art.png",
		"attributes": [
			{"trait_type": "Era", "value": era_title},
			{"trait_type": "Player Role", "value": role.capitalize()},
			{"trait_type": "Outcome", "value": "Synthesis"},
			{"trait_type": "Beats", "value": sim.beat, "display_type": "number"},
			{"trait_type": "Obey", "value": sim.counts.obey, "display_type": "number"},
			{"trait_type": "Negotiate", "value": sim.counts.negotiate, "display_type": "number"},
			{"trait_type": "Defy", "value": sim.counts.defy, "display_type": "number"},
			{"trait_type": "Seed", "value": str(sim.rng.seed)},
			{"trait_type": "Log Hash (SHA-256)", "value": h},
			{"trait_type": "Rules", "value": ("Node %s + Lens %s" % [(sim as NodeSimV2).rules_version() if sim is NodeSimV2 else NodeSim.RULES_VERSION, Lens.RULES_VERSION]) if sim is NodeSim \
				else (("Lens " + Lens.RULES_VERSION) if sim is LensSim else "Engine only")},
		] + _gender_attributes(sim) + edition_attrs,
	}


## NODE-RULES G4: register shares + synthesis type.
static func _gender_attributes(sim: DialecticSim) -> Array:
	if not (sim is NodeSim):
		return []
	var ns := sim as NodeSim
	var sh := NodeSim.share(ns.registers)
	var rar := Rarity.of(sim)
	return [
		{"trait_type": "Rarity (%s)" % Rarity.VERSION, "value": rar.tier},
		{"trait_type": "Rarity Reason", "value": rar.reason if rar.reason != "" else "—"},
		{"trait_type": "Synthesis Type", "value": ns.synthesis_type.capitalize()},
		{"trait_type": "Command %", "value": sh.command, "display_type": "number"},
		{"trait_type": "Care %", "value": sh.care, "display_type": "number"},
		{"trait_type": "Resistance %", "value": sh.resistance, "display_type": "number"},
	]


static func readme(era_title: String, h: String) -> String:
	return """# Mint-ready: Subjugated Dialectics — %s #%s

This folder was extracted from a synthesis at the Balance Node. **Nothing has been minted.**
Minting is a blockchain transaction you sign yourself; it costs gas and is permanent.

## Files
- `art.png` — the artwork shown at synthesis
- `qr.png` — **the canonical QR**: raw black-and-white, the seal of this piece. A phone camera opens the viewer,
  which rebuilds the piece from `replay.txt` and shows AUTHENTIC when the log hash matches
- `derivatives/qr_ink.png`, `qr_dots.png`, `qr_emblem.png` — styled derivative prints of the same QR (they scan to
  the same link). Secondary to `qr.png`; never mint or present them as the canonical QR
- `replay.txt` — seed + era + role + inputs; the game rebuilds this exact run from it
- `metadata.json` — ERC-721 metadata (name, description, attributes)

## Verify authenticity
Replaying `replay.txt` in the game must give log hash `%s`.

## Steps to mint (you do these)
1. Choose a chain and a wallet. Check fees and the legal / tax situation where you live first.
2. Upload `art.png` to IPFS (any pinning service). Copy its CID.
3. In `metadata.json`, replace `REPLACE_WITH_IMAGE_CID` with that CID.
4. Upload the edited `metadata.json` to IPFS. Copy its CID.
5. Mint an ERC-721 token whose token URI is `ipfs://<metadata CID>` — with a no-code minting
   platform or your own contract.
6. Keep this folder; the replay code and hash are the proof the token matches a real game.
""" % [era_title, h.left(8), h]


static func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
