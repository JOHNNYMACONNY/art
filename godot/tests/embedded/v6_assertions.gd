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
	print("[V6_ASSERTIONS] Starting complete V6 Golden Slice Cohesion & Full Run assertions...")
	await controller.get_tree().create_timer(0.2).timeout
	
	# 1. Cold Spawn & Discovery
	controller.player.global_position = Vector3(0, 0, 10.0)
	assert(controller.player.global_position.distance_to(Vector3(0, 0, 10.0)) < 0.1, "FAIL: Player must spawn at Vector3(0, 0, 10.0)")
	assert(not controller.touch_ui.tension_panel.visible, "FAIL: Tension HUD must start hidden")
	assert(not controller.touch_ui.replay_panel.visible, "FAIL: Replay panel must start hidden")
	
	# 2. Player moves to SignalTuner at z = -3.5 -> Tune Signal
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.2)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	assert(controller._active_target == controller.signal_tuner, "FAIL: SignalTuner must be targeted")
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.2).timeout
	controller.signal_tuner.tune_dial(0.57)
	await controller.get_tree().create_timer(0.5).timeout
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.LOCKED or controller.signal_tuner.current_state == SignalTuner.TunerState.SPENT, "FAIL: SignalTuner must lock after tuning")
	assert(controller.corroded_panel.is_powered, "FAIL: CorrodedPanel must become powered")
	
	# 3. Peel Panel -> Extract Core -> Disturbance Alert
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.2)
	controller.corroded_panel._on_body_entered(controller.player)
	controller.corroded_panel.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.2).timeout
	controller.corroded_panel.progress_peel(1.0)
	await controller.get_tree().create_timer(0.2).timeout
	controller.corroded_panel.complete_extraction()
	await controller.get_tree().create_timer(2.0).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.DISTURBANCE_ALERT, "FAIL: Core extraction must trigger DISTURBANCE_ALERT")
	await controller.get_tree().create_timer(0.8).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL: Alert must transition to PURSUIT_ACTIVE")
	assert(controller.pursuer.is_active, "FAIL: Pursuer must activate")
	
	# 4. Mount Bike & Chase down track
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.is_player_in_range = true
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	controller.courier_bike.rotation.y = PI
	
	# Verify real GAS & BRAKE touch routes with the same ScreenTouch events
	# consumed by the production gui_input handlers.
	var gas_touch := InputEventScreenTouch.new()
	gas_touch.index = 101
	gas_touch.position = Vector2(1.0, 1.0)
	gas_touch.pressed = true
	controller.touch_ui.gas_button.gui_input.emit(gas_touch)
	assert(controller._throttle_input == 1.0, "FAIL: GAS ScreenTouch press must set throttle input to 1.0")
	gas_touch.pressed = false
	controller.touch_ui.gas_button.gui_input.emit(gas_touch)
	assert(controller._throttle_input == 0.0, "FAIL: GAS ScreenTouch release must reset throttle input to 0.0")
	var brake_touch := InputEventScreenTouch.new()
	brake_touch.index = 102
	brake_touch.position = Vector2(1.0, 1.0)
	brake_touch.pressed = true
	controller.touch_ui.brake_button.gui_input.emit(brake_touch)
	assert(controller._throttle_input == -1.0, "FAIL: BRAKE ScreenTouch press must set throttle input to -1.0")
	brake_touch.pressed = false
	controller.touch_ui.brake_button.gui_input.emit(brake_touch)
	assert(controller._throttle_input == 0.0, "FAIL: BRAKE ScreenTouch release must reset throttle input to 0.0")
	
	# 5. Route Switch -> SignalGate slams -> Detour -> Evasion
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.signal_gate.set_pursuit_active(true)
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 2.5)
	controller.signal_gate.update_player_distance(controller.courier_bike.global_position)
	controller._evaluate_target_selection()
	assert(controller.touch_ui.route_switch_button.visible, "FAIL: Driving RouteSwitchButton must show")
	controller._throttle_input = 1.0
	controller.touch_ui.route_switch_button.pressed.emit()
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING, "FAIL: Gate must enter TRIGGERING")
	await controller.get_tree().create_timer(0.75).timeout
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: Gate must enter TRIGGERED")
	assert(not controller.signal_gate.barrier_collision.disabled, "FAIL: Barrier collision must lock solid")
	
	await controller.get_tree().create_timer(3.8).timeout
	assert(controller.pursuer.current_detour_index > 0 or controller.pursuer.current_detour_index == -1, "FAIL: Pursuer must step through detour waypoints")
	await controller.get_tree().create_timer(2.2).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM or controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL: Pursuit must evade naturally")
	assert(controller.touch_ui.replay_panel.visible, "FAIL: Replay button must show upon quiet aftermath")
	
	# 6. Deterministic Replay Reset via ReplayButton Signal
	controller.touch_ui.replay_button.pressed.emit()
	assert(controller.player.global_position.distance_to(Vector3(0, 0, 10.0)) < 0.1, "FAIL: Replay reset must restore player spawn to Vector3(0, 0, 10.0)")
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Replay reset must restore bike state to PARKED")
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.DORMANT, "FAIL: Replay reset must restore tuner to DORMANT")
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Replay reset must restore panel to IDLE")
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.DORMANT, "FAIL: Replay reset must restore gate to DORMANT")
	assert(not controller.pursuer.is_active, "FAIL: Replay reset must deactivate pursuer")
	assert(not controller.touch_ui.replay_panel.visible, "FAIL: Replay reset must hide replay overlay")
	
	print("[V6_ASSERTIONS] PASSED! ALL V6 GOLDEN SLICE COHESION ASSERTIONS GREEN.")
	controller.get_tree().quit()


static func export_visuals(controller: ScrapTestBlock) -> void:
	print("[V6_VISUALS] Exporting 6 required V6 visual screenshots to res://verification/v6/...")
	await controller.get_tree().create_timer(0.2).timeout
	
	# 1. v6_cold_spawn.png
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_cold_spawn.png")
	
	# 2. v6_signal_tuning.png
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.2)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_signal_tuning.png")
	
	# 3. v6_core_extraction.png
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.2)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_core_extraction.png")
	
	# 4. v6_bike_mount_chase.png
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 2.5)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_bike_mount_chase.png")
	
	# 5. v6_route_switch_slam.png
	controller.signal_gate.update_player_distance(controller.courier_bike.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.4).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_route_switch_slam.png")
	
	# 6. v6_quiet_aftermath_replay.png
	controller._on_successful_evasion()
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_quiet_aftermath_replay.png")
	
	print("[V6_VISUALS] ALL 6 V6 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	controller.get_tree().quit()


