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
	print("[V1_ASSERTIONS] Starting strict V1 test suite...")
	await controller.get_tree().create_timer(0.1).timeout
	controller.corroded_panel.is_powered = true
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel must start IDLE")
	var rejections := controller.corroded_panel.trigger_action()
	assert(not rejections, "FAIL: Out-of-range action must return false")
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.8)
	await controller.get_tree().create_timer(0.3).timeout
	assert(controller.corroded_panel.is_player_in_range, "FAIL: Player must be in range")
	controller._active_target = controller.corroded_panel
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.2).timeout
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.PEELING, "FAIL: Panel must enter PEELING")
	controller._on_peel_gesture_dragged(1.0)
	await controller.get_tree().create_timer(0.2).timeout
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.EXPOSED, "FAIL: Panel must enter EXPOSED")
	controller._on_core_tap_pressed()
	await controller.get_tree().create_timer(0.3).timeout
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.EXTRACTED, "FAIL: Panel must enter EXTRACTED")
	assert(not controller.player.is_input_locked, "FAIL: Player input must unlock")
	print("[V1_ASSERTIONS] PASSED! ALL V1 REACTION ASSERTIONS GREEN.")
	controller.get_tree().quit()


