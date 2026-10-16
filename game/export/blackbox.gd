class_name Blackbox
extends RefCounted
## The owner's private folder: <NFT root>/_BLACKBOX/
##   creator_private.key    — signing key (never published; back it up)
##   ledger.json            — every extracted piece: edition, hash, canonical code, signature, status
##   registry_public.json   — the public subset (edition, hash, era, signature) — copy to the viewer site to publish
##   README.md              — what is here and how to protect it
## Edition policy implemented (DRAFT, see EDITION-RULES.md): one log hash = one edition number; extracting the
## same piece again returns its existing edition instead of a new one.

const DIR_NAME := "_BLACKBOX"


static func dir_for(root: String) -> String:
	return root.path_join(DIR_NAME)


static func has_key(bb: String) -> bool:
	return FileAccess.file_exists(bb.path_join(Signer.PRIVATE_FILE))


static func load_ledger(bb: String) -> Dictionary:
	var j = JSON.parse_string(FileAccess.get_file_as_string(bb.path_join("ledger.json"))) if FileAccess.file_exists(bb.path_join("ledger.json")) else null
	return j if typeof(j) == TYPE_DICTIONARY else {"editions": []}


static func find(ledger: Dictionary, log_hash: String) -> Dictionary:
	for e in ledger.editions:
		if e.hash == log_hash:
			return e
	return {}


## Records (or returns the existing record of) one piece. Signs it when a creator key is present.
static func record(bb: String, sim: DialecticSim, era_id: String, role: String, code: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(bb)
	_write_readme(bb)
	var ledger := load_ledger(bb)
	var h := sim.log_hash()
	var existing := find(ledger, h)
	if not existing.is_empty():
		return existing.merged({"duplicate": true})
	var edition: int = ledger.editions.size() + 1
	var sig := ""
	if has_key(bb):
		sig = Signer.sign(bb.path_join(Signer.PRIVATE_FILE), Signer.message(h, code, edition))
	var e := {"edition": edition, "hash": h, "code": code, "era": era_id, "role": role, "outcome": sim.outcome,
		"synthesis_type": (sim as NodeSim).synthesis_type if sim is NodeSim else "", "signature": sig,
		"extracted_at": Time.get_datetime_string_from_system(true), "status": "extracted"}
	ledger.editions.append(e)
	_save(bb.path_join("ledger.json"), ledger)
	var reg: Array = []
	for x in ledger.editions:
		if x.signature != "":
			reg.append({"edition": x.edition, "hash": x.hash, "era": x.era, "signature": x.signature, "code": x.code})
	_save(bb.path_join("registry_public.json"), {"creator_public_key_file": Signer.PUBLIC_FILE, "pieces": reg})
	return e.merged({"duplicate": false})


static func _save(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  ") + "\n")
		f.close()


static func _write_readme(bb: String) -> void:
	var p := bb.path_join("README.md")
	if FileAccess.file_exists(p):
		return
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f == null:
		return
	f.store_string("""# _BLACKBOX — private

Nothing in this folder is ever published by the game.

- `creator_private.key` — your signing key. Anyone holding it can sign pieces as you. **Back it up** (if lost, you
  cannot sign new pieces with the same identity) and never upload it.
- `ledger.json` — every piece extracted from the Node: edition number, log hash, canonical replay code, signature.
- `registry_public.json` — the part that is safe to publish. Copy it to the viewer site as `registry.json`
  so the viewer can show SIGNED · EDITION #n.

## Protect this folder
Make an encrypted disk image of it (Disk Utility → File → New Image → Image from Folder → Encryption: 256-bit AES)
with a password only you know, and keep the image instead of the plain folder. The game needs the folder (mounted
image) only while extracting and signing.
""")
	f.close()
