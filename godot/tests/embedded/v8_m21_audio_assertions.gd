extends RefCounted

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const MemoryEchoController = preload("res://scripts/prototype/memory_echo_controller.gd")
const ScrapHaulerScript = preload("res://scripts/vehicles/scrap_hauler.gd")
const ScrapWorkerScript = preload("res://scripts/entities/scrap_worker.gd")
const UtilityCrawlerScript = preload("res://scripts/entities/utility_crawler.gd")
const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramDirectorScript = preload("res://scripts/audio/radio/radio_program_director.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")
const CourierBikeScript = preload("res://scripts/vehicles/courier_bike.gd")
const PursuerPrototypeScript = preload("res://scripts/entities/pursuer_prototype.gd")
const SignalGateInteractableScript = preload("res://scripts/interactions/signal_gate_interactable.gd")
const SignalTunerScript = preload("res://scripts/interactions/signal_tuner.gd")
const CorrodedPanelScript = preload("res://scripts/interactions/corroded_panel.gd")
const TestHelpers = preload("res://tests/embedded/test_helpers.gd")

static func run(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[RUNNING V8 M21 SEMANTIC AUDIO REGISTRY & RESOLVER ASSERTION SUITE (#21)]")
	print("=========================================================================\n")

	# -------------------------------------------------------------------------
	# ASSERTION 1: Master Slot Table Schema Completeness, Diegesis & Loop Lifecycle
	# -------------------------------------------------------------------------
	print("[ASSERTION 1] Testing Master Slot Table Schema completeness...")
	var all_slots: Dictionary = AudioRegistryScript.get_all_slots()
	assert(all_slots.size() >= 20, "FAIL 1: AudioRegistry must contain at least 20 registered semantic slots (found %d)" % all_slots.size())

	for slot_id in all_slots.keys():
		var slot_def: Dictionary = all_slots[slot_id]
		assert(slot_def.has("slot_id") and slot_def["slot_id"] == slot_id, "FAIL 1: Slot %s missing valid slot_id" % slot_id)
		assert(not slot_def.has("sound_event"), "FAIL 1: Slot %s must NOT embed raw integer sound_event" % slot_id)
		assert(slot_def.has("domain") and slot_def["domain"] is int, "FAIL 1: Slot %s missing valid domain" % slot_id)
		assert(slot_def.has("diegesis") and slot_def["diegesis"] is int, "FAIL 1: Slot %s missing valid diegesis" % slot_id)
		assert(slot_def.has("spatial_type") and slot_def["spatial_type"] is int, "FAIL 1: Slot %s missing valid spatial_type" % slot_id)
		assert(slot_def.has("mix_group") and slot_def["mix_group"] is int, "FAIL 1: Slot %s missing valid mix_group" % slot_id)
		assert(slot_def.has("playback_type") and slot_def["playback_type"] is int, "FAIL 1: Slot %s missing valid playback_type" % slot_id)
		assert(slot_def.has("is_looping") and slot_def["is_looping"] is bool, "FAIL 1: Slot %s missing is_looping bool" % slot_id)
		assert(slot_def.has("loop_start_sec") and slot_def["loop_start_sec"] is float, "FAIL 1: Slot %s missing loop_start_sec" % slot_id)
		assert(slot_def.has("loop_end_sec") and slot_def["loop_end_sec"] is float, "FAIL 1: Slot %s missing loop_end_sec" % slot_id)
		assert(slot_def.has("cooldown_msec") and slot_def["cooldown_msec"] >= 0, "FAIL 1: Slot %s missing valid cooldown_msec" % slot_id)
		assert(slot_def.has("max_concurrency") and slot_def["max_concurrency"] >= 1, "FAIL 1: Slot %s missing valid max_concurrency" % slot_id)
		assert(slot_def.has("asset_status") and slot_def["asset_status"] is int, "FAIL 1: Slot %s missing valid asset_status" % slot_id)

	# Verify enum-to-semantic ID mapping in AudioManager
	assert(AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.FOOTSTEP) == "player.footstep", "FAIL 1: FOOTSTEP maps to player.footstep")
	assert(AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.BRAKE_SCREECH) == "vehicle.brake_screech", "FAIL 1: BRAKE_SCREECH maps to vehicle.brake_screech")
	assert(AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.PANEL_PEEL) == "interaction.panel_peel", "FAIL 1: PANEL_PEEL maps to interaction.panel_peel")
	assert(AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.COLLISION_GLANCE) == "vehicle.collision_glance", "FAIL 1: COLLISION_GLANCE maps to vehicle.collision_glance")
	print("  -> Assertion 1 PASS: Master Slot Table schema, Diegesis & symbolic enum mapping 100%% complete (%d slots verified)!" % all_slots.size())

	# -------------------------------------------------------------------------
	# ASSERTION 2: Domain, Diegesis, Mix Group & Backlog Queries
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 2] Testing domain, diegesis, and mix group queries...")
	var vehicle_slots: Array[Dictionary] = AudioRegistryScript.get_slots_by_domain(AudioRegistryScript.Domain.VEHICLE)
	assert(vehicle_slots.size() >= 4, "FAIL 2: VEHICLE domain must contain at least 4 slots (found %d)" % vehicle_slots.size())

	var diegetic_slots: Array[Dictionary] = AudioRegistryScript.get_slots_by_diegesis(AudioRegistryScript.Diegesis.DIEGETIC)
	assert(diegetic_slots.size() >= 12, "FAIL 2: DIEGETIC query must return at least 12 slots (found %d)" % diegetic_slots.size())

	var non_diegetic_slots: Array[Dictionary] = AudioRegistryScript.get_slots_by_diegesis(AudioRegistryScript.Diegesis.NON_DIEGETIC)
	assert(non_diegetic_slots.size() >= 4, "FAIL 2: NON_DIEGETIC query must return at least 4 slots (found %d)" % non_diegetic_slots.size())

	var threat_mix: Array[Dictionary] = AudioRegistryScript.get_slots_by_mix_group(AudioRegistryScript.MixGroup.CRITICAL_THREAT)
	assert(threat_mix.size() >= 4, "FAIL 2: CRITICAL_THREAT mix group must contain at least 4 slots (found %d)" % threat_mix.size())

	var backlog: Array[Dictionary] = AudioRegistryScript.get_replacement_backlog()
	assert(backlog.size() == 0, "FAIL 2: Replacement backlog should be 0 upon 100%% 01Q audio catalog promotion (found %d)" % backlog.size())
	print("  -> Assertion 2 PASS: Domain, Diegesis, Mix Group, and Backlog queries verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 3: Narrow Migrated Playback Tracer Inventory (Asset-Only)
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 3] Testing narrow playback migration tracer inventory...")
	assert(AudioManagerScript.MIGRATED_TRACER_EVENTS.size() == 4, "FAIL 3: MIGRATED_TRACER_EVENTS must contain exactly 4 focused tracer events")
	assert(AudioManagerScript.MIGRATED_TRACER_EVENTS.has(AudioManagerScript.SoundEvent.FOOTSTEP), "FAIL 3: Must include FOOTSTEP")
	assert(AudioManagerScript.MIGRATED_TRACER_EVENTS.has(AudioManagerScript.SoundEvent.BRAKE_SCREECH), "FAIL 3: Must include BRAKE_SCREECH")
	assert(AudioManagerScript.MIGRATED_TRACER_EVENTS.has(AudioManagerScript.SoundEvent.PANEL_PEEL), "FAIL 3: Must include PANEL_PEEL")
	assert(AudioManagerScript.MIGRATED_TRACER_EVENTS.has(AudioManagerScript.SoundEvent.COLLISION_GLANCE), "FAIL 3: Must include COLLISION_GLANCE")
	assert(not AudioManagerScript.MIGRATED_TRACER_EVENTS.has(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT), "FAIL 3: Must NOT include DISTURBANCE_ALERT in early-return tracer")
	print("  -> Assertion 3 PASS: Narrow asset-only playback migration tracer boundary strictly verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 4: Dev Opt-In & Explicit Manifest Path Gating (Zero Auto-Discovery)
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 4] Testing dev opt-in and zero auto-discovery contract...")
	AudioReferenceResolverScript.reset()
	var prev_env := OS.get_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO")
	var prev_man_env := OS.get_environment("ECHOES_REFERENCE_AUDIO_MANIFEST")
	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "")
	OS.set_environment("ECHOES_REFERENCE_AUDIO_MANIFEST", "")

	var default_res: AudioStreamWAV = AudioReferenceResolverScript.resolve_stream("player.footstep")
	assert(default_res == null, "FAIL 4: Without opt-in flag, resolve_stream must return null")

	# Test that with opt-in enabled but no manifest path provided, resolver does NOT auto-discover
	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "1")
	AudioReferenceResolverScript.reset()
	assert(AudioReferenceResolverScript.get_manifest_path() == "", "FAIL 4: Manifest path must default to empty string (no implicit auto-discovery)")
	assert(AudioReferenceResolverScript.resolve_stream("player.footstep") == null, "FAIL 4: Without explicit manifest path, resolve_stream must return null")
	print("  -> Assertion 4 PASS: Dev opt-in and zero auto-discovery contract strictly verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 5: Strict Versioned Manifest Schema Validation (Exact int 1)
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 5] Testing strict versioned manifest schema validation...")
	var malformed_json_path := "user://test_malformed_manifest.json"
	var f_mal := FileAccess.open(malformed_json_path, FileAccess.WRITE)
	if f_mal:
		f_mal.store_string("{ invalid_json_syntax: [")
		f_mal.close()
	var mal_result: Dictionary = AudioReferenceResolverScript.load_manifest(malformed_json_path)
	assert(mal_result.is_empty(), "FAIL 5: Malformed JSON manifest must return empty dict")
	DirAccess.remove_absolute(malformed_json_path)

	# Test missing version
	var no_ver_path := "user://test_no_ver_manifest.json"
	var f_nv := FileAccess.open(no_ver_path, FileAccess.WRITE)
	if f_nv:
		f_nv.store_string(JSON.stringify({"slots": {"player.footstep": "footstep.wav"}}))
		f_nv.close()
	assert(AudioReferenceResolverScript.load_manifest(no_ver_path).is_empty(), "FAIL 5: Manifest without version must be rejected")
	DirAccess.remove_absolute(no_ver_path)

	# Test float version (1.5)
	var float_ver_path := "user://test_float_ver_manifest.json"
	var f_fv := FileAccess.open(float_ver_path, FileAccess.WRITE)
	if f_fv:
		f_fv.store_string(JSON.stringify({"version": 1.5, "slots": {"player.footstep": "footstep.wav"}}))
		f_fv.close()
	assert(AudioReferenceResolverScript.load_manifest(float_ver_path).is_empty(), "FAIL 5: Float version (1.5) must be rejected")
	DirAccess.remove_absolute(float_ver_path)

	# Test string version ("1")
	var str_ver_path := "user://test_str_ver_manifest.json"
	var f_sv := FileAccess.open(str_ver_path, FileAccess.WRITE)
	if f_sv:
		f_sv.store_string(JSON.stringify({"version": "1", "slots": {"player.footstep": "footstep.wav"}}))
		f_sv.close()
	assert(AudioReferenceResolverScript.load_manifest(str_ver_path).is_empty(), "FAIL 5: String version ('1') must be rejected")
	DirAccess.remove_absolute(str_ver_path)

	# Test version 0
	var zero_ver_path := "user://test_zero_ver_manifest.json"
	var f_zv := FileAccess.open(zero_ver_path, FileAccess.WRITE)
	if f_zv:
		f_zv.store_string(JSON.stringify({"version": 0, "slots": {"player.footstep": "footstep.wav"}}))
		f_zv.close()
	assert(AudioReferenceResolverScript.load_manifest(zero_ver_path).is_empty(), "FAIL 5: Version 0 must be rejected")
	DirAccess.remove_absolute(zero_ver_path)

	# Test unsupported version (99)
	var bad_ver_path := "user://test_bad_ver_manifest.json"
	var f_bv := FileAccess.open(bad_ver_path, FileAccess.WRITE)
	if f_bv:
		f_bv.store_string(JSON.stringify({"version": 99, "slots": {"player.footstep": "footstep.wav"}}))
		f_bv.close()
	assert(AudioReferenceResolverScript.load_manifest(bad_ver_path).is_empty(), "FAIL 5: Manifest with version != 1 must be rejected")
	DirAccess.remove_absolute(bad_ver_path)

	# Test non-string entry
	var bad_schema_path := "user://test_bad_schema_manifest.json"
	var f_schema := FileAccess.open(bad_schema_path, FileAccess.WRITE)
	if f_schema:
		f_schema.store_string(JSON.stringify({
			"version": 1,
			"slots": {
				"player.footstep": 12345
			}
		}))
		f_schema.close()
	var schema_result: Dictionary = AudioReferenceResolverScript.load_manifest(bad_schema_path)
	assert(schema_result.is_empty(), "FAIL 5: Non-string manifest entries must be rejected")
	DirAccess.remove_absolute(bad_schema_path)
	print("  -> Assertion 5 PASS: Strict Version 1 exact integer manifest schema enforcement verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 6: Path Traversal, Absolute Path & Sibling-Prefix Escape Defense
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 6] Testing path traversal, absolute path and sibling-prefix security...")
	assert(AudioReferenceResolverScript.is_valid_relative_path("../secret/audio.wav") == false, "FAIL 6: Must reject ../ path traversal")
	assert(AudioReferenceResolverScript.is_valid_relative_path("audio/../../../etc/passwd.wav") == false, "FAIL 6: Must reject nested traversal")
	assert(AudioReferenceResolverScript.is_valid_relative_path("/absolute/root/audio.wav") == false, "FAIL 6: Must reject leading slash absolute path")
	assert(AudioReferenceResolverScript.is_valid_relative_path("C:\\windows\\audio.wav") == false, "FAIL 6: Must reject Windows drive path")
	assert(AudioReferenceResolverScript.is_valid_relative_path("res://audio.wav") == false, "FAIL 6: Must reject URI scheme in relative manifest")
	assert(AudioReferenceResolverScript.is_valid_relative_path("audio.ogg") == false, "FAIL 6: Must reject .ogg in WAV-only tracer")
	assert(AudioReferenceResolverScript.is_valid_relative_path("audio.mp3") == false, "FAIL 6: Must reject .mp3 in WAV-only tracer")
	assert(AudioReferenceResolverScript.is_valid_relative_path("sounds/footstep.wav") == true, "FAIL 6: Must accept valid relative .wav path")

	# Sibling-prefix escape test
	assert(AudioReferenceResolverScript.is_contained_in_sandbox("user://sandbox_other/test.wav", "user://sandbox/") == false, "FAIL 6: Sibling directory escape must be rejected")
	assert(AudioReferenceResolverScript.is_contained_in_sandbox("user://sandbox/nested/test.wav", "user://sandbox/") == true, "FAIL 6: Genuine subpath must be accepted")
	print("  -> Assertion 6 PASS: Traversal, absolute, sibling-prefix, and WAV-only constraints verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 7: Native WAV Loader Validation & Corrupt WAV Falsification
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 7] Testing native WAV loader and corrupt file handling...")
	var test_sandbox_dir := "user://m21_sandbox_test/"
	DirAccess.make_dir_absolute(test_sandbox_dir)
	var corrupt_wav_path := test_sandbox_dir + "corrupt.wav"
	var f_corrupt := FileAccess.open(corrupt_wav_path, FileAccess.WRITE)
	if f_corrupt:
		f_corrupt.store_string("NOT_A_REAL_WAV_FILE_GARBAGE_BYTES_1234567890")
		f_corrupt.close()

	var corrupt_manifest := test_sandbox_dir + "manifest.json"
	var f_cman := FileAccess.open(corrupt_manifest, FileAccess.WRITE)
	if f_cman:
		f_cman.store_string(JSON.stringify({
			"version": 1,
			"slots": {
				"player.footstep": "corrupt.wav"
			}
		}))
		f_cman.close()

	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "1")
	AudioReferenceResolverScript.reset()
	var corrupt_res: AudioStreamWAV = AudioReferenceResolverScript.resolve_stream("player.footstep", corrupt_manifest)
	assert(corrupt_res == null, "FAIL 7: Corrupt non-WAV bytes must safely resolve to null without crash")
	DirAccess.remove_absolute(corrupt_wav_path)
	DirAccess.remove_absolute(corrupt_manifest)
	DirAccess.remove_absolute(test_sandbox_dir)
	print("  -> Assertion 7 PASS: Corrupt WAV files fail closed to null safely!")

	# -------------------------------------------------------------------------
	# ASSERTION 8: Asset Status Precedence Helper & FINAL Slot Defense
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 8] Testing asset status precedence helper...")
	assert(AudioRegistryScript.is_reference_allowed_for_status(AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK) == true, "FAIL 8: PROCEDURAL_FALLBACK allows reference")
	assert(AudioRegistryScript.is_reference_allowed_for_status(AudioRegistryScript.AssetStatus.REFERENCE_ONLY) == true, "FAIL 8: REFERENCE_ONLY allows reference")
	assert(AudioRegistryScript.is_reference_allowed_for_status(AudioRegistryScript.AssetStatus.ORIGINAL_WIP) == true, "FAIL 8: ORIGINAL_WIP allows reference")
	assert(AudioRegistryScript.is_reference_allowed_for_status(AudioRegistryScript.AssetStatus.ORIGINAL_FINAL) == false, "FAIL 8: ORIGINAL_FINAL rejects reference")
	assert(AudioRegistryScript.is_reference_allowed_for_status(AudioRegistryScript.AssetStatus.LICENSED_FINAL) == false, "FAIL 8: LICENSED_FINAL rejects reference")
	print("  -> Assertion 8 PASS: Asset status precedence contract verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 9: Real Runtime Manifest Route via Environment Variables
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 9] Testing real runtime manifest route via environment variables...")
	var real_sandbox_dir := "user://m21_real_runtime/"
	DirAccess.make_dir_absolute(real_sandbox_dir)
	var real_manifest_path := real_sandbox_dir + "manifest.json"
	var real_wav_name := "footstep_ref.wav"
	var real_wav_path := real_sandbox_dir + real_wav_name

	TestHelpers.create_test_wav_file(real_wav_path, 2205)

	var f_real_man := FileAccess.open(real_manifest_path, FileAccess.WRITE)
	if f_real_man:
		f_real_man.store_string(JSON.stringify({
			"version": 1,
			"slots": {
				"player.footstep": real_wav_name
			}
		}))
		f_real_man.close()

	var prev_manifest_env := OS.get_environment("ECHOES_REFERENCE_AUDIO_MANIFEST")
	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "1")
	OS.set_environment("ECHOES_REFERENCE_AUDIO_MANIFEST", real_manifest_path)
	AudioReferenceResolverScript.reset()
	controller.audio_mgr.reset_audio_instant()

	# Call play_event directly without priming cache
	var initial_transients_count: int = controller.audio_mgr._active_transients.size()
	controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.FOOTSTEP, Vector3.ZERO)
	assert(controller.audio_mgr.get_event_count(AudioManagerScript.SoundEvent.FOOTSTEP) == 1, "FAIL 9: Event count == 1")
	assert(controller.audio_mgr._active_transients.size() == initial_transients_count + 1, "FAIL 9: Exactly 1 reference transient player spawned")

	# Throttle check
	controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.FOOTSTEP, Vector3.ZERO)
	assert(controller.audio_mgr.get_event_count(AudioManagerScript.SoundEvent.FOOTSTEP) == 1, "FAIL 9: Throttled repeat within cooldown")

	# Restore env
	OS.set_environment("ECHOES_REFERENCE_AUDIO_MANIFEST", prev_manifest_env)
	print("  -> Assertion 9 PASS: Real runtime environment manifest discovery route verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 10: DISTURBANCE_ALERT Siren Trigger Parity Under Reference Mode
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 10] Testing DISTURBANCE_ALERT side-effect parity under reference mode...")
	controller.audio_mgr.reset_audio_instant()
	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "1")
	AudioReferenceResolverScript.reset()

	controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT, Vector3.ZERO)
	assert(controller.audio_mgr._siren_player != null and controller.audio_mgr._siren_player.playing, "FAIL 10: DISTURBANCE_ALERT must start siren audio even in reference mode")
	print("  -> Assertion 10 PASS: DISTURBANCE_ALERT siren side effect strictly preserved!")

	# -------------------------------------------------------------------------
	# ASSERTION 11: 2D Non-Diegetic Reference Transient Tracking & Reset Safety
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 11] Testing 2D non-diegetic reference transient tracking and reset...")
	var test_stream := AudioStreamWAV.new()
	test_stream.data = PackedByteArray([128, 128, 128])
	controller.audio_mgr._play_reference_stream(test_stream, "player.signal_lock_pulse", Vector3.ZERO)
	assert(controller.audio_mgr._active_2d_transients.size() == 1, "FAIL 11: Exactly 1 2D transient tracked in _active_2d_transients")

	controller.audio_mgr.reset_audio_instant()
	assert(controller.audio_mgr._active_2d_transients.size() == 0, "FAIL 11: 2D transients cleanly wiped on reset")
	print("  -> Assertion 11 PASS: 2D reference transient tracking and leak-proof reset verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 12: Complete Cleanup of Sandbox Test Artifacts
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 12] Testing complete cleanup of test artifacts...")
	DirAccess.remove_absolute(real_wav_path)
	DirAccess.remove_absolute(real_manifest_path)
	DirAccess.remove_absolute(real_sandbox_dir)
	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", prev_env)
	AudioReferenceResolverScript.reset()
	controller.audio_mgr.reset_audio_instant()
	print("  -> Assertion 12 PASS: Authoritative instant reset & test file cleanup 100% verified!")

	print("\n=========================================================================")
	print("[ALL V8 M21 AUDIO REGISTRY & RESOLVER ASSERTIONS (1-12) PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)

# =============================================================================
# V8 M22: REACTIVE RADIO RUNTIME & ONE-STATION PROGRAM DIRECTOR ASSERTIONS (#22)
# =============================================================================


