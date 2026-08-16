class_name AudioManager
extends Node

# State-Driven Spatialized 3D Audio Manager for Echos in the Scrap

enum SoundEvent {
	FOOTSTEP,
	PROXIMITY_HUM,
	PANEL_PEEL,
	SPARK,
	CORE_PULL,
	COMPLETION
}

var _players: Dictionary = {}
var _spatial_hum_player: AudioStreamPlayer3D = null

func _ready() -> void:
	for event in SoundEvent.values():
		if event == SoundEvent.PROXIMITY_HUM:
			var p3d := AudioStreamPlayer3D.new()
			p3d.name = "SpatialHumPlayer"
			p3d.unit_size = 4.0
			p3d.max_distance = 12.0
			add_child(p3d)
			_spatial_hum_player = p3d
			_players[event] = p3d
		else:
			var p := AudioStreamPlayer.new()
			p.name = "AudioPlayer_" + str(event)
			add_child(p)
			_players[event] = p
	_setup_synth_sounds()

func _setup_synth_sounds() -> void:
	_players[SoundEvent.FOOTSTEP].stream = _create_click_stream(0.04, 120.0)
	_players[SoundEvent.PROXIMITY_HUM].stream = _create_hum_stream(0.5, 65.0)
	_players[SoundEvent.PANEL_PEEL].stream = _create_noise_stream(0.25, 600.0)
	_players[SoundEvent.SPARK].stream = _create_noise_stream(0.08, 2400.0)
	_players[SoundEvent.CORE_PULL].stream = _create_click_stream(0.3, 440.0)
	_players[SoundEvent.COMPLETION].stream = _create_chime_stream(0.6, 880.0)

func play_event(event: SoundEvent, global_pos: Vector3 = Vector3.ZERO) -> void:
	if _players.has(event):
		if event == SoundEvent.PROXIMITY_HUM and _spatial_hum_player:
			_spatial_hum_player.global_position = global_pos
			if not _spatial_hum_player.playing:
				_spatial_hum_player.play()
		else:
			var p: AudioStreamPlayer = _players[event]
			if not p.playing:
				p.play()

func set_hum_pitch(pitch_scale: float) -> void:
	if _spatial_hum_player:
		_spatial_hum_player.pitch_scale = clamp(pitch_scale, 0.5, 2.0)

func stop_event(event: SoundEvent) -> void:
	if _players.has(event):
		_players[event].stop()

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
		var sample := int(128.0 + 45.0 * (sin(2.0 * PI * freq * t) + 0.5 * sin(2.0 * PI * (freq * 2.0) * t)))
		data[i] = clamp(sample, 0, 255)
	wav.data = data
	return wav

func _create_noise_stream(duration: float, _filter_freq: float) -> AudioStreamWAV:
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
