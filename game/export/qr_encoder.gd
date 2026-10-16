class_name QrEncoder
extends RefCounted
## Minimal QR Code encoder: byte mode, error correction M, versions 1-10 (up to 213 bytes).
## Follows ISO/IEC 18004 (structure after Nayuki's reference implementation). Cross-checked
## module-for-module against the Python `qrcode` package in tests/qr_encoder_test.gd.

const ECC_PER_BLOCK := [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26] # level M
const NUM_BLOCKS := [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5] # level M
const ALIGN := [[], [], [6, 18], [6, 22], [6, 26], [6, 30], [6, 34], [6, 22, 38], [6, 24, 42], [6, 26, 46], [6, 28, 50]]
const FORMAT_M := 0 # ECC level M format bits

var size := 0
var version := 0
var mask := -1
var _m: Array = [] # rows of bools (dark)
var _f: Array = [] # rows of bools (function module)


## Returns an encoder holding the symbol, or null if the data is too long. force_mask: -1 = choose by penalty.
static func encode(data: PackedByteArray, force_mask := -1) -> QrEncoder:
	var q := QrEncoder.new()
	for v in range(1, 11):
		var cap: int = _num_raw(v) / 8 - ECC_PER_BLOCK[v] * NUM_BLOCKS[v]
		var count_bits := 8 if v < 10 else 16
		if 4 + count_bits + data.size() * 8 <= cap * 8:
			q._build(v, data, cap, count_bits, force_mask)
			return q
	return null


func matrix() -> Array:
	return _m


func to_image(scale := 8, border := 4) -> Image:
	var px := (size + border * 2) * scale
	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in size:
		for x in size:
			if _m[y][x]:
				img.fill_rect(Rect2i((x + border) * scale, (y + border) * scale, scale, scale), Color.BLACK)
	return img


# ---------------- build ----------------

func _build(v: int, data: PackedByteArray, cap: int, count_bits: int, force_mask: int) -> void:
	version = v
	size = v * 4 + 17
	_m = []
	_f = []
	for y in size:
		var a := []; a.resize(size); a.fill(false)
		var b := []; b.resize(size); b.fill(false)
		_m.append(a)
		_f.append(b)
	# bit stream
	var bits: Array[int] = []
	_append_bits(bits, 0x4, 4)
	_append_bits(bits, data.size(), count_bits)
	for byte in data:
		_append_bits(bits, byte, 8)
	_append_bits(bits, 0, mini(4, cap * 8 - bits.size()))
	_append_bits(bits, 0, (8 - bits.size() % 8) % 8)
	var cw := PackedByteArray()
	for i in range(0, bits.size(), 8):
		var b := 0
		for j in 8:
			b = (b << 1) | bits[i + j]
		cw.append(b)
	var pad := 0xEC
	while cw.size() < cap:
		cw.append(pad)
		pad = 0x11 if pad == 0xEC else 0xEC
	var all := _add_ecc_and_interleave(cw)
	_draw_function_patterns()
	_draw_codewords(all)
	if force_mask >= 0:
		mask = force_mask
	else:
		var best := INF
		for msk in 8:
			_apply_mask(msk)
			_draw_format(msk)
			var p := _penalty()
			if p < best:
				best = p
				mask = msk
			_apply_mask(msk) # undo (XOR)
	_apply_mask(mask)
	_draw_format(mask)


static func _append_bits(bits: Array[int], val: int, n: int) -> void:
	for i in range(n - 1, -1, -1):
		bits.append((val >> i) & 1)


static func _num_raw(v: int) -> int:
	var r := (16 * v + 128) * v + 64
	if v >= 2:
		var na := v / 7 + 2
		r -= (25 * na - 10) * na - 55
		if v >= 7:
			r -= 36
	return r


func _set_fn(x: int, y: int, dark: bool) -> void:
	_m[y][x] = dark
	_f[y][x] = true


func _draw_function_patterns() -> void:
	for i in size:
		_set_fn(6, i, i % 2 == 0)
		_set_fn(i, 6, i % 2 == 0)
	for c in [[3, 3], [size - 4, 3], [3, size - 4]]:
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var xx: int = c[0] + dx
				var yy: int = c[1] + dy
				if xx >= 0 and xx < size and yy >= 0 and yy < size:
					var dist := maxi(absi(dx), absi(dy))
					_set_fn(xx, yy, dist != 2 and dist != 4)
	var pos: Array = ALIGN[version]
	var n := pos.size()
	for i in n:
		for j in n:
			if (i == 0 and j == 0) or (i == 0 and j == n - 1) or (i == n - 1 and j == 0):
				continue
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					_set_fn(pos[i] + dx, pos[j] + dy, maxi(absi(dx), absi(dy)) != 1)
	_draw_format(0)
	if version >= 7:
		var rem := version
		for i in 12:
			rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
		var vb := (version << 12) | rem
		for i in 18:
			var bit := ((vb >> i) & 1) != 0
			var a := size - 11 + i % 3
			var b := i / 3
			_set_fn(a, b, bit)
			_set_fn(b, a, bit)


func _draw_format(msk: int) -> void:
	var d := (FORMAT_M << 3) | msk
	var rem := d
	for i in 10:
		rem = (rem << 1) ^ ((rem >> 9) * 0x537)
	var bits := ((d << 10) | rem) ^ 0x5412
	for i in 6:
		_set_fn(8, i, ((bits >> i) & 1) != 0)
	_set_fn(8, 7, ((bits >> 6) & 1) != 0)
	_set_fn(8, 8, ((bits >> 7) & 1) != 0)
	_set_fn(7, 8, ((bits >> 8) & 1) != 0)
	for i in range(9, 15):
		_set_fn(14 - i, 8, ((bits >> i) & 1) != 0)
	for i in 8:
		_set_fn(size - 1 - i, 8, ((bits >> i) & 1) != 0)
	for i in range(8, 15):
		_set_fn(8, size - 15 + i, ((bits >> i) & 1) != 0)
	_set_fn(8, size - 8, true)


func _add_ecc_and_interleave(data: PackedByteArray) -> PackedByteArray:
	var nb: int = NUM_BLOCKS[version]
	var ecl: int = ECC_PER_BLOCK[version]
	var raw := _num_raw(version) / 8
	var n_short := nb - raw % nb
	var short_len := raw / nb
	var div := _rs_divisor(ecl)
	var blocks: Array = []
	var k := 0
	for i in nb:
		var dl := short_len - ecl + (0 if i < n_short else 1)
		var dat := data.slice(k, k + dl)
		k += dl
		var ecc := _rs_remainder(dat, div)
		if i < n_short:
			dat.append(0)
		dat.append_array(ecc)
		blocks.append(dat)
	var out := PackedByteArray()
	for i in (blocks[0] as PackedByteArray).size():
		for j in nb:
			if i != short_len - ecl or j >= n_short:
				out.append(blocks[j][i])
	return out


static func _rs_mul(x: int, y: int) -> int:
	var z := 0
	for i in range(7, -1, -1):
		z = (z << 1) ^ ((z >> 7) * 0x11D)
		z ^= ((y >> i) & 1) * x
	return z & 0xFF


static func _rs_divisor(degree: int) -> PackedByteArray:
	var r := PackedByteArray()
	r.resize(degree)
	r.fill(0)
	r[degree - 1] = 1
	var root := 1
	for i in degree:
		for j in degree:
			r[j] = _rs_mul(r[j], root)
			if j + 1 < degree:
				r[j] ^= r[j + 1]
		root = _rs_mul(root, 0x02)
	return r


static func _rs_remainder(data: PackedByteArray, div: PackedByteArray) -> PackedByteArray:
	var r := PackedByteArray()
	r.resize(div.size())
	r.fill(0)
	for b in data:
		var factor := b ^ r[0]
		r = r.slice(1)
		r.append(0)
		for i in div.size():
			r[i] ^= _rs_mul(div[i], factor)
	return r


func _draw_codewords(data: PackedByteArray) -> void:
	var i := 0
	var right := size - 1
	while right >= 1:
		if right == 6:
			right = 5
		for vert in size:
			for j in 2:
				var x := right - j
				var upward := ((right + 1) & 2) == 0
				var y := size - 1 - vert if upward else vert
				if not _f[y][x] and i < data.size() * 8:
					_m[y][x] = ((data[i >> 3] >> (7 - (i & 7))) & 1) != 0
					i += 1
		right -= 2


func _apply_mask(msk: int) -> void:
	for y in size:
		for x in size:
			if _f[y][x]:
				continue
			var inv := false
			match msk:
				0: inv = (x + y) % 2 == 0
				1: inv = y % 2 == 0
				2: inv = x % 3 == 0
				3: inv = (x + y) % 3 == 0
				4: inv = (x / 3 + y / 2) % 2 == 0
				5: inv = x * y % 2 + x * y % 3 == 0
				6: inv = (x * y % 2 + x * y % 3) % 2 == 0
				7: inv = ((x + y) % 2 + x * y % 3) % 2 == 0
			if inv:
				_m[y][x] = not _m[y][x]


## Simplified penalty (runs, 2x2 blocks, dark balance). Any mask decodes; this only picks a readable one.
func _penalty() -> float:
	var p := 0.0
	var dark := 0
	for y in size:
		var run := 1
		for x in size:
			if _m[y][x]:
				dark += 1
			if x > 0:
				if _m[y][x] == _m[y][x - 1]:
					run += 1
					if run == 5: p += 3
					elif run > 5: p += 1
				else:
					run = 1
			if x > 0 and y > 0 and _m[y][x] == _m[y][x - 1] and _m[y][x] == _m[y - 1][x] and _m[y][x] == _m[y - 1][x - 1]:
				p += 3
	for x in size:
		var run := 1
		for y in range(1, size):
			if _m[y][x] == _m[y - 1][x]:
				run += 1
				if run == 5: p += 3
				elif run > 5: p += 1
			else:
				run = 1
	var total := size * size
	p += floorf(absf(dark * 20.0 - total * 10.0) / total) * 10.0
	return p
