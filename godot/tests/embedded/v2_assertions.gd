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
	print("[V2_ASSERTIONS] Starting strict V2 SignalTuner & World State assertions...")
	await controller.get_tree().create_timer(0.1).timeout
	
	controller.player.global_position = Vector3(0, 0, 10.0)
	await controller.get_tree().create_timer(0.1).timeout
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	assert(controller.signal_tuner != null, "FAIL: SignalTuner must exist")
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.DORMANT, "FAIL: Tuner must start DORMANT")
	assert(not controller.corroded_panel.is_powered, "FAIL: CorrodedPanel must start UNPOWERED")
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.START, "FAIL: World state must start START")
	
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 5.0)
	await controller.get_tree().create_timer(0.2).timeout
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.ATTRACTING, "FAIL: Tuner must enter ATTRACTING")
	
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 2.0)
	await controller.get_tree().create_timer(0.2).timeout
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.READY, "FAIL: Tuner must enter READY")
	assert(controller._active_target == controller.signal_tuner, "FAIL: Active target must be SignalTuner")
	
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.2).timeout
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: Tuner must enter TUNING")
	assert(controller.player.is_input_locked, "FAIL: Player locomotion must lock during tuning")
	
	controller.signal_tuner.tune_dial(0.57)
	await controller.get_tree().create_timer(0.5).timeout
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL: Tuner must lock signal")
	assert(controller.corroded_panel.is_powered, "FAIL: CorrodedPanel must power on upon Signal Lock")
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.PANEL_POWERED, "FAIL: World state must advance to PANEL_POWERED")
	assert(not controller.player.is_input_locked, "FAIL: Player locomotion must unlock after lock")
	
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.8)
	await controller.get_tree().create_timer(0.3).timeout
	controller._active_target = controller.corroded_panel
	controller._on_action_pressed()
	controller._on_peel_gesture_dragged(1.0)
	controller._on_core_tap_pressed()
	await controller.get_tree().create_timer(0.4).timeout
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.CORE_EXTRACTED, "FAIL: World state must reach CORE_EXTRACTED")
	
	print("[V2_ASSERTIONS] PASSED! ALL V2 MICRO-PLAY LOOP ASSERTIONS SUCCEEDED CLEANLY.")
	controller.get_tree().quit()


