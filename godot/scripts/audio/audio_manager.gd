class_name AudioManager
extends Node

# Echos in the Scrap - Audio Engine & Sound Synthesis Manager
# Features procedural AudioStreamWAV synthesis, transient voice throttling,
# 3-tier perceptual mix hierarchy, and authoritative leak-proof instant reset.

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
	SIREN_ALARM,
	GATE_SLAM,
	DISMOUNT_REJECTED,
	DISTURBANCE_ALERT,
	PURSUIT_INTERCEPTED,
	EVASION_RELEASE,
	COLLISION_GLANCE,
	COLLISION_HEAD_ON
}

enum MixState {
	CALM,
	SIGNAL_CURIOSITY,
	TUNING_FOCUS,
	PANEL_ENERGY,
	EXTRACTION_IMPACT,
	DISTURBANCE,
	PURSUIT_PRESSURE,
	ROUTE_SWITCH_IMPACT,
	EVASION_RELEASE,
	QUIET_AFTERMATH
}

var current_mix_state: MixState = MixState.CALM

var _engine_player: AudioStreamPlayer3D = null
var _hum_player: AudioStreamPlayer3D = null
var _static_player: AudioStreamPlayer = null
var _siren_player: AudioStreamPlayer3D = null
var _tension_player: AudioStreamPlayer = null

var _engine_stream: AudioStreamWAV = null
var _hum_stream: AudioStreamWAV = null
var _static_stream: AudioStreamWAV = null
var _siren_stream: AudioStreamWAV = null
var _tension_stream: AudioStreamWAV = null

# Transient voice budget & registry
const MAX_CONCURRENT_TRANSIENTS: int = 8
var _active_transients: Array[AudioStreamPlayer3D] = []
var _last_event_timestamps: Dictionary = {} # SoundEvent -> int (ticks_msec)

# Pursuit pressure tracking
var _current_pursuit_pressure: float = 0.0
var _tension_layer_active: bool = false

# Minimum interval between duplicate transient events (throttling)
const EVENT_COOLDOWNS_MSEC: Dictionary = {
	SoundEvent.FOOTSTEP: 120,
	SoundEvent.SPARK: 80,
	SoundEvent.COLLISION_GLANCE: 120,
	SoundEvent.COLLISION_HEAD_ON: 200,
	SoundEvent.DISMOUNT_REJECTED: 150,
	SoundEvent.BRAKE_SCREECH: 150
}

func _ready() -> void:
	_engine_stream = _create_noise_wav(0.5, 0.4)
	_engine_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_hum_stream = _create_tone_wav(120.0, 0.5, 0.3)
	_hum_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_static_stream = _create_noise_wav(0.5, 0.25)
	_static_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_siren_stream = _create_tone_wav(440.0, 0.6, 0.4)
	_siren_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_tension_stream = _create_harmonic_drone_wav(110.0, 220.0, 1.0, 0.35)
	_tension_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
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

	_tension_player = AudioStreamPlayer.new()
	_tension_player.name = "PursuitTensionPlayer"
	_tension_player.bus = &"Master"
	_tension_player.stream = _tension_stream
	_tension_player.volume_db = -80.0
	add_child(_tension_player)

func play_event(event: SoundEvent, pos: Vector3 = Vector3.ZERO) -> void:
	var now := Time.get_ticks_msec()
	if EVENT_COOLDOWNS_MSEC.has(event):
		var cd: int = EVENT_COOLDOWNS_MSEC[event]
		if _last_event_timestamps.has(event):
			if now - int(_last_event_timestamps[event]) < cd:
				return # Throttled
	_last_event_timestamps[event] = now

	match event:
		SoundEvent.FOOTSTEP:
			_play_synth_click(pos, 320.0, 0.04, 0.25)
		SoundEvent.PROXIMITY_HUM:
			if _hum_player and not _hum_player.playing:
				_hum_player.global_position = pos
				_hum_player.play()
		SoundEvent.PANEL_PEEL:
			_play_synth_sweep(pos, 180.0, 450.0, 0.25, 0.35)
		SoundEvent.CORE_PULL:
			_play_synth_sweep(pos, 600.0, 1200.0, 0.4, 0.45)
		SoundEvent.SPARK:
			_play_synth_click(pos, 880.0, 0.08, 0.4)
		SoundEvent.COMPLETION:
			_play_synth_chime(pos)
		SoundEvent.SIGNAL_LOCK:
			_play_synth_sweep(pos, 440.0, 880.0, 0.35, 0.5)
		SoundEvent.PANEL_POWERED:
			_play_synth_chime(pos)
		SoundEvent.ENGINE_REV:
			if _engine_player and not _engine_player.playing:
				_engine_player.global_position = pos
				_engine_player.play()
		SoundEvent.BRAKE_SCREECH:
			_play_synth_sweep(pos, 900.0, 300.0, 0.2, 0.35)
		SoundEvent.BIKE_MOUNT:
			_play_synth_click(pos, 520.0, 0.1, 0.35)
		SoundEvent.BIKE_DISMOUNT:
			_play_synth_click(pos, 380.0, 0.1, 0.35)
		SoundEvent.SIREN_ALARM:
			set_siren_audio(true, pos)
		SoundEvent.GATE_SLAM:
			_play_synth_sweep(pos, 240.0, 60.0, 0.45, 0.6)
		SoundEvent.DISMOUNT_REJECTED:
			_play_synth_rejection_buzz(pos)
		SoundEvent.DISTURBANCE_ALERT:
			_play_synth_sweep(pos, 350.0, 700.0, 0.4, 0.6)
			set_siren_audio(true, pos)
		SoundEvent.PURSUIT_INTERCEPTED:
			_play_synth_sweep(pos, 400.0, 100.0, 0.5, 0.7)
		SoundEvent.EVASION_RELEASE:
			_play_synth_sweep(pos, 500.0, 1000.0, 0.5, 0.5)
			set_siren_audio(false, Vector3.ZERO)
			if _tension_player and _tension_player.playing:
				_tension_player.stop()
		SoundEvent.COLLISION_GLANCE:
			_play_synth_sweep(pos, 750.0, 350.0, 0.12, 0.35)
		SoundEvent.COLLISION_HEAD_ON:
			_play_synth_sweep(pos, 150.0, 40.0, 0.35, 0.65)

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
			_static_player.volume_db = lerp(0.0, -28.0, accuracy)
		else:
			if _static_player.playing:
				_static_player.stop()

## Continuous pursuit pressure API
## Maps distance into continuous siren pitch escalation and harmonic tension drone
func set_pursuit_pressure(distance: float, pursuer_pos: Vector3) -> void:
	# Normalized pressure P: 0.0 at >= 20m, smoothly rising to 1.0 at <= 5m
	var p: float = clampf((20.0 - distance) / 15.0, 0.0, 1.0)
	_current_pursuit_pressure = p

	if _siren_player:
		_siren_player.global_position = pursuer_pos
		if not _siren_player.playing:
			_siren_player.play()
		# Modulate siren pitch higher as pursuer closes in
		_siren_player.pitch_scale = lerpf(1.0, 1.45, p)
		_siren_player.volume_db = lerpf(-4.0, 3.0, p)

	# Tension drone with hysteresis: engage < 14m, disengage > 18m
	if not _tension_layer_active and distance < 14.0:
		_tension_layer_active = true
		if _tension_player and not _tension_player.playing:
			_tension_player.play()
	elif _tension_layer_active and distance > 18.0:
		_tension_layer_active = false
		if _tension_player and _tension_player.playing:
			_tension_player.stop()

	if _tension_player and _tension_layer_active and _tension_player.playing:
		# Low-mid tension layer volume scales smoothly from -24dB to -6dB
		_tension_player.volume_db = lerpf(-24.0, -6.0, p)

## Clear and halt all pursuit pressure audio layers
func clear_pursuit_pressure() -> void:
	set_siren_audio(false, Vector3.ZERO)
	if _tension_player and _tension_player.playing:
		_tension_player.stop()
	_tension_layer_active = false
	_current_pursuit_pressure = 0.0

## Handle neutral collision telemetry from CourierBike
func on_collision_contact(head_on_ratio: float, impact_speed: float, pos: Vector3) -> void:
	if impact_speed < 1.0:
		return
	if head_on_ratio < 0.35:
		play_event(SoundEvent.COLLISION_GLANCE, pos)
	elif head_on_ratio >= 0.35 and impact_speed >= 3.0:
		play_event(SoundEvent.COLLISION_HEAD_ON, pos)

## Authoritative instant reset: halts all streams and clears all transient nodes
func reset_audio_instant() -> void:
	# Clean up all active transient players
	for player in _active_transients:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active_transients.clear()

	# Stop all continuous loop players
	if _engine_player:
		_engine_player.stop()
		_engine_player.pitch_scale = 1.0
		_engine_player.volume_db = 0.0
	if _hum_player:
		_hum_player.stop()
		_hum_player.pitch_scale = 1.0
		_hum_player.volume_db = 0.0
	if _siren_player:
		_siren_player.stop()
		_siren_player.pitch_scale = 1.0
		_siren_player.volume_db = 0.0
	if _static_player:
		_static_player.stop()
		_static_player.volume_db = 0.0
	if _tension_player:
		_tension_player.stop()
		_tension_player.volume_db = -80.0

	_current_pursuit_pressure = 0.0
	_tension_layer_active = false
	_last_event_timestamps.clear()
	current_mix_state = MixState.CALM

func set_mix_state(state: MixState) -> void:
	current_mix_state = state
	match state:
		MixState.CALM:
			set_tuning_audio(0.0)
			set_siren_audio(false, Vector3.ZERO)
			if _tension_player and _tension_player.playing:
				_tension_player.stop()
		MixState.SIGNAL_CURIOSITY:
			set_tuning_audio(0.15)
		MixState.TUNING_FOCUS:
			set_tuning_audio(0.4)
		MixState.PANEL_ENERGY:
			set_tuning_audio(0.0)
		MixState.EXTRACTION_IMPACT:
			play_event(SoundEvent.COMPLETION, Vector3.ZERO)
		MixState.DISTURBANCE:
			play_event(SoundEvent.DISTURBANCE_ALERT, Vector3.ZERO)
		MixState.PURSUIT_PRESSURE:
			pass
		MixState.ROUTE_SWITCH_IMPACT:
			play_event(SoundEvent.GATE_SLAM, Vector3.ZERO)
		MixState.EVASION_RELEASE:
			play_event(SoundEvent.EVASION_RELEASE, Vector3.ZERO)
		MixState.QUIET_AFTERMATH:
			set_siren_audio(false, Vector3.ZERO)
			set_tuning_audio(0.0)
			if _tension_player and _tension_player.playing:
				_tension_player.stop()

# -----------------------------------------------------------------------------
# INTERNAL PROCEDURAL SYNTHESIS & TRANSIENT MANAGEMENT
# -----------------------------------------------------------------------------

func _register_and_play_transient(player: AudioStreamPlayer3D, pos: Vector3, duration: float = 0.2) -> void:
	# Enforce transient voice budget
	while _active_transients.size() >= MAX_CONCURRENT_TRANSIENTS:
		var oldest: AudioStreamPlayer3D = _active_transients.pop_front()
		if is_instance_valid(oldest):
			oldest.stop()
			oldest.queue_free()

	_active_transients.append(player)
	add_child(player)
	player.global_position = pos
	player.play()

	var player_id: int = player.get_instance_id()
	player.finished.connect(_on_transient_finished.bind(player_id))

	var tree := get_tree()
	if tree:
		tree.create_timer(duration + 0.05).timeout.connect(_on_transient_finished.bind(player_id))

func _on_transient_finished(player_id: int) -> void:
	var obj := instance_from_id(player_id)
	if is_instance_valid(obj):
		var p := obj as AudioStreamPlayer3D
		if p:
			_active_transients.erase(p)
			p.queue_free()

func _play_synth_click(pos: Vector3, freq: float, duration: float, volume: float = 0.4) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 8.0
	player_3d.stream = _create_tone_wav(freq, duration, volume)
	_register_and_play_transient(player_3d, pos, duration)

func _play_synth_rejection_buzz(pos: Vector3) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 10.0
	player_3d.stream = _create_dual_beep_wav(160.0, 0.16, 0.5)
	_register_and_play_transient(player_3d, pos, 0.16)

func _play_synth_sweep(pos: Vector3, start_f: float, end_f: float, duration: float, volume: float = 0.4) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 10.0
	player_3d.stream = _create_sweep_wav(start_f, end_f, duration, volume)
	_register_and_play_transient(player_3d, pos, duration)

func _play_synth_chime(pos: Vector3) -> void:
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = 12.0
	player_3d.stream = _create_harmonic_chime_wav(880.0, 1320.0, 0.45, 0.5)
	_register_and_play_transient(player_3d, pos, 0.45)

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

## True linear frequency sweep generator
func _create_sweep_wav(start_f: float, end_f: float, duration: float, volume: float = 0.4) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	var f_diff: float = end_f - start_f
	for i in range(sample_count):
		var t: float = float(i) / 22050.0
		# Integral of linear frequency: phase(t) = 2*PI*(start_f * t + (f_diff / (2*T)) * t^2)
		var phase: float = 2.0 * PI * (start_f * t + (f_diff / (2.0 * duration)) * t * t)
		var sample: float = sin(phase) * volume
		data[i] = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

func _create_dual_beep_wav(freq: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	var half_count: int = sample_count / 2
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var beep_t: float = float(i % half_count) / 22050.0
		var envelope: float = 1.0 if (i % half_count) < int(float(half_count) * 0.7) else 0.0
		var sample: float = sin(2.0 * PI * freq * beep_t) * volume * envelope
		data[i] = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

func _create_harmonic_chime_wav(f1: float, f2: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var decay: float = 1.0 - (t / duration)
		var sample: float = (sin(2.0 * PI * f1 * t) * 0.6 + sin(2.0 * PI * f2 * t) * 0.4) * volume * decay
		data[i] = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

func _create_harmonic_drone_wav(f1: float, f2: float, duration: float, volume: float = 0.3) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var sample: float = (sin(2.0 * PI * f1 * t) * 0.7 + sin(2.0 * PI * f2 * t) * 0.3) * volume
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
