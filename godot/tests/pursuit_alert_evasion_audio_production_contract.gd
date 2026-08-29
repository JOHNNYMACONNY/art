extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const TARGETS := [
	{
		"label": "disturbance alert",
		"event": AudioManagerScript.SoundEvent.DISTURBANCE_ALERT,
		"slot": "pursuit.disturbance_alert",
		"path": "res://audio/pursuit/sfx_pursuit_disturbance_alert.wav",
		"provenance": "GTA_SA:GENRL:BANK_138:SOUND_40",
		"mix_rate": 20000,
		"duration": 0.2805,
		"fallback_duration": 0.4,
	},
	{
		"label": "evaded stinger",
		"event": AudioManagerScript.SoundEvent.EVASION_RELEASE,
		"slot": "pursuit.evaded_stinger",
		"path": "res://audio/pursuit/sfx_pursuit_evaded_stinger.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_45",
		"mix_rate": 18000,
		"duration": 0.5907,
		"fallback_duration": 0.5,
	},
]

const RETAINED_SCANNER_SLOT := "pursuit.pursuer_sweep"

static func verify(manager: Node) -> String:
	if manager == null:
		return "AudioManager is missing"

	var cache_value: Variant = manager.get("_production_transient_streams")
	if typeof(cache_value) != TYPE_DICTIONARY:
		return "AudioManager production transient cache is unavailable"
	var production_streams: Dictionary = cache_value

	for index in range(TARGETS.size()):
		var target: Dictionary = TARGETS[index]
		var label: String = target["label"]
		var event: int = target["event"]
		var slot_id: String = target["slot"]
		var asset_path: String = target["path"]

		if not AudioRegistryScript.has_slot(slot_id):
			return "%s slot is not registered" % label
		if AudioManagerScript.event_to_slot_id(event) != slot_id:
			return "%s event mapping must be %s" % [label, slot_id]

		var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
		if slot.get("domain") != AudioRegistryScript.Domain.PURSUIT:
			return "%s domain must remain PURSUIT" % label
		if slot.get("diegesis") != AudioRegistryScript.Diegesis.NON_DIEGETIC:
			return "%s diegesis must remain NON_DIEGETIC" % label
		if slot.get("spatial_type") != AudioRegistryScript.SpatialType.NON_DIEGETIC_2D:
			return "%s must preserve retained semantic/reference 2D spatial metadata" % label
		if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
			return "%s must remain TRANSIENT" % label
		if bool(slot.get("is_looping", true)):
			return "%s must remain non-looping" % label
		if slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			return "%s must be production-final" % label
		if slot.get("replacement_required") != false:
			return "%s must clear replacement_required" % label
		if AudioRegistryScript.get_production_asset_path(slot_id) != asset_path:
			return "%s production path mismatch" % label
		if AudioRegistryScript.get_source_provenance(slot_id) != String(target["provenance"]):
			return "%s provenance mismatch" % label

		if not FileAccess.file_exists(asset_path):
			return "%s production WAV is missing" % label
		var stream := load(asset_path) as AudioStreamWAV
		if stream == null or stream.data.is_empty():
			return "%s failed to load as non-empty AudioStreamWAV" % label
		if stream.format != AudioStreamWAV.FORMAT_16_BITS:
			return "%s must be 16-bit PCM" % label
		if stream.stereo:
			return "%s must be mono" % label
		if stream.mix_rate != int(target["mix_rate"]):
			return "%s native sample-rate mismatch: expected %d got %d" % [label, int(target["mix_rate"]), stream.mix_rate]
		if absf(stream.get_length() - float(target["duration"])) > 0.01:
			return "%s duration mismatch: expected %.4fs got %.4fs" % [label, float(target["duration"]), stream.get_length()]

		if not production_streams.has(event) or production_streams[event] != stream:
			return "%s was not resolved into production transient cache" % label

		manager.call("reset_audio_instant")
		var test_pos := Vector3(6.0 + float(index), 1.5, -4.0 - float(index))
		manager.call("play_event", event, test_pos)
		var active: Array = manager.get("_active_transients")
		if active.is_empty():
			return "%s did not create a production 3D transient" % label
		var player := active[-1] as AudioStreamPlayer3D
		if player == null or player.stream != stream:
			return "%s did not play the selected production stream" % label
		if player.global_position.distance_to(test_pos) > 0.01:
			return "%s did not preserve supplied runtime position" % label
		if absf(player.unit_size - 10.0) > 0.01:
			return "%s changed shipping unit_size from 10" % label
		if player.max_distance != 0.0:
			return "%s introduced unauthorized max_distance override" % label

		manager.call("reset_audio_instant")
		var saved_stream: AudioStream = production_streams[event]
		production_streams.erase(event)
		manager.set("_production_transient_streams", production_streams)
		manager.call("play_event", event, test_pos)
		var fallback: Array = manager.get("_active_transients")
		if fallback.is_empty():
			return "%s procedural fallback did not create a transient" % label
		var fallback_player := fallback[-1] as AudioStreamPlayer3D
		if fallback_player == null or fallback_player.stream == stream:
			return "%s fallback is not independently reachable" % label
		if absf(fallback_player.stream.get_length() - float(target["fallback_duration"])) > 0.02:
			return "%s fallback duration changed" % label
		production_streams[event] = saved_stream
		manager.set("_production_transient_streams", production_streams)

	# One missing production stream must not disable the other.
	manager.call("reset_audio_instant")
	var first_event: int = TARGETS[0]["event"]
	var second_event: int = TARGETS[1]["event"]
	var saved_first: AudioStream = production_streams[first_event]
	production_streams.erase(first_event)
	manager.set("_production_transient_streams", production_streams)
	manager.call("play_event", second_event, Vector3(11.0, 1.0, -3.0))
	var isolation_active: Array = manager.get("_active_transients")
	var second_stream := load(String(TARGETS[1]["path"])) as AudioStreamWAV
	var isolation_player: AudioStreamPlayer3D = null
	if not isolation_active.is_empty():
		isolation_player = isolation_active[-1] as AudioStreamPlayer3D
	if isolation_player == null or isolation_player.stream != second_stream:
		production_streams[first_event] = saved_first
		manager.set("_production_transient_streams", production_streams)
		return "missing disturbance production stream disabled evasion production playback"
	production_streams[first_event] = saved_first
	manager.set("_production_transient_streams", production_streams)

	# Disturbance side effect: siren must start in both production and fallback paths.
	manager.call("reset_audio_instant")
	var siren := manager.get_node_or_null("SirenAlarmPlayer") as AudioStreamPlayer3D
	if siren == null:
		return "siren player is unavailable"
	manager.call("play_event", AudioManagerScript.SoundEvent.DISTURBANCE_ALERT, Vector3(3.0, 0.0, 8.0))
	if not siren.playing:
		return "production disturbance alert failed to activate siren"

	manager.call("reset_audio_instant")
	production_streams.erase(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT)
	manager.set("_production_transient_streams", production_streams)
	manager.call("play_event", AudioManagerScript.SoundEvent.DISTURBANCE_ALERT, Vector3(3.0, 0.0, 8.0))
	if not siren.playing:
		return "fallback disturbance alert failed to activate siren"
	production_streams[AudioManagerScript.SoundEvent.DISTURBANCE_ALERT] = load(String(TARGETS[0]["path"]))
	manager.set("_production_transient_streams", production_streams)

	# Evasion cue must not create a new radio-recovery owner. Direct event playback
	# should leave current radio duck untouched; the release envelope remains separate.
	manager.call("reset_audio_instant")
	manager.call("set_radio_duck", -11.0, 0.0)
	manager.call("play_event", AudioManagerScript.SoundEvent.EVASION_RELEASE, Vector3.ZERO)
	if absf(float(manager.call("get_radio_duck")) - -11.0) > 0.1:
		return "production evasion stinger incorrectly changed radio duck ownership"

	# Scanner slot verified (promoted to LICENSED_FINAL in Audio Production 01P).
	var scanner: Dictionary = AudioRegistryScript.get_slot(RETAINED_SCANNER_SLOT)
	if scanner.is_empty():
		return "pursuer scanner slot is missing"
	if scanner.get("playback_type") != AudioRegistryScript.PlaybackType.CONTINUOUS_LOOP or not bool(scanner.get("is_looping", false)):
		return "pursuer scanner slot must remain a continuous loop semantic"
	if scanner.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		return "pursuer scanner slot must be LICENSED_FINAL post-01P"
	if scanner.get("replacement_required") != false:
		return "pursuer scanner slot must not be replacement-required post-01P"
	if AudioRegistryScript.get_production_asset_path(RETAINED_SCANNER_SLOT) != "res://audio/pursuit/loop_pursuit_scanner_sweep.wav":
		return "pursuer scanner slot must point to 01P production path"

	manager.call("reset_audio_instant")
	return ""
