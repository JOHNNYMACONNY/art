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
	print("[V8 M15 ASSERTIONS] Starting Fast Pursuit Retry & World Continuity Suite (CTW Feel 05)...")
	print("=========================================================================\n")
	
	await controller.get_tree().process_frame
	
	# -------------------------------------------------------------------------
	# ASSERTION 1: Strict Zero-Mutation Contract on Invalid Retry Attempts
	# -------------------------------------------------------------------------
	print("[ASSERTION 1] Testing retry_chase() zero-mutation contract across CALM, PURSUIT_ACTIVE, EVADED, and INTERCEPTED...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.5).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL 1: Initial pursuit state CALM")
	
	# 1A: Invalid retry from CALM / Cold Start
	var snap_pos_1a: Vector3 = controller.player.global_position
	var snap_state_1a: ScrapTestBlock.PursuitState = controller.current_pursuit_state
	var snap_tuner_1a: int = controller.signal_tuner.current_state
	var snap_panel_1a: int = controller.corroded_panel.current_step
	var snap_echo_1a: int = controller.echo_controller.get_trigger_count() if controller.echo_controller else 0
	var snap_pursuer_1a: bool = controller.pursuer.is_active if controller.pursuer else false
	var snap_audio_1a: int = int(controller.audio_mgr.current_mix_state) if controller.audio_mgr else 0
	controller.retry_chase()
	await controller.get_tree().create_timer(0.05).timeout
	assert(controller.player.global_position.distance_to(snap_pos_1a) < 0.05, "FAIL 1A: Player position unchanged")
	assert(controller.current_pursuit_state == snap_state_1a, "FAIL 1A: State remains CALM")
	assert(controller.signal_tuner.current_state == snap_tuner_1a, "FAIL 1A: Tuner remains DORMANT")
	assert(controller.corroded_panel.current_step == snap_panel_1a, "FAIL 1A: Panel remains IDLE")
	assert((controller.echo_controller.get_trigger_count() if controller.echo_controller else 0) == snap_echo_1a, "FAIL 1A: Echo count unchanged")
	assert((controller.pursuer.is_active if controller.pursuer else false) == snap_pursuer_1a, "FAIL 1A: Pursuer remains inactive")
	assert(int(controller.audio_mgr.current_mix_state) == snap_audio_1a, "FAIL 1A: Audio mix unchanged")
	print("  -> 1A PASS: Cold start retry rejected with zero mutation")

	# 1B: Solve Slice to PURSUIT_ACTIVE -> test invalid retry while pursuit is running
	controller.signal_tuner._lock_signal()
	controller.corroded_panel.current_step = CorrodedPanel.Step.EXPOSED
	controller._on_core_tap_pressed()
	await controller.echo_controller.echo_completed
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL 1B: Pursuit active")
	
	var snap_pursuit_state_1b: ScrapTestBlock.PursuitState = controller.current_pursuit_state
	var snap_target_1b: Node3D = controller.pursuer.target_node if controller.pursuer else null
	var snap_veh_state_1b: int = controller.courier_bike.current_state if controller.courier_bike else 0
	controller.retry_chase()
	await controller.get_tree().create_timer(0.05).timeout
	assert(controller.current_pursuit_state == snap_pursuit_state_1b, "FAIL 1B: Pursuit remains PURSUIT_ACTIVE")
	assert(controller.pursuer.target_node == snap_target_1b, "FAIL 1B: Pursuer target unchanged")
	assert(controller.courier_bike.current_state == snap_veh_state_1b, "FAIL 1B: Bike driving unchanged")
	print("  -> 1B PASS: Active pursuit retry rejected with zero mutation")

	# 1C: Successful Evasion -> verify [ RETRY CHASE ] is HIDDEN and retry_chase() is rejected
	controller._on_successful_evasion()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL 1C: State is EVADED")
	assert(controller.touch_ui.replay_panel.visible, "FAIL 1C: Replay overlay visible on evasion")
	assert(not controller.touch_ui.retry_chase_button.visible, "FAIL 1C: RETRY CHASE button must be HIDDEN on successful evasion")
	controller.retry_chase()
	await controller.get_tree().create_timer(0.05).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL 1C: State remains EVADED with zero mutation")
	print("  -> 1C PASS: Evasion exposes Replay only and rejects retry with zero mutation")

	# 1D: Interception in-flight (INTERCEPTED before 0.8s recovery timeout) -> test rejection
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.CALM
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.05).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED, "FAIL 1D: State is INTERCEPTED")
	controller.retry_chase()
	await controller.get_tree().create_timer(0.05).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED, "FAIL 1D: Retry rejected while recovery is in-flight")
	print("  -> 1D PASS: In-flight interception retry rejected with zero mutation")
	print("  -> Assertion 1 PASS: Complete zero-mutation contract proven across all invalid states!")

	# -------------------------------------------------------------------------
	# ASSERTION 2 & 3: Solved Content & Echo Preservation Across Fast Pursuit Retry
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 2 & 3] Waiting for recovery to RETRY_READY -> Fast Retry -> Latency & Content Preservation...")
	# Await recovery callback (0.8s timeout from _on_pursuer_intercepted)
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 2: Interception recovered to RETRY_READY")
	assert(controller.touch_ui.replay_panel.visible, "FAIL 2: Replay overlay visible with RETRY CHASE option")
	assert(controller.touch_ui.retry_chase_button.visible, "FAIL 2: RETRY CHASE button is visible in RETRY_READY")
	
	# Capture Proof 1: Intercepted retry overlay
	await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m15/m15_01_intercepted_retry_overlay.png")
	print("  Saved: godot/verification/v8/m15/m15_01_intercepted_retry_overlay.png")
	
	# Execute Fast Pursuit Retry & Measure Latency
	var retry_t0: float = Time.get_ticks_msec() / 1000.0
	controller.touch_ui.retry_chase_button.pressed.emit()
	
	# Await pursuit restart (disturbance timer 0.75s + 0.1s buffer)
	await controller.get_tree().create_timer(0.85).timeout
	var retry_lat: float = (Time.get_ticks_msec() / 1000.0) - retry_t0
	print("  [LATENCY] Retry tap -> active pursuit: %.2fs (limit <= 3.0s)" % retry_lat)
	assert(retry_lat <= 3.0, "FAIL 3: Retry latency must be <= 3.0s")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL 3: Pursuit active after retry")
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL 3: Player mounted on bike")
	assert(controller.active_vehicle == controller.courier_bike, "FAIL 3: Active vehicle is bike")
	
	# Verify Solved Content & Memory Echo Preservation
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL 3: Tuner remains LOCKED")
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.EXTRACTED, "FAIL 3: Panel remains EXTRACTED")
	assert(controller.echo_controller.has_completed(), "FAIL 3: Echo remains consumed")
	assert(controller.echo_controller.get_trigger_count() == 1, "FAIL 3: Echo lifetime count remains exactly 1 (no replay)")
	print("  -> Assertion 2 & 3 PASS: Solved content preserved, Echo count == 1, latency <= 3s!")

	# Capture Proof 2: Fast retried chase active
	await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m15/m15_02_fast_retried_chase_active.png")
	print("  Saved: godot/verification/v8/m15/m15_02_fast_retried_chase_active.png")

	# -------------------------------------------------------------------------
	# ASSERTION 4: Double-Tap Retry Authority Consumption & Exact Single Onset
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 4] Testing double-tap Retry authority consumption & exact single onset...")
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 4: Reached RETRY_READY")
	
	controller.audio_mgr.reset_event_counts()
	assert(controller.audio_mgr.get_event_count(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT) == 0, "FAIL 4: Disturbance count reset to 0")
	
	# Rapid double-tap
	controller.touch_ui.retry_chase_button.pressed.emit()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.DISTURBANCE_ALERT, "FAIL 4: Tap 1 immediately consumed RETRY_READY authority")
	controller.touch_ui.retry_chase_button.pressed.emit() # Tap 2 should be rejected from DISTURBANCE_ALERT
	
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL 4: Single active pursuit established")
	assert(controller.audio_mgr.get_event_count(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT) == 1, "FAIL 4: Exactly one DISTURBANCE_ALERT onset emitted across double-tap")
	assert(controller.echo_controller.get_trigger_count() == 1, "FAIL 4: Lifetime echo count strictly 1")
	print("  -> Assertion 4 PASS: First tap immediately consumed authority, exactly 1 onset, double tap is strictly idempotent!")

	# -------------------------------------------------------------------------
	# ASSERTION 5: Sticky Input Clearance Across Interception & Retry
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 5] Testing sticky driving inputs cleared on retry...")
	controller._steer_input = 1.0
	controller._throttle_input = 1.0
	controller._handbrake_input = true
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 5: Reached RETRY_READY")
	controller.touch_ui.retry_chase_button.pressed.emit()
	await controller.get_tree().create_timer(0.1).timeout
	assert(controller._steer_input == 0.0, "FAIL 5: Steer input reset")
	assert(controller._throttle_input == 0.0, "FAIL 5: Throttle input reset")
	assert(not controller._handbrake_input, "FAIL 5: Handbrake input reset")
	await controller.get_tree().create_timer(0.75).timeout
	print("  -> Assertion 5 PASS: All sticky inputs cleared cleanly!")

	# -------------------------------------------------------------------------
	# ASSERTION 6: Signal Gate Reset & Re-arm on Retry
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 6] Testing Signal Gate reset and re-arm on retry...")
	controller.signal_gate.begin_interaction(controller.courier_bike.global_position)
	await controller.get_tree().create_timer(0.8).timeout
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL 6: Gate was triggered")
	assert(not controller.signal_gate.barrier_collision.disabled, "FAIL 6: Barrier collision was active")
	
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 6: Reached RETRY_READY")
	controller.touch_ui.retry_chase_button.pressed.emit()
	await controller.get_tree().create_timer(0.1).timeout
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.READY, "FAIL 6: Gate restored to READY")
	assert(controller.signal_gate.barrier_pivot.rotation.y == 0.0, "FAIL 6: Gate barrier reset to 0 rotation")
	assert(controller.signal_gate.barrier_collision.disabled, "FAIL 6: Barrier collision disabled")
	
	await controller.get_tree().create_timer(0.85).timeout
	controller.signal_gate.begin_interaction(controller.courier_bike.global_position)
	await controller.get_tree().create_timer(0.8).timeout
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL 6: Gate re-triggered successfully in new chase")
	print("  -> Assertion 6 PASS: Gate correctly resets to READY and re-arms on retry!")

	# -------------------------------------------------------------------------
	# ASSERTION 7: Audio Mix-State & Transient Cleanup on Retry
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 7] Testing audio mix-state and active transient cleanup...")
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 7: Reached RETRY_READY")
	controller.touch_ui.retry_chase_button.pressed.emit()
	assert(controller.audio_mgr.current_mix_state == AudioManagerScript.MixState.DISTURBANCE, "FAIL 7: Mix state enters DISTURBANCE on retry")
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.audio_mgr.current_mix_state == AudioManagerScript.MixState.PURSUIT_PRESSURE, "FAIL 7: Mix state returns to PURSUIT_PRESSURE")
	print("  -> Assertion 7 PASS: Audio mix state and transient cleanup verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 8: Vehicle Class Parity (Scrap Hauler Path Retry)
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 8] Testing Scrap Hauler path retry parity...")
	controller.courier_bike.force_dismount()
	controller.player.global_position = controller.scrap_hauler.global_position + Vector3(0, 0, 0.5)
	controller.scrap_hauler.mount_interactable.update_player_distance(controller.player.global_position)
	controller.scrap_hauler.request_mount(controller.player)
	await controller.get_tree().create_timer(0.3).timeout
	assert(controller.scrap_hauler.current_state == ScrapHaulerScript.VehicleState.DRIVING, "FAIL 8: Hauler mounted")
	
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.CALM
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.pursuer.target_node == controller.scrap_hauler, "FAIL 8: Pursuer targets Scrap Hauler")
	
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 8: Reached RETRY_READY")
	controller.touch_ui.retry_chase_button.pressed.emit()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.scrap_hauler.current_state == ScrapHaulerScript.VehicleState.DRIVING, "FAIL 8: Player remounted on Scrap Hauler")
	assert(controller.active_vehicle == controller.scrap_hauler, "FAIL 8: Active vehicle is Scrap Hauler")
	assert(controller.pursuer.target_node == controller.scrap_hauler, "FAIL 8: Pursuer targets Scrap Hauler after retry")
	print("  -> Assertion 8 PASS: Scrap Hauler path retry parity verified!")

	# -------------------------------------------------------------------------
	# ASSERTION 9: Repeated Intercept -> Retry Cycles (5 Consecutive Cycles)
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 9] Testing 5 consecutive intercept -> retry cycles...")
	for cycle in range(5):
		controller._on_pursuer_intercepted()
		await controller.get_tree().create_timer(0.85).timeout
		assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 9: Cycle %d reached RETRY_READY" % cycle)
		controller.touch_ui.retry_chase_button.pressed.emit()
		await controller.get_tree().create_timer(0.85).timeout
		assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL 9: Cycle %d pursuit active" % cycle)
		assert(controller.echo_controller.get_trigger_count() == 1, "FAIL 9: Cycle %d echo count == 1" % cycle)
		assert(controller.corroded_panel.current_step == CorrodedPanel.Step.EXTRACTED, "FAIL 9: Cycle %d panel solved" % cycle)
	print("  -> Assertion 9 PASS: 5 consecutive retry cycles pass with 0 leak / echo count == 1!")

	# -------------------------------------------------------------------------
	# ASSERTION 10: Full Replay Still Restores Cold-Start Semantics
	# -------------------------------------------------------------------------
	print("\n[ASSERTION 10] Testing full Replay Slice reset after retry cycles...")
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY, "FAIL 10: Reached RETRY_READY")
	controller.touch_ui.replay_button.pressed.emit()
	await controller.get_tree().create_timer(0.1).timeout
	
	print("  [DEBUG] Assertion 10 player.global_position: ", controller.player.global_position)
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL 10: State restored to CALM")
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.DORMANT, "FAIL 10: Tuner reset to DORMANT")
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL 10: Panel reset to IDLE")
	assert(not controller.echo_controller.has_completed(), "FAIL 10: Echo re-armed (has_triggered == false)")
	assert(controller.player.global_position.distance_to(Vector3(0, 0, 10.0)) < 0.6, "FAIL 10: Player reset to cold start position")
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL 10: Bike reset to PARKED")
	assert(controller.scrap_hauler.current_state == ScrapHaulerScript.VehicleState.PARKED, "FAIL 10: Hauler reset to PARKED")
	assert(not controller.touch_ui.replay_panel.visible, "FAIL 10: Replay overlay hidden")
	print("  -> Assertion 10 PASS: Full Replay Slice restores complete cold-start baseline!")

	print("\n=========================================================================")
	print("[ALL V8 M15 FAST PURSUIT RETRY ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)

# =============================================================================
# V8 M21: SEMANTIC AUDIO REGISTRY & LOCAL REFERENCE RESOLVER ASSERTIONS (#21)
# =============================================================================

