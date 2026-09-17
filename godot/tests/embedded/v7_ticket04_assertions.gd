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

static func run_04_1(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V7_TICKET04_1_ASSERTIONS] Starting GTA/CTW Controls & Transmission Suite (Ticket 04.1)...")
	print("Target Build: main | Testing Touch Ownership, Anchor-Follow, & Transmission Contract")
	print("=========================================================================\n")
	await controller.get_tree().create_timer(0.2).timeout

	# -------------------------------------------------------------------------
	# TEST 1: Drag-off GAS cannot latch throttle
	# -------------------------------------------------------------------------
	print("[TEST 1] Testing Drag-off GAS pointer release...")
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui._is_gas_pressed = true
	controller.touch_ui._gas_touch_index = 2
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == 1.0, "FAIL: Initial gas input must be 1.0")

	# Simulate finger release off-rect anywhere on screen (touch index 2 released)
	controller.touch_ui._handle_touch_up_anywhere(2)
	assert(controller.touch_ui._is_gas_pressed == false, "FAIL: Drag-off gas release must set _is_gas_pressed to false")
	assert(controller.touch_ui._gas_touch_index == -1, "FAIL: _gas_touch_index must reset to -1")
	assert(controller._throttle_input == 0.0, "FAIL: Net throttle must return to 0.0 on drag-off release")
	print("[TICKET 04.1 TEST 1 PASSED] Drag-off GAS release verified cleanly!")

	# -------------------------------------------------------------------------
	# TEST 2: Drag-off BRAKE cannot latch brake/reverse
	# -------------------------------------------------------------------------
	print("[TEST 2] Testing Drag-off BRAKE pointer release...")
	controller.touch_ui._is_brake_pressed = true
	controller.touch_ui._brake_touch_index = 3
	controller.touch_ui._emit_net_throttle()
	assert(controller._throttle_input == -1.0, "FAIL: Initial brake input must be -1.0")

	# Simulate finger release off-rect anywhere on screen (touch index 3 released)
	controller.touch_ui._handle_touch_up_anywhere(3)
	assert(controller.touch_ui._is_brake_pressed == false, "FAIL: Drag-off brake release must set _is_brake_pressed to false")
	assert(controller.touch_ui._brake_touch_index == -1, "FAIL: _brake_touch_index must reset to -1")
	assert(controller._throttle_input == 0.0, "FAIL: Net throttle must return to 0.0 on drag-off release")
	print("[TICKET 04.1 TEST 2 PASSED] Drag-off BRAKE release verified cleanly!")

	# -------------------------------------------------------------------------
	# TEST 3: Handbrake Release Safety
	# -------------------------------------------------------------------------
	print("[TEST 3] Testing Handbrake Touch Ownership & Release...")
	controller.touch_ui._is_handbrake_pressed = true
	controller.touch_ui._handbrake_touch_index = 4
	controller.touch_ui.driving_handbrake_updated.emit(true)
	assert(controller._handbrake_input == true, "FAIL: _handbrake_input must be true when handbrake pressed")

	controller.touch_ui._handle_touch_up_anywhere(4)
	assert(controller.touch_ui._is_handbrake_pressed == false, "FAIL: Handbrake release must set _is_handbrake_pressed to false")
	assert(controller.touch_ui._handbrake_touch_index == -1, "FAIL: _handbrake_touch_index must reset to -1")
	assert(controller._handbrake_input == false, "FAIL: _handbrake_input must reset to false on release")
	print("[TICKET 04.1 TEST 3 PASSED] Handbrake touch ownership and release verified!")

	# -------------------------------------------------------------------------
	# TEST 4: Joystick Anchor-Follow Reversal without Deadband
	# -------------------------------------------------------------------------
	print("[TEST 4] Testing Joystick Anchor-Follow Dynamic Re-centering...")
	controller.touch_ui._start_joystick(1, Vector2(100.0, 300.0))
	assert(controller.touch_ui._joystick_center_pos == Vector2(100.0, 300.0), "FAIL: Joystick center must start at touch point")

	# Drag right to 300px (displacement = 200px > 80px max radius)
	controller.touch_ui._update_joystick(Vector2(300.0, 300.0))
	assert(is_equal_approx(controller.touch_ui._current_joystick_vec.x, 1.0), "FAIL: Max displacement must clamp steer to +1.0")
	# With anchor follow, center must have shifted to 300 - 80 = 220px
	assert(is_equal_approx(controller.touch_ui._joystick_center_pos.x, 220.0), "FAIL: Anchor-follow center must shift to 220.0 (got %.1f)" % controller.touch_ui._joystick_center_pos.x)

	# Now reverse direction by moving 10px left to 290px
	controller.touch_ui._update_joystick(Vector2(290.0, 300.0))
	# New displacement: 290 - 220 = 70px -> steer = 70 / 80 = 0.875 (Immediate drop without deadband!)
	assert(is_equal_approx(controller.touch_ui._current_joystick_vec.x, 70.0 / 80.0), "FAIL: Immediate reverse steer must be 0.875 (got %.4f)" % controller.touch_ui._current_joystick_vec.x)
	assert(controller._steer_input < 1.0, "FAIL: Reversal must immediately reduce steer below 1.0")
	controller.touch_ui._stop_joystick()
	print("[TICKET 04.1 TEST 4 PASSED] Joystick anchor-follow eliminates reversal deadband cleanly!")

	# -------------------------------------------------------------------------
	# TEST 5: Public reset_all_input_states Invariant
	# -------------------------------------------------------------------------
	print("[TEST 5] Testing reset_all_input_states() lifecycle method...")
	controller.touch_ui._start_joystick(1, Vector2(100, 100))
	controller.touch_ui._is_gas_pressed = true
	controller.touch_ui._is_brake_pressed = true
	controller.touch_ui._is_handbrake_pressed = true
	controller.touch_ui._emit_net_throttle()

	controller.touch_ui.reset_all_input_states()
	assert(controller.touch_ui._joystick_active == false, "FAIL: Joystick must be inactive after reset")
	assert(controller.touch_ui._is_gas_pressed == false and controller.touch_ui._is_brake_pressed == false and controller.touch_ui._is_handbrake_pressed == false, "FAIL: All driving inputs must be false")
	assert(controller._throttle_input == 0.0, "FAIL: Net throttle must be 0.0")
	assert(controller._steer_input == 0.0, "FAIL: Steer input must be 0.0")
	assert(controller._handbrake_input == false, "FAIL: Handbrake must be false")
	print("[TICKET 04.1 TEST 5 PASSED] reset_all_input_states() verified completely!")

	# -------------------------------------------------------------------------
	# TEST 6: FORWARD + BRAKE HELD -> DECEL -> SETTLE HYSTERESIS -> REVERSE
	# -------------------------------------------------------------------------
	print("[TEST 6] Testing Forward + Brake continuous crossing into Reverse...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_gear = CourierBike.GearState.FORWARD
	controller.courier_bike.current_speed = 10.0

	var dt := 0.016
	var steps := 0
	while controller.courier_bike.current_speed > 0.0 and steps < 100:
		controller.courier_bike.set_drive_inputs(-1.0, 0.0, dt)
		steps += 1

	assert(controller.courier_bike.current_speed == 0.0, "FAIL: Bike must reach 0.0 m/s under braking")
	assert(controller.courier_bike.current_gear == CourierBike.GearState.FORWARD, "FAIL: Must remain in FORWARD during initial zero-speed frame (hysteresis active)")

	# Continue holding brake for 0.06s (less than 0.12s settle window)
	for i in range(4): # 4 * 0.016 = 0.064s
		controller.courier_bike.set_drive_inputs(-1.0, 0.0, dt)
		assert(controller.courier_bike.current_speed == 0.0, "FAIL: Speed must remain 0.0 during settle window")
		assert(controller.courier_bike.current_gear == CourierBike.GearState.FORWARD, "FAIL: Must remain FORWARD during settle window")

	# Continue holding brake past settle duration (another 5 frames -> 0.144s total)
	for i in range(5):
		controller.courier_bike.set_drive_inputs(-1.0, 0.0, dt)

	assert(controller.courier_bike.current_gear == CourierBike.GearState.REVERSE, "FAIL: Gear must shift to REVERSE after settle window")
	assert(controller.courier_bike.current_speed < 0.0, "FAIL: Bike must accelerate into negative reverse speed (got %.2f)" % controller.courier_bike.current_speed)
	print("[TICKET 04.1 TEST 6 PASSED] Forward -> Stop -> Settle -> Reverse transition verified!")

	# -------------------------------------------------------------------------
	# TEST 7: REVERSE + GAS HELD -> DECEL -> SETTLE HYSTERESIS -> FORWARD
	# -------------------------------------------------------------------------
	print("[TEST 7] Testing Reverse + Gas continuous crossing into Forward...")
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_gear = CourierBike.GearState.REVERSE
	controller.courier_bike.current_speed = -3.5

	steps = 0
	while controller.courier_bike.current_speed < 0.0 and steps < 100:
		controller.courier_bike.set_drive_inputs(1.0, 0.0, dt) # Gas applied to reverse motion
		steps += 1

	assert(controller.courier_bike.current_speed == 0.0, "FAIL: Reverse motion must decelerate to 0.0 under Gas")
	assert(controller.courier_bike.current_gear == CourierBike.GearState.REVERSE, "FAIL: Must remain REVERSE during initial zero frame")

	# Continue holding Gas past settle window
	for i in range(10): # 10 * 0.016 = 0.16s > 0.12s
		controller.courier_bike.set_drive_inputs(1.0, 0.0, dt)

	assert(controller.courier_bike.current_gear == CourierBike.GearState.FORWARD, "FAIL: Gear must shift to FORWARD after settle window")
	assert(controller.courier_bike.current_speed > 0.0, "FAIL: Bike must accelerate forward (got %.2f)" % controller.courier_bike.current_speed)
	print("[TICKET 04.1 TEST 7 PASSED] Reverse -> Stop -> Settle -> Forward transition verified!")

	# -------------------------------------------------------------------------
	# TEST 8: Zero-Speed Chatter Immunity
	# -------------------------------------------------------------------------
	print("[TEST 8] Testing Zero-Speed Chatter Immunity on Brief Brake Taps...")
	controller.courier_bike.current_speed = 0.0
	controller.courier_bike.current_gear = CourierBike.GearState.FORWARD
	# Tap brake for 2 frames (32ms < 120ms), then release
	controller.courier_bike.set_drive_inputs(-1.0, 0.0, dt)
	controller.courier_bike.set_drive_inputs(-1.0, 0.0, dt)
	controller.courier_bike.set_drive_inputs(0.0, 0.0, dt) # release
	assert(controller.courier_bike.current_speed == 0.0, "FAIL: Brief brake tap at zero must not induce reverse movement")
	assert(controller.courier_bike.current_gear == CourierBike.GearState.FORWARD, "FAIL: Gear must remain FORWARD after incomplete settle")
	print("[TICKET 04.1 TEST 8 PASSED] Zero-speed chatter immunity verified!")

	# -------------------------------------------------------------------------
	# TEST 9: E-BRAKE and ROUTE SWITCH Hitbox Separation
	# -------------------------------------------------------------------------
	print("[TEST 9] Testing E-BRAKE vs ROUTE SWITCH Hitbox Separation...")
	var hb_btn: Button = controller.touch_ui.handbrake_button
	var rs_btn: Button = controller.touch_ui.route_switch_button
	assert(hb_btn != null and rs_btn != null, "FAIL: Both buttons must exist")
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	await controller.get_tree().process_frame
	var hb_rect: Rect2 = hb_btn.get_global_rect()
	var rs_rect: Rect2 = rs_btn.get_global_rect()
	print("[TEST 9 LOG] Handbrake Rect: %s | Route Switch Rect: %s" % [hb_rect, rs_rect])
	assert(!hb_rect.intersects(rs_rect), "FAIL: Handbrake and Route Switch hit rectangles must not overlap!")
	controller.touch_ui.set_route_switch_button_visible(false)
	print("[TICKET 04.1 TEST 9 PASSED] Control hitbox separation verified!")

	# -------------------------------------------------------------------------
	# TEST 10: Joystick Knob Visual Centering Invariant
	# -------------------------------------------------------------------------
	print("[TEST 10] Testing Joystick Knob Visual Centering Invariant...")
	controller.touch_ui.reset_all_input_states()
	var base: Control = controller.touch_ui.joystick_base
	var handle: Control = controller.touch_ui.joystick_handle
	assert(base != null and handle != null, "FAIL: Joystick nodes missing")
	
	# Check at rest
	var rest_base_c: Vector2 = base.position + (base.size * 0.5)
	var rest_knob_c: Vector2 = handle.position + (handle.size * 0.5)
	var rest_offset: Vector2 = (handle.position + (handle.size * 0.5)) - (base.size * 0.5)
	print("[TEST 10 LOG] Rest knob center offset from base center: %s" % rest_offset)
	assert(rest_offset.length() < 1.0, "FAIL: Knob must be visually centered in base at rest")
	
	# Start touch at (100, 400) and drag to (140, 400)
	controller.touch_ui._start_joystick(0, Vector2(100, 400))
	controller.touch_ui._update_joystick(Vector2(140, 400))
	assert(controller.touch_ui._current_joystick_vec.x > 0.0, "FAIL: Joystick vector must register right deflection")
	
	# Stop joystick
	controller.touch_ui._stop_joystick()
	var stop_offset: Vector2 = (handle.position + (handle.size * 0.5)) - (base.size * 0.5)
	assert(stop_offset.length() < 1.0, "FAIL: Knob must return to visual center on release")
	print("[TICKET 04.1 TEST 10 PASSED] Joystick visual centering invariant verified!")

	print("\n=========================================================================")
	print("[ALL V7 TICKET 04.1 ASSERTIONS PASSED CLEANLY]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


static func run_04_2(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V7_TICKET04_2_ASSERTIONS] Starting GTA/CTW Handling Foundation Suite (Ticket 04.2)...")
	print("Target Build: main | Testing Speed-Sensitive Steer, Arcade Drift & Traction Model")
	print("=========================================================================\n")
	await controller.get_tree().create_timer(0.2).timeout

	# -------------------------------------------------------------------------
	# TEST 1: Speed-Sensitive Steering Rate Authority
	# -------------------------------------------------------------------------
	print("[TEST 1] Testing Speed-Sensitive Steering Scaling (Low Speed vs Max Speed)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING

	# Measure yaw change at low speed (2.0 m/s) over 10 frames
	controller.courier_bike.current_speed = 2.0
	controller.courier_bike.rotation.y = 0.0
	var dt := 0.016
	for i in range(10):
		controller.courier_bike.set_drive_inputs(0.0, 1.0, dt) # full right steer
		controller.courier_bike._physics_process(dt)
	var low_speed_yaw: float = abs(controller.courier_bike.rotation.y)

	# Measure yaw change at top speed (14.0 m/s) over 10 frames
	controller.courier_bike.current_speed = 14.0
	controller.courier_bike.rotation.y = 0.0
	for i in range(10):
		controller.courier_bike.set_drive_inputs(0.0, 1.0, dt) # full right steer
		controller.courier_bike._physics_process(dt)
	var high_speed_yaw: float = abs(controller.courier_bike.rotation.y)

	print("[TEST 1 LOG] Low speed (2m/s) yaw delta = %.4f rad | High speed (14m/s) yaw delta = %.4f rad" % [low_speed_yaw, high_speed_yaw])
	assert(low_speed_yaw > high_speed_yaw * 1.8, "FAIL: Low-speed steer authority must be >1.8x higher than high-speed steer authority!")
	print("[TICKET 04.2 TEST 1 PASSED] Speed-sensitive steering curve verified!")

	# -------------------------------------------------------------------------
	# TEST 2: Heading / Velocity Decoupling & Lateral Momentum Preservation
	# -------------------------------------------------------------------------
	print("[TEST 2] Testing Heading/Velocity Decoupling under Normal Traction...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 14.0
	controller.courier_bike.velocity = Vector3(0, 0, -14.0) # Moving in -Z
	controller.courier_bike.rotation.y = 0.0

	# Apply 1 frame of sharp steer
	controller.courier_bike.set_drive_inputs(0.0, 1.0, dt, false)
	controller.courier_bike._physics_process(dt)

	# Heading has rotated right (basis.x has non-zero Z component)
	var forward_dir: Vector3 = -controller.courier_bike.global_transform.basis.z
	var right_dir: Vector3 = controller.courier_bike.global_transform.basis.x
	var lateral_slip: float = controller.courier_bike.velocity.dot(right_dir)

	# In pure kinematic rotation, lateral_slip would be 0.0. In our arcade model, velocity preserves outward lateral momentum!
	print("[TEST 2 LOG] Frame 1 Lateral momentum preserved: %.4f m/s" % lateral_slip)
	# Heading angle vs velocity angle
	var heading_angle: float = atan2(-forward_dir.x, -forward_dir.z)
	var vel_angle: float = atan2(-controller.courier_bike.velocity.normalized().x, -controller.courier_bike.velocity.normalized().z)
	var slip_diff: float = abs(wrapf(heading_angle - vel_angle, -PI, PI))
	print("[TEST 2 LOG] Heading/Velocity slip angle difference: %.4f rad (%.2f°)" % [slip_diff, rad_to_deg(slip_diff)])
	assert(slip_diff > 0.001, "FAIL: Velocity must decouple from heading to preserve lateral momentum!")
	print("[TICKET 04.2 TEST 2 PASSED] Heading/velocity decoupling verified!")

	# -------------------------------------------------------------------------
	# TEST 3: Handbrake Traction Break & Slip Angle Enlargement
	# -------------------------------------------------------------------------
	print("[TEST 3] Testing Handbrake Powerslide & Slip Angle Enlargement...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 12.0
	controller.courier_bike.velocity = Vector3(0, 0, -12.0)
	controller.courier_bike.rotation.y = 0.0

	# Steer without handbrake over 15 frames
	for i in range(15):
		controller.courier_bike.set_drive_inputs(0.0, 1.0, dt, false)
		controller.courier_bike._physics_process(dt)
	var normal_forward: Vector3 = -controller.courier_bike.global_transform.basis.z
	var normal_slip: float = controller.courier_bike.velocity.cross(normal_forward).length()

	# Steer WITH handbrake over 15 frames from identical initial condition
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 12.0
	controller.courier_bike.velocity = Vector3(0, 0, -12.0)
	controller.courier_bike.rotation.y = 0.0

	for i in range(15):
		controller.courier_bike.set_drive_inputs(0.0, 1.0, dt, true) # HANDBRAKE ON
		controller.courier_bike._physics_process(dt)
	var handbrake_forward: Vector3 = -controller.courier_bike.global_transform.basis.z
	var handbrake_slip: float = controller.courier_bike.velocity.cross(handbrake_forward).length()

	print("[TEST 3 LOG] Normal slip cross = %.4f | Handbrake slip cross = %.4f" % [normal_slip, handbrake_slip])
	assert(handbrake_slip > normal_slip * 1.5, "FAIL: Handbrake must produce significantly larger slip angle than normal grip!")
	print("[TICKET 04.2 TEST 3 PASSED] Handbrake slip angle enlargement verified!")

	# -------------------------------------------------------------------------
	# TEST 4: Handbrake Release Grip Recovery
	# -------------------------------------------------------------------------
	print("[TEST 4] Testing Grip Recovery on Handbrake Release...")
	# Vehicle is sliding; release handbrake and simulate 25 frames of straight tracking
	for i in range(25):
		controller.courier_bike.set_drive_inputs(1.0, 0.0, dt, false) # Straight gas, handbrake OFF
		controller.courier_bike._physics_process(dt)

	var recovery_forward: Vector3 = -controller.courier_bike.global_transform.basis.z
	var recovery_right: Vector3 = controller.courier_bike.global_transform.basis.x
	var recovered_lateral: float = abs(controller.courier_bike.velocity.dot(recovery_right))
	print("[TEST 4 LOG] Post-drift recovered lateral speed: %.4f m/s" % recovered_lateral)
	assert(recovered_lateral < 0.25, "FAIL: Releasing handbrake must recover tire grip and align velocity with forward heading!")
	print("[TICKET 04.2 TEST 4 PASSED] Handbrake grip recovery verified!")

	# -------------------------------------------------------------------------
	# TEST 5: Numerical Stability & Velocity Bounding (Strict <= max_speed)
	# -------------------------------------------------------------------------
	print("[TEST 5] Testing Numerical Stability under 100 Frames of Aggressive Controls...")
	for i in range(100):
		var test_throttle: float = 1.0 if (i % 3 == 0) else (-1.0 if (i % 3 == 1) else 0.0)
		var test_steer: float = sin(i * 0.3)
		var test_hb: bool = (i % 5 == 0)
		controller.courier_bike.set_drive_inputs(test_throttle, test_steer, dt, test_hb)
		controller.courier_bike._physics_process(dt)
		assert(not is_nan(controller.courier_bike.current_speed), "FAIL: current_speed became NaN at frame %d" % i)
		assert(not is_inf(controller.courier_bike.current_speed), "FAIL: current_speed became Inf at frame %d" % i)
		assert(not is_nan(controller.courier_bike.velocity.x) and not is_nan(controller.courier_bike.velocity.z), "FAIL: Velocity NaN at frame %d" % i)
		assert(controller.courier_bike.velocity.length() <= controller.courier_bike.max_speed + 0.01, "FAIL: Velocity exceeded strict max_speed bound")

	print("[TICKET 04.2 TEST 5 PASSED] Numerical stability and strict velocity bounding verified!")

	# -------------------------------------------------------------------------
	# TEST 6: Prevent Stationary Handbrake Body Pivot
	# -------------------------------------------------------------------------
	print("[TEST 6] Testing Stationary Handbrake Body Pivot Immunity (0 m/s)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 0.0
	controller.courier_bike.velocity = Vector3.ZERO
	controller.courier_bike.rotation.y = 0.0

	# Hold full steer + E-BRAKE for 60 frames (1.0s) at 0 m/s
	for i in range(60):
		controller.courier_bike.set_drive_inputs(0.0, 1.0, dt, true) # FULL STEER + HANDBRAKE at 0 speed
		controller.courier_bike._physics_process(dt)

	var stationary_yaw: float = abs(controller.courier_bike.rotation.y)
	print("[TEST 6 LOG] 1-second stationary steer+handbrake yaw delta = %.6f rad" % stationary_yaw)
	assert(stationary_yaw < 0.0001, "FAIL: Stationary vehicle must not rotate in place under steer/handbrake")
	print("[TICKET 04.2 TEST 6 PASSED] Stationary handbrake pivot immunity verified!")

	# -------------------------------------------------------------------------
	# TEST 7: Falsify Handbrake Speed Injection (Full Gas + Full Steer + Handbrake for 2s)
	# -------------------------------------------------------------------------
	print("[TEST 7] Falsifying Handbrake Speed Injection (2 seconds full gas + steer + drift)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.current_speed = 0.0
	controller.courier_bike.velocity = Vector3.ZERO

	var max_drift_vel_mag: float = 0.0
	for i in range(120): # 120 * 0.016 = 1.92s ~ 2 seconds
		controller.courier_bike.set_drive_inputs(1.0, 1.0, dt, true) # FULL GAS + FULL STEER + HANDBRAKE
		controller.courier_bike._physics_process(dt)
		var v_mag: float = controller.courier_bike.velocity.length()
		if v_mag > max_drift_vel_mag:
			max_drift_vel_mag = v_mag
		assert(v_mag <= controller.courier_bike.max_speed + 0.01, "FAIL: Speed injection detected during handbrake! v=%.2f > %.2f" % [v_mag, controller.courier_bike.max_speed])

	print("[TEST 7 LOG] Max velocity magnitude during 2s full gas drift: %.2f m/s (max_speed=%.2f m/s)" % [max_drift_vel_mag, controller.courier_bike.max_speed])
	print("[TICKET 04.2 TEST 7 PASSED] Handbrake speed injection falsified cleanly!")

	print("\n=========================================================================")
	print("[ALL V7 TICKET 04.2 ASSERTIONS PASSED CLEANLY]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


static func run_04_3(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V7_TICKET04_3_ASSERTIONS] Starting GTA Collision Response & Glance Deflection Suite...")
	print("Target Build: main | Testing Tangential Retention, Impact Shedding, & Corner Recovery")
	print("=========================================================================\n")
	await controller.get_tree().create_timer(0.2).timeout
	var dt: float = 0.016

	# -------------------------------------------------------------------------
	# TEST 1: Shallow Wall Glance at Medium Speed (8 m/s, ~15° incidence)
	# -------------------------------------------------------------------------
	print("[TEST 1] Testing Shallow Wall Glance at Medium Speed (8 m/s, 15° incidence)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.global_position = Vector3(-2.8, 0.05, 10.0) # Near ShortcutLeftWall at X = -3.0
	controller.courier_bike.rotation.y = deg_to_rad(-15.0) # Aimed slightly into wall
	controller.courier_bike.current_speed = 8.0
	controller.courier_bike.velocity = -controller.courier_bike.global_transform.basis.z * 8.0

	for i in range(15):
		controller.courier_bike.set_drive_inputs(1.0, 0.0, dt, false)
		controller.courier_bike._physics_process(dt)

	var speed_t1: float = controller.courier_bike.current_speed
	print("[TEST 1 LOG] Post-glance speed: %.2f m/s (from 8.0 m/s)" % speed_t1)
	assert(speed_t1 >= 6.0, "FAIL: Shallow glance at medium speed must retain >= 75%% speed (got %.2f m/s)" % speed_t1)
	assert(controller.courier_bike.global_position.x > -3.5, "FAIL: Bike tunneled through wall")
	print("[TICKET 04.3 TEST 1 PASSED] Medium-speed shallow glance verified!")

	# -------------------------------------------------------------------------
	# TEST 2: Shallow Wall Glance at Max Speed (14 m/s, ~15° incidence)
	# -------------------------------------------------------------------------
	print("[TEST 2] Testing Shallow Wall Glance at Max Speed (14 m/s, 15° incidence)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.global_position = Vector3(-2.8, 0.05, 10.0)
	controller.courier_bike.rotation.y = deg_to_rad(-15.0)
	controller.courier_bike.current_speed = 14.0
	controller.courier_bike.velocity = -controller.courier_bike.global_transform.basis.z * 14.0

	for i in range(15):
		controller.courier_bike.set_drive_inputs(1.0, 0.0, dt, false)
		controller.courier_bike._physics_process(dt)

	var speed_t2: float = controller.courier_bike.current_speed
	print("[TEST 2 LOG] Post-glance speed: %.2f m/s (from 14.0 m/s)" % speed_t2)
	assert(speed_t2 >= 11.0, "FAIL: Shallow glance at max speed must retain high tangential momentum (got %.2f m/s)" % speed_t2)
	print("[TICKET 04.3 TEST 2 PASSED] High-speed shallow glance verified!")

	# -------------------------------------------------------------------------
	# TEST 3: 45° Impact at 10 m/s
	# -------------------------------------------------------------------------
	print("[TEST 3] Testing 45° Impact at 10 m/s...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.global_position = Vector3(-2.8, 0.05, 10.0)
	controller.courier_bike.rotation.y = deg_to_rad(-45.0)
	controller.courier_bike.current_speed = 10.0
	controller.courier_bike.velocity = -controller.courier_bike.global_transform.basis.z * 10.0

	for i in range(15):
		controller.courier_bike.set_drive_inputs(0.0, 0.0, dt, false)
		controller.courier_bike._physics_process(dt)

	var speed_t3: float = controller.courier_bike.current_speed
	print("[TEST 3 LOG] Post-45° impact speed: %.2f m/s (from 10.0 m/s)" % speed_t3)
	assert(speed_t3 < 8.5 and speed_t3 > 2.0, "FAIL: 45° impact must shed proportional speed (got %.2f m/s)" % speed_t3)
	print("[TICKET 04.3 TEST 3 PASSED] 45° impact response verified!")

	# -------------------------------------------------------------------------
	# TEST 4: Near-Head-On Impact (90° into wall)
	# -------------------------------------------------------------------------
	print("[TEST 4] Testing Near-Head-On Impact (90° into wall)...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.global_position = Vector3(-2.8, 0.05, 10.0)
	controller.courier_bike.rotation.y = deg_to_rad(-90.0) # Straight into wall
	controller.courier_bike.current_speed = 10.0
	controller.courier_bike.velocity = -controller.courier_bike.global_transform.basis.z * 10.0

	for i in range(20):
		controller.courier_bike.set_drive_inputs(0.0, 0.0, dt, false)
		controller.courier_bike._physics_process(dt)

	var speed_t4: float = controller.courier_bike.current_speed
	print("[TEST 4 LOG] Post-head-on impact speed: %.2f m/s (from 10.0 m/s)" % speed_t4)
	assert(speed_t4 <= 2.5, "FAIL: Head-on collision must shed substantial speed (got %.2f m/s)" % speed_t4)
	print("[TICKET 04.3 TEST 4 PASSED] Head-on impact speed shedding verified!")

	# -------------------------------------------------------------------------
	# TEST 5: Repeated Wall Scraping (50 frames sustained contact)
	# -------------------------------------------------------------------------
	print("[TEST 5] Testing Repeated Wall Scraping (50 frames sustained contact)...")
	for i in range(50):
		controller.courier_bike.set_drive_inputs(1.0, 0.2, dt, false) # Holding slight steer into wall
		controller.courier_bike._physics_process(dt)
		assert(not is_nan(controller.courier_bike.current_speed) and not is_inf(controller.courier_bike.current_speed), "FAIL: NaN/Inf speed during wall grind")
		assert(controller.courier_bike.velocity.length() <= controller.courier_bike.max_speed * 1.05, "FAIL: Velocity energy injection during wall grind")

	print("[TICKET 04.3 TEST 5 PASSED] Repeated wall scraping stability verified!")

	# -------------------------------------------------------------------------
	# TEST 6: Reverse Recovery from Wall Contact
	# -------------------------------------------------------------------------
	print("[TEST 6] Testing Reverse Recovery after Obstacle Contact...")
	# While blocked against wall, hold brake/reverse to back away
	for i in range(30):
		controller.courier_bike.set_drive_inputs(-1.0, 0.0, dt, false)
		controller.courier_bike._physics_process(dt)

	print("[TEST 6 LOG] Post-recovery gear: %s | speed: %.2f m/s" % [CourierBike.GearState.keys()[controller.courier_bike.current_gear], controller.courier_bike.current_speed])
	assert(controller.courier_bike.current_gear == CourierBike.GearState.REVERSE or controller.courier_bike.current_speed < 0.0, "FAIL: Vehicle must reverse away from wall on reverse input")
	print("[TICKET 04.3 TEST 6 PASSED] Reverse recovery from wall verified!")

	# -------------------------------------------------------------------------
	# TEST 7: Handbrake Slide Wall Contact
	# -------------------------------------------------------------------------
	print("[TEST 7] Testing Handbrake Powerslide Wall Contact...")
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	controller.courier_bike.current_state = CourierBike.BikeState.DRIVING
	controller.courier_bike.global_position = Vector3(-2.8, 0.05, 10.0)
	controller.courier_bike.rotation.y = deg_to_rad(-30.0)
	controller.courier_bike.current_speed = 12.0
	controller.courier_bike.velocity = Vector3(0, 0, -12.0)

	for i in range(20):
		controller.courier_bike.set_drive_inputs(0.0, 1.0, dt, true) # Handbrake powerslide into wall
		controller.courier_bike._physics_process(dt)
		assert(not is_nan(controller.courier_bike.rotation.y), "FAIL: NaN yaw during drift collision")
		assert(controller.courier_bike.velocity.length() <= 14.0, "FAIL: Speed exploded during drift collision")

	print("[TICKET 04.3 TEST 7 PASSED] Handbrake drift collision stability verified!")

	print("\n=========================================================================")
	print("[ALL V7 TICKET 04.3 ASSERTIONS PASSED CLEANLY]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


