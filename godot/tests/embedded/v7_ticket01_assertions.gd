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
	print("[V7_TICKET01_ASSERTIONS] Starting V7 Ticket 01 Retest Assertions (BUG-01 & BUG-02)...")
	await controller.get_tree().create_timer(0.2).timeout
	controller.signal_gate.set_pursuit_active(true)
	controller.pursuer.activate_pursuit(controller.courier_bike)
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 5.0)
	controller.player.global_position = controller.courier_bike.global_position
	controller.pursuer.global_position = controller.signal_gate.global_position + Vector3(0, 0, 0.5)
	await controller.get_tree().process_frame
	await controller.get_tree().process_frame
	controller.signal_gate.begin_interaction(controller.courier_bike.global_position)
	await controller.get_tree().create_timer(0.75).timeout
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: Gate must be TRIGGERED")
	assert(not controller.signal_gate.barrier_collision.disabled, "FAIL: barrier_collision.disabled MUST become false!")
	print("[TEST BUG-01 PASSED] barrier_collision.disabled became false immediately!")
	controller._on_successful_evasion()
	await controller.get_tree().create_timer(0.2).timeout
	controller.corroded_panel.power_on()
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.0)
	controller.corroded_panel._on_body_entered(controller.player)
	controller.corroded_panel.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.1).timeout
	controller._on_peel_gesture_dragged(0.4)
	controller.touch_ui.peel_gesture_released.emit()
	await controller.get_tree().create_timer(0.1).timeout
	assert(controller.corroded_panel.current_step == CorrodedPanel.Step.APPROACHED or controller.corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel step must reset!")
	assert(not controller.player.is_input_locked, "FAIL: Player input must unlock!")
	print("[TEST BUG-02 PASSED] Peel gesture touch release cancelled interaction cleanly!")
	print("[V7_TICKET01_ASSERTIONS] ALL V7 TICKET 01 ASSERTIONS PASSED GREEN!")
	controller.get_tree().quit(0)


