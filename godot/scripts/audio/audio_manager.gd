class_name AudioManager
extends Node

# Echos in the Scrap - Audio Engine & Sound Synthesis Manager
# Features valid procedural AudioStreamWAV buffers for spatial 3D audio and UI events

enum SoundEvent {
	FOOTSTEP,
	PROXIMITY_HUM,
	PANEL_PEEL,
	CORE_PULL,
	SPARK,
	COMPLETION,
	SIGNAL_LOCK,
	PANEL_POWERED,
	ENGINE_REV,
	BRAKE_SCREECH,
	BIKE_MOUNT,
	BIKE_DISMOUNT,
	SIREN_ALARM
}

var _engine_player: AudioStreamPlayer3D = null
var _hum_player: AudioStreamPlayer3D = null
var _static_player: AudioStreamPlayer = null
var _siren_player: AudioStreamPlayer3D = null

var _engine_stream: AudioStreamWAV = null
var _hum_stream: AudioStreamWAV = null
var _static_stream: AudioStreamWAV = null
var _siren_stream: AudioStreamWAV = null

func _ready() -> void:
	_engine_stream = _create_noise_wav(0.5, 0.4)
	_hum_stream = _create_tone_wav(120.0, 0.5, 0.3)
	_hum_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_static_stream = _create_noise_wav(0.5, 0.25)
	_siren_stream = _create_tone_wav(440.0, 0.6, 0.4)
	_siren_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	_hum_player = AudioStreamPlayer3D.new()
	_hum_player.name = "ProximityHumPlayer"
	_hum_player.bus = &"Master"
	_hum_player.unit_size = 10.0
	_hum_player.max_distance = 25.0
	_hum_player.stream = _hum_stream
	add_child(_hum_player)
	
	_engine_player = AudioStreamPlayer3D.new()
	_engine_player.name = "EngineRevPlayer"
	_engine_player.bus = &"Master"
	_engine_player.unit_size = 12.0
	_engine_player.max_distance = 30.0
	_engine_player.stream = _engine_stream
	add_child(_engine_player)
	
	_siren_player = AudioStreamPlayer3D.new()
	_siren_player.name = "SirenAlarmPlayer"
	_siren_player.bus = &"Master"
	_siren_player.unit_size = 15.0
	_siren_player.max_distance = 35.0
	_siren_player.stream = _siren_stream
	add_child(_siren_player)
	
	_static_player = AudioStreamPlayer.new()
	_static_player.name = "StaticNoisePlayer"
	_static_player.bus = &"Master"
	_static_player.stream = _static_stream
	add_child(_static_player)

func play_event(event: SoundEvent, pos: Vector3 = Vector3.ZERO) -> void:
	match event:
		SoundEvent.FOOTSTEP:
			_play_synth_click(pos, 320.0, 0.04)
		SoundEvent.PROXIMITY_HUM:
			if _hum_player and not _hum_player.playing:
				_hum_player.global_position = pos
				_hum_player.play()
		SoundEvent.PANEL_PEEL:
			_play_synth_sweep(pos, 180.0, 450.0, 0.25)
		SoundEvent.CORE_PULL:
			_play_synth_sweep(pos, 600.0, 1200.0, 0.4)
		SoundEvent.SPARK:
			_play_synth_click(pos, 880.0, 0.08)
		SoundEvent.COMPLETION:
			_play_synth_chime(pos)
		SoundEvent.SIGNAL_LOCK:
			_play_synth_sweep(pos, 440.0, 880.0, 0.35)
		SoundEvent.PANEL_POWERED:
			_play_synth_chime(pos)
		SoundEvent.ENGINE_REV:
			if _engine_player and not _engine_player.playing:
				_engine_player.global_position = pos
				_engine_player.play()
		SoundEvent.BRAKE_SCREECH:
			_play_synth_sweep(pos, 900.0, 300.0, 0.2)
		SoundEvent.BIKE_MOUNT:
			_play_synth_click(pos, 520.0, 0.1)
		SoundEvent.BIKE_DISMOUNT:
			_play_synth_click(pos, 380.0, 0.1)
		SoundEvent.SIREN_ALARM:
			set_siren_audio(true, pos)

func stop_event(event: SoundEvent) -> void:
	if event == SoundEvent.PROXIMITY_HUM and _hum_player:
		_hum_player.stop()
	elif event == SoundEvent.ENGINE_REV and _engine_player:
		_engine_player.stop()
	elif event == SoundEvent.SIREN_ALARM and _siren_player:
		_siren_player.stop()

func set_siren_audio(active: bool, pos: Vector3) -> void:
	if _siren_player:
		_siren_player.global_position = pos
		if active:
			if not _siren_player.playing:
				_siren_player.play()
		else:
			if _siren_player.playing:
				_siren_player.stop()

func set_hum_pitch(pitch: float) -> void:
	if _hum_player:
		_hum_player.pitch_scale = clampf(pitch, 0.5, 2.5)

func set_engine_audio(speed_ratio: float, pos: Vector3) -> void:
	if _engine_player:
		_engine_player.global_position = pos
		if speed_ratio > 0.01:
			if not _engine_player.playing:
				_engine_player.play()
			_engine_player.pitch_scale = lerp(0.8, 2.2, speed_ratio)
		else:
			if _engine_player.playing:
				_engine_player.stop()

func set_tuning_audio(accuracy: float) -> void:
	if _static_player:
		if accuracy > 0.01:
			if not _static_player.playing:
				_static_player.play()
			_static_player.volume_db = lerp(0.0, -24.0, accuracy)
		else:
			if _static_player.playing:
				_static_player.stop()

func _play_synth_click(pos: Vector3, freq: float, duration: float) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 8.0
	player_3d.stream = _create_tone_wav(freq, duration, 0.4)
	add_child(player_3d)
	player_3d.global_position = pos
	player_3d.play()
	get_tree().create_timer(duration + 0.05).timeout.connect(player_3d.queue_free)

func _play_synth_sweep(pos: Vector3, start_f: float, _end_f: float, duration: float) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 10.0
	player_3d.stream = _create_tone_wav(start_f, duration, 0.4)
	add_child(player_3d)
	player_3d.global_position = pos
	player_3d.play()
	get_tree().create_timer(duration + 0.05).timeout.connect(player_3d.queue_free)

func _play_synth_chime(pos: Vector3) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 12.0
	player_3d.stream = _create_tone_wav(880.0, 0.4, 0.5)
	add_child(player_3d)
	player_3d.global_position = pos
	player_3d.play()
	get_tree().create_timer(0.45).timeout.connect(player_3d.queue_free)

func _create_tone_wav(freq: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var sample := sin(2.0 * PI * freq * t) * volume
		data[i] = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

func _create_noise_wav(duration: float, volume: float = 0.3) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var sample := (randf() * 2.0 - 1.0) * volume
		data[i] = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav
