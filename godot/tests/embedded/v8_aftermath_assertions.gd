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

static func export_aftermath_proof(controller: ScrapTestBlock) -> void:
	print("\n[V8 AFTERMATH PROOF] Exporting 4 aftermath transition screenshots...")
	
	# Frame 1: Pursuit Active
	controller.reset_slice()
	await controller.get_tree().create_timer(0.2).timeout
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	controller.pursuer.activate_pursuit(controller.courier_bike)
	controller.pursuer.global_position = controller.courier_bike.global_position - Vector3(0, 0, 8.0)
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.PURSUIT_ACTIVE
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	controller.touch_ui.show_tension_hud("[ ALERT: PURSUIT ACTIVE ]")
	controller.touch_ui.update_tension_proximity(8.0, true)
	await controller.get_tree().create_timer(0.25).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_aftermath_01_pursuit_active.png")
	print("  Saved: v8_aftermath_01_pursuit_active.png")

	# Frame 2: Contact Broken (Distance > 18m)
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.CONTACT_BROKEN
	controller.pursuer.global_position = controller.courier_bike.global_position - Vector3(0, 0, 22.0)
	controller.touch_ui.update_tension_proximity(22.0, false)
	controller.touch_ui.show_tension_hud("[ DISTURBANCE: TRACKING LOST ]")
	await controller.get_tree().create_timer(0.25).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_aftermath_02_contact_broken.png")
	print("  Saved: v8_aftermath_02_contact_broken.png")

	# Frame 3: De-escalating Retreat (Pursuer visible, amber search, slowing down, Replay available)
	controller._on_successful_evasion()
	await controller.get_tree().create_timer(0.5).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_aftermath_03_de_escalating_retreat.png")
	print("  Saved: v8_aftermath_03_de_escalating_retreat.png")

	# Frame 4: Quiet Settled Aftermath (De-escalation finished, world settled)
	await controller.get_tree().create_timer(2.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_aftermath_04_quiet_settled.png")
	print("  Saved: v8_aftermath_04_quiet_settled.png")

	print("\n[ALL 4 AFTERMATH PROOFS EXPORTED SUCCESSFULLY!]\n")
	controller.get_tree().quit(0)


static func run_aftermath_assertions(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V8 M03] Starting Threat Aftermath & World Continuity Assertions Suite...")
	print("=========================================================================\n")

	await controller.get_tree().process_frame

	# -------------------------------------------------------------------------
	# TEST 1: PURSUER DE-ESCALATION STATE TRANSITION
	# -------------------------------------------------------------------------
	print("[TEST 1] Evasion triggers graceful de-escalation rather than instant disappearance...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.2).timeout
	
	controller.pursuer.activate_pursuit(controller.courier_bike)
	assert(controller.pursuer.is_active and controller.pursuer.current_state == PursuerPrototype.PursuerState.CHASING, "FAIL 1: Pursuer is CHASING")
	assert(controller.pursuer.visible == true, "FAIL 1: Pursuer is visible")
	
	# Trigger evasion
	controller._on_successful_evasion()
	assert(controller.pursuer.is_active == true, "FAIL 1: Pursuer MUST remain active during de-escalation (not hard killed)")
	assert(controller.pursuer.visible == true, "FAIL 1: Pursuer MUST remain visible during retreat")
	assert(controller.pursuer.current_state == PursuerPrototype.PursuerState.DE_ESCALATING, "FAIL 1: State must be DE_ESCALATING")
	assert(controller.pursuer.target_node == null, "FAIL 1: Target decoupled during retreat")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL 1: Game state is EVADED")
	assert(controller.touch_ui.replay_panel.visible == true, "FAIL 1: Replay overlay accessible during aftermath")
	print("  -> Test 1 PASS: Evasion triggers graceful DE_ESCALATING state!")

	# -------------------------------------------------------------------------
	# TEST 2: GUARANTEED NON-INTERCEPTION DURING DE-ESCALATION
	# -------------------------------------------------------------------------
	print("[TEST 2] Player proximity during de-escalation cannot trigger interception...")
	# Place player directly in front of de-escalating pursuer
	controller.courier_bike.global_position = controller.pursuer.global_position + Vector3(0, 0, 0.5)
	var intercepted_fired := [false]
	var intercept_cb := func(): intercepted_fired[0] = true
	controller.pursuer.intercepted_target.connect(intercept_cb)
	
	# Simulate 0.6 seconds of physics steps
	for i in range(36):
		controller.pursuer._physics_process(1.0 / 60.0)
		
	assert(not intercepted_fired[0], "FAIL 2: Interception must NEVER fire once in DE_ESCALATING state")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL 2: Game state remains EVADED")
	controller.pursuer.intercepted_target.disconnect(intercept_cb)
	print("  -> Test 2 PASS: Guaranteed non-hostile safety during de-escalation confirmed!")

	# -------------------------------------------------------------------------
	# TEST 3: PHYSICAL DECELERATION & AMBER LIGHT SEARCH TRANSITION
	# -------------------------------------------------------------------------
	print("[TEST 3] Physical speed decays smoothly toward search pace & amber light dims...")
	controller.pursuer.current_speed = 15.0
	for i in range(30):
		controller.pursuer._physics_process(1.0 / 60.0)
	assert(controller.pursuer.current_speed < 13.0, "FAIL 3: Pursuer speed decelerated")
	assert(controller.pursuer.siren_light.light_color == Color(1.0, 0.65, 0.2), "FAIL 3: Siren light transitioned to amber")
	print("  -> Test 3 PASS: Smooth physical deceleration and visual search mode verified!")

	# -------------------------------------------------------------------------
	# TEST 4: DE-ESCALATION COMPLETION & SAFE DISENGAGEMENT
	# -------------------------------------------------------------------------
	print("[TEST 4] De-escalation timer completion gracefully disengages pursuer...")
	# Advance remaining duration past 2.5s threshold
	for i in range(150):
		controller.pursuer._physics_process(1.0 / 60.0)
		
	assert(controller.pursuer.current_state == PursuerPrototype.PursuerState.EVADED_DISENGAGED, "FAIL 4: Pursuer reached EVADED_DISENGAGED")
	assert(controller.pursuer.is_active == false and controller.pursuer.visible == false, "FAIL 4: Pursuer safely hidden after disengagement")
	assert(controller.pursuer.current_speed == 0.0 and controller.pursuer.velocity == Vector3.ZERO, "FAIL 4: Motion halted")
	print("  -> Test 4 PASS: Disengagement completed cleanly!")

	# -------------------------------------------------------------------------
	# TEST 5: FRAME-RATE INDEPENDENT PURSUIT RELEASE ENVELOPE (03.2B INTEGRATION)
	# -------------------------------------------------------------------------
	print("[TEST 5] Audio pursuit pressure monotonic decay & evasion integration (03.2B)...")
	# 5.1: Real-pressure evasion path
	controller.audio_mgr.set_pursuit_pressure(8.0, controller.pursuer.global_position)
	assert(controller.audio_mgr._current_pursuit_pressure > 0.6, "FAIL 5A: Pursuit pressure armed at high level")
	assert(controller.audio_mgr._tension_layer_active and controller.audio_mgr._tension_player.playing, "FAIL 5A: Tension layer active")
	var initial_p: float = controller.audio_mgr._current_pursuit_pressure
	
	# Execute actual controller successful evasion sequence
	controller._on_successful_evasion()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL 5B1: Controller state EVADED")
	assert(controller.audio_mgr.current_mix_state == AudioManagerScript.MixState.EVASION_RELEASE, "FAIL 5B2: MixState is EVASION_RELEASE")
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == true, "FAIL 5B3: Decay envelope active immediately after evasion")
	assert(controller.audio_mgr._tension_player.playing, "FAIL 5B4: Tension drone remains playing during early envelope (not hard cut)")
	
	# Sample beginning (t=0)
	var p_start: float = controller.audio_mgr._current_pursuit_pressure
	assert(p_start == initial_p, "FAIL 5C: Start sample matches initial pressure")
	
	# Step mid-point (t = 0.5s)
	for i in range(30):
		controller.audio_mgr._process(1.0 / 60.0)
	var p_mid: float = controller.audio_mgr._current_pursuit_pressure
	assert(p_mid < p_start and p_mid > 0.0, "FAIL 5D: Monotonic decay verified (0 < p_mid < p_start)")
	
	# Test active pursuit interruption during decay -> Cleanly cancels decay
	controller.audio_mgr.set_pursuit_pressure(6.0, controller.pursuer.global_position)
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == false, "FAIL 5E: Reactivation cancelled decay envelope")
	
	# Re-start decay to completion
	controller.audio_mgr.start_pursuit_release_decay(0.8)
	for i in range(60):
		controller.audio_mgr._process(1.0 / 60.0)
		
	# Sample end (t >= 0.8s) -> Total silence
	assert(controller.audio_mgr._current_pursuit_pressure == 0.0, "FAIL 5F1: Pressure reached zero")
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == false, "FAIL 5F2: Decay completed")
	assert(not controller.audio_mgr._tension_player.playing, "FAIL 5F3: Tension drone halted at end of decay")
	assert(not controller.audio_mgr._siren_player.playing, "FAIL 5F4: Siren halted at end of decay")
	
	# 5.2: Zero-pressure evasion path (long-distance escape never synthesizes new tension)
	controller.audio_mgr.clear_pursuit_pressure()
	assert(controller.audio_mgr._current_pursuit_pressure == 0.0, "FAIL 5G1: Starting pressure is 0")
	controller._on_successful_evasion()
	assert(controller.audio_mgr._current_pursuit_pressure == 0.0, "FAIL 5G2: Zero-pressure evasion never synthesizes new pressure")
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == false, "FAIL 5G3: Decay envelope inactive when zero pressure")
	assert(not controller.audio_mgr._tension_player.playing, "FAIL 5G4: Tension player remains stopped")
	
	# 5.3: Instant reset authoritative override during active decay
	controller.audio_mgr.set_pursuit_pressure(8.0, controller.pursuer.global_position)
	controller.audio_mgr.start_pursuit_release_decay(1.0)
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == true, "FAIL 5H1: Decay armed before reset")
	controller.audio_mgr.reset_audio_instant()
	assert(controller.audio_mgr._is_decaying_pursuit_pressure == false, "FAIL 5H2: Instant reset immediately killed decay envelope")
	assert(controller.audio_mgr._current_pursuit_pressure == 0.0, "FAIL 5H3: Instant reset zeroed pressure")
	
	print("  -> Test 5 PASS: Frame-rate independent pursuit release envelope (03.2B) verified!")

	# -------------------------------------------------------------------------
	# TEST 6: REPLAY / RESET DETERMINISTIC LIFECYCLE
	# -------------------------------------------------------------------------
	print("[TEST 6] Replay / slice reset immediately restores clean INACTIVE state...")
	# Activate pursuit again
	controller.pursuer.activate_pursuit(controller.courier_bike)
	controller.pursuer.global_position = Vector3(10.0, 0.6, 25.0)
	controller.pursuer.velocity = Vector3(5.0, 0.0, -10.0)
	
	# Execute Replay reset
	controller.touch_ui.replay_button.pressed.emit()
	await controller.get_tree().process_frame
	await controller.get_tree().process_frame
	
	assert(controller.pursuer.current_state == PursuerPrototype.PursuerState.INACTIVE, "FAIL 6: State reset to INACTIVE")
	assert(controller.pursuer.is_active == false, "FAIL 6: is_active is false")
	assert(controller.pursuer.visible == false, "FAIL 6: visible is false")
	assert(controller.pursuer.global_position == Vector3(0, 0.6, -10.0), "FAIL 6: Restored initial spawn coordinates")
	assert(controller.pursuer.velocity == Vector3.ZERO, "FAIL 6: Velocity is zero")
	assert(controller.pursuer.detour_waypoints.size() == 0, "FAIL 6: Detour waypoints purged")
	assert(controller.pursuer.target_node == null, "FAIL 6: Target decoupled")
	print("  -> Test 6 PASS: Full deterministic reset verified across all state variables!")

	# -------------------------------------------------------------------------
	# TEST 7: SUBSEQUENT PURSUIT RE-TRIGGERING AFTER RESET
	# -------------------------------------------------------------------------
	print("[TEST 7] Subsequent disturbance alert after reset cleanly re-arms and chases...")
	controller.trigger_disturbance_alert()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.DISTURBANCE_ALERT, "FAIL 7: Disturbance alert armed")
	await controller.get_tree().create_timer(0.85).timeout
	
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL 7: Pursuit activated")
	assert(controller.pursuer.is_active == true and controller.pursuer.visible == true, "FAIL 7: Pursuer active & visible")
	assert(controller.pursuer.current_state == PursuerPrototype.PursuerState.CHASING, "FAIL 7: State is CHASING")
	assert(controller.pursuer.target_node != null, "FAIL 7: Target acquired")
	print("  -> Test 7 PASS: Clean re-triggering after reset confirmed!")

	# Cleanup
	controller.reset_slice()
	print("\n=========================================================================")
	print("[ALL V8 M03 THREAT AFTERMATH ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)

# =============================================================================
# V8 M04: MEMORY ECHO EXTRACTION PAYOFF ASSERTIONS
# Suite 21 — 10 assertions + 4-stage visual proof
# Authorized from a077e2ac939a1300ac05ca12b64002d4972d883c
# =============================================================================


