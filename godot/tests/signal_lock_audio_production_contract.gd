extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const SLOT_ID := "player.signal_lock_pulse"
const PRODUCTION_ASSET_PATH := "res://audio/player/sfx_player_signal_lock_pulse.wav"
const SOURCE_PROVENANCE := "GTA_SA:GENRL:BANK_143:SOUND_31"
const EXPECTED_MIX_RATE := 23000
const EXPECTED_DURATION_SEC := 0.3780

static func verify(manager: Node) -> String:
	if manager == null:
		return "AudioManager is missing"
	if not AudioRegistryScript.has_slot(SLOT_ID):
		return "signal lock slot is not registered"

	var slot: Dictionary = AudioRegistryScript.get_slot(SLOT_ID)
	if slot.get("domain") != AudioRegistryScript.Domain.PLAYER:
		return "signal lock domain must remain PLAYER"
	if slot.get("diegesis") != AudioRegistryScript.Diegesis.HYBRID:
		return "signal lock diegesis must remain HYBRID"
	if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
		return "signal lock spatial metadata must match live 3D tuner playback"
	if slot.get("mix_group") != AudioRegistryScript.MixGroup.SIGNATURE_ECHO:
		return "signal lock mix group must remain SIGNATURE_ECHO"
	if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		return "signal lock must remain a transient"
	if bool(slot.get("is_looping", true)):
		return "signal lock must remain non-looping"
	if slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		return "signal lock must be promoted to production-final status"
	if slot.get("replacement_required") != false:
		return "signal lock production asset must clear replacement_required"
	if AudioRegistryScript.get_production_asset_path(SLOT_ID) != PRODUCTION_ASSET_PATH:
		return "signal lock production path must be %s" % PRODUCTION_ASSET_PATH
	if AudioRegistryScript.get_source_provenance(SLOT_ID) != SOURCE_PROVENANCE:
		return "signal lock provenance must be %s" % SOURCE_PROVENANCE

	if not FileAccess.file_exists(PRODUCTION_ASSET_PATH):
		return "signal lock production WAV is missing"
	var stream := load(PRODUCTION_ASSET_PATH) as AudioStreamWAV
	if stream == null or stream.data.is_empty():
		return "signal lock production asset must load as non-empty AudioStreamWAV"
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		return "signal lock production WAV must be 16-bit PCM"
	if stream.stereo:
		return "signal lock production WAV must be mono for tuner localization"
	if stream.mix_rate != EXPECTED_MIX_RATE:
		return "signal lock production WAV must preserve native 23 kHz mix rate (got %d)" % stream.mix_rate
	if absf(stream.get_length() - EXPECTED_DURATION_SEC) > 0.01:
		return "signal lock production WAV must preserve ~0.3780s duration (got %.4fs)" % stream.get_length()

	var event := AudioManagerScript.SoundEvent.SIGNAL_LOCK
	if AudioManagerScript.event_to_slot_id(event) != SLOT_ID:
		return "SIGNAL_LOCK must map to player.signal_lock_pulse"

	var cache_value: Variant = manager.get("_production_transient_streams")
	if typeof(cache_value) != TYPE_DICTIONARY:
		return "AudioManager production transient cache is unavailable"
	var production_streams: Dictionary = cache_value
	if not production_streams.has(event) or production_streams[event] != stream:
		return "AudioManager did not resolve the signal lock production stream through registry"

	manager.call("reset_audio_instant")
	var test_pos := Vector3(-4.25, 2.0, 13.5)
	manager.call("play_event", event, test_pos)
	var active: Array = manager.get("_active_transients")
	if active.is_empty():
		return "SIGNAL_LOCK did not create a production 3D transient"
	var player := active[-1] as AudioStreamPlayer3D
	if player == null or player.stream != stream:
		return "SIGNAL_LOCK did not play the selected production stream"
	if player.global_position.distance_to(test_pos) > 0.01:
		return "SIGNAL_LOCK did not preserve supplied tuner world position"
	if absf(player.unit_size - 10.0) > 0.01:
		return "SIGNAL_LOCK changed spatial unit_size from existing value 10"
	if player.max_distance != 0.0:
		return "SIGNAL_LOCK production path introduced an unauthorized max_distance override"

	manager.call("reset_audio_instant")
	production_streams.erase(event)
	manager.set("_production_transient_streams", production_streams)
	manager.call("play_event", event, test_pos)
	var fallback: Array = manager.get("_active_transients")
	if fallback.is_empty():
		return "procedural signal lock fallback did not create a transient"
	var fallback_player := fallback[-1] as AudioStreamPlayer3D
	if fallback_player == null or fallback_player.stream == stream:
		return "procedural signal lock fallback is not independently reachable"
	if absf(fallback_player.unit_size - 10.0) > 0.01:
		return "procedural signal lock fallback changed unit_size"
	if absf(fallback_player.stream.get_length() - 0.35) > 0.02:
		return "procedural signal lock fallback no longer preserves ~0.35s sweep duration"

	# Restore exact ready-state cache for downstream regression contracts.
	manager.call("reset_audio_instant")
	production_streams[event] = stream
	manager.set("_production_transient_streams", production_streams)
	return ""
