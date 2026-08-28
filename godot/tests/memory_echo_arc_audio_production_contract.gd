extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const MemoryEchoControllerScript = preload("res://scripts/prototype/memory_echo_controller.gd")

const TARGETS := [
	{
		"label": "echo onset",
		"event": AudioManagerScript.SoundEvent.ECHO_ONSET,
		"slot": "echo.onset",
		"path": "res://audio/echo/sfx_echo_onset.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_37",
		"mix_rate": 22050,
		"duration": 0.2018,
		"fallback_duration": 0.28,
		"volume_db": -8.0,
	},
	{
		"label": "echo peak",
		"event": AudioManagerScript.SoundEvent.ECHO_PEAK,
		"slot": "echo.bed_loop",
		"path": "res://audio/echo/sfx_echo_peak.wav",
		"provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_78",
		"mix_rate": 15000,
		"duration": 1.0727,
		"fallback_duration": 1.10,
		"volume_db": -4.0,
	},
	{
		"label": "echo tail",
		"event": AudioManagerScript.SoundEvent.ECHO_TAIL,
		"slot": "echo.completion",
		"path": "res://audio/echo/sfx_echo_completion_tail.wav",
		"provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_60",
		"mix_rate": 12000,
		"duration": 0.4420,
		"fallback_duration": 0.45,
		"volume_db": -12.0,
	},
]

static func verify(manager: Node) -> String:
	if manager == null:
		return "AudioManager is missing"

	if absf(float(MemoryEchoControllerScript.ONSET_DURATION) - 0.28) > 0.001:
		return "Memory Echo ONSET timing changed"
	if absf(float(MemoryEchoControllerScript.PEAK_DURATION) - 1.10) > 0.001:
		return "Memory Echo PEAK timing changed"
	if absf(float(MemoryEchoControllerScript.RELEASE_DURATION) - 0.45) > 0.001:
		return "Memory Echo RELEASE timing changed"

	var echo_voice := manager.get("_echo_voice") as AudioStreamPlayer
	if echo_voice == null:
		return "shared MemoryEchoVoice is unavailable"
	if StringName(echo_voice.bus) != &"Master":
		return "MemoryEchoVoice must remain routed to Master"

	var cache_value: Variant = manager.get("_echo_production_streams")
	if typeof(cache_value) != TYPE_DICTIONARY:
		return "dedicated Echo production stream cache is unavailable"
	var production_streams: Dictionary = cache_value

	for target in TARGETS:
		var label: String = target["label"]
		var event: int = target["event"]
		var slot_id: String = target["slot"]
		var asset_path: String = target["path"]

		if AudioManagerScript.event_to_slot_id(event) != slot_id:
			return "%s event mapping must remain %s" % [label, slot_id]
		if not AudioRegistryScript.has_slot(slot_id):
			return "%s semantic slot is missing" % label

		var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
		if slot.get("domain") != AudioRegistryScript.Domain.ECHO:
			return "%s domain must remain ECHO" % label
		if slot.get("diegesis") != AudioRegistryScript.Diegesis.NON_DIEGETIC:
			return "%s diegesis must remain NON_DIEGETIC" % label
		if slot.get("spatial_type") != AudioRegistryScript.SpatialType.NON_DIEGETIC_2D:
			return "%s spatial metadata must remain NON_DIEGETIC_2D" % label
		if slot.get("mix_group") != AudioRegistryScript.MixGroup.SIGNATURE_ECHO:
			return "%s mix group must remain SIGNATURE_ECHO" % label
		if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
			return "%s must be aligned to finite TRANSIENT playback" % label
		if bool(slot.get("is_looping", true)):
			return "%s must remain non-looping" % label
		if float(slot.get("loop_start_sec", -1.0)) != 0.0 or float(slot.get("loop_end_sec", -1.0)) != 0.0:
			return "%s loop window must be cleared" % label
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
			return "%s was not resolved into the dedicated Echo production cache" % label

		manager.call("reset_audio_instant")
		var before_3d: int = (manager.get("_active_transients") as Array).size()
		var before_2d: int = (manager.get("_active_2d_transients") as Array).size()
		manager.call("play_event", event, Vector3(99.0, 42.0, -17.0))
		if echo_voice.stream != stream:
			return "%s did not play selected production stream on shared Echo voice" % label
		if not echo_voice.playing:
			return "%s production stream did not enter playing state" % label
		if absf(echo_voice.volume_db - float(target["volume_db"])) > 0.01:
			return "%s changed retained phase volume" % label
		if (manager.get("_active_transients") as Array).size() != before_3d:
			return "%s incorrectly entered generic 3D transient pool" % label
		if (manager.get("_active_2d_transients") as Array).size() != before_2d:
			return "%s incorrectly created a generic 2D transient voice" % label

		manager.call("reset_audio_instant")
		var saved_stream: AudioStream = production_streams[event]
		production_streams.erase(event)
		manager.set("_echo_production_streams", production_streams)
		manager.call("play_event", event, Vector3.ZERO)
		if echo_voice.stream == stream:
			return "%s procedural fallback is not independently reachable" % label
		if not echo_voice.stream is AudioStreamWAV:
			return "%s fallback did not produce AudioStreamWAV" % label
		if absf(echo_voice.stream.get_length() - float(target["fallback_duration"])) > 0.02:
			return "%s fallback duration changed" % label
		production_streams[event] = saved_stream
		manager.set("_echo_production_streams", production_streams)

	# A missing Onset production stream must not disable Peak production playback.
	manager.call("reset_audio_instant")
	var onset_event: int = TARGETS[0]["event"]
	var peak_event: int = TARGETS[1]["event"]
	var saved_onset: AudioStream = production_streams[onset_event]
	production_streams.erase(onset_event)
	manager.set("_echo_production_streams", production_streams)
	manager.call("play_event", peak_event, Vector3.ZERO)
	var peak_stream := load(String(TARGETS[1]["path"])) as AudioStreamWAV
	if echo_voice.stream != peak_stream:
		production_streams[onset_event] = saved_onset
		manager.set("_echo_production_streams", production_streams)
		return "one missing Echo production stream disabled another phase"
	production_streams[onset_event] = saved_onset
	manager.set("_echo_production_streams", production_streams)

	# MEMORY_ECHO mix state must retain radio duck ownership and trigger production Onset.
	manager.call("reset_audio_instant")
	manager.call("set_mix_state", AudioManagerScript.MixState.MEMORY_ECHO)
	if absf(float(manager.call("get_radio_duck")) - -16.0) > 0.1:
		return "MEMORY_ECHO mix state no longer applies -16 dB radio duck"
	var onset_stream := load(String(TARGETS[0]["path"])) as AudioStreamWAV
	if echo_voice.stream != onset_stream:
		return "MEMORY_ECHO mix state did not trigger production Echo Onset"

	manager.call("reset_audio_instant")
	if echo_voice.playing:
		return "authoritative reset left MemoryEchoVoice playing"
	if absf(echo_voice.volume_db) > 0.01:
		return "authoritative reset did not restore MemoryEchoVoice volume"

	return ""
