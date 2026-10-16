extends SceneTree
## Offline: replay code round-trips every role (incl. AUTO-FINISH midway), and the NFT package is written correctly.
## godot --headless --path game -s tests/export_test.gd

var failures := 0

func check(cond: bool, label: String) -> void:
	failures += 0 if cond else 1
	if not cond:
		print("FAIL ", label)


## Plays like main.gd does: human for `human_beats` beats, then AUTO-FINISH (sim.step()).
func play(seed_value: int, era: String, role: String, human_beats: int, pick: RandomNumberGenerator) -> DialecticSim:
	var sim := DialecticSim.new(seed_value, 60, Eras.get_era(era).commands)
	var pending := [0.0]
	if role == "audience":
		sim.audience_chooser = func(_s: DialecticSim) -> float: return pending[0]
	while not sim.ended:
		if sim.beat >= human_beats:
			sim.step()
			continue
		match role:
			"audience":
				pending[0] = [-0.2, 0.0, 0.2][pick.randi_range(0, 2)]
				sim.begin_beat()
				sim.finish_beat()
			"persona":
				sim.begin_beat()
				sim.finish_beat(["obey", "negotiate", "defy"][pick.randi_range(0, 2)])
			"system":
				sim.begin_beat(pick.randi_range(0, 3))
				sim.finish_beat()
	return sim


func _init() -> void:
	var pick := RandomNumberGenerator.new()
	pick.seed = 99
	var cases := 0
	var synth: DialecticSim = null
	for era in Eras.ORDER:
		for role in ["audience", "persona", "system"]:
			for s in range(1, 21):
				var hb: int = [999, 0, 3, pick.randi_range(1, 30)][s % 4] # full human / instant auto / early / random
				var sim := play(s * 7919, era, role, hb, pick)
				var code := ReplayCode.encode(sim, era, role)
				var r := ReplayCode.decode(code)
				check(code != "" and r.ok and r.hash == sim.log_hash(), "round-trip %s %s seed %d hb %d" % [era, role, s, hb])
				cases += 1
				if synth == null and sim.outcome == "synthesis" and role == "persona":
					synth = sim
	print("replay round-trips: ", cases)
	check(not ReplayCode.decode("SD1.industrial.p.1.0.x.zzzz").ok, "tampered hash rejected")
	check(not ReplayCode.decode("hello").ok, "malformed rejected")
	check(not ReplayCode.decode("SD1.atlantis.p.1.0.o.abc").ok, "unknown era rejected")

	# QR of a real code fits and is square
	var code := ReplayCode.encode(synth, "industrial", "persona")
	var qr := QrEncoder.encode(code.to_utf8_buffer())
	check(qr != null and qr.matrix().size() == qr.size, "QR built for real code (v%d, %d chars)" % [qr.version if qr else -1, code.length()])

	# the longest possible code (audience, 60 beats, 2 chars per beat) + the viewer link still fits a QR
	var longest := "SD6.posttruth.a.2147483647.60." + "zC".repeat(60) + ".aaaaaaaaaaaa"
	var lq := QrEncoder.encode(NftPackage.qr_payload(longest).to_utf8_buffer())
	check(lq != null, "longest code + viewer URL fits QR (%d bytes)" % NftPackage.qr_payload(longest).length())
	check(NftPackage.qr_payload("X").begins_with("https://xeroxgate77.github.io/engine77/#"), "QR payload is the viewer link")

	# NFT package
	var root := ProjectSettings.globalize_path("res://tests/_out")
	var art := Image.create(64, 64, false, Image.FORMAT_RGB8)
	art.fill(Color("e0a030"))
	var res := NftPackage.write(synth, "industrial", "persona", art, {"text": "T", "dilemma": "D"}, root)
	check(res.ok, "package written")
	if res.ok:
		for f in ["art.png", "qr.png", "replay.txt", "metadata.json", "README-MINT.md",
				"derivatives/qr_ink.png", "derivatives/qr_dots.png", "derivatives/qr_emblem.png"]:
			check(FileAccess.file_exists(res.dir.path_join(f)), "has " + f)
		var canon := Image.load_from_file(res.dir.path_join("qr.png"))
		var only_bw := true
		for y in range(0, canon.get_height(), 7):
			for x in range(0, canon.get_width(), 7):
				var c := canon.get_pixel(x, y)
				only_bw = only_bw and (c == Color.WHITE or c == Color.BLACK)
		check(only_bw, "canonical qr.png is raw black-and-white")
		var md = JSON.parse_string(FileAccess.get_file_as_string(res.dir.path_join("metadata.json")))
		check(typeof(md) == TYPE_DICTIONARY and md.image.begins_with("ipfs://") and md.attributes.size() >= 8, "metadata is ERC-721 shaped")
		var rc := FileAccess.get_file_as_string(res.dir.path_join("replay.txt")).strip_edges()
		check(ReplayCode.decode(rc).ok, "replay.txt decodes to the same game")
		check(FileAccess.get_file_as_string(res.dir.path_join("README-MINT.md")).contains("Nothing has been minted"), "readme says not minted")
	var lose := DialecticSim.new(1, 1)
	lose.run()
	check(not NftPackage.write(lose, "industrial", "persona", art, {}, root).ok, "no-synthesis game refused")
	if res.ok:
		for f in DirAccess.get_files_at(res.dir.path_join("derivatives")):
			DirAccess.remove_absolute(res.dir.path_join("derivatives").path_join(f))
		DirAccess.remove_absolute(res.dir.path_join("derivatives"))
		for f in DirAccess.get_files_at(res.dir):
			DirAccess.remove_absolute(res.dir.path_join(f))
		DirAccess.remove_absolute(res.dir)
		DirAccess.remove_absolute(root)

	print("RESULT: ", "FAIL (%d)" % failures if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
