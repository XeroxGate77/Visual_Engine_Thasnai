extends SceneTree
## Check an era pack before it goes into the game. Writes nothing.
##   godot --headless --path game -s tools/check_era_pack.gd -- /path/to/pack.json
## Exit 0 = valid (warnings are for the owner to judge), 1 = rejected.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: godot --headless --path game -s tools/check_era_pack.gd -- pack.json")
		quit(1)
		return
	var p := EraPack.load_file(args[0])
	for w in p.warnings:
		print("note: ", w)
	if not p.ok:
		for e in p.errors:
			print("ERROR: ", e)
		print("RESULT: REJECTED")
		quit(1)
		return
	var rep := EraPackCheck.report(p.era)
	print(EraPackCheck.format(p.id, rep))
	print("content hash: ", p.hash)
	var ok: bool = rep.measure.deterministic
	print("RESULT: ", "VALID — copy it into game/era_packs/" if ok else "REJECTED")
	quit(0 if ok else 1)
