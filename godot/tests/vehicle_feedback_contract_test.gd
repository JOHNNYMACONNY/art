extends RefCounted

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const CourierBikeScript = preload("res://scripts/vehicles/courier_bike.gd")

static func _pcm_span(stream: AudioStreamWAV) -> int:
	if stream == null or stream.data.is_empty():
		return 0
	var minimum_byte := 255
	var maximum_byte := 0
	for sample_byte in stream.data:
		minimum_byte = mini(minimum_byte, int(sample_byte))
		maximum_byte = maxi(maximum_byte, int(sample_byte))
	return maximum_byte - minimum_byte

static func _latest_transient_pcm_span(manager: Node) -> int:
	var transients: Array = manager.get("_active_transients")
	if transients.is_empty():
		return 0
	var player := transients.back() as AudioStreamPlayer3D
	if player == null or not player.stream is AudioStreamWAV:
		return 0
	return _pcm_span(player.stream as AudioStreamWAV)

static func verify(manager: Node) -> String:
	var bike := CourierBikeScript.new()

	# Capability seam: intentionally RED on main@05d8161.
	if not bike.has_method("get_vehicle_feedback_telemetry"):
		bike.free()
		return "Courier Bike vehicle-feedback telemetry seam is absent"
	if not manager.has_method("update_vehicle_feedback"):
		bike.free()
		return "AudioManager vehicle-feedback update seam is absent"
	if not manager.has_method("get_vehicle_feedback_snapshot"):
		bike.free()
		return "AudioManager vehicle-feedback diagnostic snapshot is absent"
	if not manager.has_method("clear_vehicle_feedback"):
		bike.free()
		return "AudioManager vehicle-feedback clear seam is absent"

	# E1: stable propulsion/load derives from observation-only bike telemetry.
	bike.current_speed = 7.0
	bike.velocity = Vector3(0.0, 0.0, -7.0)
	bike.is_handbrake_active = false
	var before_speed: float = bike.current_speed
	var before_velocity: Vector3 = bike.velocity
	var stable: Dictionary = bike.call("get_vehicle_feedback_telemetry", 0.70)
	if String(stable.get("traction_state", "")) != "STABLE":
		bike.free()
		return "Straight propulsion did not classify STABLE"
	if float(stable.get("load_ratio", 0.0)) < 0.35:
		bike.free()
		return "Propulsion load was not represented in telemetry"
	if bike.current_speed != before_speed or bike.velocity != before_velocity:
		bike.free()
		return "Telemetry sampling mutated Courier Bike handling state"

	manager.call("update_vehicle_feedback", stable, Vector3.ZERO)
	var engine := manager.get_node_or_null("EngineRevPlayer") as AudioStreamPlayer3D
	if engine == null or not engine.playing:
		bike.free()
		return "Stable propulsion did not activate the engine feedback voice"
	var high_load_pitch: float = engine.pitch_scale
	var high_load_volume: float = engine.volume_db

	# Same speed, less load: engine must not remain a raw speed-only mapping.
	var low_load: Dictionary = bike.call("get_vehicle_feedback_telemetry", 0.15)
	manager.call("update_vehicle_feedback", low_load, Vector3.ZERO)
	if not (high_load_pitch > engine.pitch_scale or high_load_volume > engine.volume_db):
		bike.free()
		return "Engine feedback remained speed-only; load made no audible-control difference"

	# E4: stable -> near-slip -> full handbrake slide -> one-shot recovery catch.
	bike.velocity = Vector3(1.15, 0.0, -7.0)
	var near_slip: Dictionary = bike.call("get_vehicle_feedback_telemetry", 0.45)
	if String(near_slip.get("traction_state", "")) != "NEAR_SLIP":
		bike.free()
		return "Moderate lateral slip did not classify NEAR_SLIP"
	manager.call("update_vehicle_feedback", near_slip, Vector3.ZERO)
	var traction := manager.get_node_or_null("TractionScrubPlayer") as AudioStreamPlayer3D
	if traction == null or not traction.playing:
		bike.free()
		return "Near-slip did not activate bounded traction scrub"
	var near_slip_db: float = traction.volume_db

	bike.is_handbrake_active = true
	bike.velocity = Vector3(2.8, 0.0, -7.0)
	var full_slip: Dictionary = bike.call("get_vehicle_feedback_telemetry", 0.20)
	if String(full_slip.get("traction_state", "")) != "FULL_SLIP":
		bike.free()
		return "Handbrake slide did not classify FULL_SLIP"
	manager.call("update_vehicle_feedback", full_slip, Vector3.ZERO)
	if traction.volume_db < near_slip_db + 2.0:
		bike.free()
		return "Full-slip scrub is not meaningfully stronger than near-slip scrub"

	bike.is_handbrake_active = false
	bike.velocity = Vector3(0.0, 0.0, -7.0)
	stable = bike.call("get_vehicle_feedback_telemetry", 0.55)
	manager.call("update_vehicle_feedback", stable, Vector3.ZERO)
	var recovered: Dictionary = manager.call("get_vehicle_feedback_snapshot")
	if String(recovered.get("state", "")) != "RECOVERY" or traction.playing:
		bike.free()
		return "Slip release did not produce a clean recovery-catch transition"
	if not AudioManagerScript.SoundEvent.has("TRACTION_RECOVERY"):
		bike.free()
		return "TRACTION_RECOVERY semantic event is absent"
	var recovery_event: int = int(AudioManagerScript.SoundEvent["TRACTION_RECOVERY"])
	if int(manager.call("get_event_count", recovery_event)) != 1:
		bike.free()
		return "Recovery catch did not fire exactly once"
	manager.call("update_vehicle_feedback", stable, Vector3.ZERO)
	if int(manager.call("get_event_count", recovery_event)) != 1:
		bike.free()
		return "Stable frames retriggered the recovery catch"

	# E5: issue #14 requires matched-speed glance vs hard/head-on proof.
	const MATCHED_IMPACT_SPEED := 8.0
	manager.call("on_collision_contact", 0.20, MATCHED_IMPACT_SPEED, Vector3.ZERO)
	var glance: Dictionary = manager.call("get_vehicle_feedback_snapshot")
	var glance_energy: float = float(glance.get("last_collision_intensity", 0.0))
	manager.call("on_collision_contact", 0.90, MATCHED_IMPACT_SPEED, Vector3.ZERO)
	var hard: Dictionary = manager.call("get_vehicle_feedback_snapshot")
	var hard_energy: float = float(hard.get("last_collision_intensity", 0.0))
	if glance_energy <= 0.0 or hard_energy < glance_energy + 0.20:
		bike.free()
		return "Matched-speed hard impact did not communicate materially greater event energy than a glance"

	# Scaled impact energy must reach the audible waveform, not live only in a
	# diagnostic snapshot. Two hard impacts at different speeds use the same event
	# family, so a larger PCM span proves actual energy scaling rather than routing.
	var timestamps: Dictionary = manager.get("_last_event_timestamps")
	timestamps.clear()
	manager.call("on_collision_contact", 0.90, 4.0, Vector3.ZERO)
	var low_speed_hard_span := _latest_transient_pcm_span(manager)
	timestamps.clear()
	manager.call("on_collision_contact", 0.90, 10.0, Vector3.ZERO)
	var high_speed_hard_span := _latest_transient_pcm_span(manager)
	if low_speed_hard_span <= 0 or high_speed_hard_span < low_speed_hard_span + 12:
		bike.free()
		return "Hard-impact waveform energy did not scale materially with impact speed"

	# E7: pursuit remains perceptually critical during both traction and impact.
	manager.call("set_pursuit_pressure", 8.0, Vector3.ZERO)
	manager.call("update_vehicle_feedback", full_slip, Vector3.ZERO)
	var pursuit_snapshot: Dictionary = manager.call("get_vehicle_feedback_snapshot")
	var siren := manager.get_node_or_null("SirenAlarmPlayer") as AudioStreamPlayer3D
	var tension := manager.get_node_or_null("PursuitTensionPlayer") as AudioStreamPlayer
	if siren == null or not siren.playing or tension == null or not tension.playing:
		bike.free()
		return "Pursuit critical layers were not active for overlap proof"
	if float(pursuit_snapshot.get("traction_volume_db", 0.0)) > -18.0:
		bike.free()
		return "Traction texture did not duck beneath pursuit priority"
	timestamps.clear()
	manager.call("on_collision_contact", 0.90, MATCHED_IMPACT_SPEED, Vector3.ZERO)
	if not siren.playing or not tension.playing:
		bike.free()
		return "Hard impact interrupted pursuit-critical layers"
	var pursuit_transients: Array = manager.get("_active_transients")
	if pursuit_transients.size() > int(manager.MAX_CONCURRENT_TRANSIENTS):
		bike.free()
		return "Pursuit + impact overlap exceeded the transient voice budget"

	# Signature transition: Memory Echo vehicle texture stays subordinate, then
	# disturbance takes priority without waking an unducked traction layer.
	manager.call("set_mix_state", AudioManagerScript.MixState.MEMORY_ECHO)
	manager.call("update_vehicle_feedback", full_slip, Vector3.ZERO)
	var echo_snapshot: Dictionary = manager.call("get_vehicle_feedback_snapshot")
	if float(echo_snapshot.get("traction_volume_db", 0.0)) > -18.0:
		bike.free()
		return "Traction texture did not remain subordinate during Memory Echo"
	manager.call("set_mix_state", AudioManagerScript.MixState.DISTURBANCE)
	manager.call("update_vehicle_feedback", full_slip, Vector3.ZERO)
	var disturbance_snapshot: Dictionary = manager.call("get_vehicle_feedback_snapshot")
	if float(disturbance_snapshot.get("traction_volume_db", 0.0)) > -18.0:
		bike.free()
		return "Traction texture did not remain subordinate after Memory Echo -> disturbance"
	if siren == null or not siren.playing:
		bike.free()
		return "Disturbance did not retain the critical siren layer after Memory Echo overlap"

	# Existing voice budget/cooldowns and authoritative reset remain the owners.
	manager.call("reset_audio_instant")
	var reset_snapshot: Dictionary = manager.call("get_vehicle_feedback_snapshot")
	if bool(reset_snapshot.get("engine_playing", true)) or bool(reset_snapshot.get("traction_playing", true)):
		bike.free()
		return "Authoritative reset left vehicle feedback playing"
	var active_transients: Array = manager.get("_active_transients")
	if not active_transients.is_empty():
		bike.free()
		return "Authoritative reset left vehicle transients alive"

	bike.free()
	return ""
