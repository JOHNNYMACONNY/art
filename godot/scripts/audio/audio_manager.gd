class_name AudioManager
extends Node

# Echos in the Scrap - Audio Engine & Sound Synthesis Manager
# Handles footstep, spatial interaction hums, frequency tuning noise, and vehicle engine audio

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
	BIKE_DISMOUNT
}

var _engine_player: AudioStreamPlayer3D = null
var _hum_player: AudioStreamPlayer3D = null
var _static_player: AudioStreamPlayer = null

func _ready() -> void:
	_hum_player = AudioStreamPlayer3D.new()
	_hum_player.name = "ProximityHumPlayer"
	_hum_player.bus = &"Master"
	_hum_player.unit_size = 10.0
	_hum_player.max_distance = 25.0
	add_child(_hum_player)
	_hum_player.stream = _generate_hum_stream()
	
	_engine_player = AudioStreamPlayer3D.new()
	_engine_player.name = "EngineRevPlayer"
	_engine_player.bus = &"Master"
	_engine_player.unit_size = 12.0
	_engine_player.max_distance = 30.0
	add_child(_engine_player)
	_engine_player.stream = _generate_engine_stream()
	
	_static_player = AudioStreamPlayer.new()
	_static_player.name = "StaticNoisePlayer"
	_static_player.bus = &"Master"
	add_child(_static_player)
	_static_player.stream = _generate_static_stream()

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

func stop_event(event: SoundEvent) -> void:
	if event == SoundEvent.PROXIMITY_HUM and _hum_player:
		_hum_player.stop()
	elif event == SoundEvent.ENGINE_REV and _engine_player:
		_engine_player.stop()

func set_hum_pitch(pitch: float) -> void:
	if _hum_player:
		_hum_player.pitch_scale = clamp(pitch, 0.5, 2.5)

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

func _generate_hum_stream() -> AudioStreamGenerator:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	return gen

func _generate_engine_stream() -> AudioStreamGenerator:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	return gen

func _generate_static_stream() -> AudioStreamGenerator:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	return gen

func _play_synth_click(pos: Vector3, _freq: float, duration: float) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 8.0
	add_child(player_3d)
	player_3d.global_position = pos
	player_3d.play()
	get_tree().create_timer(duration).timeout.connect(player_3d.queue_free)

func _play_synth_sweep(pos: Vector3, _start_f: float, _end_f: float, duration: float) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 10.0
	add_child(player_3d)
	player_3d.global_position = pos
	player_3d.play()
	get_tree().create_timer(duration).timeout.connect(player_3d.queue_free)

func _play_synth_chime(pos: Vector3) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 12.0
	add_child(player_3d)
	player_3d.global_position = pos
	player_3d.play()
	get_tree().create_timer(0.5).timeout.connect(player_3d.queue_free)
