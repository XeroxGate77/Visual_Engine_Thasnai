class_name PlayerExtract
extends RefCounted
## Extracts made by PLAYERS in a public build (owner 2026-10-16: players may extract; no creator signature).
## The package is the normal one (NftPackage / NftPackagePack) — this only labels it honestly and, on the web,
## packs the folder into a .zip the browser can download (a browser cannot write to the Desktop).
## Player editions are numbered in the player's own ledger; they are never the creator's editions, and the viewer
## shows "Not in the creator's registry" for them.

const LABEL := "player — public build · not a creator edition"
const WEB_ROOT := "user://Subjugated Dialectics NFT"


## Adds the "Extracted by" attribute to metadata.json and a note to README-MINT.md. Idempotent.
static func mark(dir: String) -> void:
	var mp := dir.path_join("metadata.json")
	var md = JSON.parse_string(FileAccess.get_file_as_string(mp))
	if typeof(md) != TYPE_DICTIONARY:
		return
	for a in md.attributes:
		if a.trait_type == "Extracted by":
			return
	md.attributes.append({"trait_type": "Extracted by", "value": LABEL})
	NftPackage._write_text(mp, JSON.stringify(md, "  ") + "\n")
	var rp := dir.path_join("README-MINT.md")
	NftPackage._write_text(rp, FileAccess.get_file_as_string(rp) + "\n> Extracted by a player in the public build: unsigned, numbered in the player's own ledger — not an edition of the creator.\n")


## Zips `dir` (sub-folders included) into `zip_path`; returns the zip bytes (empty on failure).
static func zip_folder(dir: String, zip_path: String) -> PackedByteArray:
	DirAccess.make_dir_recursive_absolute(zip_path.get_base_dir())
	var z := ZIPPacker.new()
	if z.open(zip_path) != OK:
		return PackedByteArray()
	var top := dir.get_file()
	_add(z, dir, top)
	z.close()
	return FileAccess.get_file_as_bytes(zip_path)


static func _add(z: ZIPPacker, path: String, rel: String) -> void:
	for f in DirAccess.get_files_at(path):
		z.start_file(rel.path_join(f))
		z.write_file(FileAccess.get_file_as_bytes(path.path_join(f)))
		z.close_file()
	for d in DirAccess.get_directories_at(path):
		_add(z, path.path_join(d), rel.path_join(d))
