extends SceneTree

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const SLOT_ID := "player.signal_lock_pulse"
const PRODUCTION_ASSET_PATH := "res://audio/player/sfx_player_signal_lock_pulse.wav"

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[AUDIO_PRODUCTION_01F] FAIL: %s" % message)
	await process_frame
	await process_frame
	quit(1)

func _run() -> void:
	if not AudioRegistryScript.has_slot(SLOT_ID):
		await _fail("signal lock slot is not registered")
		return

	var slot: Dictionary = AudioRegistryScript.get_slot(SLOT_ID)
	if slot.get("domain") != AudioRegistryScript.Domain.PLAYER:
		await _fail("signal lock domain must remain PLAYER")
		return
	if slot.get("diegesis") != AudioRegistryScript.Diegesis.HYBRID:
		await _fail("signal lock diegesis must remain HYBRID")
		return
	if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
		await _fail("signal lock spatial metadata must match live 3D tuner playback")
		return
	if slot.get("mix_group") != AudioRegistryScript.MixGroup.SIGNATURE_ECHO:
		await _fail("signal lock mix group must remain SIGNATURE_ECHO")
		return
	if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT or bool(slot.get("is_looping", true)):
		await _fail("signal lock must remain a non-looping transient")
		return
	if slot.get("replacement_required") != false:
		await _fail("selected signal lock production asset must clear replacement_required")
		return
	if AudioRegistryScript.get_production_asset_path(SLOT_ID) != PRODUCTION_ASSET_PATH:
		await _fail("signal lock production path must be %s" % PRODUCTION_ASSET_PATH)
		return

	var provenance: String = AudioRegistryScript.get_source_provenance(SLOT_ID)
	if not provenance.begins_with("GTA_SA:") or provenance.find(":BANK_") < 0 or provenance.find(":SOUND_") < 0:
		await _fail("signal lock provenance must record exact GTA pak/bank/sound identity")
		return

	if not FileAccess.file_exists(PRODUCTION_ASSET_PATH):
		await _fail("signal lock production WAV is missing")
		return
	var stream := load(PRODUCTION_ASSET_PATH) as AudioStreamWAV
	if stream == null or stream.data.is_empty():
		await _fail("signal lock production asset must load as non-empty AudioStreamWAV")
		return
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		await _fail("signal lock production WAV must be 16-bit PCM")
		return
	if stream.stereo:
		await _fail("signal lock production WAV must be mono for tuner localization")
		return
	if stream.get_length() < 0.08 or stream.get_length() > 0.45:
		await _fail("signal lock production transient must stay compact (got %.4fs)" % stream.get_length())
		return

	if AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.SIGNAL_LOCK) != SLOT_ID:
		await _fail("SIGNAL_LOCK must map to player.signal_lock_pulse")
		return

	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var cache_value: Variant = manager.get("_production_transient_streams")
	if typeof(cache_value) != TYPE_DICTIONARY:
		manager.queue_free()
		await _fail("AudioManager production transient cache is unavailable")
		return
	var production_streams: Dictionary = cache_value
	var event := AudioManagerScript.SoundEvent.SIGNAL_LOCK
	if not production_streams.has(event) or production_streams[event] != stream:
		manager.queue_free()
		await _fail("AudioManager did not resolve the signal lock production stream through registry")
		return

	var test_pos := Vector3(-4.25, 2.0, 13.5)
	manager.play_event(event, test_pos)
	var active: Array = manager.get("_active_transients")
	if active.is_empty():
		manager.queue_free()
		await _fail("SIGNAL_LOCK did not create a production 3D transient")
		return
	var player := active[-1] as AudioStreamPlayer3D
	if player == null or player.stream != stream:
		manager.queue_free()
		await _fail("SIGNAL_LOCK did not play the selected production stream")
		return
	if player.global_position.distance_to(test_pos) > 0.01:
		manager.queue_free()
		await _fail("SIGNAL_LOCK did not preserve supplied tuner world position")
		return
	if absf(player.unit_size - 10.0) > 0.01:
		manager.queue_free()
		await _fail("SIGNAL_LOCK changed spatial unit_size from existing value 10")
		return

	manager.reset_audio_instant()
	production_streams.erase(event)
	manager.set("_production_transient_streams", production_streams)
	manager.play_event(event, test_pos)
	var fallback: Array = manager.get("_active_transients")
	if fallback.is_empty():
		manager.queue_free()
		await _fail("procedural signal lock fallback did not create a transient")
		return
	var fallback_player := fallback[-1] as AudioStreamPlayer3D
	if fallback_player == null or fallback_player.stream == stream:
		manager.queue_free()
		await _fail("procedural signal lock fallback is not independently reachable")
		return
	if absf(fallback_player.unit_size - 10.0) > 0.01:
		manager.queue_free()
		await _fail("procedural signal lock fallback changed unit_size")
		return
	if absf(fallback_player.stream.get_length() - 0.35) > 0.02:
		manager.queue_free()
		await _fail("procedural signal lock fallback no longer preserves ~0.35s sweep duration")
		return

	manager.reset_audio_instant()
	manager.queue_free()
	await process_frame
	await process_frame
	print("[AUDIO_PRODUCTION_01F] PASS: signal lock semantic repair, production 3D playback and procedural fallback verified")
	quit(0)
