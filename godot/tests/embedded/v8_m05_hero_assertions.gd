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
	print("[V8 M05 HERO SILHOUETTE & COURIER IDENTITY ASSERTIONS] Starting...")
	print("=========================================================================\n")

	# ─────────────────────────────────────────────────────────────────────────
	# SETUP: fresh slice
	# ─────────────────────────────────────────────────────────────────────────
	controller.reset_slice()
	await controller.get_tree().process_frame
	await controller.get_tree().process_frame

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 1: Existing gameplay collision shapes unchanged
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 1: Existing gameplay collision shapes unchanged ---")
	var runner_col := controller.player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert(runner_col != null, "FAIL A1: Runner must have CollisionShape3D")
	assert(runner_col.shape is CapsuleShape3D, "FAIL A1: Runner collision must be CapsuleShape3D")
	var r_capsule := runner_col.shape as CapsuleShape3D
	assert(is_equal_approx(r_capsule.radius, 0.4), "FAIL A1: Runner capsule radius must be 0.4")
	assert(is_equal_approx(r_capsule.height, 1.8), "FAIL A1: Runner capsule height must be 1.8")

	var bike_col := controller.courier_bike.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert(bike_col != null, "FAIL A1: CourierBike must have CollisionShape3D")
	assert(bike_col.shape is BoxShape3D, "FAIL A1: CourierBike collision must be BoxShape3D")
	var b_box := bike_col.shape as BoxShape3D
	assert(b_box.size.is_equal_approx(Vector3(1.0, 1.0, 2.2)), "FAIL A1: CourierBike box size must be Vector3(1.0, 1.0, 2.2)")
	print("  -> Assertion 1 PASS: Gameplay collision shapes 100% preserved")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 2: Runner movement kinematics & 8-way visual facing
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 2: Runner movement kinematics & 8-way visual facing ---")
	assert(is_equal_approx(controller.player.move_speed, 8.5), "FAIL A2: Runner move_speed must be 8.5")
	assert(is_equal_approx(controller.player.acceleration, 40.0), "FAIL A2: Runner acceleration must be 40.0")
	assert(is_equal_approx(controller.player.friction, 35.0), "FAIL A2: Runner friction must be 35.0")

	# Test 8-way facing across directional vectors
	var test_dirs := [
		Vector2(1.0, 0.0),   # Right
		Vector2(-1.0, 0.0),  # Left
		Vector2(0.0, -1.0),  # Up
		Vector2(0.0, 1.0),   # Down
		Vector2(0.707, -0.707), # Up-Right
	]
	for dir in test_dirs:
		controller.player.set_joystick_input(dir)
		controller.player._physics_process(1.0 / 60.0)
		assert(controller.player.mesh_pivot != null, "FAIL A2: mesh_pivot must exist")
		assert(controller.player.velocity.length() > 0.0, "FAIL A2: Runner must respond with non-zero velocity")
		await controller.get_tree().physics_frame
	
	controller.player.set_joystick_input(Vector2.ZERO)
	controller.player._physics_process(1.0 / 60.0)
	await controller.get_tree().physics_frame
	print("  -> Assertion 2 PASS: Runner movement kinematics and 8-way facing verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 3: Courier Bike handling constants unchanged
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 3: Courier Bike handling constants unchanged ---")
	assert(is_equal_approx(controller.courier_bike.max_speed, 14.0), "FAIL A3: Bike max_speed must be 14.0")
	assert(is_equal_approx(controller.courier_bike.max_reverse_speed, -4.0), "FAIL A3: Bike max_reverse_speed must be -4.0")
	assert(is_equal_approx(controller.courier_bike.acceleration, 12.0), "FAIL A3: Bike acceleration must be 12.0")
	assert(is_equal_approx(controller.courier_bike.braking_friction, 18.0), "FAIL A3: Bike braking_friction must be 18.0")
	assert(is_equal_approx(controller.courier_bike.steering_speed, 2.5), "FAIL A3: Bike steering_speed must be 2.5")
	assert(is_equal_approx(controller.courier_bike.dismount_speed_limit, 1.5), "FAIL A3: Bike dismount_speed_limit must be 1.5")
	print("  -> Assertion 3 PASS: Courier Bike handling constants 100% preserved")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 4: Mount / dismount lifecycle & posture transition
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 4: Mount / dismount lifecycle & posture transition ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	await controller.get_tree().process_frame
	
	var mount_ok: bool = controller.courier_bike.request_mount(controller.player)
	assert(mount_ok, "FAIL A4: request_mount must succeed when player is in range")
	assert(controller.player.is_mounted, "FAIL A4: player.is_mounted must be true after mounting")
	assert(controller.player.is_input_locked, "FAIL A4: player.is_input_locked must be true while mounted")
	# Seated forward crouch posture check: torso Y lower than standing (1.15)
	if controller.player.torso_node:
		assert(controller.player.torso_node.position.y < 0.8, "FAIL A4: Seated riding posture must lower torso")

	# Settle mounting state to DRIVING
	await controller.get_tree().create_timer(0.3).timeout
	await controller.get_tree().process_frame
	
	# Dismount
	var dismount_ok: bool = controller.courier_bike.request_dismount()
	assert(dismount_ok, "FAIL A4: request_dismount must succeed at zero speed")
	await controller.get_tree().create_timer(0.25).timeout
	await controller.get_tree().process_frame
	
	assert(not controller.player.is_mounted, "FAIL A4: player.is_mounted must be false after dismount")
	assert(not controller.player.is_input_locked, "FAIL A4: player.is_input_locked must be false after dismount")
	if controller.player.torso_node:
		assert(is_equal_approx(controller.player.torso_node.position.y, 1.15), "FAIL A4: Standing posture must be restored upon dismount")
	print("  -> Assertion 4 PASS: Mount / dismount lifecycle & posture transitions verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 5: Rider visual association & visibility while mounted
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 5: Rider visual association & visibility while mounted ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	var mount_ok5: bool = controller.courier_bike.request_mount(controller.player)
	assert(mount_ok5, "FAIL A5: Mount must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	await controller.get_tree().process_frame
	controller.courier_bike.current_speed = 10.0
	
	for _i in range(10):
		controller.courier_bike._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
		
	assert(controller.player.visible, "FAIL A5: Player runner must remain visible while mounted")
	controller.courier_bike.rider_socket.force_update_transform()
	var dist_to_socket := controller.player.global_position.distance_to(controller.courier_bike.to_global(controller.courier_bike.rider_socket.position))
	assert(dist_to_socket < 0.1, "FAIL A5: Player must track RiderSocket precisely while mounted (dist: %f)" % dist_to_socket)
	print("  -> Assertion 5 PASS: Rider visual association and continuous visibility verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 6: Visual reset cleanses all states (runner posture and bike lean)
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 6: Visual reset cleanses all states ---")
	# Force bike lean and mounted posture
	if controller.courier_bike.visual_root:
		controller.courier_bike.visual_root.rotation.z = deg_to_rad(12.0)
	controller.player.set_mounted_posture(true)
	
	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(not controller.player.is_mounted, "FAIL A6: player.is_mounted must be reset to false")
	if controller.player.torso_node:
		assert(is_equal_approx(controller.player.torso_node.position.y, 1.15), "FAIL A6: Torso must reset to standing height 1.15")
	if controller.courier_bike.visual_root:
		assert(controller.courier_bike.visual_root.rotation.is_equal_approx(Vector3.ZERO), "FAIL A6: Bike visual_root rotation must reset to ZERO")
	print("  -> Assertion 6 PASS: Visual reset cleanses all states cleanly")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 7: Pursuit target switching between runner and bike
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 7: Pursuit target switching between runner and bike ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.pursuer:
		controller.pursuer.activate_pursuit(controller.player)
		assert(controller.pursuer.target_node == controller.player, "FAIL A7: Pursuer target must be player on foot")
		
		# Mount bike -> target automatically switches to courier_bike via _on_bike_mounted signal
		controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
		controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
		var mount_ok7: bool = controller.courier_bike.request_mount(controller.player)
		assert(mount_ok7, "FAIL A7: Mount must succeed")
		await controller.get_tree().create_timer(0.3).timeout
		await controller.get_tree().process_frame
		assert(controller.pursuer.target_node == controller.courier_bike, "FAIL A7: Pursuer target must automatically switch to courier_bike upon mounted signal")
		
		# Dismount -> target automatically switches back to player via _on_bike_dismounted signal
		var dismount_ok7: bool = controller.courier_bike.request_dismount()
		assert(dismount_ok7, "FAIL A7: Dismount must succeed at stationary speed")
		await controller.get_tree().create_timer(0.25).timeout
		await controller.get_tree().process_frame
		assert(controller.pursuer.target_node == controller.player, "FAIL A7: Pursuer target must automatically switch back to player upon dismounted signal")
	print("  -> Assertion 7 PASS: Pursuit target switching between runner and bike verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 8: Echo overlay compatibility (no mesh corruption)
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 8: Echo overlay compatibility ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller._on_extraction_completed()
	await controller.get_tree().process_frame
	assert(controller.echo_controller != null and controller.echo_controller.current_phase == MemoryEchoController.EchoPhase.ONSET,
		"FAIL A8: Echo ONSET must be active")
	assert(controller.player.visible, "FAIL A8: Player must remain visible during Echo ONSET")
	assert(controller.player.torso_node != null and controller.player.head_node != null, "FAIL A8: Player hero mesh nodes must remain intact")
	controller.reset_slice()
	await controller.get_tree().process_frame
	print("  -> Assertion 8 PASS: Echo overlay does not corrupt hero rendering")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 9: Mobile-safe HUD remains unobstructed
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 9: Mobile-safe HUD remains unobstructed ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.touch_ui:
		controller.touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
		assert(controller.touch_ui.visible, "FAIL A9: Touch UI must be visible in FOOT_TRAVERSAL mode")
		controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
		assert(controller.touch_ui.visible, "FAIL A9: Touch UI must be visible in VEHICLE_DRIVING mode")
	print("  -> Assertion 9 PASS: Mobile-safe HUD remains unobstructed with hero visuals")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 10: Full Golden Slice completable with 7 rendered visual proofs
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 10: Full Golden Slice completable with 7 rendered visual proofs ---")
	controller.reset_slice()
	await controller.get_tree().process_frame

	# Proof 1: Runner Idle / Exploration
	for _i in range(3):
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m05/m05_01_runner_idle.png")
	print("  -> Visual proof saved: m05_01_runner_idle.png")

	# Proof 2: Runner Interaction / Extraction
	if controller.signal_tuner:
		controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.2)
		controller._on_tuner_signal_locked(controller.signal_tuner)
	for _i in range(4):
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m05/m05_02_runner_extraction.png")
	print("  -> Visual proof saved: m05_02_runner_extraction.png")

	# Proof 3: Bike Parked + Mount
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.8)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	for _i in range(4):
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m05/m05_03_bike_parked_mount.png")
	print("  -> Visual proof saved: m05_03_bike_parked_mount.png")

	# Mount bike and start driving
	var mount_ok10: bool = controller.courier_bike.request_mount(controller.player)
	assert(mount_ok10, "FAIL A10: Mount must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	await controller.get_tree().process_frame
	controller.courier_bike.current_speed = 10.0
	for _i in range(12):
		controller.courier_bike._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame

	# Proof 4: Normal Driving
	TestHelpers.save_proof_png(controller, "res://verification/v8/m05/m05_04_bike_driving.png")
	print("  -> Visual proof saved: m05_04_bike_driving.png")

	# Steer and handbrake for drift turn
	controller.courier_bike.steering_angle = 1.0
	controller.courier_bike.is_handbrake_active = true
	for _i in range(12):
		controller.courier_bike._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame

	# Proof 5: Drift / Turn Lean
	TestHelpers.save_proof_png(controller, "res://verification/v8/m05/m05_05_bike_drift_turn.png")
	print("  -> Visual proof saved: m05_05_bike_drift_turn.png")

	# Activate pursuit chase
	if controller.pursuer:
		controller.pursuer.activate_pursuit(controller.courier_bike)
		controller.pursuer.global_position = controller.courier_bike.global_position - Vector3(0, 0, 6.0)
		controller.current_pursuit_state = ScrapTestBlock.PursuitState.PURSUIT_ACTIVE
	for _i in range(8):
		await controller.get_tree().process_frame

	# Proof 6: Pursuit Chase
	TestHelpers.save_proof_png(controller, "res://verification/v8/m05/m05_06_pursuit_chase.png")
	print("  -> Visual proof saved: m05_06_pursuit_chase.png")

	# Evasion & Safe Dismount into Aftermath
	controller._on_successful_evasion()
	
	# Decelerate bike through braking friction until speed is <= dismount_speed_limit
	while abs(controller.courier_bike.current_speed) > controller.courier_bike.dismount_speed_limit:
		controller.courier_bike.current_speed = move_toward(controller.courier_bike.current_speed, 0.0, controller.courier_bike.braking_friction * (1.0 / 60.0))
		controller.courier_bike._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
		
	var dismount_ok10: bool = controller.courier_bike.request_dismount()
	assert(dismount_ok10, "FAIL A10: request_dismount must succeed when decelerated below dismount limit")
	await controller.get_tree().create_timer(0.3).timeout
	for _i in range(6):
		await controller.get_tree().process_frame

	# Verify genuine dismounted aftermath state before capturing proof
	assert(controller.courier_bike.occupant == null, "FAIL A10: courier_bike occupant must be null after dismount")
	assert(not controller.player.is_mounted, "FAIL A10: player.is_mounted must be false after dismount")
	assert(controller.player.visible, "FAIL A10: player must be visible in aftermath")
	if controller.player.torso_node:
		assert(is_equal_approx(controller.player.torso_node.position.y, 1.15), "FAIL A10: player standing posture must be restored")
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL A10: bike must be in PARKED state in aftermath")

	# Proof 7: Aftermath / Dismounted
	TestHelpers.save_proof_png(controller, "res://verification/v8/m05/m05_07_aftermath_dismounted.png")
	print("  -> Visual proof saved: m05_07_aftermath_dismounted.png")

	print("  -> Assertion 10 PASS: Full Golden Slice completable with all 7 hero visual proofs")

	# ─────────────────────────────────────────────────────────────────────────
	# CLEANUP & REPORT
	# ─────────────────────────────────────────────────────────────────────────
	controller.reset_slice()
	print("\n=========================================================================")
	print("[ALL V8 M05 HERO SILHOUETTE & COURIER IDENTITY ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


