extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const SLOT_ID := "interaction.gate_triggered"
const PRODUCTION_ASSET_PATH := "res://audio/interaction/sfx_interaction_gate_slam.wav"
const SOURCE_PROVENANCE := "GTA_SA:GENRL:BANK_42:SOUND_0"
const EXPECTED_MIX_RATE := 18000
const EXPECTED_DURATION_SEC := 0.5538

static func verify(manager: Node) -> String:
	if manager == null:
		return "AudioManager is missing"
	if not AudioRegistryScript.has_slot(SLOT_ID):
		return "%s slot is not registered" % SLOT_ID

	var slot: Dictionary = AudioRegistryScript.get_slot(SLOT_ID)
	if slot.get("domain") != AudioRegistryScript.Domain.INTERACTION:
		return "gate slot domain must remain INTERACTION"
	if slot.get("diegesis") != AudioRegistryScript.Diegesis.DIEGETIC:
		return "gate slot diegesis must remain DIEGETIC"
	if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
		return "gate slot spatial_type must remain DIEGETIC_3D"
	if slot.get("mix_group") != AudioRegistryScript.MixGroup.CRITICAL_THREAT:
		return "gate slot mix_group must remain CRITICAL_THREAT"
	if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		return "gate slot playback_type must remain TRANSIENT"
	if bool(slot.get("is_looping", true)):
		return "gate production sound must remain non-looping"
	if slot.get("replacement_required") != false:
		return "selected production gate sound must clear replacement_required"
	if AudioRegistryScript.get_production_asset_path(SLOT_ID) != PRODUCTION_ASSET_PATH:
		return "gate production_asset_path must be %s" % PRODUCTION_ASSET_PATH
	if AudioRegistryScript.get_source_provenance(SLOT_ID) != SOURCE_PROVENANCE:
		return "gate source_provenance must be %s" % SOURCE_PROVENANCE

	if not FileAccess.file_exists(PRODUCTION_ASSET_PATH):
		return "production gate WAV is missing"
	var stream := load(PRODUCTION_ASSET_PATH) as AudioStreamWAV
	if stream == null:
		return "production gate asset failed to load as AudioStreamWAV"
	if stream.data.is_empty():
		return "production gate WAV contains no PCM data"
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		return "production gate WAV must be 16-bit PCM"
	if stream.stereo:
		return "production gate WAV must be mono for 3D localization"
	if stream.mix_rate != EXPECTED_MIX_RATE:
		return "production gate WAV must preserve native 18 kHz mix rate (got %d)" % stream.mix_rate
	if absf(stream.get_length() - EXPECTED_DURATION_SEC) > 0.01:
		return "production gate WAV must preserve ~0.5538s duration (got %.4fs)" % stream.get_length()

	if AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.GATE_SLAM) != SLOT_ID:
		return "GATE_SLAM must map to interaction.gate_triggered"
	if manager.get("_gate_slam_production_stream") == null:
		return "AudioManager did not resolve the gate production stream"

	manager.call("reset_audio_instant")
	var test_pos := Vector3(-17.25, 1.5, 42.0)
	manager.call("play_event", AudioManagerScript.SoundEvent.GATE_SLAM, test_pos)
	var active: Array = manager.get("_active_transients")
	if active.is_empty():
		return "GATE_SLAM did not create a production transient voice"
	var player := active[-1] as AudioStreamPlayer3D
	if player == null or player.stream != stream:
		return "GATE_SLAM did not play the selected production stream"
	if player.global_position.distance_to(test_pos) > 0.01:
		return "GATE_SLAM did not preserve the supplied gate world position"

	manager.call("reset_audio_instant")
	manager.set("_gate_slam_production_stream", null)
	manager.call("play_event", AudioManagerScript.SoundEvent.GATE_SLAM, test_pos)
	var fallback: Array = manager.get("_active_transients")
	if fallback.is_empty():
		return "procedural gate fallback did not create a transient voice"
	var fallback_player := fallback[-1] as AudioStreamPlayer3D
	if fallback_player == null or fallback_player.stream == stream:
		return "procedural gate fallback is not independently reachable"

	# Restore production stream so later runtime tests see the same ready-state contract.
	manager.call("reset_audio_instant")
	manager.set("_gate_slam_production_stream", stream)
	return ""
