extends Node
## Placeholder sound effects synthesized at startup (no audio assets needed yet).
## Swap any entry for a real AudioStream later; call sites only use play("name").

const MIX_RATE := 22050
const VOICES := 10

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_streams["hit_light"] = _thump(0.07, 170.0, 0.55, 0.5)
	_streams["hit_medium"] = _thump(0.12, 120.0, 0.6, 0.65)
	_streams["hit_heavy"] = _thump(0.22, 75.0, 0.7, 0.85)
	_streams["ko"] = _thump(0.7, 55.0, 0.9, 1.0)
	_streams["swing"] = _noise_sweep(0.08, 0.18)
	_streams["swing_heavy"] = _noise_sweep(0.16, 0.22)
	_streams["spear_slash"] = _mix(_thump(0.06, 260.0, 0.7, 0.45), _tone_sweep(0.06, 1400.0, 900.0, 0.12))
	_streams["shield_bash"] = _mix(_thump(0.14, 110.0, 0.5, 0.7), _square(0.1, 330.0, 0.12))
	_streams["spear_finisher"] = _mix(_thump(0.16, 95.0, 0.7, 0.75), _tone_sweep(0.1, 1600.0, 700.0, 0.12))
	_streams["axe_light"] = _mix(_thump(0.08, 150.0, 0.8, 0.55), _noise_sweep(0.05, 0.1))
	_streams["axe_heavy"] = _mix(_thump(0.28, 55.0, 0.9, 0.95), _noise_sweep(0.12, 0.14))
	_streams["jump"] = _tone_sweep(0.07, 260.0, 520.0, 0.25)
	_streams["land"] = _thump(0.05, 90.0, 0.2, 0.25)
	_streams["dodge"] = _noise_sweep(0.12, 0.12)
	_streams["tech"] = _tone_sweep(0.06, 700.0, 900.0, 0.25)
	_streams["menu_move"] = _square(0.04, 660.0, 0.15)
	_streams["menu_ok"] = _square(0.09, 990.0, 0.2)
	_streams["beep"] = _square(0.12, 520.0, 0.2)
	_streams["go"] = _square(0.3, 880.0, 0.25)


func play(sound: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
	if not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db
	p.play()


## Hit sound scaled by damage dealt.
func play_hit(damage: float) -> void:
	if damage >= 13.0:
		play("hit_heavy")
	elif damage >= 7.0:
		play("hit_medium")
	else:
		play("hit_light")


# --- synthesis helpers -------------------------------------------------------

## Layers two sounds (the shorter one is padded with silence).
func _mix(a: AudioStreamWAV, b: AudioStreamWAV) -> AudioStreamWAV:
	var n := maxi(a.data.size(), b.data.size()) / 2
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var va := a.data.decode_s16(i * 2) / 32767.0 if i * 2 < a.data.size() else 0.0
		var vb := b.data.decode_s16(i * 2) / 32767.0 if i * 2 < b.data.size() else 0.0
		out[i] = va + vb
	return _wav(out)


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = MIX_RATE
	s.stereo = false
	s.data = data
	return s


## Low sine "body" plus a noise crack, both with exponential decay.
func _thump(length: float, freq: float, noise_amount: float, gain: float) -> AudioStreamWAV:
	var n := int(length * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var env := exp(-t / (length * 0.3))
		var f := freq * (1.0 + 1.5 * exp(-t * 40.0))
		phase += TAU * f / MIX_RATE
		var crack := randf_range(-1.0, 1.0) * exp(-t * 60.0) * noise_amount
		out[i] = (sin(phase) * 0.8 + crack) * env * gain
	return _wav(out)


func _noise_sweep(length: float, gain: float) -> AudioStreamWAV:
	var n := int(length * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / n
		var k := lerpf(0.05, 0.6, t)  # one-pole low-pass opening up = "whoosh"
		last = lerpf(last, randf_range(-1.0, 1.0), k)
		out[i] = last * sin(PI * t) * gain * 3.0
	return _wav(out)


func _tone_sweep(length: float, f0: float, f1: float, gain: float) -> AudioStreamWAV:
	var n := int(length * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += TAU * lerpf(f0, f1, t) / MIX_RATE
		out[i] = sin(phase) * (1.0 - t) * gain
	return _wav(out)


func _square(length: float, freq: float, gain: float) -> AudioStreamWAV:
	var n := int(length * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / MIX_RATE
		out[i] = (1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0) * gain * (1.0 - float(i) / n)
	return _wav(out)
