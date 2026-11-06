extends RefCounted
## Sintetizador procedural: genera TODOS los sonidos y la música del juego
## por código (sin archivos de audio). Ventajas: proyecto liviano, sin
## licencias de terceros, y fácil de reemplazar después por grabaciones reales.

const RATE := 22050


static func new_buffer(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	b.fill(0.0)
	return b


static func midi(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


static func pcm_bytes(b: PackedFloat32Array) -> PackedByteArray:
	var peak := 0.0001
	for v in b:
		peak = maxf(peak, absf(v))
	var g := minf(1.0, 0.85 / peak)
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in b.size():
		data.encode_s16(i * 2, int(clampf(b[i] * g, -1.0, 1.0) * 32767.0))
	return data


static func wav_from_bytes(data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size() / 2
	return w


static func to_wav(b: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	return wav_from_bytes(pcm_bytes(b), loop)


## Cuerda pulsada (Karplus-Strong): guitarra criolla.
static func add_pluck(b: PackedFloat32Array, start: float, freq: float, dur: float, gain: float,
		rng: RandomNumberGenerator, damp: float = 0.996, wrap: bool = false) -> void:
	var n := maxi(2, int(RATE / freq))
	var ring := PackedFloat32Array()
	ring.resize(n)
	var prev := 0.0
	for i in n:
		prev = prev * 0.5 + rng.randf_range(-1.0, 1.0) * 0.5   # ruido suavizado = tono más cálido
		ring[i] = prev
	var s0 := int(start * RATE)
	var length := int(dur * RATE)
	var size := b.size()
	if not wrap:
		length = mini(length, size - s0)
	var idx := 0
	var fade := mini(400, length)
	for i in length:
		var nxt := idx + 1
		if nxt >= n:
			nxt = 0
		var v := ring[idx]
		ring[idx] = (v + ring[nxt]) * 0.5 * damp
		var e := 1.0
		if i > length - fade:
			e = float(length - i) / fade
		var k := s0 + i
		if wrap:
			k = k % size
		b[k] += v * gain * e
		idx = nxt


## Tono con envolvente. wave: "sine", "saw", "square", "quena".
static func add_tone(b: PackedFloat32Array, start: float, freq: float, dur: float, gain: float,
		wave: String = "sine", freq_end: float = -1.0, vibrato: float = 0.0,
		attack: float = 0.01, release: float = 0.08, wrap: bool = false,
		rng: RandomNumberGenerator = null) -> void:
	var s0 := int(start * RATE)
	var length := int(dur * RATE)
	var size := b.size()
	if not wrap:
		length = mini(length, size - s0)
	var ph := 0.0
	var a := maxi(1, int(attack * RATE))
	var r := maxi(1, int(release * RATE))
	if freq_end < 0.0:
		freq_end = freq
	for i in length:
		var t := float(i) / RATE
		var f := lerpf(freq, freq_end, float(i) / length)
		if vibrato > 0.0:
			f *= 1.0 + vibrato * sin(TAU * 5.5 * t)
		ph += f / RATE
		ph -= floorf(ph)
		var v := 0.0
		match wave:
			"sine": v = sin(TAU * ph)
			"saw": v = 2.0 * ph - 1.0
			"square": v = 1.0 if ph < 0.5 else -1.0
			"quena":
				v = sin(TAU * ph) + 0.25 * sin(TAU * ph * 2.0) + 0.08 * sin(TAU * ph * 3.0)
				if rng:
					v += rng.randf_range(-0.12, 0.12)
		var e := 1.0
		if i < a:
			e = float(i) / a
		elif i > length - r:
			e = float(length - i) / r
		var k := s0 + i
		if wrap:
			k = k % size
		b[k] += v * gain * e


static func add_noise(b: PackedFloat32Array, start: float, dur: float, gain: float,
		rng: RandomNumberGenerator, decay: float = 20.0, smooth: float = 0.0, wrap: bool = false) -> void:
	var s0 := int(start * RATE)
	var length := int(dur * RATE)
	var size := b.size()
	if not wrap:
		length = mini(length, size - s0)
	var prev := 0.0
	for i in length:
		var t := float(i) / RATE
		var v := rng.randf_range(-1.0, 1.0)
		prev = prev * smooth + v * (1.0 - smooth)
		var k := s0 + i
		if wrap:
			k = k % size
		b[k] += prev * gain * exp(-decay * t)


## Bombo legüero: parche (grave) y aro (golpe seco en el borde).
static func add_bombo(b: PackedFloat32Array, start: float, gain: float, rng: RandomNumberGenerator, wrap: bool = false) -> void:
	var s0 := int(start * RATE)
	var length := int(0.45 * RATE)
	var size := b.size()
	if not wrap:
		length = mini(length, size - s0)
	var ph := 0.0
	for i in length:
		var t := float(i) / RATE
		var f := 48.0 + 70.0 * exp(-t * 18.0)
		ph += f / RATE
		var v := sin(TAU * ph) * exp(-t * 7.0)
		if i < 300:
			v += rng.randf_range(-0.4, 0.4) * (1.0 - i / 300.0)
		var k := s0 + i
		if wrap:
			k = k % size
		b[k] += v * gain


static func add_aro(b: PackedFloat32Array, start: float, gain: float, rng: RandomNumberGenerator, wrap: bool = false) -> void:
	add_noise(b, start, 0.05, gain * 0.6, rng, 90.0, 0.2, wrap)
	add_tone(b, start, 820.0, 0.04, gain * 0.35, "sine", 600.0, 0.0, 0.001, 0.03, wrap)


# --------------------------------------------------------------------- SFX

static func make_sfx() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var out := {}
	var b: PackedFloat32Array

	b = new_buffer(0.14)
	add_noise(b, 0.0, 0.12, 0.7, rng, 45.0, 0.55)
	add_tone(b, 0.0, 150.0, 0.06, 0.5, "sine", 90.0, 0.0, 0.001, 0.04)
	out["card"] = to_wav(b)

	b = new_buffer(0.08)
	add_noise(b, 0.0, 0.07, 0.5, rng, 60.0, 0.3)
	out["deal"] = to_wav(b)

	b = new_buffer(0.05)
	add_tone(b, 0.0, 1250.0, 0.04, 0.4, "sine", 900.0, 0.0, 0.001, 0.03)
	out["click"] = to_wav(b)

	b = new_buffer(0.7)
	add_bombo(b, 0.0, 0.9, rng)
	add_tone(b, 0.05, midi(57), 0.5, 0.25, "saw", midi(64), 0.01, 0.03, 0.2)
	add_tone(b, 0.05, midi(61), 0.5, 0.18, "saw", midi(68), 0.01, 0.03, 0.2)
	add_bombo(b, 0.22, 0.6, rng)
	out["call"] = to_wav(b)

	b = new_buffer(1.3)
	for k in 3:
		add_bombo(b, k * 0.16, 1.0, rng)
	add_noise(b, 0.48, 0.8, 0.35, rng, 4.0, 0.1)
	add_tone(b, 0.48, midi(57), 0.75, 0.22, "saw", -1.0, 0.012, 0.02, 0.3)
	add_tone(b, 0.48, midi(61), 0.75, 0.18, "saw", -1.0, 0.012, 0.02, 0.3)
	add_tone(b, 0.48, midi(64), 0.75, 0.18, "saw", -1.0, 0.012, 0.02, 0.3)
	out["call_big"] = to_wav(b)

	b = new_buffer(0.5)
	add_bombo(b, 0.0, 1.2, rng)
	add_noise(b, 0.0, 0.25, 0.8, rng, 25.0, 0.7)
	out["bang"] = to_wav(b)

	b = new_buffer(0.4)
	add_tone(b, 0.0, midi(72), 0.14, 0.35, "sine", -1.0, 0.0, 0.005, 0.05)
	add_tone(b, 0.12, midi(79), 0.25, 0.35, "sine", -1.0, 0.0, 0.005, 0.15)
	out["quiero"] = to_wav(b)

	b = new_buffer(0.5)
	add_tone(b, 0.0, midi(67), 0.18, 0.25, "square", -1.0, 0.0, 0.005, 0.05)
	add_tone(b, 0.17, midi(60), 0.3, 0.25, "square", midi(58), 0.0, 0.005, 0.2)
	out["no_quiero"] = to_wav(b)

	b = new_buffer(0.6)
	add_pluck(b, 0.0, midi(76), 0.6, 0.7, rng)
	out["win_baza"] = to_wav(b)

	b = new_buffer(1.4)
	var arp := [69, 73, 76, 81, 85]
	for i in arp.size():
		add_pluck(b, i * 0.09, midi(arp[i]), 1.0, 0.6, rng)
	add_bombo(b, 0.0, 0.6, rng)
	out["win_hand"] = to_wav(b)

	b = new_buffer(1.8)
	add_tone(b, 0.0, midi(58), 0.35, 0.3, "saw", midi(57), 0.0, 0.02, 0.08)
	add_tone(b, 0.38, midi(57), 0.35, 0.3, "saw", midi(56), 0.0, 0.02, 0.08)
	add_tone(b, 0.76, midi(56), 0.9, 0.3, "saw", midi(52), 0.02, 0.02, 0.4)
	out["lose_hand"] = to_wav(b)

	b = new_buffer(1.2)
	add_noise(b, 0.0, 1.1, 0.6, rng, 2.5, 0.85)
	add_tone(b, 0.0, 95.0, 1.1, 0.45, "saw", 60.0, 0.06, 0.08, 0.5)
	add_tone(b, 0.0, 142.0, 1.1, 0.25, "saw", 85.0, 0.08, 0.08, 0.5)
	out["roar"] = to_wav(b)

	b = new_buffer(2.4)
	for k in 4:
		add_bombo(b, k * 0.2, 0.9, rng)
	var fan := [57, 61, 64, 69, 73, 76, 81]
	for i in fan.size():
		add_pluck(b, 0.8 + i * 0.07, midi(fan[i]), 1.5, 0.55, rng)
	add_tone(b, 0.8, midi(81), 1.4, 0.15, "quena", -1.0, 0.01, 0.05, 0.6, false, rng)
	out["win_match"] = to_wav(b)

	b = new_buffer(0.6)
	add_pluck(b, 0.0, midi(64), 0.5, 0.5, rng)
	add_pluck(b, 0.08, midi(71), 0.5, 0.5, rng)
	add_aro(b, 0.0, 0.7, rng)
	out["envido"] = to_wav(b)
	return out


# --------------------------------------------------------------------- MÚSICA

## Loop de chacarera en La menor (6/8): bombo legüero, guitarra y quena.
static func make_music() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1810
	var eighth := 0.2
	var bars := 16
	var b := new_buffer(bars * 6 * eighth)
	var chords := {
		"Am": {"bass": [45, 52], "notes": [57, 60, 64]},
		"E7": {"bass": [40, 47], "notes": [56, 59, 62, 64]},
		"Dm": {"bass": [38, 45], "notes": [57, 62, 65]},
	}
	var prog := ["Am", "Am", "E7", "E7", "Am", "Am", "E7", "Am",
		"Dm", "Dm", "Am", "Am", "E7", "E7", "Am", "Am"]
	for bar in bars:
		var t0 := bar * 6 * eighth
		var ch: Dictionary = chords[prog[bar]]
		# Bombo: parche en 1 y 4, aro en el resto.
		add_bombo(b, t0, 0.55, rng, true)
		add_aro(b, t0 + eighth, 0.25, rng, true)
		add_aro(b, t0 + 2 * eighth, 0.3, rng, true)
		add_bombo(b, t0 + 3 * eighth, 0.45, rng, true)
		add_aro(b, t0 + 4 * eighth, 0.25, rng, true)
		add_aro(b, t0 + 5 * eighth, 0.35, rng, true)
		# Guitarra: bajo + rasguido arpegiado.
		add_pluck(b, t0, midi(ch["bass"][0]), 0.9, 0.55, rng, 0.997, true)
		add_pluck(b, t0 + 3 * eighth, midi(ch["bass"][1]), 0.7, 0.45, rng, 0.997, true)
		for beat in [1, 2, 4, 5]:
			var notes: Array = ch["notes"]
			for i in notes.size():
				add_pluck(b, t0 + beat * eighth + i * 0.012, midi(notes[i]), 0.35, 0.22, rng, 0.993, true)
	# Quena: melodía (compás, corchea de inicio, duración en corcheas, nota MIDI).
	var mel := [
		[2, 0, 2, 71], [2, 2, 1, 68], [2, 3, 1, 71], [2, 4, 2, 74],
		[3, 0, 3, 76], [3, 3, 1, 74], [3, 4, 2, 71],
		[4, 0, 2, 72], [4, 2, 1, 71], [4, 3, 3, 69],
		[5, 0, 2, 76], [5, 2, 1, 74], [5, 3, 1, 72], [5, 4, 1, 71], [5, 5, 1, 69],
		[6, 0, 2, 68], [6, 2, 1, 69], [6, 3, 3, 71], [7, 0, 5, 69],
		[8, 0, 2, 77], [8, 2, 1, 76], [8, 3, 3, 74],
		[9, 0, 2, 69], [9, 2, 1, 74], [9, 3, 3, 77],
		[10, 0, 2, 76], [10, 2, 1, 72], [10, 3, 3, 69],
		[11, 0, 2, 72], [11, 2, 1, 74], [11, 3, 3, 76],
		[12, 0, 2, 74], [12, 2, 1, 71], [12, 3, 3, 68],
		[13, 0, 2, 71], [13, 2, 1, 74], [13, 3, 3, 76],
		[14, 0, 2, 72], [14, 2, 1, 71], [14, 3, 3, 69], [15, 0, 4, 69],
	]
	for n in mel:
		var st: float = (n[0] * 6 + n[1]) * eighth
		var du: float = n[2] * eighth
		add_tone(b, st, midi(n[3]), du * 0.95, 0.16, "quena", -1.0, 0.006, 0.03, minf(0.12, du * 0.4), true, rng)
	return b
