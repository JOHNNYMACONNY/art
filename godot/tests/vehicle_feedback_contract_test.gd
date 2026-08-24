extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const CourierBikeScript = preload("res://scripts/vehicles/courier_bike.gd")

var _manager: Node = null
var _bike: CharacterBody3D = null

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[CTW_FEEL_04] %s" % message)
	if is_instance_valid(_manager):
		_manager.queue_free()
	if is_instance_valid(_bike):
		_bike.free()
	await process_frame
	await process_frame
	quit(1)

func _require(condition: bool, message: String) -> bool:
	if not condition:
		await _fail(message)
		return false
	return true

func _telemetry(throttle: float) -> Dictionary:
	return _bike.call("get_vehicle_feedback_telemetry", throttle)

func _run() -> void:
	_bike = CourierBikeScript.new()
	_manager = AudioManagerScript.new()
	root.add_child(_manager)
	await process_frame

	# TDD RED on main@05d8161: CTW Feel 04 has no telemetry-driven vehicle
	# feedback seam yet. Keep the contract narrow and gameplay-facing.
	if not _bike.has_method("get_vehicle_feedback_telemetry"):
		await _fail("Courier Bike vehicle-feedback telemetry seam is absent")
		return
	if not _manager.has_method("update_vehicle_feedback"):
		await _fail("AudioManager vehicle-feedback update seam is absent")
		return
	if not _manager.has_method("get_vehicle_feedback_snapshot"):
		await _fail("AudioManager vehicle-feedback diagnostic snapshot is absent")
		return
	if not _manager.has_method("clear_vehicle_feedback"):
		await _fail("AudioManager vehicle-feedback clear seam is absent")
		return

	# E1: stable propulsion/load must be real bike telemetry and observation-only.
	_bike.current_speed = 7.0
	_bike.velocity = Vector3(0.0, 0.0, -7.0)
	_bike.is_handbrake_active = false
	var before_speed: float = _bike.current_speed
	var before_velocity: Vector3 = _bike.velocity
	var stable := _telemetry(0.70)
	if not await _require(String(stable.get("traction_state", "")) == "STABLE", "Straight propulsion did not classify STABLE"):
		return
	if not await _require(float(stable.get("load_ratio", 0.0)) >= 0.35, "Propulsion load was not represented in telemetry"):
		return
	if not await _require(_bike.current_speed == before_speed and _bike.velocity == before_velocity, "Telemetry sampling mutated Courier Bike handling state"):
		return

	_manager.call("update_vehicle_feedback", stable, Vector3.ZERO)
	var engine := _manager.get_node_or_null("EngineRevPlayer") as AudioStreamPlayer3D
	if not await _require(engine != null and engine.playing, "Stable propulsion did not activate the engine feedback voice"):
		return
	var stable_pitch: float = engine.pitch_scale
	var stable_volume: float = engine.volume_db

	# Same speed, stronger throttle/load: pitch/level must react to load rather than
	# remaining a raw speed-only mapping.
	var low_load := _telemetry(0.15)
	_manager.call("update_vehicle_feedback", low_load, Vector3.ZERO)
	var low_load_pitch: float = engine.pitch_scale
	var low_load_volume: float = engine.volume_db
	if not await _require(stable_pitch > low_load_pitch or stable_volume > low_load_volume, "Engine feedback remained speed-only; load made no audible-control difference"):
		return

	# E4: stable -> near slip -> full handbrake slip -> recovery catch.
	_bike.velocity = Vector3(1.15, 0.0, -7.0)
	var near_slip := _telemetry(0.45)
	if not await _require(String(near_slip.get("traction_state", "")) == "NEAR_SLIP", "Moderate lateral slip did not classify NEAR_SLIP"):
		return
	_manager.call("update_vehicle_feedback", near_slip, Vector3.ZERO)
	var traction := _manager.get_node_or_null("TractionScrubPlayer") as AudioStreamPlayer3D
	if not await _require(traction != null and traction.playing, "Near-slip did not activate bounded traction scrub"):
		return
	var near_slip_db: float = traction.volume_db

	_bike.is_handbrake_active = true
	_bike.velocity = Vector3(2.8, 0.0, -7.0)
	var full_slip := _telemetry(0.20)
	if not await _require(String(full_slip.get("traction_state", "")) == "FULL_SLIP", "Handbrake slide did not classify FULL_SLIP"):
		return
	_manager.call("update_vehicle_feedback", full_slip, Vector3.ZERO)
	var full_slip_db: float = traction.volume_db
	if not await _require(full_slip_db >= near_slip_db + 2.0, "Full-slip scrub is not meaningfully stronger than near-slip scrub"):
		return

	_bike.is_handbrake_active = false
	_bike.velocity = Vector3(0.0, 0.0, -7.0)
	stable = _telemetry(0.55)
	_manager.call("update_vehicle_feedback", stable, Vector3.ZERO)
	var recovered: Dictionary = _manager.call("get_vehicle_feedback_snapshot")
	if not await _require(String(recovered.get("state", "")) == "RECOVERY", "Slip release did not produce a distinct recovery-catch state"):
		return
	if not await _require(not traction.playing, "Traction scrub loop leaked through recovery"):
		return
	var recovery_event: int = int(AudioManagerScript.SoundEvent.get("TRACTION_RECOVERY", -1))
	if not await _require(recovery_event >= 0, "TRACTION_RECOVERY semantic event is absent"):
		return
	if not await _require(int(_manager.call("get_event_count", recovery_event)) == 1, "Recovery catch did not fire exactly once"):
		return
	_manager.call("update_vehicle_feedback", stable, Vector3.ZERO)
	if not await _require(int(_manager.call("get_event_count", recovery_event)) == 1, "Stable frames retriggered the recovery catch"):
		return

	# E5: matched routing semantics, but event energy must scale with impact speed.
	_manager.call("on_collision_contact", 0.20, 4.0, Vector3.ZERO)
	var glance: Dictionary = _manager.call("get_vehicle_feedback_snapshot")
	var glance_energy: float = float(glance.get("last_collision_intensity", 0.0))
	_manager.call("on_collision_contact", 0.90, 10.0, Vector3.ZERO)
	var hard: Dictionary = _manager.call("get_vehicle_feedback_snapshot")
	var hard_energy: float = float(hard.get("last_collision_intensity", 0.0))
	if not await _require(glance_energy > 0.0 and hard_energy >= glance_energy + 0.30, "Hard impact did not communicate materially greater event energy than a glance"):
		return

	# E7 + Echo overlap: pursuit/signature layers retain perceptual priority.
	_manager.call("set_pursuit_pressure", 8.0, Vector3.ZERO)
	_manager.call("update_vehicle_feedback", full_slip, Vector3.ZERO)
	var pursuit_snapshot: Dictionary = _manager.call("get_vehicle_feedback_snapshot")
	var siren := _manager.get_node_or_null("SirenAlarmPlayer") as AudioStreamPlayer3D
	var tension := _manager.get_node_or_null("PursuitTensionPlayer") as AudioStreamPlayer
	if not await _require(siren != null and siren.playing and tension != null and tension.playing, "Pursuit critical layers were not active for overlap proof"):
		return
	if not await _require(float(pursuit_snapshot.get("traction_volume_db", 0.0)) <= -18.0, "Traction texture did not duck beneath pursuit priority"):
		return

	_manager.call("set_mix_state", AudioManagerScript.MixState.MEMORY_ECHO)
	_manager.call("update_vehicle_feedback", full_slip, Vector3.ZERO)
	var echo_snapshot: Dictionary = _manager.call("get_vehicle_feedback_snapshot")
	if not await _require(float(echo_snapshot.get("traction_volume_db", 0.0)) <= -18.0, "Traction texture did not remain subordinate during Memory Echo"):
		return

	# Replay/reset contract: no vehicle loops or recovery/impact transients survive.
	_manager.call("reset_audio_instant")
	var reset_snapshot: Dictionary = _manager.call("get_vehicle_feedback_snapshot")
	if not await _require(not bool(reset_snapshot.get("engine_playing", true)), "Authoritative reset left engine feedback playing"):
		return
	if not await _require(not bool(reset_snapshot.get("traction_playing", true)), "Authoritative reset left traction feedback playing"):
		return
	if not await _require((_manager.get("_active_transients") as Array).is_empty(), "Authoritative reset left vehicle transients alive"):
		return

	print("[CTW_FEEL_04] PASS stable/near-slip/full-slip/recovery + scaled impacts + overlap/reset")
	_bike.free()
	_bike = null
	_manager.queue_free()
	await process_frame
	await process_frame
	quit(0)
