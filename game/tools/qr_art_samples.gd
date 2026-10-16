extends Node
## Windowed tool: renders the hi-res artwork and the 3 QR art styles for one real game into res://../docs/qr-art/.
## Run the scene tools/qr_art_samples.tscn (needs a renderer; not --headless).

func _ready() -> void:
	var out := ProjectSettings.globalize_path("res://../docs/qr-art")
	DirAccess.make_dir_recursive_absolute(out)
	var sim := NodeSimV4.new(3, 60, Eras.get_era("industrial").commands)
	sim.run()
	var payload := NftPackage.qr_payload(ReplayCode.encode(sim, "industrial", "persona"))
	var q := QrEncoder.encode(payload.to_utf8_buffer())
	var art: Image = await HiresRender.render(get_tree(), sim, 2048)
	art.save_png(out + "/art_2048.png")
	for style in ["ink", "dots", "emblem"]:
		QrArt.render(q, sim, style, 1600, art).save_png(out + "/qr_%s.png" % style)
	var f := FileAccess.open(out + "/payload.txt", FileAccess.WRITE)
	f.store_string(payload + "\n" + "art %dx%d\n" % [art.get_width(), art.get_height()])
	f.close()
	get_tree().quit()
