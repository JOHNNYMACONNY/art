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
	print("[V7_TICKET06_ASSERTIONS] Starting Audio Pressure & Replay Cohesion Suite...")
	print("Target Build: main | Testing Semantic Hierarchy, Pressure Layer, Voice Throttling, Sweeps & Instant Reset")
	print("=========================================================================\n")

	# -------------------------------------------------------------------------
	# TEST 1: Semantic Event Routing Separation
	# -------------------------------------------------------------------------
	print("[TEST 1] Testing Semantic Event Routing Separation...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	assert(AudioManagerScript.SoundEvent.has("DISMOUNT_REJECTED"), "FAIL: SoundEvent must have DISMOUNT_REJECTED")
	assert(AudioManagerScript.SoundEvent.has("DISTURBANCE_ALERT"), "FAIL: SoundEvent must have DISTURBANCE_ALERT")
	assert(AudioManagerScript.SoundEvent.has("PURSUIT_INTERCEPTED"), "FAIL: SoundEvent must have PURSUIT_INTERCEPTED")
	assert(AudioManagerScript.SoundEvent.has("EVASION_RELEASE"), "FAIL: SoundEvent must have EVASION_RELEASE")
	assert(AudioManagerScript.SoundEvent.has("COLLISION_GLANCE"), "FAIL: SoundEvent must have COLLISION_GLANCE")
	assert(AudioManagerScript.SoundEvent.has("COLLISION_HEAD_ON"), "FAIL: SoundEvent must have COLLISION_HEAD_ON")
	print("[TICKET 06 TEST 1 PASSED] Semantic event routing separation verified!")

	# -------------------------------------------------------------------------
	# TEST 2: Pursuit Pressure Distance Response & Monotonic Pitch Scaling
	# -------------------------------------------------------------------------
	print("[TEST 2] Testing Pursuit Pressure Distance Response & Monotonic Pitch Scaling...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	controller.audio_mgr.set_pursuit_pressure(25.0, Vector3(0, 0, -25.0))
	assert(is_zero_approx(controller.audio_mgr._current_pursuit_pressure), "FAIL: Pressure must be 0.0 at distance >= 20m")
	assert(not controller.audio_mgr._tension_layer_active, "FAIL: Tension drone must not engage at distance > 14m")

	controller.audio_mgr.set_pursuit_pressure(12.5, Vector3(0, 0, -12.5))
	assert(abs(controller.audio_mgr._current_pursuit_pressure - 0.5) < 0.01, "FAIL: Pressure must be 0.5 at distance 12.5m")
	assert(controller.audio_mgr._tension_layer_active, "FAIL: Tension drone must engage when distance < 14m")
	assert(controller.audio_mgr._siren_player.pitch_scale > 1.15, "FAIL: Siren pitch scale must elevate under pressure")

	controller.audio_mgr.set_pursuit_pressure(5.0, Vector3(0, 0, -5.0))
	assert(is_equal_approx(controller.audio_mgr._current_pursuit_pressure, 1.0), "FAIL: Pressure must be 1.0 at distance <= 5m")
	assert(controller.audio_mgr._siren_player.pitch_scale >= 1.44, "FAIL: Siren pitch scale must reach max ~1.45 at max pressure")
	print("[TICKET 06 TEST 2 PASSED] Pursuit pressure distance response verified!")

	# -------------------------------------------------------------------------
	# TEST 3: Collision Severity Mapping (Glance vs Low-Speed vs Head-On)
	# -------------------------------------------------------------------------
	print("[TEST 3] Testing Collision Severity Mapping...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	# Shallow glance: head_on_ratio = 0.15, impact_speed = 8.0 m/s
	controller.audio_mgr.on_collision_contact(0.15, 8.0, Vector3.ZERO)
	assert(controller.audio_mgr._active_transients.size() == 1, "FAIL: Shallow glance must spawn 1 transient voice")
	
	# Low-speed head-on bump: head_on_ratio = 0.85, impact_speed = 1.8 m/s (< 3.0 m/s)
	controller.audio_mgr.reset_audio_instant()
	controller.audio_mgr.on_collision_contact(0.85, 1.8, Vector3.ZERO)
	assert(controller.audio_mgr._active_transients.size() == 0, "FAIL: Low-speed head-on contact (<3.0 m/s) must not trigger heavy crunch")

	# High-speed head-on collision: head_on_ratio = 0.85, impact_speed = 10.0 m/s (>= 3.0 m/s)
	controller.audio_mgr.reset_audio_instant()
	controller.audio_mgr.on_collision_contact(0.85, 10.0, Vector3.ZERO)
	assert(controller.audio_mgr._active_transients.size() == 1, "FAIL: High-speed head-on collision must spawn 1 transient voice")
	print("[TICKET 06 TEST 3 PASSED] Collision severity mapping verified!")

	# -------------------------------------------------------------------------
	# TEST 4: Collision Voice Throttling & Bounded Node Spawning
	# -------------------------------------------------------------------------
	print("[TEST 4] Testing Collision Voice Throttling...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	# Fire 50 collision events in immediate succession
	for i in range(50):
		controller.audio_mgr.on_collision_contact(0.2, 10.0, Vector3.ZERO)
	print("[TEST 4 LOG] Active transients after 50 rapid calls: %d" % controller.audio_mgr._active_transients.size())
	assert(controller.audio_mgr._active_transients.size() <= AudioManager.MAX_CONCURRENT_TRANSIENTS, "FAIL: Active transients exceeded max budget")
	assert(controller.audio_mgr._active_transients.size() == 1, "FAIL: Same-event throttling should allow only 1 voice per cooldown period")
	print("[TICKET 06 TEST 4 PASSED] Collision voice throttling verified!")

	# -------------------------------------------------------------------------
	# TEST 5: Tuning Static and Near-Lock Lifecycle
	# -------------------------------------------------------------------------
	print("[TEST 5] Testing Tuning Static and Near-Lock Lifecycle...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	controller.audio_mgr.set_tuning_audio(0.0)
	assert(controller.audio_mgr._static_player == null or not controller.audio_mgr._static_player.playing, "FAIL: Static player should not play at accuracy 0")

	controller.audio_mgr.set_tuning_audio(0.5)
	assert(controller.audio_mgr._static_player.playing, "FAIL: Static player must play when tuning active")
	var vol_mid: float = controller.audio_mgr._static_player.volume_db
	controller.audio_mgr.set_tuning_audio(0.95)
	var vol_high: float = controller.audio_mgr._static_player.volume_db
	assert(vol_high < vol_mid, "FAIL: Static volume must attenuate as accuracy rises")
	controller.audio_mgr.set_tuning_audio(0.0)
	assert(not controller.audio_mgr._static_player.playing, "FAIL: Canceling tuning must stop static player")
	print("[TICKET 06 TEST 5 PASSED] Tuning static and near-lock lifecycle verified!")

	# -------------------------------------------------------------------------
	# TEST 6: Panel Peel Pitch Progression
	# -------------------------------------------------------------------------
	print("[TEST 6] Testing Panel Peel Pitch Progression...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM, Vector3.ZERO)
	controller.audio_mgr.set_hum_pitch(1.15)
	assert(is_equal_approx(controller.audio_mgr._hum_player.pitch_scale, 1.15), "FAIL: Hum pitch at start of drag must be 1.15")
	controller.audio_mgr.set_hum_pitch(1.30)
	assert(is_equal_approx(controller.audio_mgr._hum_player.pitch_scale, 1.30), "FAIL: Hum pitch at end of drag must be 1.30")
	controller.audio_mgr.set_hum_pitch(1.50)
	assert(is_equal_approx(controller.audio_mgr._hum_player.pitch_scale, 1.50), "FAIL: Hum pitch at core expose must be 1.50")
	print("[TICKET 06 TEST 6 PASSED] Panel peel pitch progression verified!")

	# -------------------------------------------------------------------------
	# TEST 7: Authentic Audio Stream Verification
	# -------------------------------------------------------------------------
	print("[TEST 7] Testing Authentic Audio Stream Formats & Properties...")
	var peel_stream := load("res://audio/interaction/sfx_interaction_panel_peel.wav") as AudioStreamWAV
	assert(peel_stream != null, "FAIL: Panel peel production stream must load")
	assert(peel_stream.format == AudioStreamWAV.FORMAT_16_BITS, "FAIL: Production stream must be 16-bit PCM")
	assert(peel_stream.mix_rate == 18000, "FAIL: Panel peel native rate is 18000 Hz")

	var lock_stream := load("res://audio/player/sfx_player_signal_lock_pulse.wav") as AudioStreamWAV
	assert(lock_stream != null, "FAIL: Signal lock production stream must load")
	assert(lock_stream.format == AudioStreamWAV.FORMAT_16_BITS, "FAIL: Signal lock must be 16-bit PCM")
	print("[TICKET 06 TEST 7 PASSED] Authentic audio stream properties verified!")

	# -------------------------------------------------------------------------
	# TEST 8: Transient Voice Budget & Auto-Cleanup
	# -------------------------------------------------------------------------
	print("[TEST 8] Testing Transient Voice Budget & Auto-Cleanup...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	var test_stream := load("res://audio/player/sfx_player_footstep.wav") as AudioStreamWAV
	for i in range(15):
		var p := AudioStreamPlayer3D.new()
		p.stream = test_stream
		controller.audio_mgr._register_and_play_transient(p, Vector3.ZERO, 0.05)
	assert(controller.audio_mgr._active_transients.size() <= AudioManager.MAX_CONCURRENT_TRANSIENTS, "FAIL: Active transients exceeded max budget")
	await controller.get_tree().create_timer(0.12).timeout
	print("[TEST 8 LOG] Active transients after timer expiry: %d" % controller.audio_mgr._active_transients.size())
	assert(controller.audio_mgr._active_transients.size() == 0, "FAIL: All transient voices must clean up after expiry")
	print("[TICKET 06 TEST 8 PASSED] Transient voice budget & auto-cleanup verified!")

	# -------------------------------------------------------------------------
	# TEST 9: Gate Slam Semantic Trigger
	# -------------------------------------------------------------------------
	print("[TEST 9] Testing Gate Slam Semantic Trigger...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.GATE_SLAM, controller.signal_gate.global_position)
	assert(controller.audio_mgr._active_transients.size() > 0, "FAIL: Gate slam must spawn transient audio voice")
	print("[TICKET 06 TEST 9 PASSED] Gate slam semantic trigger verified!")

	# -------------------------------------------------------------------------
	# TEST 10: Pursuit Intercept vs Evasion Outcome Semantic Separation
	# -------------------------------------------------------------------------
	print("[TEST 10] Testing Pursuit Intercept vs Evasion Outcome Semantic Separation...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.8).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL: Pursuit must be active")

	controller._on_pursuer_intercepted()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED, "FAIL: State must be INTERCEPTED")
	assert(not controller.audio_mgr._siren_player.playing, "FAIL: Siren must stop immediately on interception")
	assert(not controller.audio_mgr._tension_player.playing, "FAIL: Tension drone must stop immediately on interception")

	# Wait 1.0s through recovery callback
	await controller.get_tree().create_timer(1.0).timeout
	assert(controller.audio_mgr.current_mix_state != AudioManager.MixState.EVASION_RELEASE, "FAIL: Interception must NOT play EVASION_RELEASE afterward")
	print("[TICKET 06 TEST 10 PASSED] Pursuit intercept vs evasion semantic separation verified!")

	# -------------------------------------------------------------------------
	# TEST 11: reset_audio_instant() Authoritative Full Silence
	# -------------------------------------------------------------------------
	print("[TEST 11] Testing reset_audio_instant() Authoritative Full Silence...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	# Start everything playing
	controller.audio_mgr.set_engine_audio(0.8, Vector3.ZERO)
	controller.audio_mgr.set_siren_audio(true, Vector3.ZERO)
	controller.audio_mgr.set_tuning_audio(0.6)
	if not controller.audio_mgr._static_player.playing:
		controller.audio_mgr._static_player.play()
	controller.audio_mgr.set_pursuit_pressure(5.0, Vector3.ZERO)
	controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM, Vector3.ZERO)
	for i in range(4):
		controller.audio_mgr._play_synth_click(Vector3.ZERO, 400.0, 1.0)
	
	assert(controller.audio_mgr._engine_player.playing, "Pre-check engine")
	assert(controller.audio_mgr._siren_player.playing, "Pre-check siren")
	assert(controller.audio_mgr._static_player.playing, "Pre-check static")
	assert(controller.audio_mgr._active_transients.size() > 0, "Pre-check transients")

	controller.audio_mgr.reset_audio_instant()

	assert(not controller.audio_mgr._engine_player.playing, "FAIL: Engine must be stopped after reset")
	assert(not controller.audio_mgr._siren_player.playing, "FAIL: Siren must be stopped after reset")
	assert(not controller.audio_mgr._static_player.playing, "FAIL: Static must be stopped after reset")
	assert(not controller.audio_mgr._hum_player.playing, "FAIL: Hum must be stopped after reset")
	assert(not controller.audio_mgr._tension_player.playing, "FAIL: Tension player must be stopped after reset")
	assert(controller.audio_mgr._active_transients.size() == 0, "FAIL: All transients must be cleared on reset")
	assert(controller.audio_mgr.current_mix_state == AudioManager.MixState.CALM, "FAIL: Mix state must be CALM after reset")
	print("[TICKET 06 TEST 11 PASSED] reset_audio_instant() full silence verified!")

	# -------------------------------------------------------------------------
	# TEST 12: Replay During Truly Active Pursuit and Interaction
	# -------------------------------------------------------------------------
	print("[TEST 12] Testing Replay During Truly Active Pursuit and Interaction...")
	# Part A: Active pursuit replay
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL: Pursuit must be active")
	if controller.pursuer and controller.player:
		controller.pursuer.global_position = controller.player.global_position + Vector3(0, 0, -8.0)
		controller.audio_mgr.set_pursuit_pressure(8.0, controller.pursuer.global_position)
	assert(controller.audio_mgr._siren_player.playing, "FAIL: Siren must be active during pursuit")
	assert(controller.audio_mgr._tension_player.playing, "FAIL: Tension drone must be active at 8m distance")

	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	assert(not controller.audio_mgr._siren_player.playing, "FAIL: Siren must be stopped after mid-pursuit replay")
	assert(not controller.audio_mgr._tension_player.playing, "FAIL: Tension drone must be stopped after mid-pursuit replay")
	assert(controller.audio_mgr._active_transients.size() == 0, "FAIL: 0 transients active after replay")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL: Pursuit state must be CALM")

	# Part B: Truly active tuner interaction replay
	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 0.5)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.READY, "FAIL: Tuner must enter READY state")
	var success: bool = controller.signal_tuner.begin_interaction(controller.player.global_position)
	assert(success and controller.signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: Tuner must enter TUNING state")
	controller.signal_tuner.tune_dial(0.25) # Tune into active tuning accuracy range without early locking
	await controller.get_tree().create_timer(0.05).timeout
	assert(controller.audio_mgr._static_player.playing, "FAIL: Static player must be active during tuning")

	controller.reset_slice()
	await controller.get_tree().create_timer(0.05).timeout
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.DORMANT, "FAIL: Tuner must be DORMANT after reset")
	assert(not controller.audio_mgr._static_player.playing, "FAIL: Static player must be stopped after tuner replay")
	assert(not controller.audio_mgr._hum_player.playing, "FAIL: Hum player must be stopped after tuner replay")
	assert(controller.audio_mgr._active_transients.size() == 0, "FAIL: 0 transients active after tuner replay")
	print("[TICKET 06 TEST 12 PASSED] Replay during active pursuit and interaction verified!")

	print("\n=========================================================================")
	print("[ALL V7 TICKET 06 ASSERTIONS PASSED CLEANLY]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


