class_name AudioManager
extends Node

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramDirectorScript = preload("res://scripts/audio/radio/radio_program_director.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")
const VehicleFeedbackLayerScript = preload("res://scripts/audio/vehicle_feedback_layer.gd")

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
	COLLISION_HEAD_ON,
	## M04 — Memory Echo signature events
	ECHO_ONSET,
	ECHO_PEAK,
	ECHO_TAIL,
	## M07 — Living Scrap Yard ambient life events
	AMBIENT_WORK_CLINK,
	AMBIENT_SERVO_HUM,
	## CTW Feel 04 — appended to preserve all existing event ordinals
	TRACTION_RECOVERY,
	## World Event 01 — appended; FB-13 companion identity without changing prior ordinals
	FB13_THRUM
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
	QUIET_AFTERMATH,
	## M04 — Memory Echo window: extraction transient → echo → disturbance
	MEMORY_ECHO
}

var current_mix_state: MixState = MixState.CALM

var _engine_player: AudioStreamPlayer3D = null
var _hum_player: AudioStreamPlayer3D = null
var _static_player: AudioStreamPlayer = null
var _siren_player: AudioStreamPlayer3D = null
var _tension_player: AudioStreamPlayer = null
var _ambient_wind_player: AudioStreamPlayer = null
## M04: dedicated echo voice (non-spatial — echo is inside-the-head by design)
var _echo_voice: AudioStreamPlayer = null
## CTW Feel 04: bounded presentation helper; AudioManager remains lifecycle owner.
var _vehicle_feedback_layer: Node = null

## Radio Subsystem (#22)
var _radio_director: RefCounted = null
var _radio_player: Node = null

var _engine_stream: AudioStreamWAV = null
var _hum_stream: AudioStreamWAV = null
var _static_stream: AudioStreamWAV = null
var _siren_stream: AudioStreamWAV = null
var _tension_stream: AudioStreamWAV = null
var _ambient_wind_stream: AudioStreamWAV = null
var _fb13_production_stream: AudioStream = null
var _gate_slam_production_stream: AudioStream = null
var _production_transient_streams: Dictionary = {}
var _echo_production_streams: Dictionary = {}

# Transient voice budget & registry
const MAX_CONCURRENT_TRANSIENTS: int = 8
var _active_transients: Array[AudioStreamPlayer3D] = []
var _active_2d_transients: Array[AudioStreamPlayer] = []
var _last_event_timestamps: Dictionary = {} # SoundEvent -> int (ticks_msec)
var event_counts: Dictionary = {} # SoundEvent -> int

# Pursuit pressure tracking
var _current_pursuit_pressure: float = 0.0
var _tension_layer_active: bool = false
var _is_decaying_pursuit_pressure: bool = false
var _decay_rate_per_sec: float = 1.0
var _decay_initial_pressure: float = 0.0
var _current_radio_duck_db: float = 0.0
var _decay_initial_duck_db: float = 0.0

# M25: Precursor Echo Hybrid Radio Interference Tracking
var _radio_interference_player: AudioStreamPlayer3D = null
var _radio_interference_stream: AudioStreamWAV = null
var _radio_interference_intensity: float = 0.0
var _current_contamination_duck_db: float = 0.0

const INTERFERENCE_OUTER_RADIUS: float = 18.0
const INTERFERENCE_INNER_RADIUS: float = 3.0
const AMBIENT_WIND_BASE_DB: float = -18.0
const AMBIENT_WIND_PRIORITY_DB: float = -30.0

# Minimum interval between duplicate transient events (throttling)
const EVENT_COOLDOWNS_MSEC: Dictionary = {
	SoundEvent.FOOTSTEP: 120,
	SoundEvent.SPARK: 80,
	SoundEvent.COLLISION_GLANCE: 120,
	SoundEvent.COLLISION_HEAD_ON: 200,
	SoundEvent.DISMOUNT_REJECTED: 150,
	SoundEvent.BRAKE_SCREECH: 150
}

## Narrow playback migration tracer events for #21 validation (asset-only events)
const MIGRATED_TRACER_EVENTS: Array[SoundEvent] = [
	SoundEvent.FOOTSTEP,
	SoundEvent.BRAKE_SCREECH,
	SoundEvent.PANEL_PEEL,
	SoundEvent.COLLISION_GLANCE
]

const EVENT_TO_SLOT_MAP: Dictionary = {
	SoundEvent.FOOTSTEP: "player.footstep",
	SoundEvent.PANEL_PEEL: "interaction.panel_peel",
	SoundEvent.SPARK: "interaction.wire_spark",
	SoundEvent.COMPLETION: "interaction.core_extracted",
	SoundEvent.SIGNAL_LOCK: "player.signal_lock_pulse",
	SoundEvent.BRAKE_SCREECH: "vehicle.brake_screech",
	SoundEvent.BIKE_MOUNT: "player.bike_mount",
	SoundEvent.BIKE_DISMOUNT: "player.bike_dismount",
	SoundEvent.DISTURBANCE_ALERT: "pursuit.disturbance_alert",
	SoundEvent.PURSUIT_INTERCEPTED: "pursuit.intercepted_impact",
	SoundEvent.EVASION_RELEASE: "pursuit.evaded_stinger",
	SoundEvent.COLLISION_GLANCE: "vehicle.collision_glance",
	SoundEvent.COLLISION_HEAD_ON: "vehicle.collision_hard",
	SoundEvent.ECHO_ONSET: "echo.onset",
	SoundEvent.ECHO_PEAK: "echo.bed_loop",
	SoundEvent.ECHO_TAIL: "echo.completion",
	SoundEvent.GATE_SLAM: "interaction.gate_triggered",
	SoundEvent.FB13_THRUM: "world.fb13_thrum"
}

const PRODUCTION_TRANSIENT_EVENTS: Array[SoundEvent] = [
	SoundEvent.FOOTSTEP,
	SoundEvent.PANEL_PEEL,
	SoundEvent.SPARK,
	SoundEvent.COMPLETION,
	SoundEvent.SIGNAL_LOCK,
	SoundEvent.BRAKE_SCREECH,
	SoundEvent.BIKE_MOUNT,
	SoundEvent.BIKE_DISMOUNT,
	SoundEvent.DISTURBANCE_ALERT,
	SoundEvent.PURSUIT_INTERCEPTED,
	SoundEvent.EVASION_RELEASE,
	SoundEvent.COLLISION_GLANCE,
	SoundEvent.COLLISION_HEAD_ON,
]

const PRODUCTION_TRANSIENT_UNIT_SIZES: Dictionary = {
	SoundEvent.FOOTSTEP: 8.0,
	SoundEvent.PANEL_PEEL: 10.0,
	SoundEvent.SPARK: 8.0,
	SoundEvent.COMPLETION: 12.0,
	SoundEvent.SIGNAL_LOCK: 10.0,
	SoundEvent.BRAKE_SCREECH: 10.0,
	SoundEvent.BIKE_MOUNT: 8.0,
	SoundEvent.BIKE_DISMOUNT: 8.0,
	SoundEvent.DISTURBANCE_ALERT: 10.0,
	SoundEvent.PURSUIT_INTERCEPTED: 10.0,
	SoundEvent.EVASION_RELEASE: 10.0,
	SoundEvent.COLLISION_GLANCE: 10.0,
	SoundEvent.COLLISION_HEAD_ON: 10.0,
}

const ECHO_PRODUCTION_EVENTS: Array[SoundEvent] = [
	SoundEvent.ECHO_ONSET,
	SoundEvent.ECHO_PEAK,
	SoundEvent.ECHO_TAIL,
]

static func event_to_slot_id(event: SoundEvent) -> String:
	return EVENT_TO_SLOT_MAP.get(event, "")

func _load_registry_loop_or_fallback(slot_id: String, fallback_stream: AudioStreamWAV) -> AudioStreamWAV:
	var asset_path: String = AudioRegistryScript.get_production_asset_path(slot_id)
	if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
		var production_stream := load(asset_path) as AudioStreamWAV
		if production_stream != null:
			production_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			return production_stream
	fallback_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return fallback_stream

func _ready() -> void:
	add_to_group("audio_manager")
	var fb13_asset_path: String = AudioRegistryScript.get_production_asset_path("world.fb13_thrum")
	if not fb13_asset_path.is_empty() and ResourceLoader.exists(fb13_asset_path):
		_fb13_production_stream = load(fb13_asset_path)
	var gate_slam_asset_path: String = AudioRegistryScript.get_production_asset_path("interaction.gate_triggered")
	if not gate_slam_asset_path.is_empty() and ResourceLoader.exists(gate_slam_asset_path):
		_gate_slam_production_stream = load(gate_slam_asset_path)
	var ambient_wind_asset_path: String = AudioRegistryScript.get_production_asset_path("world.ambient_wind")
	if not ambient_wind_asset_path.is_empty() and ResourceLoader.exists(ambient_wind_asset_path):
		_ambient_wind_stream = load(ambient_wind_asset_path) as AudioStreamWAV
		if _ambient_wind_stream:
			_ambient_wind_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_load_production_transient_streams()
	_load_echo_production_streams()
	_engine_stream = _load_registry_loop_or_fallback("vehicle.engine_rev", _create_noise_wav(0.5, 0.4))
	_hum_stream = _create_tone_wav(120.0, 0.5, 0.3)
	_hum_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_static_stream = _create_noise_wav(0.5, 0.25)
	_static_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_siren_stream = _load_registry_loop_or_fallback("pursuit.siren_alarm", _create_tone_wav(440.0, 0.6, 0.4))
	_tension_stream = _create_harmonic_drone_wav(110.0, 220.0, 1.0, 0.35)
	_tension_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_radio_interference_stream = _load_registry_loop_or_fallback("echo.radio_interference", _create_fractured_carrier_wav(1.0, 0.3))
	
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

	_ambient_wind_player = AudioStreamPlayer.new()
	_ambient_wind_player.name = "AmbientWindPlayer"
	_ambient_wind_player.bus = &"Master"
	_ambient_wind_player.stream = _ambient_wind_stream
	_ambient_wind_player.volume_db = AMBIENT_WIND_BASE_DB
	add_child(_ambient_wind_player)
	start_ambient_wind()

	## M04: echo voice — shared player, stream swapped per phase
	_echo_voice = AudioStreamPlayer.new()
	_echo_voice.name = "MemoryEchoVoice"
	_echo_voice.bus = &"Master"
	_echo_voice.volume_db = 0.0
	add_child(_echo_voice)

	## M25: Precursor Echo Hybrid Radio Interference 3D player
	_radio_interference_player = AudioStreamPlayer3D.new()
	_radio_interference_player.name = "RadioInterferencePlayer3D"
	_radio_interference_player.bus = &"Master"
	_radio_interference_player.unit_size = 8.0
	_radio_interference_player.max_distance = 25.0
	_radio_interference_player.stream = _radio_interference_stream
	_radio_interference_player.volume_db = -80.0
	add_child(_radio_interference_player)

	## CTW Feel 04: one bounded continuous helper and traction voice.
	_vehicle_feedback_layer = VehicleFeedbackLayerScript.new()
	_vehicle_feedback_layer.name = "VehicleFeedbackLayer"
	add_child(_vehicle_feedback_layer)
	_vehicle_feedback_layer.call("configure", self, _engine_player, SoundEvent.TRACTION_RECOVERY)

func _load_production_transient_streams() -> void:
	_production_transient_streams.clear()
	for event in PRODUCTION_TRANSIENT_EVENTS:
		var slot_id: String = event_to_slot_id(event)
		if slot_id.is_empty():
			continue
		var asset_path: String = AudioRegistryScript.get_production_asset_path(slot_id)
		if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
			continue
		var stream: AudioStream = load(asset_path)
		if stream != null:
			_production_transient_streams[event] = stream

func _load_echo_production_streams() -> void:
	_echo_production_streams.clear()
	for event in ECHO_PRODUCTION_EVENTS:
		var slot_id: String = event_to_slot_id(event)
		if slot_id.is_empty():
			continue
		var asset_path: String = AudioRegistryScript.get_production_asset_path(slot_id)
		if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
			continue
		var stream: AudioStream = load(asset_path)
		if stream != null:
			_echo_production_streams[event] = stream

## #31: Bounded runtime output diagnostics. This is an on-demand snapshot only;
## get_output_latency() may be expensive and must never be polled per-frame.
func get_runtime_audio_diagnostics() -> Dictionary:
	var master_idx: int = AudioServer.get_bus_index(&"Master")
	var driver_name: String = AudioServer.get_driver_name()
	return {
		"driver_name": driver_name,
		"output_device": AudioServer.output_device,
		"output_devices": AudioServer.get_output_device_list(),
		"mix_rate": AudioServer.get_mix_rate(),
		"output_latency": AudioServer.get_output_latency(),
		"master_bus_index": master_idx,
		"master_muted": AudioServer.is_bus_mute(master_idx) if master_idx >= 0 else true,
		"master_volume_db": AudioServer.get_bus_volume_db(master_idx) if master_idx >= 0 else -80.0,
		"headless_dummy_driver": driver_name.to_lower() == "dummy",
	}

func play_event(event: SoundEvent, pos: Vector3 = Vector3.ZERO) -> void:
	var now := Time.get_ticks_msec()
	if EVENT_COOLDOWNS_MSEC.has(event):
		var cd: int = EVENT_COOLDOWNS_MSEC[event]
		if _last_event_timestamps.has(event):
			if now - int(_last_event_timestamps[event]) < cd:
				return # Throttled
	_last_event_timestamps[event] = now
	event_counts[event] = event_counts.get(event, 0) + 1

	# Dev-only reference override seam for narrow tracer events (clean procedural fallback by default)
	if AudioReferenceResolverScript.is_reference_enabled() and MIGRATED_TRACER_EVENTS.has(event):
		var slot_id: String = event_to_slot_id(event)
		if not slot_id.is_empty():
			var ref_stream: AudioStreamWAV = AudioReferenceResolverScript.resolve_stream(slot_id)
			if ref_stream:
				_play_reference_stream(ref_stream, slot_id, pos)
				return

	# Critical non-audio event side effects must happen regardless of whether the
	# production stream is present. Keep them ahead of the production early-return.
	if event == SoundEvent.DISTURBANCE_ALERT:
		set_siren_audio(true, pos)
	elif event == SoundEvent.PURSUIT_INTERCEPTED:
		_is_decaying_pursuit_pressure = false
		set_radio_duck(-24.0, 0.05)

	if PRODUCTION_TRANSIENT_EVENTS.has(event) and _play_production_transient(event, pos):
		return

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
			_play_gate_slam(pos)
		SoundEvent.DISMOUNT_REJECTED:
			_play_synth_rejection_buzz(pos)
		SoundEvent.DISTURBANCE_ALERT:
			_play_synth_sweep(pos, 350.0, 700.0, 0.4, 0.6)
		SoundEvent.PURSUIT_INTERCEPTED:
			_play_synth_sweep(pos, 400.0, 100.0, 0.5, 0.7)
		SoundEvent.EVASION_RELEASE:
			_play_synth_sweep(pos, 500.0, 1000.0, 0.5, 0.5)
		SoundEvent.COLLISION_GLANCE:
			_play_synth_sweep(pos, 750.0, 350.0, 0.12, 0.35)
		SoundEvent.COLLISION_HEAD_ON:
			_play_synth_sweep(pos, 150.0, 40.0, 0.35, 0.65)
		## M04 — Memory Echo events: played via dedicated non-spatial echo voice
		SoundEvent.ECHO_ONSET:
			_play_echo_onset()
		SoundEvent.ECHO_PEAK:
			_play_echo_peak()
		SoundEvent.ECHO_TAIL:
			_play_echo_tail()
		## M07 — Ambient world work life (ducked automatically during disturbance/pursuit)
		SoundEvent.AMBIENT_WORK_CLINK:
			if current_mix_state != MixState.DISTURBANCE and current_mix_state != MixState.PURSUIT_PRESSURE:
				_play_synth_click(pos, 720.0, 0.06, 0.25)
		SoundEvent.AMBIENT_SERVO_HUM:
			if current_mix_state != MixState.DISTURBANCE and current_mix_state != MixState.PURSUIT_PRESSURE:
				_play_synth_sweep(pos, 220.0, 310.0, 0.25, 0.2)
		SoundEvent.TRACTION_RECOVERY:
			_play_synth_sweep(pos, 420.0, 620.0, 0.12, 0.22)
		SoundEvent.FB13_THRUM:
			_play_fb13_thrum(pos)

func stop_event(event: SoundEvent) -> void:
	if event == SoundEvent.PROXIMITY_HUM and _hum_player:
		_hum_player.stop()
	elif event == SoundEvent.ENGINE_REV and _engine_player:
		_engine_player.stop()
	elif event == SoundEvent.SIREN_ALARM and _siren_player:
		_siren_player.stop()

func get_event_count(event: SoundEvent) -> int:
	return event_counts.get(event, 0)

func reset_event_counts() -> void:
	event_counts.clear()

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
	# The legacy speed-only seam remains authoritative for other vehicles. Once
	# Courier Bike telemetry is actively driving the richer layer, do not let the
	# controller's compatibility call overwrite load-sensitive pitch/gain.
	if _vehicle_feedback_layer and bool(_vehicle_feedback_layer.call("is_active")):
		return
	if _engine_player:
		_engine_player.global_position = pos
		if speed_ratio > 0.01:
			if not _engine_player.playing:
				_engine_player.play()
			_engine_player.pitch_scale = lerp(0.8, 2.2, speed_ratio)
		else:
			if _engine_player.playing:
				_engine_player.stop()

func update_vehicle_feedback(telemetry: Dictionary, pos: Vector3) -> void:
	if not _vehicle_feedback_layer:
		return
	var priority_duck: bool = _current_pursuit_pressure > 0.01 or current_mix_state in [
		MixState.EXTRACTION_IMPACT,
		MixState.DISTURBANCE,
		MixState.PURSUIT_PRESSURE,
		MixState.ROUTE_SWITCH_IMPACT,
		MixState.MEMORY_ECHO,
	]
	_vehicle_feedback_layer.call("update_feedback", telemetry, pos, priority_duck)

func get_vehicle_feedback_snapshot() -> Dictionary:
	if _vehicle_feedback_layer:
		return _vehicle_feedback_layer.call("snapshot")
	return {
		"active": false,
		"state": "IDLE",
		"engine_playing": false,
		"traction_playing": false,
		"traction_volume_db": -80.0,
		"last_collision_intensity": 0.0,
	}

func clear_vehicle_feedback() -> void:
	if _vehicle_feedback_layer:
		_vehicle_feedback_layer.call("clear_feedback")

func set_tuning_audio(accuracy: float) -> void:
	if _static_player:
		if accuracy > 0.01:
			if not _static_player.playing:
				_static_player.play()
			_static_player.volume_db = lerp(0.0, -28.0, accuracy)
		else:
			if _static_player.playing:
				_static_player.stop()

func _process(delta: float) -> void:
	if _is_decaying_pursuit_pressure:
		if _current_pursuit_pressure > 0.0:
			_current_pursuit_pressure = maxf(0.0, _current_pursuit_pressure - _decay_rate_per_sec * delta)
			var p: float = _current_pursuit_pressure
			if _siren_player and _siren_player.playing:
				_siren_player.pitch_scale = lerpf(1.0, 1.45, p)
				_siren_player.volume_db = lerpf(-24.0, 3.0, p)
			if _tension_player and _tension_player.playing:
				_tension_player.volume_db = lerpf(-40.0, -6.0, p)
			
			var ratio: float = clampf(_current_pursuit_pressure / maxf(_decay_initial_pressure, 0.001), 0.0, 1.0)
			var duck_target: float = lerpf(0.0, _decay_initial_duck_db, ratio)
			set_radio_duck(duck_target, 0.0)

			if _current_pursuit_pressure <= 0.0:
				clear_pursuit_pressure()
		else:
			clear_pursuit_pressure()

## Continuous pursuit pressure API
## Maps distance into continuous siren pitch escalation, harmonic tension drone & radio ducking
func set_pursuit_pressure(distance: float, pursuer_pos: Vector3) -> void:
	_is_decaying_pursuit_pressure = false # Cancel any active decay envelope when active pursuit updates
	# Normalized pressure P: 0.0 at >= 20m, smoothly rising to 1.0 at <= 5m
	var p: float = clampf((20.0 - distance) / 15.0, 0.0, 1.0)
	_current_pursuit_pressure = p

	# Continuous radio ducking: -7dB at low pressure down to -13dB at maximum pressure (no per-frame tween churn)
	var duck_target: float = lerpf(-7.0, -13.0, p)
	set_radio_duck(duck_target, 0.0)

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

## Frame-rate independent pursuit release decay envelope (03.2B)
func start_pursuit_release_decay(duration: float = 1.0) -> void:
	if _current_pursuit_pressure <= 0.0:
		# If starting pressure is zero (long-distance evasion), remain quiet without synthesizing tension
		_is_decaying_pursuit_pressure = false
		clear_pursuit_pressure()
		return
			
	_decay_initial_pressure = _current_pursuit_pressure
	_decay_initial_duck_db = _current_radio_duck_db
	_decay_rate_per_sec = _current_pursuit_pressure / maxf(duration, 0.1)
	_is_decaying_pursuit_pressure = true
	print("[AUDIO] Smooth pursuit pressure decay started (duration: %.1fs, initial: %.2f, duck: %.2f)..." % [duration, _decay_initial_pressure, _decay_initial_duck_db])

## Clear and halt all pursuit pressure audio layers
func clear_pursuit_pressure(preserve_radio_duck: bool = false) -> void:
	_is_decaying_pursuit_pressure = false
	set_siren_audio(false, Vector3.ZERO)
	if _tension_player and _tension_player.playing:
		_tension_player.stop()
	_tension_layer_active = false
	_current_pursuit_pressure = 0.0
	if not preserve_radio_duck:
		set_radio_duck(0.0, 0.0)

func _ambient_wind_is_priority_ducked() -> bool:
	return current_mix_state in [MixState.DISTURBANCE, MixState.PURSUIT_PRESSURE, MixState.MEMORY_ECHO]

func _update_ambient_wind_mix() -> void:
	if not _ambient_wind_player:
		return
	_ambient_wind_player.volume_db = AMBIENT_WIND_PRIORITY_DB if _ambient_wind_is_priority_ducked() else AMBIENT_WIND_BASE_DB

func start_ambient_wind() -> void:
	if not _ambient_wind_player or _ambient_wind_player.stream == null:
		return
	_update_ambient_wind_mix()
	if not _ambient_wind_player.playing:
		_ambient_wind_player.play()

func stop_ambient_wind() -> void:
	if _ambient_wind_player and _ambient_wind_player.playing:
		_ambient_wind_player.stop()

func _restart_ambient_wind_after_reset() -> void:
	if not is_inside_tree():
		return
	start_ambient_wind()

func _transient_instance_id(player: Node) -> int:
	return player.get_instance_id() if is_instance_valid(player) else 0

func _apply_collision_output_gain(intensity: float, previous_3d_id: int, previous_2d_id: int) -> void:
	var gain_db: float = lerpf(-8.0, 0.0, clampf(intensity, 0.0, 1.0))
	if not _active_transients.is_empty():
		var player_3d: AudioStreamPlayer3D = _active_transients.back()
		if _transient_instance_id(player_3d) != previous_3d_id:
			player_3d.volume_db = gain_db
			return
	if not _active_2d_transients.is_empty():
		var player_2d: AudioStreamPlayer = _active_2d_transients.back()
		if _transient_instance_id(player_2d) != previous_2d_id:
			player_2d.volume_db = gain_db

## Handle neutral collision telemetry from CourierBike. Routing, cooldowns and
## voice-budget ownership stay in play_event(); only the newly-created collision
## voice receives energy-derived output gain.
func on_collision_contact(head_on_ratio: float, impact_speed: float, pos: Vector3) -> void:
	var impact_intensity: float = 0.5
	if _vehicle_feedback_layer:
		_vehicle_feedback_layer.call("record_collision", head_on_ratio, impact_speed)
		var snapshot: Dictionary = _vehicle_feedback_layer.call("snapshot")
		impact_intensity = float(snapshot.get("last_collision_intensity", impact_intensity))
	if impact_speed < 1.0:
		return

	var event: SoundEvent
	if head_on_ratio < 0.35:
		event = SoundEvent.COLLISION_GLANCE
	elif impact_speed >= 3.0:
		event = SoundEvent.COLLISION_HEAD_ON
	else:
		return

	var event_count_before: int = get_event_count(event)
	var previous_3d_id: int = _transient_instance_id(_active_transients.back()) if not _active_transients.is_empty() else 0
	var previous_2d_id: int = _transient_instance_id(_active_2d_transients.back()) if not _active_2d_transients.is_empty() else 0
	play_event(event, pos)
	if get_event_count(event) > event_count_before:
		_apply_collision_output_gain(impact_intensity, previous_3d_id, previous_2d_id)

## Authoritative instant reset: halts all streams and clears all transient nodes
func reset_audio_instant() -> void:
	# CTW Feel 04 continuous layer yields to this existing reset owner.
	clear_vehicle_feedback()

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
	if _ambient_wind_player:
		_ambient_wind_player.stop()
		_ambient_wind_player.volume_db = AMBIENT_WIND_BASE_DB
	## M04: kill echo voice cleanly on instant reset — no leakage into aftermath
	if _echo_voice:
		_echo_voice.stop()
		_echo_voice.volume_db = 0.0

	## M25: kill interference player cleanly on instant reset
	if _radio_interference_player:
		_radio_interference_player.stop()
		_radio_interference_player.volume_db = -80.0
	clear_radio_interference()

	# Kill and free all active 2D reference transients
	for p2d in _active_2d_transients:
		if is_instance_valid(p2d):
			p2d.stop()
			p2d.queue_free()
	_active_2d_transients.clear()

	_is_decaying_pursuit_pressure = false
	_current_pursuit_pressure = 0.0
	_tension_layer_active = false
	_last_event_timestamps.clear()
	event_counts.clear()
	current_mix_state = MixState.CALM
	AudioReferenceResolverScript.reset()
	clear_radio_duck()
	if _radio_director:
		_radio_director.reset()
	if _radio_player:
		_radio_player.reset()
	# Preserve synchronous full-silence semantics, then re-arm the persistent
	# environmental bed on the next process turn using the same player authority.
	call_deferred("_restart_ambient_wind_after_reset")

func get_radio_director() -> RefCounted:
	if not _radio_director:
		_radio_director = RadioProgramDirectorScript.new()
	return _radio_director

func reset_radio_director(initial_seed: int = 1337) -> void:
	if _radio_director:
		_radio_director.reset(initial_seed)

func get_radio_player() -> Node:
	if not _radio_player:
		_radio_player = RadioProgramPlayerScript.new(get_radio_director())
		_radio_player.set_duck_volume_db(_current_radio_duck_db, 0.0)
		_radio_player.set_contamination_volume_db(_current_contamination_duck_db)
		add_child(_radio_player)
	return _radio_player

## M25: Non-creating radio player inspection — MUST NOT instantiate anything.
## Use for eligibility checks only; never for mount/radio lifecycle flows.
func get_existing_radio_player() -> Node:
	return _radio_player

## M25: Update Precursor Echo Hybrid Radio Interference
func update_radio_interference(source_pos: Vector3, vehicle_pos: Vector3, eligible: bool = true) -> void:
	if not eligible:
		clear_radio_interference()
		return
		
	var dist: float = vehicle_pos.distance_to(source_pos)
	if dist >= INTERFERENCE_OUTER_RADIUS:
		clear_radio_interference()
		return
		
	var intensity: float = clampf((INTERFERENCE_OUTER_RADIUS - dist) / (INTERFERENCE_OUTER_RADIUS - INTERFERENCE_INNER_RADIUS), 0.0, 1.0)
	_radio_interference_intensity = intensity
	
	if _radio_interference_player:
		_radio_interference_player.global_position = source_pos
		var base_vol: float = lerpf(-30.0, -12.0, intensity)
		
		# Attenuate directional 3D voice under pursuit/disturbance/interception pressure
		if _current_radio_duck_db <= -20.0:
			# Critical interception: suppress completely
			base_vol = -80.0
		elif _current_pursuit_pressure > 0.0:
			base_vol += lerpf(0.0, -18.0, _current_pursuit_pressure)
		elif current_mix_state == MixState.DISTURBANCE:
			base_vol += -12.0
		elif current_mix_state == MixState.MEMORY_ECHO:
			base_vol = -80.0
			
		_radio_interference_player.volume_db = base_vol
		if base_vol > -70.0:
			if not _radio_interference_player.playing:
				_radio_interference_player.play()
		else:
			if _radio_interference_player.playing:
				_radio_interference_player.stop()

	# Radio contamination gain (maps 0.0 -> 0.0 dB, 1.0 -> -4.0 dB)
	var contamination_db: float = lerpf(0.0, -4.0, intensity)
	_current_contamination_duck_db = contamination_db
	if _radio_player and _radio_player.has_method("set_contamination_volume_db"):
		_radio_player.set_contamination_volume_db(contamination_db)

func clear_radio_interference() -> void:
	_radio_interference_intensity = 0.0
	_current_contamination_duck_db = 0.0
	if _radio_interference_player and _radio_interference_player.playing:
		_radio_interference_player.stop()
		_radio_interference_player.volume_db = -80.0
	if _radio_player and _radio_player.has_method("set_contamination_volume_db"):
		_radio_player.set_contamination_volume_db(0.0)

func get_radio_interference_intensity() -> float:
	return _radio_interference_intensity

func get_radio_contamination_db() -> float:
	return _current_contamination_duck_db

func get_radio_interference_player() -> AudioStreamPlayer3D:
	return _radio_interference_player

func is_radio_playing() -> bool:
	return _radio_player.is_playing() if _radio_player else false

func is_radio_paused() -> bool:
	return _radio_player.is_paused() if _radio_player else false

func play_radio_station(station_id: String = RadioStationCatalogScript.DEFAULT_STATION_ID) -> void:
	get_radio_player().play_station(station_id)

func pause_radio() -> void:
	if _radio_player:
		_radio_player.pause()

func resume_radio() -> void:
	if _radio_player:
		_radio_player.resume()

func fade_out_radio(duration: float = 0.25) -> void:
	if _radio_player:
		_radio_player.fade_out_and_pause(duration)

func fade_in_radio(duration: float = 0.2) -> void:
	if _radio_player:
		_radio_player.fade_in_and_resume(duration)

func set_radio_duck(duck_db: float, duration: float = 0.0) -> void:
	_current_radio_duck_db = duck_db
	if _radio_player and _radio_player.has_method("set_duck_volume_db"):
		_radio_player.set_duck_volume_db(duck_db, duration)

func get_radio_duck() -> float:
	if _radio_player and _radio_player.has_method("get_duck_volume_db"):
		return _radio_player.get_duck_volume_db()
	return _current_radio_duck_db

func is_radio_duck_tweening() -> bool:
	if _radio_player and _radio_player.has_method("is_duck_tweening"):
		return _radio_player.is_duck_tweening()
	return false

func clear_radio_duck() -> void:
	_current_radio_duck_db = 0.0
	if _radio_player and _radio_player.has_method("set_duck_volume_db"):
		_radio_player.set_duck_volume_db(0.0, 0.0)

func _play_reference_stream(stream: AudioStream, slot_id: String, pos: Vector3) -> void:
	var slot_meta: Dictionary = AudioRegistryScript.get_slot(slot_id)
	var spatial = slot_meta.get("spatial_type", AudioRegistryScript.SpatialType.DIEGETIC_3D)
	var stream_len: float = stream.get_length() if stream else 1.0
	var cleanup_duration: float = maxf(0.5, stream_len + 0.1)

	if spatial == AudioRegistryScript.SpatialType.NON_DIEGETIC_2D:
		var p2d := AudioStreamPlayer.new()
		p2d.stream = stream
		p2d.bus = &"Master"
		_active_2d_transients.append(p2d)
		add_child(p2d)
		p2d.play()
		var cleanup := func():
			if is_instance_valid(p2d):
				_active_2d_transients.erase(p2d)
				p2d.queue_free()
		p2d.finished.connect(cleanup)
		get_tree().create_timer(cleanup_duration).timeout.connect(cleanup)
	else:
		var p3d := AudioStreamPlayer3D.new()
		p3d.stream = stream
		p3d.bus = &"Master"
		p3d.unit_size = 10.0
		_register_and_play_transient(p3d, pos, cleanup_duration)

func set_mix_state(state: MixState) -> void:
	current_mix_state = state
	_update_ambient_wind_mix()
	match state:
		MixState.CALM:
			set_tuning_audio(0.0)
			set_siren_audio(false, Vector3.ZERO)
			if _tension_player and _tension_player.playing:
				_tension_player.stop()
			set_radio_duck(0.0, 0.5)
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
			set_radio_duck(-10.0, 0.15)
		MixState.PURSUIT_PRESSURE:
			pass
		MixState.ROUTE_SWITCH_IMPACT:
			play_event(SoundEvent.GATE_SLAM, Vector3.ZERO)
		MixState.EVASION_RELEASE:
			play_event(SoundEvent.EVASION_RELEASE, Vector3.ZERO)
			# Radio duck recovery owned exclusively by start_pursuit_release_decay() decay envelope
		MixState.QUIET_AFTERMATH:
			set_siren_audio(false, Vector3.ZERO)
			set_tuning_audio(0.0)
			if _tension_player and _tension_player.playing:
				_tension_player.stop()
			set_radio_duck(0.0, 0.5)
		## M04: Memory Echo window — duck ambient, hold space; priority duck radio -16dB
		MixState.MEMORY_ECHO:
			set_tuning_audio(0.0)
			if _static_player and _static_player.playing:
				_static_player.stop()
			set_radio_duck(-16.0, 0.20)
			play_event(SoundEvent.ECHO_ONSET, Vector3.ZERO)

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

func _play_production_transient(event: SoundEvent, pos: Vector3) -> bool:
	var stream: AudioStream = _production_transient_streams.get(event)
	if stream == null:
		return false
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.unit_size = float(PRODUCTION_TRANSIENT_UNIT_SIZES.get(event, 10.0))
	player_3d.bus = &"Master"
	player_3d.stream = stream
	_register_and_play_transient(player_3d, pos, maxf(0.05, stream.get_length()))
	return true

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

func _play_gate_slam(pos: Vector3) -> void:
	if _gate_slam_production_stream != null:
		var player_3d := AudioStreamPlayer3D.new()
		player_3d.unit_size = 12.0
		player_3d.max_distance = 35.0
		player_3d.bus = &"Master"
		player_3d.stream = _gate_slam_production_stream
		_register_and_play_transient(player_3d, pos, 0.56)
		return

	# Existing procedural fallback retained verbatim and independently reachable.
	_play_synth_sweep(pos, 240.0, 60.0, 0.45, 0.6)

func _play_fb13_thrum(pos: Vector3) -> void:
	if _fb13_production_stream != null:
		var player_3d := AudioStreamPlayer3D.new()
		player_3d.unit_size = 10.0
		player_3d.max_distance = 30.0
		player_3d.bus = &"Master"
		player_3d.stream = _fb13_production_stream
		_register_and_play_transient(player_3d, pos, 0.66)
		return

	# Fallback: procedural synthesis retained and reachable
	# A compact low mechanical resonance with one quieter upper contact tick.
	# It stays diegetic/spatial and inside the existing transient voice budget.
	_play_synth_sweep(pos, 92.0, 148.0, 0.55, 0.34)
	_play_synth_click(pos, 310.0, 0.08, 0.16)

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

func _play_echo_phase(event: SoundEvent, fallback_stream: AudioStream, volume_db: float, label: String) -> void:
	if not _echo_voice:
		return
	var stream: AudioStream = _echo_production_streams.get(event)
	if stream == null:
		stream = fallback_stream
	_echo_voice.stop()
	_echo_voice.stream = stream
	_echo_voice.volume_db = volume_db
	_echo_voice.play()
	print("[AUDIO_ECHO] %s playing" % label)

## M04 — Memory Echo audio signature helpers
## ECHO_ONSET: low electrical crackle — reversed envelope, distinct from COMPLETION
func _play_echo_onset() -> void:
	_play_echo_phase(SoundEvent.ECHO_ONSET, _create_echo_onset_wav(), -8.0, "Onset")

## ECHO_PEAK: fractured signal ghost — sparse noise burst with comb-filter character
func _play_echo_peak() -> void:
	_play_echo_phase(SoundEvent.ECHO_PEAK, _create_echo_peak_wav(), -4.0, "Peak")

## ECHO_TAIL: electrical high-frequency tail, dropout to silence
func _play_echo_tail() -> void:
	_play_echo_phase(SoundEvent.ECHO_TAIL, _create_echo_tail_wav(), -12.0, "Tail")

func _create_tone_wav(freq: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var sample_count := int(22050 * duration)
	wav.loop_begin = 0
	wav.loop_end = sample_count
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
	wav.loop_begin = 0
	wav.loop_end = sample_count
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
	wav.loop_begin = 0
	wav.loop_end = sample_count
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var sample := (randf() * 2.0 - 1.0) * volume
		data[i] = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

# ─────────────────────────────────────────────────────────────────────────────
# M04: Memory Echo procedural synthesis helpers
# Arc: extraction transient → vacuum/drop (onset) → fractured echo (peak)
#      → electrical tail → silence → disturbance intrusion
# No loudness pile-up: echo voices are all below -4 dB; pursuit onset wins.
# ─────────────────────────────────────────────────────────────────────────────

## ECHO_ONSET (~0.28s): electrical crackle with reversed (attack-heavy) envelope
## Distinct from COMPLETION: lower base freq (220Hz), envelope inverted so
## energy front-loads and then drops, implying something tearing open.
func _create_echo_onset_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var duration := 0.28
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var norm_t := t / duration
		# Reversed envelope: loud attack, decays to near-zero
		var env := (1.0 - norm_t) * (1.0 - norm_t)
		# Harmonic stack: 220 + 330 + sparse noise for electrical texture
		var sig := (sin(2.0 * PI * 220.0 * t) * 0.5
			+ sin(2.0 * PI * 330.0 * t) * 0.3
			+ (randf() * 2.0 - 1.0) * 0.2) * env * 0.55
		data[i] = int(clampf((sig + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

## ECHO_PEAK (~1.1s): fractured echo material — sparse noise burst with comb
## filter character simulated via two detuned oscillators + amplitude modulation.
## Implies a fragmented memory signal surfacing then receding.
func _create_echo_peak_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var duration := 1.1
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var norm_t := t / duration
		# Rise quickly to peak at 0.15, then slow decay — implies revelation then recession
		var env := 0.0
		if norm_t < 0.15:
			env = norm_t / 0.15
		else:
			env = 1.0 - ((norm_t - 0.15) / 0.85)
		env = maxf(0.0, env)
		# Comb-filter texture: two detuned oscillators (185Hz + 187Hz) = 2Hz beating
		var comb := sin(2.0 * PI * 185.0 * t) * 0.4 + sin(2.0 * PI * 187.0 * t) * 0.4
		# Amplitude modulation at ~3 Hz for fragmentary pulsing quality
		var am := 0.6 + 0.4 * sin(2.0 * PI * 3.0 * t)
		# Sparse noise texture to imply signal corruption
		var noise := (randf() * 2.0 - 1.0) * 0.15
		var sig := (comb * am + noise) * env * 0.45
		data[i] = int(clampf((sig + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

## ECHO_TAIL (~0.45s): high-frequency electrical shimmer decaying to silence
## Distinctly thinner than siren/tension. Acts as dropout signal before
## disturbance intrusion breaks the quiet.
func _create_echo_tail_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var duration := 0.45
	var sample_count := int(22050 * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var norm_t := t / duration
		# Simple exponential decay to guarantee silence at end
		var env := exp(-norm_t * 5.0)
		# High-frequency shimmer: 3400Hz + 5100Hz harmonics
		var sig := (sin(2.0 * PI * 3400.0 * t) * 0.6
			+ sin(2.0 * PI * 5100.0 * t) * 0.25
			+ (randf() * 2.0 - 1.0) * 0.1) * env * 0.45
		data[i] = int(clampf((sig + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav

## M25: Precursor Echo hybrid radio interference procedural texture (~1.0s loop)
## Unstable reclaimed-radio carrier with subtle amplitude/frequency flutter
## and fracture grain — distinct from white noise or tonal hum.
func _create_fractured_carrier_wav(duration: float = 1.0, volume: float = 0.3) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var sample_count := int(22050 * duration)
	wav.loop_begin = 0
	wav.loop_end = sample_count
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		# Subtle carrier with gentle flutter
		var f1 := 175.0 + 3.0 * sin(2.0 * PI * 4.0 * t)
		var carrier := sin(2.0 * PI * f1 * t) * 0.45 + sin(2.0 * PI * (f1 * 1.5) * t) * 0.25
		# Fracture grain modulation
		var flutter := 0.7 + 0.3 * sin(2.0 * PI * 8.0 * t)
		var crackle := (randf() * 2.0 - 1.0) * 0.12
		var sig := (carrier * flutter + crackle) * volume
		data[i] = int(clampf((sig + 1.0) * 127.5, 0.0, 255.0))
	wav.data = data
	return wav
