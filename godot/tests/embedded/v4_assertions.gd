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
	print("[V4_ASSERTIONS] Starting complete V4 Pressure & Pursuit Slice assertions...")
	await controller.get_tree().create_timer(0.1).timeout
	controller._steer_input = 0.0
	controller._throttle_input = 0.0
	assert(controller.pursuer != null, "FAIL: PursuerPrototype must exist")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL: Pursuit state must start CALM")
	assert(not controller.pursuer.is_active, "FAIL: Pursuer must start INACTIVE")
	
	# Gate 0 Proof 1: Siren Spatial Position Updating
	controller.audio_mgr.set_siren_audio(true, Vector3(5, 1, 5))
	assert(controller.audio_mgr._siren_player.global_position == Vector3(5, 1, 5), "FAIL: Siren position A must update")
	controller.audio_mgr.set_siren_audio(true, Vector3(-10, 2, 15))
	assert(controller.audio_mgr._siren_player.global_position == Vector3(-10, 2, 15), "FAIL: Siren position B must update while playing")
	controller.audio_mgr.set_siren_audio(false, Vector3.ZERO)
	
	# Gate 0 Proof 2: Touch Pointer Isolation
	controller.touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 7
	touch_down.pressed = true
	touch_down.position = Vector2(600, 300)
	controller.touch_ui._gui_input(touch_down)
	assert(controller.touch_ui._interaction_touch_index == 7, "FAIL: Interaction touch must acquire index 7")
	
	var wrong_drag := InputEventScreenDrag.new()
	wrong_drag.index = 9
	wrong_drag.relative = Vector2(100, 0)
	var tuner_emitted: Array = [false]
	var tune_cb := func(_df: float): tuner_emitted[0] = true
	controller.touch_ui.tuner_dragged.connect(tune_cb)
	controller.touch_ui._gui_input(wrong_drag)
	assert(not tuner_emitted[0], "FAIL: Wrong pointer drag must NOT emit tuner_dragged")
	
	var right_drag := InputEventScreenDrag.new()
	right_drag.index = 7
	right_drag.relative = Vector2(100, 0)
	controller.touch_ui._gui_input(right_drag)
	assert(tuner_emitted[0], "FAIL: Matching pointer drag MUST emit tuner_dragged")
	controller.touch_ui.tuner_dragged.disconnect(tune_cb)
	
	var wrong_up := InputEventScreenTouch.new()
	wrong_up.index = 9
	wrong_up.pressed = false
	controller.touch_ui._gui_input(wrong_up)
	assert(controller.touch_ui._interaction_touch_index == 7, "FAIL: Wrong pointer release must NOT clear ownership")
	
	var right_up := InputEventScreenTouch.new()
	right_up.index = 7
	right_up.pressed = false
	controller.touch_ui._gui_input(right_up)
	assert(controller.touch_ui._interaction_touch_index == -1, "FAIL: Matching pointer release MUST clear ownership")
	controller.touch_ui.close_interaction_overlay()
	
	# Trigger disturbance alert
	controller.trigger_disturbance_alert()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.DISTURBANCE_ALERT, "FAIL: Core extraction must trigger DISTURBANCE_ALERT")
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL: Disturbance must transition to PURSUIT_ACTIVE")
	assert(controller.pursuer.is_active, "FAIL: Pursuer must activate")
	assert(controller.pursuer.target_node == controller.player, "FAIL: Pursuer target must be player on foot")
	
	# Mount bike during pursuit -> Pursuer switches target to bike
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.is_player_in_range = true
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	assert(controller.pursuer.target_node == controller.courier_bike, "FAIL: Pursuer target must switch to bike when mounted")
	
	# Accelerate bike facing open +Z straightaway to create distance > 18.0m -> Evasion
	controller.courier_bike.rotation.y = PI
	controller._steer_input = 0.0
	controller._throttle_input = 1.0
	controller.signal_gate.set_pursuit_active(true)
	controller.signal_gate.begin_interaction(controller.courier_bike.global_position)
	await controller.get_tree().create_timer(4.5).timeout
	assert(controller.courier_bike.global_position.distance_to(controller.pursuer.global_position) > 18.0, "FAIL: Bike must create distance > 18m from pursuer via SignalGate route switch")
	await controller.get_tree().create_timer(3.2).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CONTACT_BROKEN or controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED or controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL: Contact must break when distance > 18m")
	
	await controller.get_tree().create_timer(1.2).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM or controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL: Pursuit must return to CALM/EVADED after evasion")
	assert(not controller.pursuer.is_active or controller.pursuer.current_state == PursuerPrototype.PursuerState.DE_ESCALATING or controller.pursuer.current_state == PursuerPrototype.PursuerState.EVADED_DISENGAGED, "FAIL: Pursuer must de-escalate or deactivate after evasion")
	
	# Gate 0 Proof 3: Mounted Interception Force Dismount Recovery
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.35).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must be DRIVING before interception")
	
	controller._on_pursuer_intercepted()
	await controller.get_tree().create_timer(0.95).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Interception must reset bike state to PARKED")
	assert(controller.courier_bike.occupant == null, "FAIL: Bike occupant must be null after interception")
	assert(not controller.player.is_input_locked, "FAIL: Player input must unlock after interception")
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: Touch UI must reset to FOOT_TRAVERSAL")
	assert(controller.camera.target_node == controller.player, "FAIL: Camera target must reset to player")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.RETRY_READY or controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL: Pursuit state must reach RETRY_READY/CALM after recovery")
	
	print("[V4_ASSERTIONS] PASSED! ALL V4 PRESSURE & PURSUIT SLICE ASSERTIONS GREEN.")
	controller.get_tree().quit()


