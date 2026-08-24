class_name VehicleFeedbackLayer
extends Node

# CTW Feel 04 — bounded continuous Courier Bike feedback.
# This node observes already-authoritative bike telemetry. It never owns or
# mutates vehicle physics, pursuit state, Memory Echo state, or reset authority.

var _manager: Node = null
var _engine_player: AudioStreamPlayer3D = null
var _traction_player: AudioStreamPlayer3D = null
var _recovery_event: int = -1
var _active: bool = false
var _state: String = "IDLE"
var _previous_traction_state: String = "STABLE"
var _last_collision_intensity: float = 0.0

func configure(manager: Node, engine_player: AudioStreamPlayer3D, recovery_event: int) -> void:
	_manager = manager
	_engine_player = engine_player
	_recovery_event = recovery_event

	_traction_player = AudioStreamPlayer3D.new()
	_traction_player.name = "TractionScrubPlayer"
	_traction_player.bus = &"Master"
	_traction_player.unit_size = 8.0
	_traction_player.max_distance = 24.0
	_traction_player.volume_db = -80.0
	var scrub_stream: AudioStreamWAV = manager.call("_create_noise_wav", 0.35, 0.22)
	scrub_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_traction_player.stream = scrub_stream
	manager.add_child(_traction_player)

func is_active() -> bool:
	return _active

func update_feedback(telemetry: Dictionary, pos: Vector3, priority_duck: bool) -> void:
	_active = true
	var speed_ratio: float = clampf(float(telemetry.get("speed_ratio", 0.0)), 0.0, 1.0)
	var load_ratio: float = clampf(float(telemetry.get("load_ratio", 0.0)), 0.0, 1.0)
	var traction_state: String = String(telemetry.get("traction_state", "STABLE"))
	var slip_intensity: float = clampf(float(telemetry.get("slip_intensity", 0.0)), 0.0, 1.0)

	_update_engine(speed_ratio, load_ratio, pos)
	_update_traction(traction_state, slip_intensity, pos, priority_duck)

	var was_slipping := _previous_traction_state == "NEAR_SLIP" or _previous_traction_state == "FULL_SLIP"
	if traction_state == "STABLE" and was_slipping:
		_state = "RECOVERY"
		if _recovery_event >= 0 and _manager:
			_manager.call("play_event", _recovery_event, pos)
	else:
		_state = traction_state
	_previous_traction_state = traction_state

func record_collision(head_on_ratio: float, impact_speed: float) -> void:
	# Energy proxy stays presentation-only. The handling controller remains the
	# sole owner of actual collision speed loss and slide response.
	var speed_energy: float = clampf((maxf(impact_speed, 0.0) - 1.0) / 9.0, 0.0, 1.0)
	var direction_energy: float = clampf(head_on_ratio, 0.0, 1.0)
	_last_collision_intensity = clampf(0.10 + speed_energy * 0.55 + direction_energy * 0.35, 0.0, 1.0)

func clear_feedback() -> void:
	_active = false
	_state = "IDLE"
	_previous_traction_state = "STABLE"
	_last_collision_intensity = 0.0
	if _engine_player:
		_engine_player.stop()
		_engine_player.pitch_scale = 1.0
		_engine_player.volume_db = 0.0
	if _traction_player:
		_traction_player.stop()
		_traction_player.pitch_scale = 1.0
		_traction_player.volume_db = -80.0

func snapshot() -> Dictionary:
	return {
		"active": _active,
		"state": _state,
		"engine_playing": _engine_player.playing if _engine_player else false,
		"engine_pitch": _engine_player.pitch_scale if _engine_player else 1.0,
		"engine_volume_db": _engine_player.volume_db if _engine_player else -80.0,
		"traction_playing": _traction_player.playing if _traction_player else false,
		"traction_volume_db": _traction_player.volume_db if _traction_player else -80.0,
		"last_collision_intensity": _last_collision_intensity,
	}

func _update_engine(speed_ratio: float, load_ratio: float, pos: Vector3) -> void:
	if not _engine_player:
		return
	_engine_player.global_position = pos
	if speed_ratio <= 0.01 and load_ratio <= 0.03:
		_engine_player.stop()
		return
	if not _engine_player.playing:
		_engine_player.play()

	# Load contributes independently of road speed so acceleration/coast at the
	# same speed remain distinguishable without pushing the engine to max gain.
	_engine_player.pitch_scale = clampf(0.76 + speed_ratio * 1.05 + load_ratio * 0.28, 0.72, 2.12)
	_engine_player.volume_db = clampf(-25.0 + speed_ratio * 11.0 + load_ratio * 7.0, -25.0, -6.0)

func _update_traction(traction_state: String, slip_intensity: float, pos: Vector3, priority_duck: bool) -> void:
	if not _traction_player:
		return
	_traction_player.global_position = pos
	if traction_state != "NEAR_SLIP" and traction_state != "FULL_SLIP":
		_traction_player.stop()
		_traction_player.volume_db = -80.0
		return

	var base_db: float
	if traction_state == "FULL_SLIP":
		base_db = lerpf(-19.0, -14.0, slip_intensity)
	else:
		base_db = lerpf(-30.0, -25.0, slip_intensity)
	if priority_duck:
		base_db = minf(base_db, -20.0)
	_traction_player.volume_db = base_db
	_traction_player.pitch_scale = lerpf(0.82, 1.14, slip_intensity)
	if not _traction_player.playing:
		_traction_player.play()
