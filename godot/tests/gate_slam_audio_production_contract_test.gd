extends SceneTree

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const SLOT_ID := "interaction.gate_triggered"
const PRODUCTION_ASSET_PATH := "res://audio/interaction/sfx_interaction_gate_slam.wav"

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[GATE_SLAM_AUDIO_PRODUCTION] FAIL: %s" % message)
	await process_frame
	await process_frame
	quit(1)

func _pass(message: String) -> void:
	print("[GATE_SLAM_AUDIO_PRODUCTION] PASS: %s" % message)
	await process_frame
	await process_frame
	quit(0)

func _run() -> void:
	# 1. Existing semantic slot remains correctly typed, but now owns one selected
	# production transient and exact GTA source provenance.
	if not AudioRegistryScript.has_slot(SLOT_ID):
		await _fail("%s slot is not registered" % SLOT_ID)
		return

	var slot: Dictionary = AudioRegistryScript.get_slot(SLOT_ID)
	if slot.get("domain") != AudioRegistryScript.Domain.INTERACTION:
		await _fail("gate slot domain must remain INTERACTION")
		return
	if slot.get("diegesis") != AudioRegistryScript.Diegesis.DIEGETIC:
		await _fail("gate slot diegesis must remain DIEGETIC")
		return
	if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
		await _fail("gate slot spatial_type must remain DIEGETIC_3D")
		return
	if slot.get("mix_group") != AudioRegistryScript.MixGroup.CRITICAL_THREAT:
		await _fail("gate slot mix_group must remain CRITICAL_THREAT")
		return
	if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		await _fail("gate slot playback_type must remain TRANSIENT")
		return
	if bool(slot.get("is_looping", true)):
		await _fail("gate production sound must remain non-looping")
		return
	if slot.get("replacement_required") != false:
		await _fail("selected production gate sound must clear replacement_required")
		return
	if AudioRegistryScript.get_production_asset_path(SLOT_ID) != PRODUCTION_ASSET_PATH:
		await _fail("gate production_asset_path must be %s" % PRODUCTION_ASSET_PATH)
		return

	var provenance: String = AudioRegistryScript.get_source_provenance(SLOT_ID)
	if not provenance.begins_with("GTA_SA:") or provenance.find(":BANK_") < 0 or provenance.find(":SOUND_") < 0:
		await _fail("gate source_provenance must record exact GTA pak/bank/sound identity")
		return

	# 2. Curated production asset must be a compact mono 16-bit PCM transient.
	if not FileAccess.file_exists(PRODUCTION_ASSET_PATH):
		await _fail("production gate WAV is missing")
		return

	var stream := load(PRODUCTION_ASSET_PATH) as AudioStreamWAV
	if stream == null:
		await _fail("production gate asset failed to load as AudioStreamWAV")
		return
	if stream.data.is_empty():
		await _fail("production gate WAV contains no PCM data")
		return
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		await _fail("production gate WAV must be 16-bit PCM")
		return
	if stream.stereo:
		await _fail("production gate WAV must be mono for 3D localization")
		return
	if stream.mix_rate < 8000 or stream.mix_rate > 48000:
		await _fail("production gate WAV has implausible mix rate: %d" % stream.mix_rate)
		return
	var duration := stream.get_length()
	if duration < 0.20 or duration > 0.80:
		await _fail("production gate transient must stay compact (got %.4fs)" % duration)
		return

	# 3. AudioManager must expose the semantic mapping and load through registry.
	if AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.GATE_SLAM) != SLOT_ID:
		await _fail("GATE_SLAM must map to interaction.gate_triggered")
		return

	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	if manager.get("_gate_slam_production_stream") == null:
		manager.queue_free()
		await _fail("AudioManager did not resolve the gate production stream")
		return

	# 4. Production playback must stay 3D and preserve the supplied world source.
	var test_pos := Vector3(-17.25, 1.5, 42.0)
	manager.play_event(AudioManagerScript.SoundEvent.GATE_SLAM, test_pos)
	var active: Array = manager.get("_active_transients")
	if active.is_empty():
		manager.queue_free()
		await _fail("GATE_SLAM did not create a production transient voice")
		return
	var player := active[-1] as AudioStreamPlayer3D
	if player == null or player.stream != stream:
		manager.queue_free()
		await _fail("GATE_SLAM did not play the selected production stream")
		return
	if player.global_position.distance_to(test_pos) > 0.01:
		manager.queue_free()
		await _fail("GATE_SLAM did not preserve the supplied gate world position")
		return

	# 5. Existing procedural downward sweep remains reachable if the production
	# stream cannot be resolved.
	manager.reset_audio_instant()
	manager.set("_gate_slam_production_stream", null)
	manager.play_event(AudioManagerScript.SoundEvent.GATE_SLAM, test_pos)
	var fallback: Array = manager.get("_active_transients")
	if fallback.is_empty():
		manager.queue_free()
		await _fail("procedural gate fallback did not create a transient voice")
		return
	var fallback_player := fallback[-1] as AudioStreamPlayer3D
	if fallback_player == null or fallback_player.stream == stream:
		manager.queue_free()
		await _fail("procedural gate fallback is not independently reachable")
		return

	manager.reset_audio_instant()
	manager.queue_free()
	await process_frame
	await process_frame
	await _pass("selected gate WAV, semantic mapping, 3D production playback and procedural fallback verified")
