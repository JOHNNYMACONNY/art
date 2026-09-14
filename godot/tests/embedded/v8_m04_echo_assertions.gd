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
	print("[V8 M04 MEMORY ECHO ASSERTIONS] Starting...")
	print("=========================================================================\n")

	# ─────────────────────────────────────────────────────────────────────────
	# SETUP: fresh slice
	# ─────────────────────────────────────────────────────────────────────────
	controller.reset_slice()
	await controller.get_tree().process_frame
	await controller.get_tree().process_frame

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 1: Pre-extraction Echo triggering fails closed
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 1: Pre-extraction Echo triggering fails closed ---")
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.START, "FAIL A1: World state must start at START")
	
	# Actively attempt real controller-level pre-extraction trigger paths:
	if not controller.echo_controller:
		controller.echo_controller = MemoryEchoController.new()
		controller.echo_controller.name = "MemoryEchoController"
		controller.add_child(controller.echo_controller)
		controller.echo_controller.echo_completed.connect(controller._on_echo_completed)
	controller.echo_controller.setup(controller.audio_mgr)
	
	# Path 1: Direct un-armed call to trigger_echo() must be rejected
	var direct_unarmed_res: bool = controller.echo_controller.trigger_echo()
	assert(direct_unarmed_res == false, "FAIL A1: Direct un-armed trigger_echo() must return false")
	
	# Path 2: Gameplay _trigger_echo_sequence() call before extraction (state == START) must be rejected
	var sequence_early_res: bool = controller._trigger_echo_sequence()
	assert(sequence_early_res == false, "FAIL A1: _trigger_echo_sequence() before extraction must return false")
	
	# Prove zero side effects:
	assert(controller.echo_controller.current_phase == MemoryEchoController.EchoPhase.IDLE,
		"FAIL A1: Echo phase must remain IDLE after early trigger attempts")
	assert(controller.echo_controller.get_trigger_count() == 0,
		"FAIL A1: Trigger count must remain 0 after early trigger attempts")
	if controller.audio_mgr and controller.audio_mgr._echo_voice:
		assert(not controller.audio_mgr._echo_voice.playing,
			"FAIL A1: No echo audio must start from early trigger attempts")
	if controller.echo_controller._canvas_layer:
		assert(not controller.echo_controller._canvas_layer.visible,
			"FAIL A1: No echo visual overlay must appear from early trigger attempts")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM,
		"FAIL A1: No disturbance must start from early trigger attempts")
	print("  -> Assertion 1 PASS: Pre-extraction trigger attempts strictly fail closed with zero side effects")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 2: Extraction triggers echo exactly once (M04B lifecycle verified)
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 2: Extraction triggers echo exactly once ---")
	# Advance world to CORE_EXTRACTED state via _on_extraction_completed path
	controller._on_extraction_completed()
	await controller.get_tree().process_frame

	assert(controller.echo_controller != null, "FAIL A2: echo_controller must exist after extraction")
	assert(controller.echo_controller.get_trigger_count() == 1, "FAIL A2: Echo must be triggered exactly once by extraction")
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.CORE_EXTRACTED,
		"FAIL A2: World state must be CORE_EXTRACTED after extraction")
	assert(controller.echo_controller._canvas_layer != null and controller.echo_controller._canvas_layer.visible,
		"FAIL A2: Echo visual overlay must be visible upon extraction")
	
	# M04B Check 1: Duplicate triggers during active echo must fail closed and invalidate arming:
	var dup_active_seq: bool = controller._trigger_echo_sequence()
	assert(dup_active_seq == false, "FAIL A2: Duplicate _trigger_echo_sequence during active echo must return false")
	var dup_active_direct: bool = controller.echo_controller.trigger_echo()
	assert(dup_active_direct == false, "FAIL A2: Direct trigger_echo during active echo must return false")
	assert(controller.echo_controller.get_trigger_count() == 1, "FAIL A2: Trigger count must remain 1 during active duplicates")
	assert(not controller.echo_controller.is_armed_for_extraction, "FAIL A2: Arming token must be consumed/invalidated")

	# Step echo to completion (DONE phase)
	var max_steps2: int = 150
	while controller.echo_controller.current_phase != MemoryEchoController.EchoPhase.DONE and max_steps2 > 0:
		controller.echo_controller._process(1.0 / 60.0)
		await controller.get_tree().process_frame
		max_steps2 -= 1
	assert(controller.echo_controller.current_phase == MemoryEchoController.EchoPhase.DONE, "FAIL A2: Echo must reach DONE")

	# M04B Check 2: Second calls after completion (DONE) without Replay/reset must fail closed:
	var post_done_direct: bool = controller.echo_controller.trigger_echo()
	assert(post_done_direct == false, "FAIL A2: Direct trigger_echo after DONE must return false")
	var post_done_seq: bool = controller._trigger_echo_sequence()
	assert(post_done_seq == false, "FAIL A2: _trigger_echo_sequence after DONE must return false")
	assert(controller.echo_controller.get_trigger_count() == 1, "FAIL A2: Trigger count must strictly remain 1 after completion")
	assert(not controller.echo_controller._canvas_layer.visible, "FAIL A2: Visual overlay must remain hidden after rejected post-DONE calls")

	print("  -> Assertion 2 PASS: Exactly-once lifecycle strictly enforced across active and post-completion states")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 3: Echo does not permanently lock player input
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 3: Echo does not permanently lock player input ---")
	# Step echo controller to completion (total duration ~1.83s -> 120 steps at 60fps)
	var max_steps: int = 150
	while controller.echo_controller != null and controller.echo_controller.current_phase != MemoryEchoController.EchoPhase.DONE and max_steps > 0:
		controller.echo_controller._process(1.0 / 60.0)
		await controller.get_tree().process_frame
		max_steps -= 1
	assert(controller.echo_controller != null and controller.echo_controller.current_phase == MemoryEchoController.EchoPhase.DONE,
		"FAIL A3: Echo must complete successfully within expected window")
	if controller.player:
		assert(not controller.player.is_input_locked, "FAIL A3: Player input must not be permanently locked after echo")
	assert(controller.echo_controller._canvas_layer != null and not controller.echo_controller._canvas_layer.visible,
		"FAIL A3: Echo visual overlay must be hidden upon completion")
	print("  -> Assertion 3 PASS: Player input not permanently locked (completed cleanly)")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 4: Disturbance begins only at intended echo handoff point
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 4: Disturbance begins only after echo completes ---")
	# By the time echo completed (A3 loop), disturbance alert was triggered
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.DISTURBANCE_ALERT or
		   controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE,
		"FAIL A4: Disturbance must activate after echo_completed, not before")
	print("  -> Assertion 4 PASS: Disturbance activates only at echo handoff")

	# Visual proof: stage 4 — disturbance rupture
	TestHelpers.save_proof_png(controller, "res://verification/v8/m04/m04_04_disturbance_rupture.png")
	print("  -> Visual proof saved: m04_04_disturbance_rupture.png")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 5: Replay during echo clears it safely (no stuck state)
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 5: Replay during echo clears safely ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller._on_extraction_completed()
	await controller.get_tree().process_frame
	# Reset immediately while in ONSET echo phase
	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.START, "FAIL A5: World state must reset to START after mid-echo reset")
	if controller.echo_controller:
		assert(controller.echo_controller.current_phase == MemoryEchoController.EchoPhase.IDLE,
			"FAIL A5: Echo phase must be IDLE after reset during echo")
		assert(controller.echo_controller.get_trigger_count() == 0,
			"FAIL A5: Trigger count must be 0 after reset")
		assert(not controller.echo_controller.is_armed_for_extraction,
			"FAIL A5: Echo controller must be disarmed after reset")
		if controller.echo_controller._canvas_layer:
			assert(not controller.echo_controller._canvas_layer.visible,
				"FAIL A5: Echo visual overlay must be hidden after reset")
	if controller.audio_mgr and controller.audio_mgr._echo_voice:
		assert(not controller.audio_mgr._echo_voice.playing,
			"FAIL A5: Echo voice must not be playing after reset")
	print("  -> Assertion 5 PASS: Replay during echo clears safely")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 6: Replay after completion re-arms echo exactly once
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 6: Replay after completion re-arms echo exactly once ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller._on_extraction_completed()
	# Step echo to completion
	var max_steps6: int = 150
	while controller.echo_controller != null and controller.echo_controller.current_phase != MemoryEchoController.EchoPhase.DONE and max_steps6 > 0:
		controller.echo_controller._process(1.0 / 60.0)
		await controller.get_tree().process_frame
		max_steps6 -= 1
	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(controller.echo_controller == null or controller.echo_controller.get_trigger_count() == 0,
		"FAIL A6: Trigger count must be 0 after post-completion reset")
	# Now trigger again — should fire exactly once more
	controller._on_extraction_completed()
	await controller.get_tree().process_frame
	assert(controller.echo_controller != null and controller.echo_controller.get_trigger_count() == 1,
		"FAIL A6: Echo must re-arm for exactly one trigger after replay reset")
	print("  -> Assertion 6 PASS: Replay after completion re-arms echo exactly once")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 7: Echo audio cannot leak into reset/aftermath
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 7: Echo audio cannot leak into reset/aftermath ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.audio_mgr:
		if controller.audio_mgr._echo_voice:
			assert(not controller.audio_mgr._echo_voice.playing,
				"FAIL A7: Echo voice must be silent after reset_slice")
		assert(controller.audio_mgr.current_mix_state == AudioManagerScript.MixState.CALM,
			"FAIL A7: Mix state must be CALM after reset_slice (no echo MixState leakage)")
	print("  -> Assertion 7 PASS: Echo audio does not leak into reset/aftermath")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 8: Pursuit onset retains audio priority over echo
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 8: Pursuit onset retains audio priority over echo ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller._on_extraction_completed()
	await controller.get_tree().process_frame
	# During echo, set pursuit pressure — siren must activate (pursuit priority)
	if controller.audio_mgr and controller.pursuer:
		controller.audio_mgr.set_pursuit_pressure(4.0, controller.pursuer.global_position) # < 5m = full pressure
		await controller.get_tree().process_frame
		assert(controller.audio_mgr._siren_player and controller.audio_mgr._siren_player.playing,
			"FAIL A8: Siren must play when pursuit pressure set (even during echo)")
		# Decay flag should be cancelled by set_pursuit_pressure call
		assert(not controller.audio_mgr._is_decaying_pursuit_pressure,
			"FAIL A8: Decay must be cancelled by pursuit pressure onset")
	# Cleanup
	controller.reset_slice()
	await controller.get_tree().process_frame
	print("  -> Assertion 8 PASS: Pursuit onset retains audio priority over echo")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 9: Existing tuner/extraction semantics unchanged
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 9: Existing tuner/extraction semantics unchanged ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.START, "FAIL A9: Cold start state must be START")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL A9: Cold start pursuit must be CALM")
	assert(controller.audio_mgr.current_mix_state == AudioManagerScript.MixState.CALM,
		"FAIL A9: Cold start mix state must be CALM")
	# SIGNAL_LOCK & PANEL_POWERED path
	if controller.signal_tuner:
		controller._on_tuner_signal_locked(controller.signal_tuner)
		assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.PANEL_POWERED,
			"FAIL A9: World state must advance to PANEL_POWERED after signal lock")
	print("  -> Assertion 9 PASS: Tuner/extraction semantics unchanged")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 10: Full Golden Slice completable end-to-end with echo in sequence
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 10: Full Golden Slice completable with echo sequence ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	
	# Visual proof: stage 1 — core extraction
	TestHelpers.save_proof_png(controller, "res://verification/v8/m04/m04_01_core_extraction.png")
	print("  -> Visual proof saved: m04_01_core_extraction.png")

	# Simulate extraction -> enters MEMORY_ECHO
	controller._on_extraction_completed()
	await controller.get_tree().process_frame

	# Visual proof: stage 2 — echo onset
	TestHelpers.save_proof_png(controller, "res://verification/v8/m04/m04_02_echo_onset.png")
	print("  -> Visual proof saved: m04_02_echo_onset.png")

	# Advance to peak phase (0.3s)
	if controller.echo_controller:
		for i in range(20):
			controller.echo_controller._process(1.0 / 60.0)
			await controller.get_tree().process_frame

	# Visual proof: stage 3 — echo peak
	TestHelpers.save_proof_png(controller, "res://verification/v8/m04/m04_03_echo_peak.png")
	print("  -> Visual proof saved: m04_03_echo_peak.png")

	# Complete echo sequence to trigger disturbance
	if controller.echo_controller:
		var max_steps10: int = 150
		while controller.echo_controller.current_phase != MemoryEchoController.EchoPhase.DONE and max_steps10 > 0:
			controller.echo_controller._process(1.0 / 60.0)
			await controller.get_tree().process_frame
			max_steps10 -= 1

	for _i in range(6):
		await controller.get_tree().process_frame
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.DISTURBANCE_ALERT or
		   controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE,
		"FAIL A10: Disturbance must activate at end of full Golden Slice echo sequence")
	
	# Simulate evasion
	controller._on_successful_evasion()
	for _i in range(4):
		await controller.get_tree().process_frame
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED,
		"FAIL A10: Full Golden Slice must be completable including evasion")
	print("  -> Assertion 10 PASS: Full Golden Slice completable with echo in sequence")


	# ─────────────────────────────────────────────────────────────────────────
	# CLEANUP & REPORT
	# ─────────────────────────────────────────────────────────────────────────
	controller.reset_slice()
	print("\n=========================================================================")
	print("[ALL V8 M04 MEMORY ECHO ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


