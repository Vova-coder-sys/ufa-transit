class_name Sfx
extends RefCounted

# Короткие клипы собираются в коде: мотор, двери, монета, валидатор, шаг, звонок.

const RATE := 22050

static var _bus: AudioStreamWAV
static var _trolley: AudioStreamWAV
static var _tram: AudioStreamWAV
static var _car: AudioStreamWAV
static var _door_open: AudioStreamWAV
static var _door_shut: AudioStreamWAV
static var _coin: AudioStreamWAV
static var _paper: AudioStreamWAV
static var _beep: AudioStreamWAV
static var _bell: AudioStreamWAV
static var _step: AudioStreamWAV
static var _clack: AudioStreamWAV
static var _tune: AudioStreamWAV
static var _coach: AudioStreamWAV
static var _squeak: AudioStreamWAV


static func engine_clip(kind: String, model := "") -> AudioStreamWAV:
	if model == "ikarus" or model == "yutong":
		if _coach == null:
			_coach = _diesel(36.0, 0.7)
		return _coach
	if kind == "tram":
		if _tram == null:
			_tram = _motor(148.0, 0.2, true)
		return _tram
	if kind == "trolley":
		if _trolley == null:
			_trolley = _motor(240.0, 0.04, false)
		return _trolley
	if _bus == null:
		_bus = _diesel(64.0, 0.5)
	return _bus


static func car_clip() -> AudioStreamWAV:
	if _car == null:
		_car = _diesel(92.0, 0.28)
	return _car


static func door_clip(opening: bool) -> AudioStreamWAV:
	if opening:
		if _door_open == null:
			_door_open = _hiss(0.4, false)
		return _door_open
	if _door_shut == null:
		_door_shut = _hiss(0.26, true)
	return _door_shut


static func coin_clip() -> AudioStreamWAV:
	if _coin == null:
		_coin = _ping(1680.0, 0.14, 2.4)
	return _coin


static func paper_clip() -> AudioStreamWAV:
	if _paper == null:
		_paper = _hiss(0.09, false)
	return _paper


static func beep_clip() -> AudioStreamWAV:
	if _beep == null:
		_beep = _two_tone(880.0, 1320.0, 0.16)
	return _beep


static func bell_clip() -> AudioStreamWAV:
	if _bell == null:
		_bell = _ping(740.0, 0.45, 6.0)
	return _bell


static func step_clip() -> AudioStreamWAV:
	if _step == null:
		_step = _hiss(0.07, true)
	return _step


static func clack_clip() -> AudioStreamWAV:
	if _clack == null:
		_clack = _ping(180.0, 0.05, 28.0)
	return _clack


static func tune_clip() -> AudioStreamWAV:
	if _tune == null:
		_tune = _melody()
	return _tune


static func squeak_clip() -> AudioStreamWAV:
	if _squeak == null:
		_squeak = _ping(980.0, 0.16, 16.0)
	return _squeak


static func _melody() -> AudioStreamWAV:
	# Короткий синтетический мотив маршрутки, без чужих записей.
	var notes := [262.0, 330.0, 392.0, 330.0, 294.0, 262.0, 220.0, 262.0]
	var count := int(RATE * 3.2)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(RATE)
		var idx := int(t / 0.4) % notes.size()
		var freq: float = notes[idx]
		phase += freq / float(RATE)
		var local := fmod(t, 0.4) / 0.4
		var env := sin(local * PI) * 0.35
		samples[i] = clampf(sin(phase * TAU) * env, -1.0, 1.0)
	return _pack(samples, true)


static func play(host: Node, stream: AudioStream, db: float, pitch := 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = db
	player.pitch_scale = pitch
	player.finished.connect(player.queue_free)
	host.add_child(player)
	player.play()


static func burst(host: Node3D, stream: AudioStream, db: float, pitch := 1.0) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = db
	player.pitch_scale = pitch
	player.unit_size = 6.0
	player.max_distance = 30.0
	player.finished.connect(player.queue_free)
	host.add_child(player)
	player.play()


static func _noise(i: int) -> float:
	var n := sin(float(i) * 12.9898) * 43758.5453
	return (n - floor(n)) * 2.0 - 1.0


static func _pack(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 26000.0))
	if loop and samples.size() > 800:
		var fade := 320
		var n := samples.size()
		for i in fade:
			var k := float(i) / float(fade)
			var head := float(data.decode_s16(i * 2))
			var at := (n - fade + i) * 2
			var tail := float(data.decode_s16(at))
			data.encode_s16(at, int(lerpf(tail, head, k)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream


static func _diesel(freq: float, grit: float) -> AudioStreamWAV:
	var count := int(RATE * 0.46)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lp := 0.0
	var phase := 0.0
	for i in count:
		lp += (_noise(i) - lp) * 0.055
		phase += freq / float(RATE)
		var hum := sin(phase * TAU) * 0.5 + sin(phase * TAU * 2.0) * 0.16
		samples[i] = clampf(hum + lp * grit, -1.0, 1.0) * 0.72
	return _pack(samples, true)


static func _motor(freq: float, grit: float, clicks: bool) -> AudioStreamWAV:
	var count := int(RATE * 0.36)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lp := 0.0
	var phase := 0.0
	var every := int(RATE * 0.12)
	for i in count:
		phase += freq / float(RATE)
		lp += (_noise(i + 4) - lp) * 0.04
		var tone := sin(phase * TAU) * 0.48 + sin(phase * TAU * 2.0) * 0.1
		var click := 0.0
		if clicks:
			var k := i % every
			if k < 160:
				click = sin(float(k) / 160.0 * PI) * 0.32
		samples[i] = clampf(tone + lp * grit + click, -1.0, 1.0)
	return _pack(samples, true)


static func _hiss(seconds: float, thud: bool) -> AudioStreamWAV:
	var count := int(RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lp := 0.0
	for i in count:
		var t := float(i) / float(count)
		var env := sin(PI * t) * (1.0 - t * 0.35)
		lp += (_noise(i + 11) - lp) * 0.28
		var s := lp * env * 0.85
		if thud and t > 0.62:
			var u := (t - 0.62) / 0.38
			s += sin(u * PI) * sin(u * 70.0) * 0.45
		samples[i] = clampf(s, -1.0, 1.0)
	return _pack(samples, false)


static func _ping(freq: float, seconds: float, decay: float) -> AudioStreamWAV:
	var count := int(RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(RATE)
		phase += freq / float(RATE)
		var env := exp(-t * decay)
		var s := sin(phase * TAU) * env + sin(phase * TAU * 2.6) * env * 0.28
		samples[i] = clampf(s, -1.0, 1.0) * 0.7
	return _pack(samples, false)


static func _two_tone(a: float, b: float, seconds: float) -> AudioStreamWAV:
	var count := int(RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	var freq := a
	for i in count:
		if i == int(count * 0.48):
			freq = b
			phase = 0.0
		phase += freq / float(RATE)
		var t := float(i) / float(count)
		var env := 1.0 - smoothstep(0.42, 0.5, t) * (1.0 - smoothstep(0.5, 0.58, t))
		if t < 0.48:
			env = 1.0
		elif t < 0.52:
			env = 0.2
		else:
			env = 1.0
		var edge := 1.0
		if t > 0.88:
			edge = (1.0 - t) / 0.12
		samples[i] = sin(phase * TAU) * env * edge * 0.45
	return _pack(samples, false)
