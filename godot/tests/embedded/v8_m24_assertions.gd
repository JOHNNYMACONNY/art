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
	print("[RUNNING V8 M24 DYNAMIC RADIO MIX DUCKING & PURSUIT MODULATION (#24)]")
	print("=========================================================================\n")

	# ASSERTION 1: Gain Composition Layer Independence
	print("[ASSERTION 1] Testing Gain Composition Layer Independence...")
	controller.reset_slice()
	await controller.get_tree().process_frame
	var r_player = controller.audio_mgr.get_radio_player()
	assert(r_player.has_method("set_duck_volume_db"), "FAIL 1: Player must expose set_duck_volume_db")
	assert(r_player.has_method("get_duck_volume_db"), "FAIL 1: Player must expose get_duck_volume_db")
	assert(r_player.has_method("get_lifecycle_volume_db"), "FAIL 1: Player must expose get_lifecycle_volume_db")
	assert(r_player.has_method("get_composed_volume_db"), "FAIL 1: Player must expose get_composed_volume_db")

	# Mount bike and verify baseline gains
	controller._on_bike_mounted(controller.player)
	var mount_wait := Time.get_ticks_msec()
	while r_player.get_lifecycle_volume_db() < 0.0 and Time.get_ticks_msec() - mount_wait < 500:
		await controller.get_tree().process_frame
	assert(is_equal_approx(r_player.get_lifecycle_volume_db(), 0.0), "FAIL 1: Default lifecycle volume is 0 dB (got %.2f)" % r_player.get_lifecycle_volume_db())
	assert(is_equal_approx(r_player.get_duck_volume_db(), 0.0), "FAIL 1: Default duck volume is 0 dB")
	assert(is_equal_approx(r_player.get_composed_volume_db(), 0.0), "FAIL 1: Composed volume is 0 dB")
	print("  -> Assertion 1 PASS: Gain composition layer independence verified!")

	# ASSERTION 2: Target Duck Levels Across Discrete Mix States
	print("\n[ASSERTION 2] Testing Target Duck Levels Across Discrete Mix States (CALM, DISTURBANCE, ECHO, EVASION)...")
	# CALM -> 0 dB
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.CALM)
	var calm_wait := Time.get_ticks_msec()
	while controller.audio_mgr.is_radio_duck_tweening() and Time.get_ticks_msec() - calm_wait < 800:
		await controller.get_tree().process_frame
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), 0.0), "FAIL 2: CALM duck is 0 dB (got %.2f)" % controller.audio_mgr.get_radio_duck())

	# DISTURBANCE -> -10 dB
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.DISTURBANCE)
	var dist_wait := Time.get_ticks_msec()
	while controller.audio_mgr.is_radio_duck_tweening() and Time.get_ticks_msec() - dist_wait < 800:
		await controller.get_tree().process_frame
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -10.0), "FAIL 2: DISTURBANCE duck is -10 dB (got %.2f)" % controller.audio_mgr.get_radio_duck())

	# MEMORY_ECHO -> -16 dB
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.MEMORY_ECHO)
	var echo_wait := Time.get_ticks_msec()
	while controller.audio_mgr.is_radio_duck_tweening() and Time.get_ticks_msec() - echo_wait < 800:
		await controller.get_tree().process_frame
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -16.0), "FAIL 2: MEMORY_ECHO duck is -16 dB (got %.2f)" % controller.audio_mgr.get_radio_duck())

	# EVASION_RELEASE -> Semantic event, zero competing duck Tweens
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.EVASION_RELEASE)
	await controller.get_tree().process_frame
	assert(controller.audio_mgr.current_mix_state == AudioManagerScript.MixState.EVASION_RELEASE, "FAIL 2: MixState EVASION_RELEASE active")
	assert(controller.audio_mgr.is_radio_duck_tweening() == false, "FAIL 2: EVASION_RELEASE does not start competing duck Tween")
	print("  -> Assertion 2 PASS: MixState duck targets (0dB, -10dB, -16dB) verified!")

	# ASSERTION 3: Continuous Pursuit Pressure Ducking & Zero Per-Frame Tween Churn
	print("\n[ASSERTION 3] Testing Continuous Pursuit Pressure Ducking & Zero Per-Frame Tween Churn...")
	# Distance >= 20m -> Pressure 0.0 -> Duck -7 dB
	controller.audio_mgr.set_pursuit_pressure(25.0, Vector3.ZERO)
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -7.0), "FAIL 3: Pursuit pressure at 25m ducks immediately to -7 dB")
	assert(controller.audio_mgr.is_radio_duck_tweening() == false, "FAIL 3: No tween created on continuous pressure update")

	# Distance = 12.5m -> Pressure 0.5 -> Duck -10 dB
	controller.audio_mgr.set_pursuit_pressure(12.5, Vector3.ZERO)
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -10.0), "FAIL 3: Pursuit pressure at 12.5m ducks immediately to -10 dB")
	assert(controller.audio_mgr.is_radio_duck_tweening() == false, "FAIL 3: No tween created on continuous pressure update")

	# Distance <= 5m -> Pressure 1.0 -> Duck -13 dB
	controller.audio_mgr.set_pursuit_pressure(3.0, Vector3.ZERO)
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -13.0), "FAIL 3: Pursuit pressure at 3m ducks immediately to -13 dB")
	assert(controller.audio_mgr.is_radio_duck_tweening() == false, "FAIL 3: No tween created on continuous pressure update")

	# Run 60 frames of sustained pursuit updates to prove ZERO tween allocation churn
	for fr in range(60):
		controller.audio_mgr.set_pursuit_pressure(5.0 + float(fr % 10), Vector3.ZERO)
		await controller.get_tree().process_frame
		assert(controller.audio_mgr.is_radio_duck_tweening() == false, "FAIL 3: Zero tween churn invariant held across pursuit frame %d" % fr)
	print("  -> Assertion 3 PASS: Continuous pursuit pressure scaling & zero-tween-churn verified!")

	# ASSERTION 4: Real Interception -> Monotonic Critical Duck (-24 dB) -> RETRY_READY Clears Mix
	print("\n[ASSERTION 4] Testing Real Interception -> Monotonic Critical Duck -> RETRY_READY Clears Mix...")
	controller._on_bike_mounted(controller.player)
	controller.audio_mgr.set_pursuit_pressure(3.0, Vector3.ZERO)
	var pre_intercept_duck: float = controller.audio_mgr.get_radio_duck()
	assert(is_equal_approx(pre_intercept_duck, -13.0), "FAIL 4: Active pursuit pressure duck is -13 dB")
	
	# Real interception event
	controller._on_pursuer_intercepted()
	var immediate_duck: float = controller.audio_mgr.get_radio_duck()
	assert(immediate_duck <= pre_intercept_duck + 0.01, "FAIL 4: Immediate post-call duck must never lift toward 0 (got %.2f, pre: %.2f)" % [immediate_duck, pre_intercept_duck])

	# Critical attack monotonic transition toward -24 dB
	var prev_attack_duck: float = immediate_duck
	var int_wait := Time.get_ticks_msec()
	while controller.audio_mgr.is_radio_duck_tweening() and Time.get_ticks_msec() - int_wait < 600:
		await controller.get_tree().process_frame
		var cur_attack_duck: float = controller.audio_mgr.get_radio_duck()
		assert(cur_attack_duck <= prev_attack_duck + 0.001, "FAIL 4: Critical duck attack must be monotonically darker (cur: %.2f, prev: %.2f)" % [cur_attack_duck, prev_attack_duck])
		assert(cur_attack_duck <= pre_intercept_duck + 0.01, "FAIL 4: No sample during critical attack may exceed pre-intercept duck")
		prev_attack_duck = cur_attack_duck

	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -24.0), "FAIL 4: Interception overrides with critical duck -24 dB (got %.2f)" % controller.audio_mgr.get_radio_duck())
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED, "FAIL 4: Pursuit state is INTERCEPTED")

	# Wait for the real 0.8s recovery timer to complete and transition to RETRY_READY
	var rec_wait := Time.get_ticks_msec()
	while controller.current_pursuit_state != ScrapTestBlock.PursuitState.RETRY_READY and Time.get_ticks_msec() - rec_wait < 1500:
		await controller.get_tree().process_frame
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 4: Transitioned to RETRY_READY")
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), 0.0), "FAIL 4: RETRY_READY neutralized stored radio duck to 0 dB (got %.2f)" % controller.audio_mgr.get_radio_duck())
	assert(r_player.is_paused() == true, "FAIL 4: Radio remains paused while on foot")
	assert(controller.get_radio_owner() == null, "FAIL 4: Radio owner is null on foot")

	# Remount bike after retry: must NOT inherit stale -24 dB duck
	controller._on_bike_mounted(controller.player)
	var remount_wait := Time.get_ticks_msec()
	while r_player.get_lifecycle_volume_db() < 0.0 and Time.get_ticks_msec() - remount_wait < 500:
		await controller.get_tree().process_frame
	assert(is_equal_approx(r_player.get_duck_volume_db(), 0.0), "FAIL 4: Bike remount after retry does not inherit stale -24 dB (got %.2f)" % r_player.get_duck_volume_db())
	assert(is_equal_approx(r_player.get_composed_volume_db(), 0.0), "FAIL 4: Composed volume is 0 dB on clean remount")
	print("  -> Assertion 4 PASS: Real interception monotonic critical duck, RETRY_READY neutralization, and remount verified!")

	# ASSERTION 5: Real Evasion Controller Path (_on_successful_evasion) & Interruption
	print("\n[ASSERTION 5] Testing Real Evasion Controller Path (_on_successful_evasion) & Interruption...")
	# 1. Real active pursuit at max pressure
	controller._on_bike_mounted(controller.player)
	controller.audio_mgr.set_pursuit_pressure(5.0, Vector3.ZERO)
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -13.0), "FAIL 5: Initial pressure duck is -13 dB")

	# 2. Call REAL _on_successful_evasion()
	controller._on_successful_evasion()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL 5: Pursuit state transitioned to EVADED")
	assert(controller.audio_mgr.current_mix_state == AudioManagerScript.MixState.EVASION_RELEASE, "FAIL 5: MixState is EVASION_RELEASE")
	assert(controller.audio_mgr.is_radio_duck_tweening() == false, "FAIL 5: Zero competing duck Tweens during evasion decay")

	# Frame 1: must start at exact initial duck (-13 dB) without discontinuous jump
	await controller.get_tree().process_frame
	var prev_duck: float = controller.audio_mgr.get_radio_duck()
	assert(prev_duck <= -12.0, "FAIL 5: Evasion release starts from exact current duck (-13dB), no discontinuous jump (got %.2f)" % prev_duck)

	# Monitor monotonic recovery toward 0.0 dB
	var decay_start := Time.get_ticks_msec()
	while controller.audio_mgr._is_decaying_pursuit_pressure and Time.get_ticks_msec() - decay_start < 1500:
		await controller.get_tree().process_frame
		var cur_duck: float = controller.audio_mgr.get_radio_duck()
		assert(cur_duck >= prev_duck - 0.001, "FAIL 5: Evasion duck recovery must be strictly monotonic toward 0 dB (cur: %.2f, prev: %.2f)" % [cur_duck, prev_duck])
		prev_duck = cur_duck
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), 0.0), "FAIL 5: Duck smoothly returned to exact 0 dB post-evasion (got %.2f)" % controller.audio_mgr.get_radio_duck())
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == false, "FAIL 5: Decay envelope inactive")

	# 3. New Pursuit Cancels Evasion Recovery Mid-Flight
	controller.audio_mgr.set_pursuit_pressure(5.0, Vector3.ZERO)
	controller._on_successful_evasion()
	await controller.get_tree().process_frame
	# Allow partial recovery
	for fr in range(10):
		await controller.get_tree().process_frame
	var partial_duck: float = controller.audio_mgr.get_radio_duck()
	assert(partial_duck > -13.0 and partial_duck < 0.0, "FAIL 5: Partial recovery in progress")

	# Interrupted by new pursuit pressure update (e.g. 10m distance -> p=0.667 -> duck ~-11.0 dB)
	controller.audio_mgr.set_pursuit_pressure(10.0, Vector3.ZERO)
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == false, "FAIL 5: Decay envelope halted by new pursuit")
	assert(controller.audio_mgr.is_radio_duck_tweening() == false, "FAIL 5: No stale tween active")
	var expected_p: float = clampf((20.0 - 10.0) / 15.0, 0.0, 1.0)
	var expected_duck: float = lerpf(-7.0, -13.0, expected_p)
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), expected_duck), "FAIL 5: Duck immediately follows new pursuit curve (got %.2f, exp: %.2f)" % [controller.audio_mgr.get_radio_duck(), expected_duck])

	# Ensure old recovery does not later restore 0 dB
	for fr in range(20):
		await controller.get_tree().process_frame
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), expected_duck), "FAIL 5: Old evasion recovery never later overwrites active pursuit")
	print("  -> Assertion 5 PASS: Real evasion controller path, monotonic release, and new-pursuit cancellation verified!")

	# ASSERTION 6: Falsification - Lifecycle OFF / Dismount During Duck Never Resurrects on Recovery
	print("\n[ASSERTION 6] Falsification: OFF/Dismount during duck cannot be resurrected by recovery...")
	# 1. Start playing in Bike during Disturbance (-10 dB duck)
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.DISTURBANCE)
	var dist_a6 := Time.get_ticks_msec()
	while controller.audio_mgr.is_radio_duck_tweening() and Time.get_ticks_msec() - dist_a6 < 600:
		await controller.get_tree().process_frame
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -10.0), "FAIL 6: Disturbance duck active")
	
	# 2. Toggle radio OFF while ducked
	controller._on_radio_toggle_pressed()
	var off_wait := Time.get_ticks_msec()
	while not r_player.is_paused() and Time.get_ticks_msec() - off_wait < 600:
		await controller.get_tree().process_frame
	assert(r_player.is_paused() == true, "FAIL 6: Radio paused after toggle OFF")
	assert(controller.is_radio_enabled() == false, "FAIL 6: Session disabled")

	# 3. Mix recovers to CALM (duck 0 dB)
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.CALM)
	for fr in range(5):
		await controller.get_tree().process_frame
	assert(r_player.is_paused() == true, "FAIL 6: Radio must remain paused after mix recovery (no resurrection)")
	assert(controller.is_radio_enabled() == false, "FAIL 6: Session must remain disabled")

	# 4. Turn radio back ON
	controller._on_radio_toggle_pressed()
	var on_wait := Time.get_ticks_msec()
	while r_player.is_paused() and Time.get_ticks_msec() - on_wait < 500:
		await controller.get_tree().process_frame
	assert(r_player.is_paused() == false, "FAIL 6: Radio resumed on toggle ON")
	print("  -> Assertion 6 PASS: Duck recovery never resurrects disabled/paused radio!")

	# ASSERTION 7: Pursuit BEFORE RadioProgramPlayer Creation -> First Mount Inherits Duck
	print("\n[ASSERTION 7] Testing Pursuit BEFORE RadioProgramPlayer Creation -> First Mount Inherits Duck...")
	# 1. Cleanly tear down RadioProgramPlayer completely
	controller._on_bike_dismounted()
	await controller.get_tree().process_frame
	if controller.audio_mgr._radio_player:
		controller.audio_mgr._radio_player.queue_free()
		controller.audio_mgr._radio_player = null
	assert(controller.audio_mgr._radio_player == null, "FAIL 7: RadioProgramPlayer is completely null")

	# 2. Trigger high pursuit pressure on foot before radio player exists
	controller.audio_mgr.set_pursuit_pressure(5.0, Vector3.ZERO)
	assert(controller.audio_mgr._radio_player == null, "FAIL 7: Radio player still null before mount")
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -13.0), "FAIL 7: AudioManager retained duck state (-13 dB) without player")

	# 3. First Mount on Courier Bike creates player
	controller._on_bike_mounted(controller.player)
	var p_mount := Time.get_ticks_msec()
	while controller.audio_mgr.get_radio_player().get_lifecycle_volume_db() < 0.0 and Time.get_ticks_msec() - p_mount < 500:
		await controller.get_tree().process_frame
	var created_player = controller.audio_mgr.get_radio_player()
	assert(created_player != null, "FAIL 7: Radio player instantiated on first mount")
	assert(is_equal_approx(created_player.get_duck_volume_db(), -13.0), "FAIL 7: Newly created radio player inherited -13 dB duck immediately")
	assert(is_equal_approx(created_player.get_composed_volume_db(), -13.0), "FAIL 7: Composed volume is -13 dB")
	print("  -> Assertion 7 PASS: Pursuit before RadioProgramPlayer creation cleanly inherited on first mount!")

	# ASSERTION 8: Stale Duck / Recovery Callback Invalidation (Generation Safety)
	print("\n[ASSERTION 8] Testing Stale Duck / Recovery Callback Invalidation...")
	# 1. Launch a long 0.5s duck tween to -10 dB
	created_player.set_duck_volume_db(-10.0, 0.5)
	await controller.get_tree().process_frame

	# 2. Mid-tween, immediately slam critical duck to -24 dB
	created_player.set_duck_volume_db(-24.0, 0.0)
	assert(is_equal_approx(created_player.get_duck_volume_db(), -24.0), "FAIL 8: Critical duck set immediately")

	# 3. Wait beyond old 0.5s tween duration
	var tween_wait := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tween_wait < 600:
		await controller.get_tree().process_frame
	assert(is_equal_approx(created_player.get_duck_volume_db(), -24.0), "FAIL 8: Stale duck callback did not overwrite critical -24 dB")
	print("  -> Assertion 8 PASS: Generation safety eliminates stale duck tween callbacks!")

	# ASSERTION 9: Replay / Reset Returns Neutral Duck (0 dB) & Cleans Tweens
	print("\n[ASSERTION 9] Testing Replay / Reset Returns Neutral Duck (0 dB)...")
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.DISTURBANCE)
	var d9_wait := Time.get_ticks_msec()
	while controller.audio_mgr.is_radio_duck_tweening() and Time.get_ticks_msec() - d9_wait < 600:
		await controller.get_tree().process_frame
	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), -10.0), "FAIL 9: Disturbance duck before reset")

	controller.reset_slice()
	await controller.get_tree().process_frame

	assert(is_equal_approx(controller.audio_mgr.get_radio_duck(), 0.0), "FAIL 9: Radio duck reset to 0 dB on replay")
	assert(created_player._duck_tween == null or not created_player._duck_tween.is_valid(), "FAIL 9: Duck tween cancelled on replay")
	print("  -> Assertion 9 PASS: Deterministic replay restores neutral 0 dB duck and cancels tweens!")

	# ASSERTION 10: Single-Player Authority & 12-Cycle Stress Invariant
	print("\n[ASSERTION 10] Testing Single-Player Authority & 12-Cycle Ducking Stress...")
	for cycle in range(12):
		controller._on_bike_mounted(controller.player)
		controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.DISTURBANCE)
		controller.audio_mgr.set_pursuit_pressure(float(cycle % 15), Vector3.ZERO)
		controller._on_bike_dismounted()
		controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.MEMORY_ECHO)
		controller._on_hauler_mounted(controller.player)
		controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED, Vector3.ZERO)
		controller.audio_mgr.start_pursuit_release_decay(0.1)
		controller._on_hauler_dismounted()
	await controller.get_tree().process_frame

	var found_radio_players: int = 0
	for child in controller.audio_mgr.get_children():
		if child is AudioStreamPlayer and child.name.begins_with("RadioAudioStreamPlayer"):
			found_radio_players += 1
		for subchild in child.get_children():
			if subchild is AudioStreamPlayer and subchild.name.begins_with("RadioAudioStreamPlayer"):
				found_radio_players += 1

	assert(found_radio_players == 1, "FAIL 10: Exactly 1 RadioAudioStreamPlayer node after stress cycles")
	assert(controller.audio_mgr.get_radio_player() != null, "FAIL 10: Exactly 1 RadioProgramPlayer authority")
	print("  -> Assertion 10 PASS: Single-player authority and 0 node leaks preserved across 12 stress cycles!")

	# ASSERTION 11: Preserved Semantics & Exactly-Once Event Invariants
	print("\n[ASSERTION 11] Testing Preserved Semantics & Exactly-Once Event Invariants...")
	# Reset event counts
	controller.audio_mgr.event_counts.clear()

	# Exactly-once DISTURBANCE_ALERT
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.DISTURBANCE)
	assert(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT, 0) == 1, "FAIL 11: DISTURBANCE_ALERT fired exactly once")

	# Exactly-once ECHO_ONSET
	controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.MEMORY_ECHO)
	assert(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.ECHO_ONSET, 0) == 1, "FAIL 11: ECHO_ONSET fired exactly once")

	controller._on_bike_mounted(controller.player)
	controller.courier_bike.current_speed = 7.0
	controller.audio_mgr.set_engine_audio(0.5, controller.courier_bike.global_position)
	assert(controller.audio_mgr._engine_player != null and controller.audio_mgr._engine_player.playing == true, "FAIL 11: Engine audio functional")
	
	controller.audio_mgr.set_pursuit_pressure(10.0, controller.courier_bike.global_position)
	assert(controller.audio_mgr._siren_player != null and controller.audio_mgr._siren_player.playing == true, "FAIL 11: Siren active under pursuit")
	assert(controller.audio_mgr._tension_player != null and controller.audio_mgr._tension_player.playing == true, "FAIL 11: Tension drone active (<14m)")

	# Hysteresis check (>18m disengages tension)
	controller.audio_mgr.set_pursuit_pressure(19.0, controller.courier_bike.global_position)
	assert(controller.audio_mgr._tension_player.playing == false, "FAIL 11: Tension drone disengages at >18m")

	# Ambient sound clink
	controller.audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, Vector3.ZERO)
	assert(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, 0) > 0, "FAIL 11: Ambient clink fired")

	controller._on_bike_dismounted()
	print("  -> Assertion 11 PASS: Exactly-once events and subsystem semantics preserved!")

	print("\n=========================================================================")
	print("[ALL V8 M24 DYNAMIC RADIO MIX DUCKING ASSERTIONS (1-11) PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


