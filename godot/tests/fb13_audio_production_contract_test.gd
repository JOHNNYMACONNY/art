extends SceneTree

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const PRODUCTION_ASSET_PATH := "res://audio/world/sfx_world_fb13_resonance.wav"

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[FB13_AUDIO_PRODUCTION] FAIL: %s" % message)
	await process_frame
	await process_frame
	quit(1)

func _pass(message: String) -> void:
	print("[FB13_AUDIO_PRODUCTION] PASS: %s" % message)
	await process_frame
	await process_frame
	quit(0)

func _run() -> void:
	# 1. Verify AudioRegistry slot existence & configuration
	if not AudioRegistryScript.has_slot("world.fb13_thrum"):
		await _fail("world.fb13_thrum slot is not registered in AudioRegistry")
		return

	var slot: Dictionary = AudioRegistryScript.get_slot("world.fb13_thrum")
	if slot.get("domain") != AudioRegistryScript.Domain.WORLD:
		await _fail("world.fb13_thrum domain must be WORLD")
		return
	if slot.get("diegesis") != AudioRegistryScript.Diegesis.DIEGETIC:
		await _fail("world.fb13_thrum diegesis must be DIEGETIC")
		return
	if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
		await _fail("world.fb13_thrum spatial_type must be DIEGETIC_3D")
		return
	if slot.get("mix_group") != AudioRegistryScript.MixGroup.AMBIENT_TEXTURE:
		await _fail("world.fb13_thrum mix_group must be AMBIENT_TEXTURE")
		return
	if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		await _fail("world.fb13_thrum playback_type must be TRANSIENT")
		return
	if slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		await _fail("world.fb13_thrum asset_status must be LICENSED_FINAL")
		return
	if slot.get("replacement_required") != false:
		await _fail("world.fb13_thrum replacement_required must be false for production asset")
		return
	if slot.get("production_asset_path") != PRODUCTION_ASSET_PATH:
		await _fail("world.fb13_thrum production_asset_path mismatch")
		return
	if slot.get("source_provenance") != "GTA_SA:GENRL:BANK_7:SOUND_0":
		await _fail("world.fb13_thrum source_provenance must record GTA_SA:GENRL:BANK_7:SOUND_0")
		return

	# 2. Verify production WAV file integrity
	if not FileAccess.file_exists(PRODUCTION_ASSET_PATH):
		await _fail("Production audio file does not exist at %s" % PRODUCTION_ASSET_PATH)
		return

	var stream := load(PRODUCTION_ASSET_PATH) as AudioStreamWAV
	if stream == null:
		await _fail("Failed to load production audio as AudioStreamWAV: %s" % PRODUCTION_ASSET_PATH)
		return
	if stream.data.is_empty():
		await _fail("Production audio stream PCM data is empty")
		return
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		await _fail("Production stream must be 16-bit PCM (format=%d)" % stream.format)
		return
	if stream.stereo != false:
		await _fail("Production stream must be mono for 3D positional audio")
		return
	if stream.mix_rate != 18000:
		await _fail("Production stream mix rate must match native 18000 Hz (got %d)" % stream.mix_rate)
		return

	var dur := stream.get_length()
	if dur < 0.60 or dur > 0.70:
		await _fail("Production stream duration must be ~0.652s (got %.4fs)" % dur)
		return

	# 3. Verify AudioManager event mapping
	var slot_id: String = AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.FB13_THRUM)
	if slot_id != "world.fb13_thrum":
		await _fail("AudioManager.event_to_slot_id(FB13_THRUM) must return 'world.fb13_thrum', got '%s'" % slot_id)
		return

	# 4. Verify AudioManager runtime resolution & playback
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	if manager.get("_fb13_production_stream") == null:
		manager.queue_free()
		await _fail("AudioManager._fb13_production_stream was not loaded in _ready()")
		return

	# Test production asset playback
	manager.play_event(AudioManagerScript.SoundEvent.FB13_THRUM, Vector3(12.5, 0.0, -8.0))
	var active_transients: Array = manager.get("_active_transients")
	if active_transients.is_empty():
		manager.queue_free()
		await _fail("AudioManager failed to spawn transient voice for FB13_THRUM")
		return

	var latest_player: AudioStreamPlayer3D = active_transients[-1] as AudioStreamPlayer3D
	if latest_player == null or latest_player.stream != stream:
		manager.queue_free()
		await _fail("FB13_THRUM did not play production AudioStreamWAV stream")
		return
	if latest_player.global_position.distance_to(Vector3(12.5, 0.0, -8.0)) > 0.01:
		manager.queue_free()
		await _fail("FB13_THRUM spatial position was not assigned correctly")
		return

	# 5. Verify procedural fallback is reachable when production stream is absent
	manager.set("_fb13_production_stream", null)
	manager.play_event(AudioManagerScript.SoundEvent.FB13_THRUM, Vector3(5.0, 0.0, 5.0))
	var fallback_transients: Array = manager.get("_active_transients")
	if fallback_transients.size() < 2:
		manager.queue_free()
		await _fail("Procedural fallback did not spawn transient sweep/click voices")
		return

	# Instant reset cleanup
	manager.reset_audio_instant()
	manager.queue_free()
	await process_frame
	await process_frame

	await _pass("Slot registered, production WAV verified (18kHz 16-bit mono 0.6518s), runtime playback and procedural fallback confirmed")
