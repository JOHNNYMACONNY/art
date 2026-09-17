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

static func export_v4_visuals(controller: ScrapTestBlock) -> void:
	print("[V4_VISUALS] Exporting 6 required V4 visual screenshots to res://verification/v4/...")
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_calm.png")
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_disturbance.png")
	await controller.get_tree().create_timer(0.6).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_pursuit_foot.png")
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.5)
	await controller.get_tree().create_timer(0.2).timeout
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_mounting_under_pressure.png")
	await controller.get_tree().create_timer(0.25).timeout
	controller._throttle_input = 1.0
	await controller.get_tree().create_timer(1.5).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_driving_escape.png")
	await controller.get_tree().create_timer(3.0).timeout
	controller._throttle_input = 0.0
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_evaded_calm.png")
	print("[V4_VISUALS] ALL 6 V4 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	controller.get_tree().quit()


static func export_v3_visuals(controller: ScrapTestBlock) -> void:
	print("[V3_VISUALS] Exporting 6 required V3 visual screenshots to res://verification/v3/...")
	await controller.get_tree().create_timer(0.2).timeout
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 3.5)
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_parked.png")
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_mounting.png")
	await controller.get_tree().create_timer(0.2).timeout
	controller._throttle_input = 1.0
	await controller.get_tree().create_timer(0.8).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_driving_straight.png")
	controller._steer_input = 0.8
	await controller.get_tree().create_timer(0.5).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_cornering.png")
	controller._steer_input = 0.0
	controller._throttle_input = -1.0
	await controller.get_tree().create_timer(0.4).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_braking.png")
	controller._throttle_input = 0.0
	controller.courier_bike.current_speed = 0.0
	controller._on_dismount_pressed()
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_dismounted.png")
	print("[V3_VISUALS] ALL 6 V3 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	controller.get_tree().quit()


static func export_v2_visuals(controller: ScrapTestBlock) -> void:
	print("[V2_VISUALS] Exporting 8 required V2 visual screenshots to res://verification/v2/...")
	await controller.get_tree().create_timer(0.2).timeout
	controller.player.global_position = Vector3(0, 0, 8.0)
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_explore.png")
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 4.5)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_tuner_attract.png")
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.8)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	controller.signal_tuner.tune_dial(0.1)
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_tuning_far.png")
	controller.signal_tuner.tune_dial(0.45)
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_tuning_near.png")
	controller.signal_tuner.tune_dial(0.02)
	await controller.get_tree().create_timer(0.5).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_signal_locked.png")
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.8)
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_panel_powered.png")
	controller._active_target = controller.corroded_panel
	controller._on_action_pressed()
	controller._on_peel_gesture_dragged(0.5)
	await controller.get_tree().create_timer(0.3).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_panel_extraction.png")
	controller._on_peel_gesture_dragged(1.0)
	controller._on_core_tap_pressed()
	await controller.get_tree().create_timer(0.4).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_loop_complete.png")
	print("[V2_VISUALS] ALL 8 V2 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	controller.get_tree().quit()


