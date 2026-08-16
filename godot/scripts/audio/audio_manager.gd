class_name AudioManager
extends Node

# Procedural Audio Manager for Echoes in the Scrapheap
# Synthesizes audio feedback for movement, proximity, panel extraction, and ambience.

enum SoundEvent {
	FOOTSTEP,
	PROXIMITY_HUM,
	PANEL_PEEL,
	SPARK,
	CORE_PULL,
	COMPLETION
}

var _players: Dictionary = {}

func _ready() -> void:
	# Create stream players for distinct sound categories
	for event in SoundEvent.values():
		var p := AudioStreamPlayer.new()
		p.name = "AudioPlayer_" + str(event)
		add_child(p)
		_players[event] = p
	_setup_synth_sounds()

func _setup_synth_sounds() -> void:
	# Generate procedural audio streams for prototype verification
	_players[SoundEvent.FOOTSTEP].stream = _create_click_stream(0.04, 120.0)
	_players[SoundEvent.PROXIMITY_HUM].stream = _create_hum_stream(0.5, 60.0)
	_players[SoundEvent.PANEL_PEEL].stream = _create_noise_stream(0.2, 800.0)
	_players[SoundEvent.SPARK].stream = _create_noise_stream(0.08, 2400.0)
	_players[SoundEvent.CORE_PULL].stream = _create_click_stream(0.3, 440.0)
	_players[SoundEvent.COMPLETION].stream = _create_chime_stream(0.6, 880.0)

func play_event(event: SoundEvent) -> void:
	if _players.has(event):
		var p: AudioStreamPlayer = _players[event]
		if not p.playing:
			p.play()

func stop_event(event: SoundEvent) -> void:
	if _players.has(event):
		var p: AudioStreamPlayer = _players[event]
		p.stop()

# Helper procedural generator functions
func _create_click_stream(duration: float, freq: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(wav.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(wav.mix_rate)
		var env := 1.0 - (t / duration)
		var sample := int(128.0 + 127.0 * sin(2.0 * PI * freq * t) * env)
		data[i] = clamp(sample, 0, 255)
	wav.data = data
	return wav

func _create_hum_stream(duration: float, freq: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = int(wav.mix_rate * duration)
	var sample_count := int(wav.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(wav.mix_rate)
		var sample := int(128.0 + 40.0 * (sin(2.0 * PI * freq * t) + 0.5 * sin(2.0 * PI * (freq * 2.0) * t)))
		data[i] = clamp(sample, 0, 255)
	wav.data = data
	return wav

func _create_noise_stream(duration: float, filter_freq: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(wav.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var env := 1.0 - (float(i) / float(sample_count))
		var noise := (randf() * 2.0 - 1.0) * env
		var sample := int(128.0 + 80.0 * noise)
		data[i] = clamp(sample, 0, 255)
	wav.data = data
	return wav

func _create_chime_stream(duration: float, freq: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(wav.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / float(wav.mix_rate)
		var env := exp(-4.0 * t / duration)
		var sample := int(128.0 + 100.0 * (sin(2.0 * PI * freq * t) + 0.5 * sin(2.0 * PI * (freq * 1.5) * t)) * env)
		data[i] = clamp(sample, 0, 255)
	wav.data = data
	return wav
