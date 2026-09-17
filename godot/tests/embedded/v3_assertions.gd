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
	print("[V3_ASSERTIONS] Starting complete V3 Courier Bike Vehicle Feel Slice assertions...")
	await controller.get_tree().create_timer(0.1).timeout
	assert(controller.courier_bike != null, "FAIL: CourierBike must exist")
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must start PARKED")
	assert(controller.courier_bike.occupant == null, "FAIL: Bike occupant must start null")
	
	assert(controller.audio_mgr._engine_stream != null, "FAIL: Audio manager engine stream must exist")
	assert(controller.audio_mgr._hum_stream != null, "FAIL: Audio manager hum stream must exist")
	
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.5)
	await controller.get_tree().create_timer(0.2).timeout
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	
	assert(controller.courier_bike.current_state == CourierBike.BikeState.MOUNTING, "FAIL: Bike must enter MOUNTING")
	await controller.get_tree().create_timer(0.35).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	assert(controller.courier_bike.occupant == controller.player, "FAIL: Occupant must be player")
	assert(controller.player.is_input_locked, "FAIL: Player input must be locked while mounted")
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING, "FAIL: Touch UI must enter VEHICLE_DRIVING")
	
	controller.courier_bike.rotation.y = PI
	var initial_rot := controller.courier_bike.rotation.y
	controller._steer_input = 0.5
	controller._throttle_input = 1.0
	await controller.get_tree().create_timer(1.0).timeout
	assert(controller.courier_bike.current_speed > 5.0, "FAIL: Bike speed must accelerate under throttle")
	assert(controller.courier_bike.rotation.y != initial_rot, "FAIL: Steering must change bike heading")
	assert(controller.player.global_position.distance_to(controller.courier_bike.rider_socket.global_position) < 0.1, "FAIL: Rider avatar must remain bound to RiderSocket")
	
	controller._steer_input = 0.0
	controller._throttle_input = -1.0
	await controller.get_tree().create_timer(0.8).timeout
	assert(controller.courier_bike.current_speed <= 0.1, "FAIL: Forward braking must reach near-zero before reverse")
	await controller.get_tree().create_timer(0.8).timeout
	assert(controller.courier_bike.current_speed < 0.0, "FAIL: Continued negative throttle must reverse")
	assert(controller.courier_bike.current_speed >= controller.courier_bike.max_reverse_speed, "FAIL: Reverse speed must be limited")
	
	controller._throttle_input = 1.0
	await controller.get_tree().create_timer(1.0).timeout
	assert(abs(controller.courier_bike.current_speed) > controller.courier_bike.dismount_speed_limit, "FAIL: Bike speed must be > 1.5 m/s")
	var rejected_dismount := controller.courier_bike.request_dismount()
	assert(not rejected_dismount, "FAIL: High-speed dismount must be rejected")
	
	controller._throttle_input = 0.0
	controller.courier_bike.current_speed = 0.0
	
	controller._on_dismount_pressed()
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DISMOUNTING, "FAIL: Bike state must transition DISMOUNTING before PARKED")
	await controller.get_tree().create_timer(0.3).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must return to PARKED after dismount")
	assert(controller.courier_bike.occupant == null, "FAIL: Occupant must clear after dismount")
	assert(not controller.player.is_input_locked, "FAIL: Player input must unlock after dismount")
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: Touch UI must return to FOOT_TRAVERSAL")
	
	print("[V3_ASSERTIONS] PASSED! ALL V3 COURIER BIKE VEHICLE FEEL SLICE ASSERTIONS GREEN.")
	controller.get_tree().quit()


