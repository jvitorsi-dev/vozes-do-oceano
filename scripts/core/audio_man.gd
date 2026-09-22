extends Node
## AudioMan — trilha e efeitos 100% procedurais (sem arquivos externos),
## mais a reprodução das vozes gravadas da tripulação.
##
## Camadas de trilha: SUB (drone grave), PAD (acorde dissonante suave),
## AR (chiado de ar/estrutura), WHINE (zumbido de sistema), WATER (oceano),
## PULSE (pulsação lenta, quase batimento cardíaco).

const VOICE_DIR := "res://assets/audio/vozes/"
const SFX_RATE := 22050.0

var _music_players: Dictionary = {}
var _patches: Dictionary = {}
var _sfx: Dictionary = {}
var _voices: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _ocean_energy := 0.2


class Patch extends RefCounted:
	var kind := "sine"
	var freqs: PackedFloat32Array = PackedFloat32Array()
	var gains: PackedFloat32Array = PackedFloat32Array()
	var phases: PackedFloat32Array = PackedFloat32Array()
	var amp := 0.0
	var target := 0.0
	var smooth := 0.5
	var t := 0.0
	var cutoff := 500.0
	var lp := 0.0
	var lfo_rate := 0.07
	var lfo_depth := 0.35
	var gate_rate := 0.0
	var rng := RandomNumberGenerator.new()

	func sample(dt: float) -> float:
		t += dt
		var s := 0.0
		match kind:
			"sine":
				for i in freqs.size():
					phases[i] = fmod(phases[i] + TAU * freqs[i] * dt, TAU)
					s += sin(phases[i]) * gains[i]
			"noise":
				var n := rng.randf() * 2.0 - 1.0
				lp += (n - lp) * clampf(cutoff * dt, 0.0, 1.0)
				s = lp * 3.2
			"pulse":
				var beat := pow(maxf(0.0, sin(t * TAU * gate_rate)), 6.0)
				s = sin(TAU * freqs[0] * t) * gains[0] * (0.15 + beat)
				phases[0] = 0.0
			"whine":
				s = sin(TAU * freqs[0] * t) * gains[0]
				s += sin(TAU * freqs[1] * t + 0.7) * gains[1]
				s *= 0.6 + 0.4 * sin(t * 2.1)
		var lfo := 1.0 - lfo_depth * 0.5 * (1.0 - cos(TAU * lfo_rate * t))
		amp += (target - amp) * clampf(dt * smooth, 0.0, 1.0)
		return s * amp * lfo


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 20260920
	_build_buses()
	_build_music()
	_build_sfx()
	_load_voices()


# ================================================================ BARRAMENTOS
func _bus(name: String, target: String, effects: Array) -> void:
	var idx := AudioServer.get_bus_index(name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, name)
		AudioServer.set_bus_send(idx, target)
	for e: AudioEffect in effects:
		AudioServer.add_bus_effect(idx, e)


func _build_buses() -> void:
	AudioServer.set_bus_volume_db(0, -6.0)
	_bus("Music", "Master", [])
	_bus("SFX", "Master", [_reverb(0.35, 0.25, 0.8, 0.5)])
	_bus("Voice", "Master", [_reverb(0.22, 0.18, 0.85, 0.55), _lowpass(12000.0)])
	_bus("Radio", "Master", [_bandpass(300.0, 1.2), _distort(0.12), _reverb(0.18, 0.15, 0.7, 0.4)])
	_bus("Interface", "Master", [])


func _reverb(amount: float, damping: float, size: float, wet: float) -> AudioEffectReverb:
	var r := AudioEffectReverb.new()
	r.room_size = size
	r.damping = damping
	r.wet = wet
	r.dry = 1.0 - wet * 0.5
	r.spread = 0.9
	return r


func _lowpass(cut: float) -> AudioEffectLowPassFilter:
	var f := AudioEffectLowPassFilter.new()
	f.cutoff_hz = cut
	return f


func _bandpass(cut: float, res: float) -> AudioEffectBandPassFilter:
	var f := AudioEffectBandPassFilter.new()
	f.cutoff_hz = cut
	f.resonance = res
	return f


func _distort(amount: float) -> AudioEffectDistortion:
	var d := AudioEffectDistortion.new()
	d.mode = AudioEffectDistortion.MODE_LOFI
	d.drive = amount * 5.0
	return d


# ================================================================ TRILHA
func _patch(name: String, kind: String, freqs: Array, gains: Array, amp: float,
		lfo_rate: float, lfo_depth: float, cutoff := 500.0, gate := 0.0) -> void:
	var p := Patch.new()
	p.kind = kind
	p.rng.seed = hash(name)
	for f: float in freqs:
		p.freqs.append(f)
	for g: float in gains:
		p.gains.append(g)
	while p.phases.size() < p.freqs.size():
		p.phases.append(0.0)
	p.amp = 0.0
	p.target = amp
	p.lfo_rate = lfo_rate
	p.lfo_depth = lfo_depth
	p.cutoff = cutoff
	p.gate_rate = gate
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = AudioServer.get_mix_rate()
	gen.buffer_length = 0.5
	var player := AudioStreamPlayer.new()
	player.name = name
	player.stream = gen
	player.bus = "Music"
	player.volume_db = 0.0
	add_child(player)
	player.play()
	_music_players[name] = player
	_patches[name] = p


func _build_music() -> void:
	# SUB: o peso da estação
	_patch("sub", "sine", [27.5, 41.2, 55.0], [0.5, 0.28, 0.12], 0.32, 0.013, 0.5)
	# PAD: Ré menor com nona - frio, quase harmônico
	_patch("pad", "sine", [73.42, 87.31, 110.0, 146.83, 174.61, 220.0],
			[0.20, 0.13, 0.16, 0.11, 0.07, 0.035], 0.30, 0.021, 0.6)
	# AR: o zumbido do ar condicionado / casco
	_patch("air", "noise", [], [], 0.10, 0.031, 0.4, 900.0)
	# WHINE: a estação funcionando
	_patch("whine", "whine", [1870.0, 2790.0], [0.010, 0.006], 1.0, 0.05, 0.2)
	# WATER: o oceano, sempre presente
	_patch("water", "noise", [], [], 0.0, 0.017, 0.7, 170.0)
	# PULSE: pulsação lenta — nunca um coração, quase um
	_patch("pulse", "pulse", [46.0], [0.18], 0.0, 0.05, 0.2, 300.0, 0.33)


func _process(_delta: float) -> void:
	var rate := AudioServer.get_mix_rate()
	var dt := 1.0 / rate
	for name: String in _music_players.keys():
		var player: AudioStreamPlayer = _music_players[name]
		var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
		if pb == null:
			continue
		var patch: Patch = _patches[name]
		var frames := mini(pb.get_frames_available(), 8192)
		# alimenta em blocos pequenos: estável e barato
		for i in frames:
			var s := patch.sample(dt)
			s = clampf(s, -1.0, 1.0)
			pb.push_frame(Vector2(s, s * 0.96))


func set_layer(name: String, amp: float) -> void:
	if _patches.has(name):
		_patches[name].target = amp


func get_layer(name: String) -> float:
	return _patches[name].amp if _patches.has(name) else 0.0


func set_ocean_energy(v: float) -> void:
	_ocean_energy = clampf(v, 0.0, 1.0)
	set_layer("water", 0.06 + _ocean_energy * 0.5)
	set_layer("sub", 0.30 + _ocean_energy * 0.45)
	_patches["water"].cutoff = 150.0 + _ocean_energy * 520.0


func music_intensity(v: float) -> void:
	# 0 = quase silêncio, 1 = tenso
	set_layer("pad", 0.14 + v * 0.34)
	set_layer("air", 0.05 + v * 0.10)
	set_layer("pulse", v * 0.30)


## "Tema do oceano" — usado nas manifestações e no final.
func theme_ocean(level: float) -> void:
	set_layer("pad", 0.20 + level * 0.4)
	set_layer("whine", 0.5 + level * 0.5)
	set_layer("sub", 0.45 + level * 0.4)


func stop_all_music() -> void:
	for name: String in _patches.keys():
		_patches[name].target = 0.0


# ================================================================ SFX SINTETIZADOS
func _wav(data: PackedFloat32Array, rate := SFX_RATE, loop := false) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = int(rate)
	s.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		var v := int(clampf(data[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = data.size()
	return s


func _env(i: int, n: int, attack: float, decay: float) -> float:
	var t := float(i) / float(n)
	var a := clampf(t / maxf(attack, 0.0001), 0.0, 1.0)
	var d := pow(1.0 - t, decay)
	return a * d


func _synth(kind: String, dur: float, freq := 220.0) -> PackedFloat32Array:
	var n := int(dur * SFX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var phase := 0.0
	match kind:
		"noise":
			for i in n:
				var s := _rng.randf_range(-1.0, 1.0)
				lp += (s - lp) * 0.25
				out[i] = lp * _env(i, n, 0.01, 2.5)
		"click":
			for i in n:
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.55
				out[i] = lp * _env(i, n, 0.002, 6.0) * 0.8
		"blip":
			for i in n:
				var t := float(i) / SFX_RATE
				var f := freq * (1.0 + 0.35 * exp(-t * 22.0))
				phase += TAU * f / SFX_RATE
				out[i] = (sin(phase) * 0.6 + sin(phase * 2.0) * 0.25) * _env(i, n, 0.005, 3.0) * 0.5
		"deny":
			for i in n:
				phase += TAU * freq / SFX_RATE
				var sq := signf(sin(phase))
				out[i] = sq * _env(i, n, 0.005, 2.0) * 0.35
		"clank":
			for i in n:
				var t := float(i) / SFX_RATE
				phase += TAU * 88.0 / SFX_RATE
				var ring := sin(phase) * exp(-t * 7.0) + sin(phase * 2.41) * exp(-t * 12.0) * 0.5
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.5
				out[i] = clampf(ring * 0.55 + lp * exp(-t * 30.0) * 0.5, -1.0, 1.0)
		"thud":
			for i in n:
				var t := float(i) / SFX_RATE
				var f := 78.0 - 30.0 * clampf(t / dur, 0.0, 1.0)
				phase += TAU * f / SFX_RATE
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.12
				out[i] = (sin(phase) * 0.7 + lp * 0.4) * _env(i, n, 0.004, 2.2)
		"door":
			for i in n:
				var t := float(i) / SFX_RATE
				var trem := 0.6 + 0.4 * sin(t * 26.0)
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.06
				phase += TAU * 54.0 / SFX_RATE
				out[i] = (lp * 0.7 * trem + sin(phase) * 0.35) * _env(i, n, 0.08, 0.8) * 0.7
		"step":
			for i in n:
				var t := float(i) / SFX_RATE
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.4
				phase += TAU * 190.0 / SFX_RATE
				out[i] = (lp * exp(-t * 40.0) + sin(phase) * exp(-t * 22.0) * 0.4) * 0.45
		"drip":
			for i in n:
				var t := float(i) / SFX_RATE
				var f := 1200.0 * exp(-t * 9.0) + 300.0
				phase += TAU * f / SFX_RATE
				out[i] = sin(phase) * exp(-t * 14.0) * 0.35
		"bell":
			for i in n:
				var t := float(i) / SFX_RATE
				var d1 := exp(-t * 0.42)
				var d2 := exp(-t * 0.31)
				var d3 := exp(-t * 0.22)
				out[i] = (sin(TAU * 118.0 * t) * d1 + sin(TAU * 118.0 * 3.02 * t) * d2 * 0.42
						+ sin(TAU * 118.0 * 5.43 * t) * d3 * 0.22 + sin(TAU * 61.0 * t) * d1 * 0.3) * 0.32
		"swell":
			for i in n:
				var t := float(i) / SFX_RATE
				var k := float(i) / float(n)
				phase += TAU * (60.0 + 240.0 * k) / SFX_RATE
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * (0.02 + 0.25 * k)
				out[i] = (sin(phase) * 0.35 + lp * 0.5) * pow(k, 1.6)
		"boom":
			for i in n:
				var t := float(i) / SFX_RATE
				var f := 48.0 * exp(-t * 0.6) + 26.0
				phase += TAU * f / SFX_RATE
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.05
				out[i] = (sin(phase) * 0.8 + lp * 0.5) * exp(-t * 0.9)
		"glitch":
			for i in n:
				var t := float(i) / SFX_RATE
				var step := int(t * 34.0)
				var f := 90.0 + fmod(float(step * 37 % 211), 120.0)
				phase += TAU * f / SFX_RATE
				out[i] = signf(sin(phase)) * 0.25 * exp(-t * 3.0) * (0.5 + 0.5 * sin(t * 70.0))
		"power":
			for i in n:
				var t := float(i) / SFX_RATE
				var k := float(i) / float(n)
				phase += TAU * (80.0 + 700.0 * k) / SFX_RATE
				out[i] = (sin(phase) * 0.3 + signf(sin(phase * 0.5)) * 0.1) * (1.0 - pow(1.0 - k, 3.0)) * 0.5
		"breath":
			# ciclo de 4 s: inspira, expira. Serve de laço.
			for i in n:
				var t := float(i) / SFX_RATE
				var ph := fmod(t / 4.0, 1.0)
				var inh := exp(-pow((ph - 0.22) / 0.10, 2.0))
				var exh := exp(-pow((ph - 0.70) / 0.16, 2.0)) * 0.75
				var env_b := inh + exh
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * (0.03 + 0.22 * env_b)
				out[i] = lp * env_b * 1.6
		"sea_loop":
			# mar distante: ruído grave modulado por duas ondas lentas
			for i in n:
				var t := float(i) / SFX_RATE
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.035
				var mod := 0.55 + 0.45 * sin(t * 0.19) * sin(t * 0.077)
				out[i] = lp * mod * 1.2
		"creak":
			# metal cedendo: ruído de banda estreita com subida de tensão
			for i in n:
				var k := float(i) / float(n)
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * (0.02 + 0.2 * k)
				out[i] = lp * pow(k, 0.7) * (1.0 - pow(k, 6.0)) * 0.9
		_:
			for i in n:
				lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.1
				out[i] = lp * _env(i, n, 0.01, 2.0)
	return out


func _build_sfx() -> void:
	_sfx["click"] = _wav(_synth("click", 0.06))
	_sfx["blip"] = _wav(_synth("blip", 0.11, 780.0))
	_sfx["blip_hi"] = _wav(_synth("blip", 0.08, 1240.0))
	_sfx["beep_ok"] = _wav(_synth("blip", 0.16, 660.0))
	_sfx["deny"] = _wav(_synth("deny", 0.22, 150.0))
	_sfx["clank"] = _wav(_synth("clank", 0.75))
	_sfx["thud"] = _wav(_synth("thud", 0.8))
	_sfx["door"] = _wav(_synth("door", 1.6))
	_sfx["step"] = _wav(_synth("step", 0.18))
	_sfx["drip"] = _wav(_synth("drip", 0.5))
	_sfx["bell"] = _wav(_synth("bell", 7.0))
	_sfx["swell"] = _wav(_synth("swell", 3.0))
	_sfx["boom"] = _wav(_synth("boom", 4.5))
	_sfx["glitch"] = _wav(_synth("glitch", 0.7))
	_sfx["power"] = _wav(_synth("power", 2.0))
	_sfx["static"] = _wav(_synth("noise", 0.6))
	_sfx["breath"] = _wav(_synth("breath", 4.0), SFX_RATE, true)
	_sfx["sea"] = _wav(_synth("sea_loop", 8.0), SFX_RATE, true)
	_sfx["creak"] = _wav(_synth("creak", 2.6))


func sfx(name: String) -> AudioStream:
	return _sfx.get(name, _sfx["click"])


func play_2d(name: String, volume_db := 0.0, pitch := 1.0, bus := "SFX") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = sfx(name)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = bus
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p


func play_3d(name: String, pos: Vector3, volume_db := 0.0, pitch := 1.0, max_dist := 26.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = sfx(name)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = "SFX"
	p.max_distance = max_dist
	p.unit_size = 3.0
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	get_tree().current_scene.add_child(p) if get_tree().current_scene != null else add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()
	return p


# ================================================================ VOZES
func _load_voices() -> void:
	var d := DirAccess.open(VOICE_DIR)
	if d == null:
		return
	for f: String in d.get_files():
		var ext := f.get_extension().to_lower()
		if ext != "mp3" and ext != "ogg" and ext != "wav":
			continue
		var key := f.get_basename()
		if key.ends_with(".mp3") or key.ends_with(".ogg"):
			key = key.get_basename()
		var res: AudioStream = load(VOICE_DIR + f) as AudioStream
		if res != null:
			_voices[key] = res


func has_voice(key: String) -> bool:
	return _voices.has(key)


func voice_stream(key: String) -> AudioStream:
	return _voices.get(key, null)


## Toca uma voz. pos = Vector3 (3D, no mundo) ou null (rádio / 2D).
func play_voice(key: String, pos: Variant = null, volume_db := 0.0, pitch := 1.0,
		radio := false) -> Node:
	var stream := voice_stream(key)
	if stream == null:
		return null
	var bus := "Radio" if radio else "Voice"
	if typeof(pos) == TYPE_VECTOR3:
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.volume_db = volume_db
		p3.pitch_scale = pitch
		p3.bus = bus
		p3.max_distance = 30.0
		p3.unit_size = 4.0
		if get_tree().current_scene != null:
			get_tree().current_scene.add_child(p3)
		else:
			add_child(p3)
		p3.global_position = pos
		p3.finished.connect(p3.queue_free)
		p3.play()
		return p3
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = bus
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p


func voice_duration(key: String) -> float:
	var s := voice_stream(key)
	return s.get_length() if s != null else 3.0
