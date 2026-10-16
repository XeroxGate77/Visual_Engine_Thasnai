extends SceneTree
## Dumps QR matrices for a set of payloads (cross-checked by tests/qr_crosscheck.py against Python `qrcode`).
func _init() -> void:
	var payloads := ["A", "HELLO WORLD", "SD1.industrial.p.123456789.24.onddonnodndonnddononddo.1a2b3c4d5e6f"]
	for n in [40, 60, 80, 100, 120, 150, 180, 213]:
		var s := ""
		for i in n:
			s += char(33 + (i * 7) % 90)
		payloads.append(s)
	var out := []
	for p in payloads:
		var q := QrEncoder.encode(p.to_utf8_buffer())
		var rows := []
		for r in q.matrix():
			var line := ""
			for c in r:
				line += "1" if c else "0"
			rows.append(line)
		out.append({"data": p, "version": q.version, "mask": q.mask, "rows": rows})
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("dumped ", out.size())
	quit()
