extends SceneTree
## Offline: canonical codes, creator signature, BLACKBOX ledger (one hash = one edition), signed package, viewer check.
## Uses THROWAWAY keys in a temp folder — never the owner's real BLACKBOX.
## godot --headless --path game -s tests/edition_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	print("ok   " if cond else "FAIL ", label)


func _init() -> void:
	# canonical
	var sim := NodeSimV4.new(3, 60, Eras.get_era("industrial").commands)
	sim.run()
	var code := ReplayCode.encode(sim, "industrial", "persona")
	check(code == "SD6.industrial.p.3.0..68c32c01234c", "canonical code drops unread inputs (%s)" % code)
	check(ReplayCode.canonical("SD6.industrial.p.3.0.ndnnnnndnnnn.68c32c01234c") == code, "legacy code -> same canonical code")
	check(ReplayCode.decode(code).ok, "canonical code still rebuilds the piece")

	var root := ProjectSettings.globalize_path("res://tests/_edition_out")
	var bb := Blackbox.dir_for(root)
	var pub_dir := root.path_join("public")
	# unsigned first (no key yet)
	var art := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var r0 := NftPackage.write(sim, "industrial", "persona", art, {"text": "T", "dilemma": "D"}, root)
	check(r0.ok and r0.edition == 1 and not r0.signed, "no key -> edition #1, unsigned")
	# keys
	var k := Signer.generate_keys(bb, pub_dir)
	check(k.ok, "throwaway key pair generated")
	check(not Signer.generate_keys(bb, pub_dir).ok, "refuses to overwrite an existing private key")
	var pem := FileAccess.get_file_as_string(k.public)
	check(not pem.contains("PRIVATE"), "public file holds no private key")
	# signed second piece
	var sim2 := NodeSimV4.new(11, 60, Eras.get_era("posttruth").commands)
	sim2.run()
	check(sim2.outcome == "synthesis", "second piece is a synthesis")
	var r1 := NftPackage.write(sim2, "posttruth", "persona", art, {"text": "T", "dilemma": "D"}, root)
	check(r1.ok and r1.edition == 2 and r1.signed and not r1.duplicate, "edition #2, signed")
	var again := NftPackage.write(sim2, "posttruth", "persona", art, {"text": "T", "dilemma": "D"}, root)
	check(again.ok and again.edition == 2 and again.duplicate, "same piece again -> same edition, no new number")
	var ledger := Blackbox.load_ledger(bb)
	check(ledger.editions.size() == 2, "ledger has 2 editions")
	var md = JSON.parse_string(FileAccess.get_file_as_string(r1.dir.path_join("metadata.json")))
	var attrs := {}
	for a in md.attributes:
		attrs[a.trait_type] = a.value
	check(attrs.get("Edition") == "#002" and attrs.get("Creator Signature", "unsigned") != "unsigned", "metadata carries edition + signature")
	check(attrs.get("Rarity (R1.0)", "") == Rarity.of(sim2).tier, "metadata carries the rarity tier (%s)" % attrs.get("Rarity (R1.0)", "?"))
	# viewer check against the published registry subset
	var reg = JSON.parse_string(FileAccess.get_file_as_string(bb.path_join("registry_public.json")))
	check(reg.pieces.size() == 1 and not JSON.stringify(reg).contains("PRIVATE"), "public registry: only the signed piece, no key material")
	var viewer := load("res://viewer/viewer.gd")
	check(viewer.signature_status(pem, reg, sim2.log_hash()) == "SIGNED BY THE CREATOR · EDITION #002", "viewer: signed edition")
	check(viewer.signature_status(pem, reg, sim.log_hash()).begins_with("Not in the creator's registry"), "viewer: unsigned piece not in registry")
	var forged: Dictionary = reg.duplicate(true)
	forged.pieces[0].edition = 1
	check(viewer.signature_status(pem, forged, sim2.log_hash()).contains("INVALID"), "viewer: altered edition number -> INVALID")
	var other := Signer.generate_keys(root.path_join("other"), root.path_join("other_pub"))
	check(viewer.signature_status(FileAccess.get_file_as_string(other.public), reg, sim2.log_hash()).contains("INVALID"), "viewer: someone else's key -> INVALID")
	check(viewer.signature_status("", reg, sim2.log_hash()).contains("no creator key"), "viewer: no key in build")

	_rm(root)
	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)


func _rm(path: String) -> void:
	for d in DirAccess.get_directories_at(path):
		_rm(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
