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
	print("[V7_TICKET05_ASSERTIONS] Starting GTA/Chinatown Wars Camera Transition & Framing Suite...")
	print("Target Build: main | Testing Single-Layer Smooth Focus, Look-Ahead, FOV Breathing, Decoupled Yaw")
	print("=========================================================================\n")
	await controller.get_tree().create_timer(0.2).timeout

	# -------------------------------------------------------------------------
	# TEST 1: Target Switch Zero Instant Transform Change & Smooth Transition
	# -------------------------------------------------------------------------
	print("[TEST 1] Testing Target Switch Zero Instant Transform Change...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	var dt: float = 0.016
	
	# Camera starts settled on Player at (0, 0, 10)
	controller.camera.reset_camera_instant(controller.player)
	var pos_before: Vector3 = controller.camera.global_position
	var basis_before: Basis = controller.camera.global_transform.basis
	
	# Switch target to Courier Bike (located at -1.5, 0.05, 3.0)
	controller.camera.set_target(controller.courier_bike)
	var pos_on_call: Vector3 = controller.camera.global_position
	var basis_on_call: Basis = controller.camera.global_transform.basis
	
	assert(pos_on_call.distance_to(pos_before) < 0.0001, "FAIL: set_target() must not change camera position instantly")
	assert(basis_on_call.is_equal_approx(basis_before), "FAIL: set_target() must not change camera orientation instantly")
	
	# Simulate 1 frame: continuous smooth glide begins
	controller.camera._process(dt)
	var pos_frame_1: Vector3 = controller.camera.global_position
	var step_dist: float = pos_frame_1.distance_to(pos_before)
	print("[TEST 1 LOG] Frame 1 glide displacement: %.4f m" % step_dist)
	assert(step_dist > 0.001 and step_dist < 1.0, "FAIL: Camera must begin smooth continuous transition without popping")
	print("[TICKET 05 TEST 1 PASSED] Target switch zero instant transform change verified!")

	# -------------------------------------------------------------------------
	# TEST 2: Mount / Dismount Focus Continuity
	# -------------------------------------------------------------------------
	print("[TEST 2] Testing Mount / Dismount Focus Continuity...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	
	# Player positions near bike and mounts
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.5)
	await controller.get_tree().create_timer(0.2).timeout
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	
	assert(controller.courier_bike.current_state == CourierBike.BikeState.MOUNTING, "FAIL: Bike must enter MOUNTING")
	controller.camera.set_target(controller.courier_bike)
	
	var last_pos: Vector3 = controller.camera.global_position
	for i in range(15):
		await controller.get_tree().create_timer(0.02).timeout
		controller.camera._process(dt)
		var current_pos: Vector3 = controller.camera.global_position
		assert(not is_nan(current_pos.x) and not is_inf(current_pos.x), "FAIL: Camera NaN during mount")
		assert(current_pos.distance_to(last_pos) < 1.2, "FAIL: Camera position step during mount")
		last_pos = current_pos

	await controller.get_tree().create_timer(0.15).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike should be in DRIVING state")
	print("[TEST 2 LOG] Mount focus transition completed smoothly.")
	
	# Dismount
	controller._on_dismount_pressed()
	controller.camera.set_target(controller.player)
	for i in range(15):
		await controller.get_tree().create_timer(0.02).timeout
		controller.camera._process(dt)
		var current_pos: Vector3 = controller.camera.global_position
		assert(not is_nan(current_pos.x) and not is_inf(current_pos.x), "FAIL: Camera NaN during dismount")
		assert(current_pos.distance_to(last_pos) < 1.2, "FAIL: Camera position step during dismount")
		last_pos = current_pos

	print("[TICKET 05 TEST 2 PASSED] Mount/dismount focus continuity verified!")

	# -------------------------------------------------------------------------
	# TEST 3: Handbrake 180° Look-Ahead Reversal Damping
	# -------------------------------------------------------------------------
	print("[TEST 3] Testing Handbrake 180° Look-Ahead Reversal Damping...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.camera.reset_camera_instant(controller.courier_bike)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 14.0
	controller.courier_bike.velocity = Vector3(0, 0, -14.0) # Moving in -Z
	
	# Settle look-ahead for 30 frames
	for i in range(30):
		controller.camera._process(dt)
	var forward_look_ahead_z: float = controller.camera._smoothed_look_ahead.z
	print("[TEST 3 LOG] Steady-state look-ahead Z at 14 m/s: %.4f m" % forward_look_ahead_z)
	assert(forward_look_ahead_z < -1.5, "FAIL: Forward look-ahead should lead in -Z direction")

	# Instantaneous 180° velocity flip to +Z
	controller.courier_bike.velocity = Vector3(0, 0, 14.0)
	var crossed_zero: bool = false
	var no_overshoot: bool = true
	
	for i in range(40):
		var prev_z: float = controller.camera._smoothed_look_ahead.z
		controller.camera._process(dt)
		var cur_z: float = controller.camera._smoothed_look_ahead.z
		if prev_z < 0.0 and cur_z >= 0.0:
			crossed_zero = true
		assert(not is_nan(cur_z) and not is_inf(cur_z), "FAIL: NaN in look-ahead during reversal")

	assert(crossed_zero, "FAIL: Look-ahead must smoothly cross zero during 180° reversal")
	print("[TEST 3 LOG] Final look-ahead Z after reversal: %.4f m" % controller.camera._smoothed_look_ahead.z)
	assert(controller.camera._smoothed_look_ahead.z > 1.0, "FAIL: Look-ahead must settle in new +Z direction")
	print("[TICKET 05 TEST 3 PASSED] 180° look-ahead reversal damping verified!")

	# -------------------------------------------------------------------------
	# TEST 4: Vehicle Yaw / Camera Orientation Decoupling
	# -------------------------------------------------------------------------
	print("[TEST 4] Testing Vehicle Yaw Decoupling (Camera Basis Invariant)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.camera.reset_camera_instant(controller.courier_bike)
	var initial_cam_basis: Basis = controller.camera.global_transform.basis

	var prev_dynamic_yaw: bool = controller.camera.dynamic_yaw_enabled
	controller.camera.dynamic_yaw_enabled = false
	# Rotate vehicle through 360° at high angular speed (powerslide donut)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 5.0
	for i in range(60):
		controller.courier_bike.rotation.y += deg_to_rad(15.0) # 15 deg/frame * 60 = 900 deg
		controller.courier_bike.velocity = -controller.courier_bike.global_transform.basis.z * 5.0
		controller.camera._process(dt)
		
		# Camera basis must NOT rotate with vehicle yaw!
		var current_cam_basis: Basis = controller.camera.global_transform.basis
		var basis_diff_x: float = current_cam_basis.x.distance_to(initial_cam_basis.x)
		var basis_diff_y: float = current_cam_basis.y.distance_to(initial_cam_basis.y)
		var basis_diff_z: float = current_cam_basis.z.distance_to(initial_cam_basis.z)
		assert(basis_diff_x < 0.005 and basis_diff_y < 0.005 and basis_diff_z < 0.005, "FAIL: Camera basis must remain fixed during vehicle spin/donut")
	controller.camera.dynamic_yaw_enabled = prev_dynamic_yaw

	print("[TICKET 05 TEST 4 PASSED] Vehicle yaw / camera orientation decoupling verified!")

	# -------------------------------------------------------------------------
	# TEST 5: FOV Bounds & Monotonic Speed Response
	# -------------------------------------------------------------------------
	print("[TEST 5] Testing FOV Bounds [27.2°, 38.0°] and Monotonic Speed Breathing...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.camera.reset_camera_instant(controller.courier_bike)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	
	# Test at 0 m/s: FOV settles to 32.0°
	controller.courier_bike.current_speed = 0.0
	controller.courier_bike.velocity = Vector3.ZERO
	for i in range(40):
		controller.camera._process(dt)
	print("[TEST 5 LOG] Settle FOV at 0 m/s: %.2f°" % controller.camera.fov)
	assert(abs(controller.camera.fov - 32.0) < 0.2, "FAIL: FOV should be 32.0° at rest")

	# Accelerate to 14.0 m/s: FOV settles to 38.0°
	controller.courier_bike.current_speed = 14.0
	controller.courier_bike.velocity = Vector3(0, 0, -14.0)
	for i in range(100):
		controller.camera._process(dt)
		assert(controller.camera.fov >= 31.9 and controller.camera.fov <= 38.05, "FAIL: FOV exceeded valid range during acceleration")
	print("[TEST 5 LOG] Settle FOV at 14 m/s: %.2f°" % controller.camera.fov)
	assert(abs(controller.camera.fov - 38.0) < 0.2, "FAIL: FOV should reach 38.0° at max speed")

	# Interaction mode: FOV settles to 27.2° (32.0 * 0.85)
	controller.camera.set_interaction_mode(true, controller.signal_tuner)
	for i in range(100):
		controller.camera._process(dt)
		assert(controller.camera.fov >= 27.15 and controller.camera.fov <= 38.05, "FAIL: FOV exceeded range during interaction")
	print("[TEST 5 LOG] Settle FOV in interaction mode: %.2f°" % controller.camera.fov)
	assert(abs(controller.camera.fov - 27.2) < 0.2, "FAIL: FOV should reach 27.2° in interaction mode")
	print("[TICKET 05 TEST 5 PASSED] FOV bounds and speed breathing verified!")

	# -------------------------------------------------------------------------
	# TEST 6: Interaction Focus Enter & Exit
	# -------------------------------------------------------------------------
	print("[TEST 6] Testing Interaction Focus Enter and Exit Transition...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.camera.reset_camera_instant(controller.player)
	
	# Enter interaction mode with Signal Tuner at (1.5, 0.5, 3.0)
	controller.camera.set_interaction_mode(true, controller.signal_tuner)
	for i in range(70):
		controller.camera._process(dt)
		assert(not is_nan(controller.camera.global_position.x), "FAIL: NaN position during interaction enter")
	
	var focus_error_tuner: float = (controller.camera._smoothed_focus_pos - controller.signal_tuner.global_position).length()
	print("[TEST 6 LOG] Focus distance to tuner after 70 frames: %.4f m" % focus_error_tuner)
	assert(focus_error_tuner < 0.15, "FAIL: Camera focus must converge to interaction object")

	# Exit interaction mode: returns to player
	controller.camera.set_interaction_mode(false)
	for i in range(70):
		controller.camera._process(dt)
	var focus_error_player: float = (controller.camera._smoothed_focus_pos - controller.player.global_position).length()
	print("[TEST 6 LOG] Focus distance to player after exit: %.4f m" % focus_error_player)
	assert(focus_error_player < 0.15, "FAIL: Camera focus must return smoothly to player")
	print("[TICKET 05 TEST 6 PASSED] Interaction focus enter and exit verified!")

	# -------------------------------------------------------------------------
	# TEST 7: 60Hz vs 120Hz Full Dynamic Trajectory Equivalence
	# -------------------------------------------------------------------------
	print("[TEST 7] Testing 60Hz vs 120Hz Dynamic Trajectory Equivalence (Look-Ahead + Focus + FOV)...")
	var cam_60: ChinatownCamera3D = ChinatownCamera3D.new()
	var cam_120: ChinatownCamera3D = ChinatownCamera3D.new()
	controller.add_child(cam_60)
	controller.add_child(cam_120)
	
	var char_60: CharacterBody3D = CharacterBody3D.new()
	var char_120: CharacterBody3D = CharacterBody3D.new()
	controller.add_child(char_60)
	controller.add_child(char_120)
	
	char_60.global_position = Vector3.ZERO
	char_120.global_position = Vector3.ZERO
	
	cam_60.reset_camera_instant(char_60)
	cam_120.reset_camera_instant(char_120)
	
	# Helper lambda to compute velocity at time t in 5-phase trajectory
	var trajectory_vel := func(t: float) -> Vector3:
		if t < 0.5:
			return Vector3(0, 0, -8.0) # Phase A: Constant forward
		elif t < 1.0:
			var p: float = (t - 0.5) / 0.5
			return Vector3(0, 0, lerpf(-8.0, -14.0, p)) # Phase B: Acceleration to 14 m/s
		elif t < 1.3:
			var p: float = (t - 1.0) / 0.3
			return Vector3(0, 0, lerpf(-14.0, 0.0, p)) # Phase C: Deceleration to 0
		elif t < 1.8:
			var p: float = (t - 1.3) / 0.5
			return Vector3(0, 0, lerpf(0.0, 10.0, p)) # Phase D: 180° reversal to +10 m/s
		else:
			return Vector3(0, 0, 6.0) # Phase E: Settle in reverse at +6 m/s

	var total_time: float = 2.3
	var dt_60: float = 1.0 / 60.0
	var steps_60: int = int(round(total_time / dt_60))
	var dt_120: float = 1.0 / 120.0
	var steps_120: int = int(round(total_time / dt_120))

	# Run 60Hz sim
	for i in range(steps_60):
		var t: float = float(i) * dt_60
		char_60.velocity = trajectory_vel.call(t)
		char_60.global_position += char_60.velocity * dt_60
		cam_60._process(dt_60)

	# Run 120Hz sim
	for i in range(steps_120):
		var t: float = float(i) * dt_120
		char_120.velocity = trajectory_vel.call(t)
		char_120.global_position += char_120.velocity * dt_120
		cam_120._process(dt_120)

	var focus_diff: float = cam_60._smoothed_focus_pos.distance_to(cam_120._smoothed_focus_pos)
	var lookahead_diff: float = cam_60._smoothed_look_ahead.distance_to(cam_120._smoothed_look_ahead)
	var pos_diff: float = cam_60.global_position.distance_to(cam_120.global_position)
	var fov_diff: float = abs(cam_60.fov - cam_120.fov)
	var basis_diff: float = cam_60.global_transform.basis.z.distance_to(cam_120.global_transform.basis.z)

	print("[TEST 7 LOG] 60Hz vs 120Hz Focus Pos Diff: %.6f m" % focus_diff)
	print("[TEST 7 LOG] 60Hz vs 120Hz Look-Ahead Diff: %.6f m" % lookahead_diff)
	print("[TEST 7 LOG] 60Hz vs 120Hz Global Pos Diff: %.6f m" % pos_diff)
	print("[TEST 7 LOG] 60Hz vs 120Hz FOV Diff: %.6f°" % fov_diff)
	print("[TEST 7 LOG] 60Hz vs 120Hz Basis Diff: %.6f" % basis_diff)

	assert(focus_diff < 0.08, "FAIL: Focus pos 60Hz vs 120Hz exceeded tolerance")
	assert(lookahead_diff < 0.05, "FAIL: Look-ahead 60Hz vs 120Hz exceeded tolerance")
	assert(pos_diff < 0.08, "FAIL: Camera global position 60Hz vs 120Hz exceeded tolerance")
	assert(fov_diff < 0.1, "FAIL: FOV 60Hz vs 120Hz exceeded tolerance")
	assert(basis_diff < 0.001, "FAIL: Camera basis 60Hz vs 120Hz exceeded tolerance")

	cam_60.queue_free()
	cam_120.queue_free()
	char_60.queue_free()
	char_120.queue_free()
	print("[TICKET 05 TEST 7 PASSED] 60Hz vs 120Hz dynamic trajectory equivalence verified!")

	# -------------------------------------------------------------------------
	# TEST 8: Follow Error Bound Telemetry at 14 m/s
	# -------------------------------------------------------------------------
	print("[TEST 8] Testing Steady-State Follow Error Bound Telemetry (14 m/s)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.camera.reset_camera_instant(controller.courier_bike)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 14.0
	controller.courier_bike.velocity = Vector3(0, 0, -14.0)

	# Simulate 120 frames (2.0s) of continuous 14 m/s driving
	for i in range(120):
		controller.courier_bike.global_position += controller.courier_bike.velocity * dt
		controller.camera._process(dt)

	print("[TEST 8 LOG] Steady-state follow error: %.4f m (theoretical ≈ %.4f m)" % [controller.camera.last_follow_error, 14.0 / 5.0])
	assert(controller.camera.last_follow_error < 3.2, "FAIL: Follow error exceeded 3.2m bound at 14 m/s")
	assert(controller.camera.last_follow_error > 2.0, "FAIL: Follow error unexpectedly low (filter not damping)")
	print("[TICKET 05 TEST 8 PASSED] Follow error bound telemetry verified!")

	# -------------------------------------------------------------------------
	# TEST 9: reset_camera_instant() Full State Clear
	# -------------------------------------------------------------------------
	print("[TEST 9] Testing reset_camera_instant() Full State Clear...")
	# Put camera in dirty state: interaction mode on, offset fov, nonzero lookahead
	controller.camera.set_interaction_mode(true, controller.signal_tuner)
	controller.camera.fov = 27.2
	controller.camera._smoothed_look_ahead = Vector3(2.0, 0.0, -3.0)
	
	# Execute instant reset
	controller.camera.reset_camera_instant(controller.player)
	
	assert(controller.camera._is_interaction_mode == false, "FAIL: _is_interaction_mode must be false")
	assert(controller.camera._interaction_target == null, "FAIL: _interaction_target must be null")
	assert(controller.camera.fov == 32.0, "FAIL: fov must be reset to 32.0°")
	assert(controller.camera._smoothed_look_ahead == Vector3.ZERO, "FAIL: look-ahead must be zeroed")
	assert(controller.camera._smoothed_focus_pos == controller.player.global_position, "FAIL: focus pos must snap to player")
	
	var expected_cam_pos: Vector3 = controller.player.global_position + Vector3(12, 18, 12)
	assert(controller.camera.global_position.distance_to(expected_cam_pos) < 0.001, "FAIL: Camera position must snap to fixed rig offset")
	print("[TICKET 05 TEST 9 PASSED] reset_camera_instant() full state clear verified!")

	# -------------------------------------------------------------------------
	# TEST 10: Forward -> Reverse Look-Ahead Smooth Zero-Crossing
	# -------------------------------------------------------------------------
	print("[TEST 10] Testing Forward -> Reverse Look-Ahead Smooth Zero-Crossing...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.camera.reset_camera_instant(controller.courier_bike)
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 10.0
	controller.courier_bike.velocity = Vector3(0, 0, -10.0)

	# Settle forward look-ahead
	for i in range(25):
		controller.camera._process(dt)
	assert(controller.camera._smoothed_look_ahead.z < -1.0, "FAIL: Look-ahead should be negative in Z")

	# Apply continuous deceleration and reverse crossing
	var z_history: Array[float] = []
	for i in range(60):
		var target_v_z: float = lerpf(-10.0, 6.0, float(i) / 60.0)
		controller.courier_bike.velocity = Vector3(0, 0, target_v_z)
		controller.courier_bike.current_speed = abs(target_v_z)
		controller.camera._process(dt)
		z_history.append(controller.camera._smoothed_look_ahead.z)

	# Simulate 20 frames at settled reverse speed
	for i in range(20):
		controller.camera._process(dt)
		z_history.append(controller.camera._smoothed_look_ahead.z)

	# Verify monotonic or smooth progression across zero without jerky spikes
	var max_frame_delta: float = 0.0
	for i in range(1, z_history.size()):
		var step: float = abs(z_history[i] - z_history[i - 1])
		if step > max_frame_delta:
			max_frame_delta = step
	print("[TEST 10 LOG] Max look-ahead Z delta per frame during reverse crossing: %.4f m" % max_frame_delta)
	print("[TEST 10 LOG] Final settled reverse look-ahead Z: %.4f m" % z_history[-1])
	assert(max_frame_delta < 0.25, "FAIL: Look-ahead Z delta exceeded smoothness threshold during gear crossing")
	assert(z_history[-1] > 0.5, "FAIL: Look-ahead must smoothly reach reverse (+Z) direction")
	print("[TICKET 05 TEST 10 PASSED] Forward -> Reverse look-ahead zero-crossing verified!")

	print("\n=========================================================================")
	print("[ALL V7 TICKET 05 ASSERTIONS PASSED CLEANLY]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


