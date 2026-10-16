class_name NftPackagePack
extends RefCounted
## "Extract from the Node" for any era. Built-in era -> the locked NftPackage.write, unchanged.
## Era pack -> the same folder and files, with an SD7 code, plus `era_pack.json` (the exact pack the piece needs to
## rebuild) and an "Era Pack" attribute (id~hash8) in the metadata.


static func write(sim: DialecticSim, era_id: String, role: String, art: Image, insight: Dictionary, root: String, reg: EraRegistry) -> Dictionary:
	if not reg.is_pack(era_id):
		return NftPackage.write(sim, era_id, role, art, insight, root)
	if sim.outcome != "synthesis":
		return {"ok": false, "reason": "no synthesis — the Node has nothing to extract"}
	var code := ReplayCodePack.encode(sim, era_id, role, reg)
	if code == "":
		return {"ok": false, "reason": "replay code could not reproduce this game"}
	var qr := QrEncoder.encode(NftPackage.qr_payload(code).to_utf8_buffer())
	if qr == null:
		return {"ok": false, "reason": "replay code too long for QR"}
	var h := sim.log_hash()
	var era_title: String = reg.get_era(era_id).title
	var dir := root.path_join("SD-%s-%s" % [era_id.to_upper(), h.left(12)])
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return {"ok": false, "reason": "cannot create folder (error %d)" % err}
	if art.save_png(dir.path_join("art.png")) != OK or qr.to_image(10, 4).save_png(dir.path_join("qr.png")) != OK:
		return {"ok": false, "reason": "cannot write images"}
	var ed := Blackbox.record(Blackbox.dir_for(root), sim, era_id, role, code)
	var md := NftPackage.metadata(sim, era_title, role, code, h, insight, ed)
	md.attributes.append({"trait_type": "Era Pack", "value": "%s~%s" % [era_id, reg.hashes[era_id].left(8)]})
	NftPackage._write_text(dir.path_join("replay.txt"), code + "\n")
	NftPackage._write_text(dir.path_join("era_pack.json"), FileAccess.get_file_as_string(reg.sources[era_id]))
	NftPackage._write_text(dir.path_join("metadata.json"), JSON.stringify(md, "  ") + "\n")
	NftPackage._write_text(dir.path_join("README-MINT.md"), NftPackage.readme(era_title, h)
		+ "\n- `era_pack.json` — the era pack this piece was played on (content hash %s). The viewer needs this exact pack to rebuild the piece.\n" % reg.hashes[era_id])
	var der := dir.path_join("derivatives")
	DirAccess.make_dir_recursive_absolute(der)
	for style in ["ink", "dots", "emblem"]:
		QrArt.render(qr, sim, style, 1600, art).save_png(der.path_join("qr_%s.png" % style))
	return {"ok": true, "dir": dir, "code": code, "edition": ed.edition, "signed": ed.signature != "", "duplicate": ed.duplicate}
