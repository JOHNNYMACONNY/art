class_name VehicleFeedbackLayer
extends Node

# CTW Feel 04 — bounded continuous Courier Bike feedback.
# This node observes already-authoritative bike telemetry. It never owns or
# mutates vehicle physics, pursuit state, Memory Echo state, or reset authority.

var _manager: Node = null
var _engine_player: AudioStreamPlayer3D = null
var _idle_player: AudioStreamPlayer3D = null
var _rev_player: AudioStreamPlayer3D = null
var _coast_player: AudioStreamPlayer3D = null
var _traction_player: AudioStreamPlayer3D = null
var _recovery_event: int = -1
var _active: bool = false
var _state: String = "IDLE"
var _previous_traction_state: String = "STABLE"
var _last_collision_intensity: float = 0.0

func _create_loop_player(player_name: String, asset_path: String, unit_size: float, max_dist: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = player_name
	p.bus = &"Master"
	p.unit_size = unit_size
	p.max_distance = max_dist
	p.volume_db = -80.0
	if ResourceLoader.exists(asset_path):
		var base_stream := load(asset_path) as AudioStreamWAV
		if base_stream:
			var s := base_stream.duplicate() as AudioStreamWAV
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			p.stream = s
	_manager.add_child(p)
	return p

func configure(manager: Node, engine_player: AudioStreamPlayer3D, recovery_event: int) -> void:
	_manager = manager
	_engine_player = engine_player
	_recovery_event = recovery_event

	# Configure multi-layer GTA engine and traction players
	_idle_player = _create_loop_player("EngineIdlePlayer", "res://audio/vehicle/loop_vehicle_engine_idle.wav", 10.0, 25.0)
	_rev_player = _create_loop_player("EngineRevPlayerGTA", "res://audio/vehicle/loop_vehicle_engine_rev.wav", 12.0, 30.0)
	_coast_player = _create_loop_player("EngineCoastPlayerGTA", "res://audio/vehicle/loop_vehicle_engine_coast.wav", 10.0, 25.0)
	_traction_player = _create_loop_player("TractionScrubPlayer", "res://audio/vehicle/sfx_vehicle_brake_screech.wav", 8.0, 24.0)

func is_active() -> bool:
	return _active

func update_feedback(telemetry: Dictionary, pos: Vector3, priority_duck: bool) -> void:
	_active = true
	var speed_ratio: float = clampf(float(telemetry.get("speed_ratio", 0.0)), 0.0, 1.0)
	var load_ratio: float = clampf(float(telemetry.get("load_ratio", 0.0)), 0.0, 1.0)
	var traction_state: String = String(telemetry.get("traction_state", "STABLE"))
	var slip_intensity: float = clampf(float(telemetry.get("slip_intensity", 0.0)), 0.0, 1.0)

	_update_engine(speed_ratio, load_ratio, pos, priority_duck)
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
	if _idle_player:
		_idle_player.stop()
		_idle_player.volume_db = -80.0
	if _rev_player:
		_rev_player.stop()
		_rev_player.volume_db = -80.0
	if _coast_player:
		_coast_player.stop()
		_coast_player.volume_db = -80.0
	if _traction_player:
		_traction_player.stop()
		_traction_player.pitch_scale = 1.0
		_traction_player.volume_db = -80.0

func snapshot() -> Dictionary:
	return {
		"active": _active,
		"state": _state,
		"engine_playing": (_engine_player.playing if _engine_player else false) or (_idle_player.playing if _idle_player else false) or (_rev_player.playing if _rev_player else false),
		"engine_pitch": _engine_player.pitch_scale if _engine_player else 1.0,
		"engine_volume_db": _engine_player.volume_db if _engine_player else -80.0,
		"traction_playing": _traction_player.playing if _traction_player else false,
		"traction_volume_db": _traction_player.volume_db if _traction_player else -80.0,
		"last_collision_intensity": _last_collision_intensity,
	}

func _update_engine(speed_ratio: float, load_ratio: float, pos: Vector3, priority_duck: bool) -> void:
	if _engine_player:
		_engine_player.global_position = pos
		if not _engine_player.playing:
			_engine_player.play()
		_engine_player.pitch_scale = clampf(0.76 + speed_ratio * 1.05 + load_ratio * 0.28, 0.72, 2.12)
		var engine_db: float = clampf(-25.0 + speed_ratio * 11.0 + load_ratio * 7.0, -25.0, -6.0)
		if priority_duck:
			engine_db = minf(engine_db, -12.0)
		_engine_player.volume_db = engine_db

	if _idle_player:
		_idle_player.global_position = pos
		if not _idle_player.playing and _idle_player.stream != null:
			_idle_player.play()
		var idle_gain: float = clampf(1.0 - speed_ratio * 1.8 - load_ratio * 1.5, 0.0, 1.0)
		var idle_db: float = lerpf(-80.0, -14.0 if not priority_duck else -20.0, idle_gain)
		_idle_player.volume_db = idle_db
		_idle_player.pitch_scale = lerpf(0.92, 1.08, load_ratio)

	if _rev_player:
		_rev_player.global_position = pos
		if not _rev_player.playing and _rev_player.stream != null:
			_rev_player.play()
		var rev_gain: float = clampf(load_ratio * 0.75 + speed_ratio * 0.55, 0.0, 1.0)
		var rev_db: float = lerpf(-80.0, -8.0 if not priority_duck else -16.0, rev_gain)
		_rev_player.volume_db = rev_db
		_rev_player.pitch_scale = clampf(0.85 + speed_ratio * 0.65 + load_ratio * 0.35, 0.75, 1.85)

	if _coast_player:
		_coast_player.global_position = pos
		if not _coast_player.playing and _coast_player.stream != null:
			_coast_player.play()
		var coast_gain: float = clampf(speed_ratio * 1.2 - load_ratio * 2.0, 0.0, 1.0)
		var coast_db: float = lerpf(-80.0, -12.0 if not priority_duck else -18.0, coast_gain)
		_coast_player.volume_db = coast_db
		_coast_player.pitch_scale = clampf(0.90 + speed_ratio * 0.40, 0.80, 1.40)

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
