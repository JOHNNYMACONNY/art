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
	print("[V5_ASSERTIONS] Starting complete V5 Environmental Evasion / Scrap Route Switch assertions...")
	await controller.get_tree().create_timer(0.1).timeout
	assert(controller.signal_gate != null, "FAIL: SignalGateInteractable must exist")
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.DORMANT, "FAIL: SignalGate must start DORMANT")
	
	# DISTURBANCE_ALERT keeps gate DORMANT
	controller.trigger_disturbance_alert()
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.DORMANT, "FAIL: DISTURBANCE_ALERT must keep gate DORMANT")
	
	# PURSUIT_ACTIVE makes gate READY
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.READY, "FAIL: PURSUIT_ACTIVE must make SignalGate READY")
	
	# Player mounts bike and approaches SignalGate -> Driving RouteSwitchButton becomes visible
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.is_player_in_range = true
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	controller.courier_bike.rotation.y = PI
	
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 2.5)
	controller.signal_gate.update_player_distance(controller.courier_bike.global_position)
	controller._evaluate_target_selection()
	assert(controller._active_target == controller.signal_gate, "FAIL: Target selection must highlight SignalGate")
	assert(controller.touch_ui.route_switch_button.visible, "FAIL: Driving RouteSwitchButton must become visible")
	
	# Trigger SignalGate via UI action press -> GATE_SLAM audio event & physical barrier slam
	controller._throttle_input = 1.0
	controller._on_action_pressed()
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING, "FAIL: SignalGate must enter TRIGGERING")
	assert(controller.signal_gate.barrier_collision.disabled, "FAIL: Barrier collision shape must remain disabled until swing completes and safety sweep volume is clear")
	await controller.get_tree().create_timer(0.75).timeout
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: SignalGate must enter TRIGGERED")
	assert(not controller.signal_gate.barrier_collision.disabled, "FAIL: Barrier collision shape must activate after sweep safety check passes")
	assert(abs(controller.signal_gate.barrier_pivot.rotation.y - deg_to_rad(90.0)) < 0.1, "FAIL: Barrier pivot must swing 90 degrees")
	assert(controller.pursuer.current_detour_index == 0, "FAIL: SignalGate trigger must set pursuer detour path")
	
	# Continue driving bike down shortcut channel -> Pursuer steps through detour waypoints -> Evasion
	await controller.get_tree().create_timer(3.8).timeout
	assert(controller.pursuer.current_detour_index > 0 or controller.pursuer.current_detour_index == -1, "FAIL: Pursuer must progress through detour waypoints")
	await controller.get_tree().create_timer(2.2).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CONTACT_BROKEN or controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED or controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL: Contact must break naturally after detour reroute")
	await controller.get_tree().create_timer(1.2).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM or controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL: Pursuit must return to CALM/EVADED after evasion")
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: Triggered gate remains spent TRIGGERED after pursuit ends")
	
	print("[V5_ASSERTIONS] PASSED! ALL V5 ENVIRONMENTAL EVASION SLICE ASSERTIONS GREEN.")
	controller.get_tree().quit()


static func export_visuals(controller: ScrapTestBlock) -> void:
	print("[V5_VISUALS] Exporting 6 required V5 visual screenshots to res://verification/v5/...")
	await controller.get_tree().create_timer(0.2).timeout
	
	# 1. v5_gate_dormant.png
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_gate_dormant.png")
	
	# 2. v5_gate_ready.png
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_gate_ready.png")
	
	# 3. v5_gate_triggering.png
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 1.5)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.signal_gate.update_player_distance(controller.courier_bike.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_gate_triggering.png")
	
	# 4. v5_barrier_slam.png
	await controller.get_tree().create_timer(0.45).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_barrier_slam.png")
	
	# 5. v5_pursuer_detour.png
	await controller.get_tree().create_timer(1.0).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_pursuer_detour.png")
	
	# 6. v5_shortcut_evasion.png
	await controller.get_tree().create_timer(2.0).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_shortcut_evasion.png")
	
	print("[V5_VISUALS] ALL 6 V5 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	controller.get_tree().quit()


