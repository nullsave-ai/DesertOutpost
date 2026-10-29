class_name Sfx
## Procedural sound effects (no audio files): gunshots, hit tick, reload click, bot shot. Built once, cached.
static var _c := {}

static func _wav(s: PackedFloat32Array, rate := 22050) -> AudioStreamWAV:
	var d := PackedByteArray(); d.resize(s.size() * 2)
	for i in s.size(): d.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = rate; w.stereo = false; w.data = d; return w

static func get_stream(kind: String) -> AudioStreamWAV:
	if _c.has(kind): return _c[kind]
	var rate := 22050; var rng := RandomNumberGenerator.new(); rng.seed = 7
	var n := 0; var out := PackedFloat32Array()
	match kind:
		"rifle", "bot":
			n = int(rate * 0.30); out.resize(n); var lp := 0.0
			for i in n:
				var t := float(i) / rate; var nz := rng.randf_range(-1.0, 1.0); lp += (nz - lp) * (0.55 if kind == "rifle" else 0.30)
				out[i] = (lp * exp(-t * 16.0) * 0.9 + sin(TAU * 70.0 * t) * exp(-t * 28.0) * 0.8 + nz * exp(-t * 70.0) * 0.5) * (1.0 if kind == "rifle" else 0.7)
		"sniper":
			n = int(rate * 0.9); out.resize(n); var lp2 := 0.0
			for i in n:
				var t := float(i) / rate; var nz := rng.randf_range(-1.0, 1.0); lp2 += (nz - lp2) * 0.22
				out[i] = lp2 * exp(-t * 6.5) * 1.1 + sin(TAU * 48.0 * t) * exp(-t * 12.0) * 1.0 + nz * exp(-t * 55.0) * 0.5
		"hit":
			n = int(rate * 0.07); out.resize(n)
			for i in n: var t := float(i) / rate; out[i] = sin(TAU * 1250.0 * t) * exp(-t * 55.0) * 0.5
		"kill":
			n = int(rate * 0.18); out.resize(n)
			for i in n: var t := float(i) / rate; out[i] = (sin(TAU * 700.0 * t) + sin(TAU * 1050.0 * t)) * exp(-t * 18.0) * 0.35
		"click":
			n = int(rate * 0.05); out.resize(n)
			for i in n: var t := float(i) / rate; out[i] = rng.randf_range(-1.0, 1.0) * exp(-t * 90.0) * 0.5
		"reload":
			n = int(rate * 0.30); out.resize(n)
			for i in n:
				var t := float(i) / rate; var a := exp(-t * 80.0) * (1.0 if t < 0.1 else 0.0) + (exp(-(t - 0.2) * 90.0) if t >= 0.2 else 0.0)
				out[i] = rng.randf_range(-1.0, 1.0) * a * 0.45
		"hurt":
			n = int(rate * 0.2); out.resize(n)
			for i in n: var t := float(i) / rate; out[i] = (sin(TAU * 120.0 * t) * 0.6 + rng.randf_range(-1.0, 1.0) * 0.3) * exp(-t * 18.0)
		_: out.resize(10)
	var w := _wav(out, rate); _c[kind] = w; return w

static func play(parent: Node, kind: String, db := 0.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer.new(); p.stream = get_stream(kind); p.volume_db = db; p.pitch_scale = pitch; parent.add_child(p); p.finished.connect(p.queue_free); p.play()

static func play3d(parent: Node, pos: Vector3, kind: String, db := 0.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer3D.new(); p.stream = get_stream(kind); p.volume_db = db; p.pitch_scale = pitch; p.unit_size = 12.0; p.max_distance = 220.0
	parent.add_child(p); p.global_position = pos; p.finished.connect(p.queue_free); p.play()
