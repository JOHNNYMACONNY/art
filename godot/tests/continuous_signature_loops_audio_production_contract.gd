extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const TARGETS := [
	{
		"slot": "vehicle.engine_rev",
		"path": "res://audio/vehicle/loop_vehicle_engine_rev.wav",
		"provenance": "GTA_SA:GENRL:BANK_8:SOUND_1",
		"rate": 18000,
		"duration": 1.1962,
		"loop_end": 1.1962,
	},
	{
		"slot": "pursuit.siren_alarm",
		"path": "res://audio/pursuit/loop_pursuit_siren_alarm.wav",
		"provenance": "GTA_SA:GENRL:BANK_39:SOUND_8",
		"rate": 18000,
		"duration": 0.7772,
		"loop_end": 0.7772,
	},
	{
		"slot": "echo.radio_interference",
		"path": "res://audio/echo/loop_echo_radio_interference.wav",
		"provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_12",
		"rate": 15000,
		"duration": 0.9579,
		"loop_end": 0.9579,
	},
]

static func _verify_slot(target: Dictionary) -> String:
	var slot_id: String = target["slot"]
	var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
	if slot.is_empty():
		return "%s slot missing" % slot_id
	if slot.get("playback_type") != AudioRegistryScript.PlaybackType.CONTINUOUS_LOOP:
		return "%s must remain CONTINUOUS_LOOP" % slot_id
	if not bool(slot.get("is_looping", false)):
		return "%s must remain looping" % slot_id
	if slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		return "%s must be production-final" % slot_id
	if bool(slot.get("replacement_required", true)):
		return "%s must clear replacement_required" % slot_id
	if AudioRegistryScript.get_production_asset_path(slot_id) != String(target["path"]):
		return "%s production path mismatch" % slot_id
	if AudioRegistryScript.get_source_provenance(slot_id) != String(target["provenance"]):
		return "%s provenance mismatch" % slot_id
	if absf(float(slot.get("loop_start_sec", -1.0))) > 0.001:
		return "%s loop start must be 0" % slot_id
	if absf(float(slot.get("loop_end_sec", 0.0)) - float(target["loop_end"])) > 0.01:
		return "%s loop end mismatch" % slot_id
	if not FileAccess.file_exists(String(target["path"])):
		return "%s production WAV missing" % slot_id
	var stream := load(String(target["path"])) as AudioStreamWAV
	if stream == null or stream.data.is_empty():
		return "%s production WAV failed to load" % slot_id
	if stream.format != AudioStreamWAV.FORMAT_16_BITS or stream.stereo:
		return "%s must remain mono PCM16" % slot_id
	if stream.mix_rate != int(target["rate"]):
		return "%s native sample rate mismatch" % slot_id
	if absf(stream.get_length() - float(target["duration"])) > 0.01:
		return "%s duration mismatch" % slot_id
	if stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		return "%s must be forward-loop enabled" % slot_id
	return ""

static func verify(manager: Node) -> String:
	if manager == null:
		return "AudioManager missing"

	for target in TARGETS:
		var slot_error := _verify_slot(target)
		if not slot_error.is_empty():
			return slot_error

	var engine_stream := load(String(TARGETS[0]["path"])) as AudioStreamWAV
	var siren_stream := load(String(TARGETS[1]["path"])) as AudioStreamWAV
	var interference_stream := load(String(TARGETS[2]["path"])) as AudioStreamWAV

	var engine_player := manager.get("_engine_player") as AudioStreamPlayer3D
	var siren_player := manager.get("_siren_player") as AudioStreamPlayer3D
	var interference_player := manager.get("_radio_interference_player") as AudioStreamPlayer3D
	if engine_player == null or siren_player == null or interference_player == null:
		return "one or more existing loop players missing"
	if engine_player.name != "EngineRevPlayer" or siren_player.name != "SirenAlarmPlayer" or interference_player.name != "RadioInterferencePlayer3D":
		return "continuous loop player identity changed"
	if engine_player.stream != engine_stream:
		return "EngineRevPlayer is not using selected production stream"
	if siren_player.stream != siren_stream:
		return "SirenAlarmPlayer is not using selected production stream"
	if interference_player.stream != interference_stream:
		return "RadioInterferencePlayer3D is not using selected production stream"
	if absf(engine_player.unit_size - 12.0) > 0.01 or absf(engine_player.max_distance - 30.0) > 0.01:
		return "engine spatial authority changed"
	if absf(siren_player.unit_size - 15.0) > 0.01 or absf(siren_player.max_distance - 35.0) > 0.01:
		return "siren spatial authority changed"
	if absf(interference_player.unit_size - 8.0) > 0.01 or absf(interference_player.max_distance - 25.0) > 0.01:
		return "interference spatial authority changed"

	# Vehicle feedback formula and selected stream remain coupled to the same existing player.
	manager.call("update_vehicle_feedback", {"speed_ratio": 0.6, "load_ratio": 0.7, "traction_state": "STABLE", "slip_intensity": 0.0}, Vector3(3.0, 0.0, -2.0))
	var expected_pitch := clampf(0.76 + 0.6 * 1.05 + 0.7 * 0.28, 0.72, 2.12)
	var expected_db := clampf(-25.0 + 0.6 * 11.0 + 0.7 * 7.0, -25.0, -6.0)
	if absf(engine_player.pitch_scale - expected_pitch) > 0.01 or absf(engine_player.volume_db - expected_db) > 0.01:
		return "vehicle feedback pitch/gain formula changed"
	if engine_player.stream != engine_stream:
		return "vehicle feedback replaced production engine stream"

	# Pursuit pressure preserves the full far/mid/near pitch/gain curve and player ownership.
	manager.call("set_pursuit_pressure", 20.0, Vector3(20.0, 0.0, 0.0))
	if absf(siren_player.pitch_scale - 1.0) > 0.01 or absf(siren_player.volume_db - -4.0) > 0.01:
		return "siren far-pressure pitch/gain changed"
	manager.call("set_pursuit_pressure", 12.5, Vector3(7.0, 0.0, 4.0))
	if absf(siren_player.pitch_scale - 1.225) > 0.01 or absf(siren_player.volume_db - -0.5) > 0.01:
		return "siren mid-pressure pitch/gain changed"
	if siren_player.global_position.distance_to(Vector3(7.0, 0.0, 4.0)) > 0.01:
		return "siren lost pursuer position ownership"
	manager.call("set_pursuit_pressure", 5.0, Vector3(2.0, 0.0, 1.0))
	if absf(siren_player.pitch_scale - 1.45) > 0.01 or absf(siren_player.volume_db - 3.0) > 0.01:
		return "siren near-pressure pitch/gain changed"

	# Under live pursuit pressure, high-output telemetry must hit the existing -12 dB priority cap.
	manager.call("update_vehicle_feedback", {"speed_ratio": 1.0, "load_ratio": 1.0, "traction_state": "STABLE", "slip_intensity": 0.0}, Vector3(4.0, 0.0, -1.0))
	var priority_pitch := clampf(0.76 + 1.0 * 1.05 + 1.0 * 0.28, 0.72, 2.12)
	if absf(engine_player.pitch_scale - priority_pitch) > 0.01:
		return "priority-state engine pitch formula changed"
	if absf(engine_player.volume_db - -12.0) > 0.01:
		return "priority-state engine gain cap changed"
	if engine_player.stream != engine_stream:
		return "priority-state vehicle feedback replaced production engine stream"

	# Interference proximity/mix behavior remains on the same selected loop across outer/mid/inner range.
	manager.call("clear_pursuit_pressure")
	manager.call("set_mix_state", AudioManagerScript.MixState.CALM)
	manager.call("update_radio_interference", Vector3.ZERO, Vector3(17.0, 0.0, 0.0), true)
	if interference_player.stream != interference_stream:
		return "interference outer update replaced production stream"
	if absf(interference_player.volume_db - -28.8) > 0.25:
		return "interference outer-proximity gain changed"
	if absf(float(manager.call("get_radio_contamination_db")) - -0.2667) > 0.1:
		return "interference outer contamination curve changed"
	manager.call("update_radio_interference", Vector3.ZERO, Vector3(10.5, 0.0, 0.0), true)
	if absf(interference_player.volume_db - -21.0) > 0.2:
		return "interference mid-proximity gain changed"
	if absf(float(manager.call("get_radio_contamination_db")) - -2.0) > 0.2:
		return "interference mid contamination curve changed"
	manager.call("update_radio_interference", Vector3.ZERO, Vector3(3.0, 0.0, 0.0), true)
	if absf(interference_player.volume_db - -12.0) > 0.2:
		return "interference inner-proximity gain changed"
	if absf(float(manager.call("get_radio_contamination_db")) - -4.0) > 0.2:
		return "interference inner contamination curve changed"
	manager.call("set_mix_state", AudioManagerScript.MixState.MEMORY_ECHO)
	manager.call("update_radio_interference", Vector3.ZERO, Vector3(4.0, 0.0, 0.0), true)
	if interference_player.playing or interference_player.volume_db > -70.0:
		return "Memory Echo no longer suppresses radio interference"

	# Procedural fallbacks remain independently materialized and loop-capable.
	var engine_fallback := manager.call("_create_noise_wav", 0.5, 0.4) as AudioStreamWAV
	var siren_fallback := manager.call("_create_tone_wav", 440.0, 0.6, 0.4) as AudioStreamWAV
	var interference_fallback := manager.call("_create_fractured_carrier_wav", 1.0, 0.3) as AudioStreamWAV
	if absf(engine_fallback.get_length() - 0.5) > 0.01 or absf(siren_fallback.get_length() - 0.6) > 0.01 or absf(interference_fallback.get_length() - 1.0) > 0.01:
		return "one or more continuous procedural fallbacks changed"

	# Exercise the resolver's missing-media branch independently for every loop
	# family. Each missing slot must return only its supplied fallback, mark it as
	# forward-looping, and leave the other production-player streams untouched.
	var missing_engine := manager.call("_load_registry_loop_or_fallback", "__01l_missing_engine__", engine_fallback) as AudioStreamWAV
	if missing_engine != engine_fallback or missing_engine.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		return "engine missing-media resolver did not return loop-capable fallback"
	if siren_player.stream != siren_stream or interference_player.stream != interference_stream:
		return "engine missing-media fallback altered another production loop"

	var missing_siren := manager.call("_load_registry_loop_or_fallback", "__01l_missing_siren__", siren_fallback) as AudioStreamWAV
	if missing_siren != siren_fallback or missing_siren.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		return "siren missing-media resolver did not return loop-capable fallback"
	if engine_player.stream != engine_stream or interference_player.stream != interference_stream:
		return "siren missing-media fallback altered another production loop"

	var missing_interference := manager.call("_load_registry_loop_or_fallback", "__01l_missing_interference__", interference_fallback) as AudioStreamWAV
	if missing_interference != interference_fallback or missing_interference.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		return "interference missing-media resolver did not return loop-capable fallback"
	if engine_player.stream != engine_stream or siren_player.stream != siren_stream:
		return "interference missing-media fallback altered another production loop"

	manager.call("reset_audio_instant")
	if engine_player.playing or siren_player.playing or interference_player.playing:
		return "authoritative reset left a 01L loop voice playing"
	if absf(engine_player.pitch_scale - 1.0) > 0.01 or absf(engine_player.volume_db) > 0.01:
		return "engine reset base state changed"
	if absf(siren_player.pitch_scale - 1.0) > 0.01 or absf(siren_player.volume_db) > 0.01:
		return "siren reset base state changed"
	return ""
