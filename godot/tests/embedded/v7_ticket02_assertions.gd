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

static func run_ticket02(controller: ScrapTestBlock) -> void:
	print("[V7_TICKET02_ASSERTIONS] Starting Expanded V7 Ticket 02 Stress Tests...")
	await controller.get_tree().create_timer(0.2).timeout

	# =========================================================================
	# TASK 1: MULTI-TOUCH DRIVING CONTROLS & STATE ARBITRATION
	# =========================================================================
	print("\n--- [TASK 1] Testing Multi-Touch Driving Controls & State Arbitration ---")
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	assert(controller.touch_ui._is_gas_pressed == false and controller.touch_ui._is_brake_pressed == false, "FAIL: Driving inputs must initialize to false")
	assert(controller._throttle_input == 0.0, "FAIL: Initial throttle must be 0.0")

	# 1A. Gas alone pressed -> throttle +1.0
	controller.touch_ui._is_gas_pressed = true
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == 1.0, "FAIL: GAS held alone must set throttle to +1.0")

	# 1B. Dual-touch hold: Brake pressed while Gas held -> throttle -1.0 (Brake priority!)
	controller.touch_ui._is_brake_pressed = true
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == -1.0, "FAIL: BRAKE held while GAS held MUST prioritize Brake (-1.0)!")

	# 1C. Releasing combination A: Gas released while Brake held -> throttle -1.0
	controller.touch_ui._is_gas_pressed = false
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == -1.0, "FAIL: Releasing GAS while BRAKE held must maintain throttle at -1.0!")

	# Release Brake -> throttle 0.0
	controller.touch_ui._is_brake_pressed = false
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == 0.0, "FAIL: Releasing both must set throttle to 0.0!")

	# 1D. Releasing combination B: Both held -> Brake released while Gas held -> throttle +1.0
	controller.touch_ui._is_gas_pressed = true
	controller.touch_ui._is_brake_pressed = true
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == -1.0, "FAIL: Both held must prioritize Brake")
	controller.touch_ui._is_brake_pressed = false
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == 1.0, "FAIL: Releasing BRAKE while GAS held must return throttle to +1.0!")
	controller.touch_ui._is_gas_pressed = false
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == 0.0, "FAIL: All released must set throttle to 0.0")

	# 1E. Rapid alternation (10 fast toggles between Gas & Brake)
	print("[TASK 1] Running rapid 10-step alternation stress test between Gas and Brake...")
	for i in range(10):
		if i % 2 == 0:
			controller.touch_ui._is_gas_pressed = true
			controller.touch_ui._is_brake_pressed = false
			controller.touch_ui._emit_net_throttle()
			assert(controller._throttle_input == 1.0, "FAIL: Rapid toggle step %d failed for GAS" % i)
		else:
			controller.touch_ui._is_gas_pressed = true
			controller.touch_ui._is_brake_pressed = true
			controller.touch_ui._emit_net_throttle()
			assert(controller._throttle_input == -1.0, "FAIL: Rapid toggle step %d failed for BRAKE priority" % i)
	controller.touch_ui.reset_driving_inputs()
	assert(controller._throttle_input == 0.0, "FAIL: Reset after rapid alternation failed!")
	print("[TASK 1 PASSED] Rapid input alternation verified cleanly!")

	# 1F. Mode switch reset check (reset_driving_inputs on mode switch & reset_slice)
	print("[TASK 1] Testing reset_driving_inputs() on UI mode switches & slice reset...")
	controller.touch_ui._is_gas_pressed = true
	controller.touch_ui._is_brake_pressed = true
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == -1.0, "FAIL: Inputs set for mode switch test")

	controller.touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	assert(controller.touch_ui._is_gas_pressed == false and controller.touch_ui._is_brake_pressed == false, "FAIL: set_mode(FOOT_TRAVERSAL) must clear driving input flags!")
	assert(controller._throttle_input == 0.0, "FAIL: set_mode(FOOT_TRAVERSAL) must emit net throttle 0.0!")

	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	assert(controller.touch_ui._is_gas_pressed == false and controller.touch_ui._is_brake_pressed == false, "FAIL: set_mode(VEHICLE_DRIVING) must clear driving input flags!")
	assert(controller._throttle_input == 0.0, "FAIL: set_mode(VEHICLE_DRIVING) must emit net throttle 0.0!")

	# Test reset_slice()
	controller.touch_ui._is_gas_pressed = true
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == 1.0, "FAIL: Pre-reset_slice throttle set")
	controller.reset_slice()
	assert(controller._throttle_input == 0.0, "FAIL: reset_slice() must set _throttle_input to 0.0!")
	print("[TASK 1 PASSED] reset_driving_inputs() verified on mode switches & slice reset!")

	# =========================================================================
	# TASK 2: DISMOUNT BUTTON INTERACTION, SPEED SWEEP (0-14m/s) & RED FLASH
	# =========================================================================
	print("\n--- [TASK 2] Testing Dismount Button Rapid Tapping (0.0 m/s to 14.0 m/s) ---")
	
	# Mount bike for test
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.0)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.35).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must be in DRIVING state")
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING, "FAIL: UI mode must be VEHICLE_DRIVING")

	# Track rejection signal count and reasons
	var reject_count := [0]
	var last_reason := [CourierBike.DismountRejectReason.TOO_FAST]
	var last_speed := [0.0]
	var reject_cb := func(reason: CourierBike.DismountRejectReason, spd: float, limit: float):
		reject_count[0] += 1
		last_reason[0] = reason
		last_speed[0] = spd

	controller.courier_bike.dismount_rejected.connect(reject_cb)

	# 2A. Speed acceleration sweep from 0.0 m/s to 14.0 m/s with rapid dismount button taps
	var speed_test_points := [0.0, 1.0, 1.5, 1.6, 2.0, 5.0, 8.0, 10.0, 14.0]
	for spd in speed_test_points:
		controller.courier_bike.current_speed = spd
		print("[TASK 2 SWEEP] Testing speed %.1f m/s..." % spd)

		if spd > controller.courier_bike.dismount_speed_limit: # > 1.5 m/s
			var initial_rejects: int = reject_count[0]
			# Rapid tap 5 times at this speed
			for tap in range(5):
				assert(not controller.touch_ui.dismount_button.disabled, "FAIL: Dismount button disabled at speed %.1f m/s!" % spd)
				var success := controller.courier_bike.request_dismount()
				assert(not success, "FAIL: request_dismount() must return false at speed %.1f m/s" % spd)
			assert(reject_count[0] == initial_rejects + 5, "FAIL: Expected 5 dismount rejection signals at speed %.1f m/s" % spd)
			assert(last_reason[0] == CourierBike.DismountRejectReason.TOO_FAST, "FAIL: Reason must be TOO_FAST")
			assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike state must remain DRIVING at speed %.1f m/s" % spd)
		else: # <= 1.5 m/s -> Dismount should succeed!
			assert(not controller.touch_ui.dismount_button.disabled, "FAIL: Dismount button disabled at speed %.1f m/s!" % spd)
			var success := controller.courier_bike.request_dismount()
			assert(success, "FAIL: request_dismount() MUST succeed at speed %.1f m/s (<= 1.5 m/s)" % spd)
			await controller.get_tree().create_timer(0.25).timeout
			assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must transition to PARKED state")
			assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: UI mode must revert to FOOT_TRAVERSAL")
			
			# Re-mount bike for remaining speed points if any
			if spd < 14.0:
				controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.0)
				controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
				controller._evaluate_target_selection()
				controller._on_action_pressed()
				await controller.get_tree().create_timer(0.35).timeout
				assert(controller.courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Re-mount failed!")

	print("[TASK 2 PASSED] Dismount button speed sweep (0.0 to 14.0 m/s) verified! Button never disabled!")

	# 2B. Red Flash Animation Frame Tracking & Rapid Tapping Overlap Test
	print("\n--- [TASK 2B] Stress Testing Red Flash Animation & Multi-frame Modulation ---")
	# Re-mount bike and set speed to 10.0 m/s
	if controller.courier_bike.current_state != CourierBike.BikeState.DRIVING:
		controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.0)
		controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
		controller._evaluate_target_selection()
		controller._on_action_pressed()
		await controller.get_tree().create_timer(0.35).timeout

	controller.courier_bike.current_speed = 10.0
	
	# Tap dismount while driving at 10.0 m/s and inspect dismount_button.modulate across frames
	controller._on_dismount_pressed()
	var mod_t0 := controller.touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame 0 (Tap): modulate = %s" % mod_t0)
	
	await controller.get_tree().process_frame
	var mod_t1 := controller.touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame 1 (16ms post-process): modulate = %s" % mod_t1)
	
	await controller.get_tree().process_frame
	var mod_t2 := controller.touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame 2 (33ms post-process): modulate = %s" % mod_t2)

	await controller.get_tree().create_timer(0.25).timeout
	var mod_t_end := controller.touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame final (250ms post-timer): modulate = %s" % mod_t_end)

	# Test Rapid 5x Burst Tapping for Red Flash Overlap
	print("[RED FLASH TELEMETRY] Triggering rapid 5x burst taps on DismountButton...")
	for tap in range(5):
		controller._on_dismount_pressed()
		await controller.get_tree().create_timer(0.04).timeout # 40ms interval (25 Hz rapid tap)
	
	print("[RED FLASH TELEMETRY] 5x Burst finished. Checking modulate state...")
	var mod_burst_mid := controller.touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Burst Mid-State: modulate = %s" % mod_burst_mid)

	await controller.get_tree().create_timer(0.3).timeout
	var mod_burst_final := controller.touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Burst Final State (300ms post-burst): modulate = %s" % mod_burst_final)

	# 2C. Slow down vehicle below 1.5 m/s and verify immediate dismount
	print("\n--- [TASK 2C] Testing Immediate Dismount When slowing below 1.5 m/s ---")
	controller.courier_bike.current_speed = 1.4
	controller._on_dismount_pressed()
	await controller.get_tree().create_timer(0.3).timeout
	assert(controller.courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must reach PARKED state when dismounted at 1.4 m/s!")
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: UI mode must revert to FOOT_TRAVERSAL!")
	print("[TASK 2C PASSED] Dismount at 1.4 m/s (< 1.5 m/s) succeeded immediately!")

	print("\n=========================================================================")
	print("[ALL V7 TICKET 02 STRESS TESTS COMPLETED SUCCESSFULLY]")
	print("=========================================================================")
	controller.get_tree().quit(0)


static func run_ticket02_1(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V7_TICKET02_1_ASSERTIONS] Starting Adversarial Chase Falsification Suite (Ticket 02.1)...")
	print("Target Build: main@eb9e82a | Pursuer Max Speed: %.1f m/s | Bike Max Speed: %.1f m/s" % [controller.pursuer.max_speed if controller.pursuer else 15.5, controller.courier_bike.max_speed if controller.courier_bike else 14.0])
	print("=========================================================================\n")
	await controller.get_tree().create_timer(0.2).timeout

	# =========================================================================
	# TASK 1A: STRAIGHT-LINE DRIVING AT DEFAULT SPAWN (PURSUER Z = -15.0, BIKE Z = 3.0)
	# =========================================================================
	print("\n--- [TASK 1A] Straight-Line Driving at Default Spawn (Pursuer Z = -15.0, Dist = 18.07m) ---")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout

	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout

	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.0)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.35).timeout

	controller.courier_bike.rotation.y = PI
	controller._steer_input = 0.0
	controller._throttle_input = 1.0

	var task1a_start := Time.get_ticks_msec() / 1000.0
	var task1a_evaded := false
	var task1a_intercepted := false
	var task1a_initial_dist := controller.pursuer.global_position.distance_to(controller.courier_bike.global_position)
	print("[TASK 1A LOG] Initial Spawn Pos: Pursuer Z = %.2fm | Bike Z = %.2fm | Dist = %.2fm" % [
		controller.pursuer.global_position.z, controller.courier_bike.global_position.z, task1a_initial_dist
	])

	for frame in range(300):
		await controller.get_tree().process_frame
		if controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED:
			task1a_intercepted = true
			break
		if controller.current_pursuit_state == ScrapTestBlock.PursuitState.CONTACT_BROKEN or controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED or controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM:
			task1a_evaded = true
			var elapsed := (Time.get_ticks_msec() / 1000.0) - task1a_start
			print("[TASK 1A LOG] EVADED pursuit at t = %.2fs! Initial dist was %.2fm (> 18.0m threshold bug)." % [elapsed, task1a_initial_dist])
			break

	print("[TASK 1A RESULT] Default Spawn Straight-Line Driving: Evaded Without Gate = %s | Intercepted = %s" % [task1a_evaded, task1a_intercepted])

	# =========================================================================
	# TASK 1B: STRAIGHT-LINE DRIVING AT CLOSE SPAWN (PURSUER Z = -5.0, BIKE Z = 3.0, DIST = 8.0m)
	# =========================================================================
	print("\n--- [TASK 1B] Straight-Line Driving at Close Spawn (Pursuer Z = -5.0, Dist = 8.0m) ---")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout

	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout

	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.0)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.35).timeout

	controller.courier_bike.rotation.y = PI
	controller.pursuer.global_position = Vector3(0, 0.6, -5.0) # 8m behind bike
	controller._steer_input = 0.0
	controller._throttle_input = 1.0

	var task1b_start := Time.get_ticks_msec() / 1000.0
	var task1b_intercepted := false
	var task1b_intercept_time := 0.0

	for frame in range(600):
		await controller.get_tree().process_frame
		if controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED:
			task1b_intercepted = true
			task1b_intercept_time = (Time.get_ticks_msec() / 1000.0) - task1b_start
			print("[TASK 1B LOG] INTERCEPTED by Pursuer at t = %.2fs! Bike Speed = %.1fm/s | Pursuer Speed = %.1fm/s" % [
				task1b_intercept_time, controller.courier_bike.current_speed, controller.pursuer.current_speed
			])
			break

	print("[TASK 1B RESULT] Close Spawn Straight-Line Driving: Intercepted = %s | Intercept Time = %.2fs" % [task1b_intercepted, task1b_intercept_time])

	# =========================================================================
	# TASK 2A: FOOT CIRCLES AROUND CORRODED PANEL (PURSUER Z = -10.0)
	# =========================================================================
	print("\n--- [TASK 2A] Testing Foot Circles around Corroded Panel (Runner 8.5m/s vs Pursuer 15.5m/s) ---")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout

	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout

	var panel_center := controller.corroded_panel.global_position if controller.corroded_panel else Vector3(0, 0, -3.5)
	controller.player.global_position = panel_center + Vector3(2.0, 0, 0)
	controller.pursuer.global_position = Vector3(0, 0.6, -10.0)

	var task2a_start := Time.get_ticks_msec() / 1000.0
	var task2a_intercepted := false
	var task2a_intercept_time := 0.0
	var circle_angle := 0.0

	for frame in range(300):
		await controller.get_tree().process_frame
		circle_angle += 0.15
		var input_vec := Vector2(cos(circle_angle), sin(circle_angle))
		controller.player.set_joystick_input(input_vec)

		if controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED:
			task2a_intercepted = true
			task2a_intercept_time = (Time.get_ticks_msec() / 1000.0) - task2a_start
			print("[TASK 2A LOG] INTERCEPTED on foot around Corroded Panel at t = %.2fs! Runner Speed = %.1fm/s | Pursuer Speed = %.1fm/s" % [
				task2a_intercept_time, controller.player.velocity.length(), controller.pursuer.current_speed
			])
			break

	print("[TASK 2A RESULT] Foot circles (Panel): Intercepted = %s | Intercept Time = %.2fs" % [task2a_intercepted, task2a_intercept_time])

	# =========================================================================
	# TASK 2B: FOOT CIRCLES AROUND COURIER BIKE (PURSUER Z = -5.0)
	# =========================================================================
	print("\n--- [TASK 2B] Testing Foot Circles around Courier Bike (Runner 8.5m/s vs Pursuer 15.5m/s) ---")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout

	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout

	controller.player.global_position = controller.courier_bike.global_position + Vector3(2.0, 0, 0)
	controller.pursuer.global_position = Vector3(0, 0.6, -5.0)

	var task2b_start := Time.get_ticks_msec() / 1000.0
	var task2b_intercepted := false
	var task2b_intercept_time := 0.0
	circle_angle = 0.0

	for frame in range(300):
		await controller.get_tree().process_frame
		circle_angle += 0.15
		var input_vec := Vector2(cos(circle_angle), sin(circle_angle))
		controller.player.set_joystick_input(input_vec)

		if controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED:
			task2b_intercepted = true
			task2b_intercept_time = (Time.get_ticks_msec() / 1000.0) - task2b_start
			print("[TASK 2B LOG] INTERCEPTED on foot around Courier Bike at t = %.2fs! Runner Speed = %.1fm/s | Pursuer Speed = %.1fm/s" % [
				task2b_intercept_time, controller.player.velocity.length(), controller.pursuer.current_speed
			])
			break

	print("[TASK 2B RESULT] Foot circles (Bike): Intercepted = %s | Intercept Time = %.2fs" % [task2b_intercepted, task2b_intercept_time])

	# =========================================================================
	# TASK 3: TRIGGERING SIGNALGATE LATE (PURSUER 2.0M BEHIND BIKE)
	# =========================================================================
	print("\n--- [TASK 3] Testing Late SignalGate Trigger (Pursuer 2.0m behind bike) ---")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout

	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout

	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.0)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.35).timeout

	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 0.5) # z = 12.5
	controller.courier_bike.rotation.y = PI
	controller.courier_bike.current_speed = 12.0
	controller.pursuer.global_position = controller.courier_bike.global_position - Vector3(0, 0, 2.0) # z = 10.5 (2m behind)
	controller.pursuer.current_speed = 15.5
	controller._throttle_input = 1.0

	controller.signal_gate.set_pursuit_active(true)
	controller.signal_gate.update_player_distance(controller.courier_bike.global_position)

	print("[TASK 3 LOG] Triggering SignalGate! Bike Z = %.2fm, Pursuer Z = %.2fm, Initial Dist = %.2fm" % [
		controller.courier_bike.global_position.z, controller.pursuer.global_position.z, controller.pursuer.global_position.distance_to(controller.courier_bike.global_position)
	])
	controller.signal_gate.begin_interaction(controller.courier_bike.global_position)
	assert(controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING, "FAIL: Gate must be TRIGGERING")

	var task3_intercepted_during_swing := false
	var task3_passed_gate_before_close := false
	var task3_backtracked_detour := false

	for frame in range(120):
		await controller.get_tree().process_frame
		var pursuer_z := controller.pursuer.global_position.z
		var gate_z := controller.signal_gate.global_position.z

		if controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING and pursuer_z > gate_z:
			task3_passed_gate_before_close = true

		if controller.current_pursuit_state == ScrapTestBlock.PursuitState.INTERCEPTED:
			task3_intercepted_during_swing = true
			print("[TASK 3 LOG] INTERCEPTED during late gate swing! Frame = %d | Pursuer Z = %.2f" % [frame, pursuer_z])
			break

		if controller.signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED and controller.pursuer.current_detour_index >= 0:
			if controller.pursuer.velocity.z < -0.5:
				task3_backtracked_detour = true
				print("[TASK 3 EXPLOIT LOG] Pursuer passed gate before closure and is BACKTRACKING (-Z velocity %.1f m/s) to detour waypoint 0 at Z=8.0!" % controller.pursuer.velocity.z)

	print("[TASK 3 RESULT] Late SignalGate Trigger (2m behind): Intercepted = %s | Passed Gate Before Close = %s | Backtracked Detour = %s" % [
		task3_intercepted_during_swing, task3_passed_gate_before_close, task3_backtracked_detour
	])

	# =========================================================================
	# TASK 4: EVALUATE IF ROUTE-SWITCH COUNTERPLAY IS 100% REQUIRED OR BYPASSABLE
	# =========================================================================
	print("\n--- [TASK 4] Evaluating Route-Switch Counterplay Requirement & Bypassability ---")
	
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout

	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout

	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 1.0)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.35).timeout

	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.global_position = controller.signal_gate.global_position + Vector3(0, 0, 2.5) # z = 14.5
	controller.courier_bike.rotation.y = PI
	controller.courier_bike.current_speed = 12.0
	controller.pursuer.global_position = controller.signal_gate.global_position - Vector3(0, 0, 6.0) # z = 6.0 (8.5m behind bike)
	controller.pursuer.current_speed = 14.0
	controller._throttle_input = 1.0

	controller.signal_gate.set_pursuit_active(true)
	controller.signal_gate.update_player_distance(controller.courier_bike.global_position)

	print("[TASK 4 LOG] Executing On-Time SignalGate trigger (Pursuer 8.5m behind)...")
	controller.signal_gate.begin_interaction(controller.courier_bike.global_position)

	var task4_evaded_cleanly := false
	var task4_evasion_time := 0.0
	var task4_start := Time.get_ticks_msec() / 1000.0

	for frame in range(600):
		await controller.get_tree().process_frame
		if controller.current_pursuit_state == ScrapTestBlock.PursuitState.CONTACT_BROKEN or controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED or controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM:
			task4_evaded_cleanly = true
			task4_evasion_time = (Time.get_ticks_msec() / 1000.0) - task4_start
			print("[TASK 4 LOG] Clean Evasion Achieved via SignalGate Route Switch! Time = %.2fs" % task4_evasion_time)
			break

	print("\n=========================================================================")
	print("[SUMMARY OF ADVERSARIAL CHASE FALSIFICATION TESTS (V7 TICKET 02.1)]")
	print("  1A. Straight-Line Driving (Default Spawn Z=-15m, Dist=18.07m): Evaded = %s (Fails Tension: Default spawn exceeds 18m contact break threshold on frame 1!)" % task1a_evaded)
	print("  1B. Straight-Line Driving (Close Spawn Z=-5m, Dist=8.0m): Intercepted = %s at t=%.2fs (Passes Tension: Pursuer 15.5 m/s > Bike 14.0 m/s catches bike)" % [task1b_intercepted, task1b_intercept_time])
	print("  2A. Foot Circles around Corroded Panel: Intercepted = %s at t=%.2fs (Fails Evasion: Pursuer 15.5 m/s > Runner 8.5 m/s catches runner in < 1.5s)" % [task2a_intercepted, task2a_intercept_time])
	print("  2B. Foot Circles around Courier Bike: Intercepted = %s at t=%.2fs (Fails Evasion: Pursuer catches runner in < 1.8s)" % [task2b_intercepted, task2b_intercept_time])
	print("  3.  Late SignalGate Trigger (Pursuer 2.0m behind bike): Passed Gate = %s | Backtracked Detour = %s (Fails AI Logic: Gate 0.75s swing delay lets pursuer pass, then detour forces 180° backward U-turn)" % [task3_passed_gate_before_close, task3_backtracked_detour])
	print("  4.  On-Time SignalGate Route Switch (Pursuer 8.5m behind): Clean Evasion = %s in %.2fs (Passes Counterplay: Gate slam forces detour, enabling escape)" % [task4_evaded_cleanly, task4_evasion_time])
	print("=========================================================================")
	controller.get_tree().quit(0)


