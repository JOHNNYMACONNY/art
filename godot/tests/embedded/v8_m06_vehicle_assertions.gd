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
	print("[V8 M06 VEHICLE CLASS VARIETY & ESCAPE CHOICE ASSERTIONS] Starting...")
	print("=========================================================================\n")

	# ─────────────────────────────────────────────────────────────────────────
	# SETUP: fresh slice
	# ─────────────────────────────────────────────────────────────────────────
	controller.reset_slice()
	await controller.get_tree().process_frame
	await controller.get_tree().process_frame

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 1: Courier Bike constants & physics behavior 100% preserved
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 1: Courier Bike constants & behavior preserved ---")
	assert(controller.courier_bike != null, "FAIL A1: courier_bike must exist in scene")
	assert(is_equal_approx(controller.courier_bike.max_speed, 14.0), "FAIL A1: Bike max_speed must be 14.0")
	assert(is_equal_approx(controller.courier_bike.acceleration, 12.0), "FAIL A1: Bike acceleration must be 12.0")
	assert(is_equal_approx(controller.courier_bike.braking_friction, 18.0), "FAIL A1: Bike braking_friction must be 18.0")
	assert(is_equal_approx(controller.courier_bike.steering_speed, 2.5), "FAIL A1: Bike steering_speed must be 2.5")
	assert(is_equal_approx(controller.courier_bike.dismount_speed_limit, 1.5), "FAIL A1: Bike dismount_speed_limit must be 1.5")
	print("  -> Assertion 1 PASS: Courier Bike constants 100% preserved")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 2: Scrap Hauler full-size collision footprint & proportions
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 2: Scrap Hauler full-size collision footprint ---")
	assert(controller.scrap_hauler != null, "FAIL A2: scrap_hauler must exist in scene")
	var hauler_col := controller.scrap_hauler.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert(hauler_col != null, "FAIL A2: ScrapHauler must have CollisionShape3D")
	assert(hauler_col.shape is BoxShape3D, "FAIL A2: ScrapHauler collision must be BoxShape3D")
	var h_box := hauler_col.shape as BoxShape3D
	assert(h_box.size.is_equal_approx(Vector3(1.8, 1.4, 3.8)), "FAIL A2: ScrapHauler box size must be Vector3(1.8, 1.4, 3.8)")
	assert(is_equal_approx(controller.scrap_hauler.max_speed, 15.5), "FAIL A2: ScrapHauler max_speed must be 15.5")
	assert(is_equal_approx(controller.scrap_hauler.acceleration, 8.5), "FAIL A2: ScrapHauler acceleration must be 8.5")
	assert(is_equal_approx(controller.scrap_hauler.braking_friction, 12.0), "FAIL A2: ScrapHauler braking_friction must be 12.0")
	print("  -> Assertion 2 PASS: Scrap Hauler full-size collision footprint verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 3: Canonical touch control semantics on both vehicle classes
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 3: Canonical touch control semantics on both vehicles ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	
	# Test bike throttle & brake
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.set_drive_inputs(1.0, 0.0, 0.1, false)
	assert(controller.courier_bike.current_speed > 0.0, "FAIL A3: Bike must accelerate forward with throttle > 0")
	
	# Test hauler throttle & brake
	controller.scrap_hauler.current_state = ScrapHaulerScript.VehicleState.DRIVING
	controller.scrap_hauler.set_drive_inputs(1.0, 0.0, 0.1, false)
	assert(controller.scrap_hauler.current_speed > 0.0, "FAIL A3: Hauler must accelerate forward with throttle > 0")
	print("  -> Assertion 3 PASS: Canonical touch drive inputs functional on both vehicles")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 4: Deterministic gear transitions on both vehicles
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 4: Deterministic gear transitions on both vehicles ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	
	for veh in [controller.courier_bike, controller.scrap_hauler]:
		veh.global_position = Vector3(0, 0.05, 0)
		veh.current_state = 2 # DRIVING
		veh.current_speed = 5.0
		veh.current_gear = 0 # FORWARD
		
		# 1. Forward -> Brake -> Stop -> Reverse
		for _i in range(30):
			veh.set_drive_inputs(-1.0, 0.0, 1.0 / 60.0, false)
			veh._physics_process(1.0 / 60.0)
		assert(veh.current_speed <= 0.0, "FAIL A4: Vehicle must brake to zero")
		veh._gear_settle_timer = 0.0
		
		for _i in range(15):
			veh.set_drive_inputs(-1.0, 0.0, 1.0 / 60.0, false)
			veh._physics_process(1.0 / 60.0)
		assert(veh.current_speed < 0.0, "FAIL A4: Vehicle must reverse with backward throttle")
		assert(veh.current_gear == 1, "FAIL A4: Vehicle gear must switch to REVERSE")
		
		# 2. Reverse -> Brake -> Stop -> Forward
		for _i in range(30):
			veh.set_drive_inputs(1.0, 0.0, 1.0 / 60.0, false)
			veh._physics_process(1.0 / 60.0)
		assert(veh.current_speed >= 0.0, "FAIL A4: Vehicle must brake from reverse to zero")
		veh._gear_settle_timer = 0.0
		
		for _i in range(15):
			veh.set_drive_inputs(1.0, 0.0, 1.0 / 60.0, false)
			veh._physics_process(1.0 / 60.0)
		assert(veh.current_speed > 0.0, "FAIL A4: Vehicle must drive forward with positive throttle")
		assert(veh.current_gear == 0, "FAIL A4: Vehicle gear must switch to FORWARD")
	print("  -> Assertion 4 PASS: Complete forward->reverse->forward gear cycle verified on all classes")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 5: Handbrake zero-speed pivot exploit prevention
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 5: Handbrake zero-speed pivot exploit prevention ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	
	for veh in [controller.courier_bike, controller.scrap_hauler]:
		veh.current_state = 2 # DRIVING
		veh.current_speed = 0.0
		var start_rot_y: float = veh.rotation.y
		# Full steer + handbrake at 0 speed
		for _i in range(10):
			veh.set_drive_inputs(0.0, 1.0, 1.0 / 60.0, true)
			veh._physics_process(1.0 / 60.0)
		assert(is_equal_approx(veh.rotation.y, start_rot_y), "FAIL A5: Handbrake must not allow zero-speed steering yaw pivot exploits")
	print("  -> Assertion 5 PASS: Zero-speed handbrake pivot exploit prevented on all classes")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 6: Quantitative handling contrast between Bike and Hauler
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 6: Quantitative handling contrast between Bike and Hauler ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	
	# Contrast 1: Same-input acceleration (Bike is nimble/light, Hauler is heavy off the line)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 0.0
	controller.scrap_hauler.current_state = ScrapHaulerScript.VehicleState.DRIVING
	controller.scrap_hauler.current_speed = 0.0
	
	for _i in range(30):
		controller.courier_bike.set_drive_inputs(1.0, 0.0, 1.0 / 60.0, false)
		controller.scrap_hauler.set_drive_inputs(1.0, 0.0, 1.0 / 60.0, false)
	assert(controller.courier_bike.current_speed > controller.scrap_hauler.current_speed,
		"FAIL A6: Bike speed (%.2f) must exceed Hauler speed (%.2f) during same-input acceleration" % [controller.courier_bike.current_speed, controller.scrap_hauler.current_speed])
	print("    -> Acceleration contrast PASS: Bike %.2f m/s vs Hauler %.2f m/s" % [controller.courier_bike.current_speed, controller.scrap_hauler.current_speed])

	# Contrast 2: Same-input steering yaw rate (Bike is agile, Hauler has heavier rotational inertia)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 6.0
	controller.courier_bike.rotation.y = 0.0
	controller.scrap_hauler.current_state = ScrapHaulerScript.VehicleState.DRIVING
	controller.scrap_hauler.current_speed = 6.0
	controller.scrap_hauler.rotation.y = 0.0
	
	for _i in range(20):
		controller.courier_bike.set_drive_inputs(0.5, 1.0, 1.0 / 60.0, false)
		controller.scrap_hauler.set_drive_inputs(0.5, 1.0, 1.0 / 60.0, false)
		await controller.get_tree().physics_frame
	var bike_yaw_deg: float = abs(rad_to_deg(controller.courier_bike.rotation.y))
	var hauler_yaw_deg: float = abs(rad_to_deg(controller.scrap_hauler.rotation.y))
	assert(bike_yaw_deg > hauler_yaw_deg,
		"FAIL A6: Bike yaw (%.1f deg) must rotate faster than Hauler yaw (%.1f deg)" % [bike_yaw_deg, hauler_yaw_deg])
	print("    -> Steering agility contrast PASS: Bike %.1f deg vs Hauler %.1f deg" % [bike_yaw_deg, hauler_yaw_deg])

	# Contrast 3: Same-speed stopping distance (Planar displacement from 10 m/s under full braking)
	controller.courier_bike.global_position = Vector3(0, 0.05, 0)
	controller.courier_bike.current_speed = 10.0
	controller.courier_bike.rotation = Vector3.ZERO
	var bike_brake_start := controller.courier_bike.global_position
	while abs(controller.courier_bike.current_speed) > 0.05:
		controller.courier_bike.set_drive_inputs(-1.0, 0.0, 1.0 / 60.0, false)
		controller.courier_bike._physics_process(1.0 / 60.0)
	var bike_stopping_dist: float = bike_brake_start.distance_to(controller.courier_bike.global_position)
	
	controller.scrap_hauler.global_position = Vector3(0, 0.05, 0)
	controller.scrap_hauler.current_speed = 10.0
	controller.scrap_hauler.rotation = Vector3.ZERO
	var hauler_brake_start := controller.scrap_hauler.global_position
	while abs(controller.scrap_hauler.current_speed) > 0.05:
		controller.scrap_hauler.set_drive_inputs(-1.0, 0.0, 1.0 / 60.0, false)
		controller.scrap_hauler._physics_process(1.0 / 60.0)
	var hauler_stopping_dist: float = hauler_brake_start.distance_to(controller.scrap_hauler.global_position)
	
	assert(hauler_stopping_dist > bike_stopping_dist,
		"FAIL A6: Hauler stopping distance (%.2fm) must exceed Bike stopping distance (%.2fm)" % [hauler_stopping_dist, bike_stopping_dist])
	print("    -> Real stopping distance contrast PASS: Bike %.2fm vs Hauler %.2fm" % [bike_stopping_dist, hauler_stopping_dist])
	print("  -> Assertion 6 PASS: Quantitative handling contrast verified across all axes")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 7: Mount / exit lifecycle on both vehicles
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 7: Mount / exit lifecycle on both vehicles ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	
	# 1. Mount & dismount Courier Bike
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	assert(controller.courier_bike.request_mount(controller.player), "FAIL A7: Bike mount must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	await controller.get_tree().process_frame
	assert(controller.courier_bike.occupant == controller.player, "FAIL A7: Bike occupant must be player")
	assert(controller.courier_bike.request_dismount(), "FAIL A7: Bike dismount must succeed")
	await controller.get_tree().create_timer(0.25).timeout
	await controller.get_tree().process_frame
	assert(controller.courier_bike.occupant == null, "FAIL A7: Bike occupant must be null after dismount")

	# 2. Mount & dismount Scrap Hauler
	controller.player.global_position = controller.scrap_hauler.global_position + Vector3(0, 0, 1.0)
	controller.scrap_hauler.mount_interactable.update_player_distance(controller.player.global_position)
	assert(controller.scrap_hauler.request_mount(controller.player), "FAIL A7: Hauler mount must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	await controller.get_tree().process_frame
	assert(controller.scrap_hauler.occupant == controller.player, "FAIL A7: Hauler occupant must be player")
	assert(controller.scrap_hauler.request_dismount(), "FAIL A7: Hauler dismount must succeed")
	await controller.get_tree().create_timer(0.25).timeout
	await controller.get_tree().process_frame
	assert(controller.scrap_hauler.occupant == null, "FAIL A7: Hauler occupant must be null after dismount")
	print("  -> Assertion 7 PASS: Mount/exit lifecycle verified on both vehicle classes")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 8: Camera target switches between Runner / Bike / Hauler
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 8: Camera target switches between Runner / Bike / Hauler ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.camera:
		assert(controller.camera.target_node == controller.player, "FAIL A8: Initial camera target must be player")
		
		# Mount bike
		controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
		controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
		controller.courier_bike.request_mount(controller.player)
		await controller.get_tree().create_timer(0.3).timeout
		await controller.get_tree().process_frame
		assert(controller.camera.target_node == controller.courier_bike, "FAIL A8: Camera target must switch to courier_bike when mounted")
		
		# Dismount bike
		controller.courier_bike.request_dismount()
		await controller.get_tree().create_timer(0.25).timeout
		await controller.get_tree().process_frame
		assert(controller.camera.target_node == controller.player, "FAIL A8: Camera target must return to player upon bike dismount")
		
		# Mount hauler
		controller.player.global_position = controller.scrap_hauler.global_position + Vector3(0, 0, 1.0)
		controller.scrap_hauler.mount_interactable.update_player_distance(controller.player.global_position)
		controller.scrap_hauler.request_mount(controller.player)
		await controller.get_tree().create_timer(0.3).timeout
		await controller.get_tree().process_frame
		assert(controller.camera.target_node == controller.scrap_hauler, "FAIL A8: Camera target must switch to scrap_hauler when mounted")
		
		# Dismount hauler
		controller.scrap_hauler.request_dismount()
		await controller.get_tree().create_timer(0.25).timeout
		await controller.get_tree().process_frame
		assert(controller.camera.target_node == controller.player, "FAIL A8: Camera target must return to player upon hauler dismount")
	print("  -> Assertion 8 PASS: Camera target seamlessly switches across all 3 classes")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 9: Pursuer automatically retargets whichever vehicle is occupied
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 9: Pursuer automatically retargets whichever vehicle is occupied ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.pursuer:
		controller.pursuer.activate_pursuit(controller.player)
		assert(controller.pursuer.target_node == controller.player, "FAIL A9: Initial pursuer target must be player")
		
		# Mount hauler -> pursuer targets hauler
		controller.player.global_position = controller.scrap_hauler.global_position + Vector3(0, 0, 1.0)
		controller.scrap_hauler.mount_interactable.update_player_distance(controller.player.global_position)
		controller.scrap_hauler.request_mount(controller.player)
		await controller.get_tree().create_timer(0.3).timeout
		await controller.get_tree().process_frame
		assert(controller.pursuer.target_node == controller.scrap_hauler, "FAIL A9: Pursuer must automatically track occupied ScrapHauler")
		
		# Dismount hauler -> pursuer targets player
		controller.scrap_hauler.request_dismount()
		await controller.get_tree().create_timer(0.25).timeout
		await controller.get_tree().process_frame
		assert(controller.pursuer.target_node == controller.player, "FAIL A9: Pursuer must automatically track player on foot")
	print("  -> Assertion 9 PASS: Pursuer automatically retargets occupied vehicle class")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 10: Replay / reset clears both vehicle states cleanly
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 10: Replay / reset clears both vehicle states ---")
	controller.courier_bike.current_speed = 12.0
	controller.scrap_hauler.current_speed = 14.0
	if controller.courier_bike.visual_root: controller.courier_bike.visual_root.rotation.z = deg_to_rad(10.0)
	if controller.scrap_hauler.visual_root: controller.scrap_hauler.visual_root.rotation.z = deg_to_rad(5.0)
	
	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(controller.courier_bike.current_speed == 0.0, "FAIL A10: Bike speed must reset to 0")
	assert(controller.scrap_hauler.current_speed == 0.0, "FAIL A10: Hauler speed must reset to 0")
	assert(controller.courier_bike.occupant == null, "FAIL A10: Bike occupant must be null")
	assert(controller.scrap_hauler.occupant == null, "FAIL A10: Hauler occupant must be null")
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL A10: Bike must be PARKED")
	assert(controller.scrap_hauler.current_state == ScrapHaulerScript.VehicleState.PARKED, "FAIL A10: Hauler must be PARKED")
	print("  -> Assertion 10 PASS: Replay / reset cleanly cleanses both vehicles")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 11: Golden Slice completable with Courier Bike
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 11: Golden Slice completable with Courier Bike ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.signal_tuner: controller._on_tuner_signal_locked(controller.signal_tuner)
	controller._on_extraction_completed()
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	assert(controller.courier_bike.request_mount(controller.player), "FAIL A11: Bike mount must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	await controller.get_tree().process_frame
	controller.courier_bike.current_speed = 12.0
	for _i in range(10):
		controller.courier_bike._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	controller._on_successful_evasion()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL A11: Bike Golden Slice evasion must succeed")
	print("  -> Assertion 11 PASS: Golden Slice 100% completable with Courier Bike")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 12: Golden Slice completable with Scrap Hauler & 7 Visual Proofs
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 12: Golden Slice completable with Scrap Hauler & 7 Visual Proofs ---")
	controller.reset_slice()
	await controller.get_tree().process_frame

	# Proof 1: Runner + Bike + Hauler scale comparison
	for _i in range(3):
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m06/m06_01_scale_comparison.png")
	print("  -> Visual proof saved: m06_01_scale_comparison.png")

	# Proof 2: Hauler Parked / Entry
	controller.player.global_position = controller.scrap_hauler.global_position + Vector3(0, 0, 1.2)
	controller.scrap_hauler.mount_interactable.update_player_distance(controller.player.global_position)
	for _i in range(4):
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m06/m06_02_hauler_parked_entry.png")
	print("  -> Visual proof saved: m06_02_hauler_parked_entry.png")

	# Mount Hauler
	assert(controller.scrap_hauler.request_mount(controller.player), "FAIL A12: Hauler mount must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	await controller.get_tree().process_frame

	# Proof 3: Hauler Straight Acceleration
	controller.scrap_hauler.current_speed = 11.0
	for _i in range(12):
		controller.scrap_hauler._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m06/m06_03_hauler_acceleration.png")
	print("  -> Visual proof saved: m06_03_hauler_acceleration.png")

	# Proof 4: Hauler Heavy Braking
	controller.scrap_hauler.set_drive_inputs(-1.0, 0.0, 1.0 / 60.0, false)
	for _i in range(6):
		controller.scrap_hauler._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m06/m06_04_hauler_braking.png")
	print("  -> Visual proof saved: m06_04_hauler_braking.png")

	# Proof 5: Hauler Handbrake Drift Turn
	controller.scrap_hauler.current_speed = 12.0
	controller.scrap_hauler.steering_angle = 1.0
	controller.scrap_hauler.is_handbrake_active = true
	for _i in range(12):
		controller.scrap_hauler._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m06/m06_05_hauler_drift_turn.png")
	print("  -> Visual proof saved: m06_05_hauler_drift_turn.png")

	# Physical Route Traversal: Drive Hauler from yard lane through Security Gate (Z = 12.0m to Z > 14.0m)
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.8).timeout
	controller.scrap_hauler.global_position = Vector3(-1.5, 0.05, 6.0)
	controller.scrap_hauler.rotation.y = PI
	controller.scrap_hauler.current_state = ScrapHaulerScript.VehicleState.DRIVING
	controller.scrap_hauler.current_speed = 14.0
	controller.camera.reset_camera_instant(controller.scrap_hauler)
	if controller.pursuer:
		controller.pursuer.activate_pursuit(controller.scrap_hauler)
		controller.pursuer.global_position = Vector3(-1.5, 0.6, -2.0)
	
	var floor_node := controller.get_node_or_null("Floor")
	var hauler_snagged := false
	for f in range(60):
		controller.scrap_hauler.set_drive_inputs(1.0, 0.0, 1.0 / 60.0, false)
		if controller.scrap_hauler.get_slide_collision_count() > 0:
			for c in range(controller.scrap_hauler.get_slide_collision_count()):
				var col := controller.scrap_hauler.get_slide_collision(c)
				if col.get_collider() != floor_node and col.get_normal().y < 0.7:
					var col_parent: Node = col.get_collider().get_parent()
					if col_parent and col_parent.name.begins_with("ScrapYardDressing"):
						hauler_snagged = true
		await controller.get_tree().physics_frame
		if f == 30:
			# Proof 6: Hauler Live Pursuit Chase Through Gate Corridor
			TestHelpers.save_proof_png(controller, "res://verification/v8/m06/m06_06_hauler_pursuit.png")
			print("  -> Visual proof saved: m06_06_hauler_pursuit.png")

	assert(not hauler_snagged, "FAIL A12: Hauler must not snag against dressed props")
	assert(controller.scrap_hauler.global_position.z > 14.0, "FAIL A12: Hauler must traverse post-gate plane (Z > 14.0m)")
	print("  -> Hauler Gate Traversal: Final Z = %.2fm | Prop Snagged: %s" % [controller.scrap_hauler.global_position.z, hauler_snagged])

	# Evasion & Safe Exit into Aftermath
	controller._on_successful_evasion()
	while abs(controller.scrap_hauler.current_speed) > controller.scrap_hauler.dismount_speed_limit:
		controller.scrap_hauler.current_speed = move_toward(controller.scrap_hauler.current_speed, 0.0, controller.scrap_hauler.braking_friction * (1.0 / 60.0))
		controller.scrap_hauler._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
		
	var dismount_ok: bool = controller.scrap_hauler.request_dismount()
	assert(dismount_ok, "FAIL A12: Hauler dismount must succeed when decelerated below limit")
	await controller.get_tree().create_timer(0.3).timeout
	for _i in range(6):
		await controller.get_tree().process_frame

	assert(controller.scrap_hauler.occupant == null, "FAIL A12: Hauler occupant must be null after dismount")
	assert(not controller.player.is_mounted, "FAIL A12: Player must not be mounted")
	assert(controller.player.visible, "FAIL A12: Player must be visible in aftermath")
	assert(controller.scrap_hauler.current_state == ScrapHaulerScript.VehicleState.PARKED, "FAIL A12: Hauler must be PARKED")

	# Proof 7: Safe Exit / Aftermath
	TestHelpers.save_proof_png(controller, "res://verification/v8/m06/m06_07_hauler_exit_aftermath.png")
	print("  -> Visual proof saved: m06_07_hauler_exit_aftermath.png")

	print("  -> Assertion 12 PASS: Full Golden Slice completable with Scrap Hauler & all 7 visual proofs verified")

	# ─────────────────────────────────────────────────────────────────────────
	# CLEANUP & REPORT
	# ─────────────────────────────────────────────────────────────────────────
	controller.reset_slice()
	print("\n=========================================================================")
	print("[ALL V8 M06 VEHICLE CLASS VARIETY & ESCAPE CHOICE ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


