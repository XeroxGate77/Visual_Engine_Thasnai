extends SceneTree
## Writes the three built-in eras as era-pack files into era_packs/builtin/ — templates for AIs and the proof that
## the pack format holds an era exactly (tests/era_pack_test.gd). Not loaded by the game (sub-folder).
##   godot --headless --path game -s tools/export_builtin_packs.gd

func _init() -> void:
	var dir := ProjectSettings.globalize_path("res://era_packs/builtin")
	DirAccess.make_dir_recursive_absolute(dir)
	for id in Eras.ORDER:
		var f := FileAccess.open(dir.path_join(id + ".json"), FileAccess.WRITE)
		f.store_string(EraPack.to_json(id, Eras.get_era(id), "XeroxGate77", "built-in (sim/eras.gd)"))
		f.close()
		print("wrote era_packs/builtin/%s.json" % id)
	quit(0)
