extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const TARGETS := [
	{
		"label": "pursuit intercept",
		"event": AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED,
		"slot": "pursuit.intercepted_impact",
		"path": "res://audio/pursuit/sfx_pursuit_intercepted_impact.wav",
		"provenance": "GTA_SA:GENRL:BANK_40:SOUND_1",
		"mix_rate": 18000,
		"duration": 0.5382,
	},
	{
		"label": "collision glance",
		"event": AudioManagerScript.SoundEvent.COLLISION_GLANCE,
		"slot": "vehicle.collision_glance",
		"path": "res://audio/vehicle/sfx_vehicle_collision_glance.wav",
		"provenance": "GTA_SA:GENRL:BANK_51:SOUND_2",
		"mix_rate": 18900,
		"duration": 0.2846,
	},
	{
		"label": "collision hard",
		"event": AudioManagerScript.SoundEvent.COLLISION_HEAD_ON,
		"slot": "vehicle.collision_hard",
		"path": "res://audio/vehicle/sfx_vehicle_collision_hard.wav",
		"provenance": "GTA_SA:GENRL:BANK_58:SOUND_2",
		"mix_rate": 18000,
		"duration": 0.5700,
	},
]

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
			return "%s event mapping must remain %s" % [label, slot_id]

		var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
		if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
			return "%s must remain DIEGETIC_3D" % label
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
			return "%s was not resolved into the production transient cache" % label

		manager.call("reset_audio_instant")
		var test_pos := Vector3(4.0 + float(index), 1.25, -7.0 - float(index))
		manager.call("play_event", event, test_pos)
		var active: Array = manager.get("_active_transients")
		if active.is_empty():
			return "%s did not create a production 3D transient" % label
		var player := active[-1] as AudioStreamPlayer3D
		if player == null or player.stream != stream:
			return "%s did not play selected production stream" % label
		if player.global_position.distance_to(test_pos) > 0.01:
			return "%s did not preserve supplied gameplay world position" % label
		if absf(player.unit_size - 10.0) > 0.01:
			return "%s changed unit_size from 10" % label
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
		production_streams[event] = saved_stream
		manager.set("_production_transient_streams", production_streams)

	# One missing production stream must not disable another target.
	manager.call("reset_audio_instant")
	var first_event: int = TARGETS[0]["event"]
	var second_event: int = TARGETS[1]["event"]
	var saved_first: AudioStream = production_streams[first_event]
	production_streams.erase(first_event)
	manager.set("_production_transient_streams", production_streams)
	manager.call("play_event", second_event, Vector3(17.0, 1.0, -9.0))
	var isolation_active: Array = manager.get("_active_transients")
	var second_stream := load(String(TARGETS[1]["path"])) as AudioStreamWAV
	var isolation_player: AudioStreamPlayer3D = null
	if not isolation_active.is_empty():
		isolation_player = isolation_active[-1] as AudioStreamPlayer3D
	if isolation_player == null or isolation_player.stream != second_stream:
		production_streams[first_event] = saved_first
		manager.set("_production_transient_streams", production_streams)
		return "one missing production stream disabled another 01G target"
	production_streams[first_event] = saved_first
	manager.set("_production_transient_streams", production_streams)

	# Interception side effects must survive the production early-return path.
	manager.call("reset_audio_instant")
	manager.set("_is_decaying_pursuit_pressure", true)
	manager.call("set_radio_duck", -6.0, 0.0)
	manager.call("play_event", AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED, Vector3(2.0, 1.0, 2.0))
	if bool(manager.get("_is_decaying_pursuit_pressure")):
		return "production interception failed to cancel pursuit-pressure decay"
	if absf(float(manager.call("get_radio_duck")) - -24.0) > 0.1:
		return "production interception failed to apply -24 dB radio duck"

	# Fallback interception must preserve the same side effects.
	manager.call("reset_audio_instant")
	production_streams.erase(AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED)
	manager.set("_production_transient_streams", production_streams)
	manager.set("_is_decaying_pursuit_pressure", true)
	manager.call("set_radio_duck", -6.0, 0.0)
	manager.call("play_event", AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED, Vector3(2.0, 1.0, 2.0))
	if bool(manager.get("_is_decaying_pursuit_pressure")):
		return "fallback interception failed to cancel pursuit-pressure decay"
	if absf(float(manager.call("get_radio_duck")) - -24.0) > 0.1:
		return "fallback interception failed to apply -24 dB radio duck"
	production_streams[AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED] = load(String(TARGETS[0]["path"]))
	manager.set("_production_transient_streams", production_streams)

	# Collision energy gain must still be applied to production voices. Use the
	# same 3.5 m/s impact speed for glance and hard so direction/severity, not
	# speed, proves the hard event is materially stronger at matched speed.
	manager.call("reset_audio_instant")
	manager.call("on_collision_contact", 0.1, 3.5, Vector3(0.0, 1.0, 0.0))
	var glance_active: Array = manager.get("_active_transients")
	if glance_active.is_empty():
		return "production glance collision path did not create a voice"
	var glance_player := glance_active[-1] as AudioStreamPlayer3D
	var glance_gain := glance_player.volume_db

	manager.call("reset_audio_instant")
	manager.call("on_collision_contact", 0.9, 3.5, Vector3(0.0, 1.0, 0.0))
	var hard_low_active: Array = manager.get("_active_transients")
	if hard_low_active.is_empty():
		return "production hard collision path did not create a voice"
	var hard_low_player := hard_low_active[-1] as AudioStreamPlayer3D
	var hard_low_gain := hard_low_player.volume_db

	manager.call("reset_audio_instant")
	manager.call("on_collision_contact", 0.9, 9.0, Vector3(0.0, 1.0, 0.0))
	var hard_high_active: Array = manager.get("_active_transients")
	if hard_high_active.is_empty():
		return "high-energy production hard collision did not create a voice"
	var hard_high_player := hard_high_active[-1] as AudioStreamPlayer3D
	var hard_high_gain := hard_high_player.volume_db

	if hard_low_gain <= glance_gain:
		return "matched-speed hard collision production gain is not stronger than glance"
	if hard_high_gain <= hard_low_gain:
		return "hard collision production gain does not increase with impact energy"

	manager.call("reset_audio_instant")
	return ""
