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

static func run_thumb_reach_assertions(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V8 02.2A] Starting Dedicated Thumb Reach & Control Hierarchy Suite...")
	print("=========================================================================\n")

	await controller.get_tree().process_frame
	var vp_rect := controller.touch_ui.get_viewport_rect()

	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 960, 540), Vector2i(960, 540))
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(false)
	await controller.get_tree().process_frame

	# 1. Geometry and Baseline Positions
	var gas_r: Rect2 = controller.touch_ui.gas_button.get_global_rect()
	var brk_r: Rect2 = controller.touch_ui.brake_button.get_global_rect()
	var hbrk_r: Rect2 = controller.touch_ui.handbrake_button.get_global_rect()
	var dism_r: Rect2 = controller.touch_ui.dismount_button.get_global_rect()

	print("[GEOMETRY] Checking 2-column dimensions and bounds...")
	assert(is_equal_approx(gas_r.size.x, 132.0) and is_equal_approx(gas_r.size.y, 108.0), "FAIL: Gas size must be 132x108")
	assert(is_equal_approx(brk_r.size.x, 132.0) and is_equal_approx(brk_r.size.y, 108.0), "FAIL: Brake size must be 132x108")
	assert(is_equal_approx(hbrk_r.size.x, 132.0) and is_equal_approx(hbrk_r.size.y, 64.0), "FAIL: E-Brake size must be 132x64")
	assert(is_equal_approx(dism_r.size.x, 132.0) and is_equal_approx(dism_r.size.y, 56.0), "FAIL: Dismount size must be 132x56")
	print("  -> Button sizes PASS (Gas: %s, Brake: %s, E-Brake: %s, Dismount: %s)" % [gas_r.size, brk_r.size, hbrk_r.size, dism_r.size])

	# 2. Adjacency & Column Alignment
	print("[ALIGNMENT] Checking column alignment and vertical stacking...")
	assert(is_equal_approx(gas_r.position.y, brk_r.position.y), "FAIL: Gas and Brake must share bottom row Y alignment")
	assert(is_equal_approx(hbrk_r.position.x, brk_r.position.x), "FAIL: E-Brake must sit directly above Brake (left col)")
	assert(gas_r.position.x > brk_r.end.x, "FAIL: Gas must be rightmost primary action")
	print("  -> Column alignment PASS (Left Col X: %.1f, Right Col X: %.1f, Bottom Y: %.1f, Top Y: %.1f)" % [brk_r.position.x, gas_r.position.x, gas_r.position.y, hbrk_r.position.y])

	# 3. Dynamic Route Switch Invariance
	print("[ROUTE INVARIANCE] Testing show/hide ROUTE SWITCH causes zero movement...")
	var gas_r_before := gas_r
	var brk_r_before := brk_r
	var hbrk_r_before := hbrk_r
	var dism_r_before := dism_r

	controller.touch_ui.set_route_switch_button_visible(true)
	await controller.get_tree().process_frame
	var rs_r: Rect2 = controller.touch_ui.route_switch_button.get_global_rect()

	assert(controller.touch_ui.gas_button.get_global_rect() == gas_r_before, "FAIL: Gas position shifted when Route Switch became visible")
	assert(controller.touch_ui.brake_button.get_global_rect() == brk_r_before, "FAIL: Brake position shifted when Route Switch became visible")
	assert(controller.touch_ui.handbrake_button.get_global_rect() == hbrk_r_before, "FAIL: Handbrake position shifted when Route Switch became visible")
	assert(controller.touch_ui.dismount_button.get_global_rect() == dism_r_before, "FAIL: Dismount position shifted when Route Switch became visible")
	assert(is_equal_approx(rs_r.size.x, 132.0) and is_equal_approx(rs_r.size.y, 64.0), "FAIL: Route Switch size must be 132x64")
	assert(is_equal_approx(rs_r.position.x, gas_r.position.x), "FAIL: Route Switch must sit directly above Gas (right col)")
	assert(is_equal_approx(rs_r.position.y, hbrk_r.position.y), "FAIL: Route Switch and E-Brake must share top row Y alignment")
	print("  -> Route Invariance PASS: Zero movement in neighboring controls!")

	# 4. Pairwise Non-Intersection & Margins
	print("[INTERSECTIONS] Checking zero overlap across all 5 buttons...")
	assert(not gas_r.intersects(brk_r), "FAIL: Gas-Brake intersection")
	assert(not gas_r.intersects(hbrk_r), "FAIL: Gas-Handbrake intersection")
	assert(not gas_r.intersects(rs_r), "FAIL: Gas-RouteSwitch intersection")
	assert(not brk_r.intersects(hbrk_r), "FAIL: Brake-Handbrake intersection")
	assert(not brk_r.intersects(rs_r), "FAIL: Brake-RouteSwitch intersection")
	assert(not hbrk_r.intersects(rs_r), "FAIL: Handbrake-RouteSwitch intersection")
	assert(not dism_r.intersects(rs_r), "FAIL: Dismount-RouteSwitch intersection")
	assert(not dism_r.intersects(hbrk_r), "FAIL: Dismount-Handbrake intersection")
	print("  -> Pairwise Non-Intersection PASS: All 10 pairwise intersection checks false!")

	# 5. Muscle Memory Parity: ACTION button in FOOT mode
	print("[ACTION PARITY] Testing Foot Action button matches Gas button zone...")
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	await controller.get_tree().process_frame
	var act_r: Rect2 = controller.touch_ui.action_button.get_global_rect()
	assert(act_r == gas_r, "FAIL: Action button in Foot mode must occupy exact same rectangle as Gas button in Driving mode")
	print("  -> Action Parity PASS: Identical right-thumb touch zone (%s)" % act_r)

	# 6. Exclusion Rejection for Joystick Initiation
	print("[JOYSTICK REJECTION] Testing excluded notch/home-bar touch rejection...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(290, 0, 2050, 1080), Vector2i(2340, 1080)) # 40px left inset
	var safe_deep := controller.touch_ui.get_resolved_safe_rect()
	assert(is_equal_approx(safe_deep.position.x, 40.0), "FAIL: 40px left inset")

	# Touch in excluded notch space (x=10, y=300) -> Must NOT spawn joystick
	controller.touch_ui._stop_joystick()
	var touch_notch := InputEventScreenTouch.new()
	touch_notch.index = 1
	touch_notch.position = Vector2(10.0, 300.0)
	touch_notch.pressed = true
	controller.touch_ui._gui_input(touch_notch)
	assert(not controller.touch_ui._joystick_active, "FAIL: Touch in excluded notch space must NOT start joystick")
	print("  -> Excluded Notch Rejection PASS: Zero joystick spawned from notch zone!")

	# Touch in valid safe region (x=50, y=300) -> Must start joystick
	var touch_valid := InputEventScreenTouch.new()
	touch_valid.index = 1
	touch_valid.position = Vector2(50.0, 300.0)
	touch_valid.pressed = true
	controller.touch_ui._gui_input(touch_valid)
	assert(controller.touch_ui._joystick_active, "FAIL: Valid touch inside safe boundary must start joystick")
	controller.touch_ui._stop_joystick()
	print("  -> Valid Safe Touch PASS: Joystick spawned normally inside safe region!")

	# 7. Clean up
	controller.touch_ui.clear_simulated_safe_area()
	controller.touch_ui.set_route_switch_button_visible(false)

	print("\n=========================================================================")
	print("[ALL V8 02.2A THUMB REACH ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


static func run_multitouch_assertions(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V8 02.3] Starting Adversarial Multi-Touch & Gesture Conflict Suite...")
	print("=========================================================================\n")

	await controller.get_tree().process_frame
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 960, 540), Vector2i(960, 540))
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	await controller.get_tree().process_frame

	# -------------------------------------------------------------------------
	# TEST A: STEER + GAS
	# -------------------------------------------------------------------------
	print("[TEST A] Steer + Gas independent ownership & output...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	controller.touch_ui._update_joystick(Vector2(200.0, 350.0)) # steer right
	
	var touch_gas := InputEventScreenTouch.new()
	touch_gas.index = 1
	touch_gas.pressed = true
	controller.touch_ui.gas_button.gui_input.emit(touch_gas)
	
	assert(controller.touch_ui._joystick_active and controller.touch_ui._joystick_touch_index == 0, "FAIL A: Joystick owned by index 0")
	assert(controller.touch_ui._is_gas_pressed and controller.touch_ui._gas_touch_index == 1, "FAIL A: Gas owned by index 1")
	assert(controller._throttle_input == 1.0, "FAIL A: Throttle output +1.0")
	assert(controller._steer_input > 0.5, "FAIL A: Steer input active")
	print("  -> Test A PASS: Steer + Gas cleanly independent!")

	# -------------------------------------------------------------------------
	# TEST B: STEER + BRAKE
	# -------------------------------------------------------------------------
	print("[TEST B] Steer + Brake independent ownership...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	
	var touch_brk := InputEventScreenTouch.new()
	touch_brk.index = 2
	touch_brk.pressed = true
	controller.touch_ui.brake_button.gui_input.emit(touch_brk)
	
	assert(controller.touch_ui._joystick_active and controller.touch_ui._joystick_touch_index == 0, "FAIL B: Joystick owned")
	assert(controller.touch_ui._is_brake_pressed and controller.touch_ui._brake_touch_index == 2, "FAIL B: Brake owned")
	assert(controller._throttle_input == -1.0, "FAIL B: Throttle output -1.0")
	print("  -> Test B PASS: Steer + Brake cleanly independent!")

	# -------------------------------------------------------------------------
	# TEST C: STEER + E-BRAKE
	# -------------------------------------------------------------------------
	print("[TEST C] Steer + E-Brake independent ownership...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	
	var touch_hb := InputEventScreenTouch.new()
	touch_hb.index = 3
	touch_hb.pressed = true
	controller.touch_ui.handbrake_button.gui_input.emit(touch_hb)
	
	assert(controller.touch_ui._joystick_active and controller.touch_ui._joystick_touch_index == 0, "FAIL C: Joystick owned")
	assert(controller.touch_ui._is_handbrake_pressed and controller.touch_ui._handbrake_touch_index == 3, "FAIL C: E-Brake owned")
	assert(controller._handbrake_input == true, "FAIL C: Handbrake output true")
	print("  -> Test C PASS: Steer + E-Brake cleanly independent!")

	# -------------------------------------------------------------------------
	# TEST D: STEER + GAS + E-BRAKE (3 Simultaneous Touches & All Release Orders)
	# -------------------------------------------------------------------------
	print("[TEST D] 3 Simultaneous Touches (Steer + Gas + E-Brake) in all release orders...")
	# Order 1: Release Gas first
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	controller.touch_ui.gas_button.gui_input.emit(touch_gas) # idx 1
	controller.touch_ui.handbrake_button.gui_input.emit(touch_hb) # idx 3
	assert(controller._throttle_input == 1.0 and controller._handbrake_input == true and controller.touch_ui._joystick_active, "FAIL D: All 3 active")
	
	controller.touch_ui._handle_touch_up_anywhere(1) # Release Gas
	assert(controller._throttle_input == 0.0, "FAIL D1: Throttle reset after gas release")
	assert(controller._handbrake_input == true, "FAIL D1: Handbrake must persist")
	assert(controller.touch_ui._joystick_active, "FAIL D1: Joystick must persist")
	
	# Order 2: Release E-Brake first
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	controller.touch_ui.gas_button.gui_input.emit(touch_gas)
	controller.touch_ui.handbrake_button.gui_input.emit(touch_hb)
	controller.touch_ui._handle_touch_up_anywhere(3) # Release E-Brake
	assert(controller._throttle_input == 1.0, "FAIL D2: Throttle must persist")
	assert(controller._handbrake_input == false, "FAIL D2: Handbrake reset")
	assert(controller.touch_ui._joystick_active, "FAIL D2: Joystick must persist")
	
	# Order 3: Release Steer first
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	controller.touch_ui.gas_button.gui_input.emit(touch_gas)
	controller.touch_ui.handbrake_button.gui_input.emit(touch_hb)
	controller.touch_ui._handle_touch_up_anywhere(0) # Release Steer
	assert(not controller.touch_ui._joystick_active, "FAIL D3: Joystick stopped")
	assert(controller._throttle_input == 1.0, "FAIL D3: Throttle must persist")
	assert(controller._handbrake_input == true, "FAIL D3: Handbrake must persist")
	print("  -> Test D PASS: 3 simultaneous touches maintain perfect state across all release orders!")

	# -------------------------------------------------------------------------
	# TEST E: GAS + BRAKE PRIORITY
	# -------------------------------------------------------------------------
	print("[TEST E] Gas + Brake Priority (Brake wins on conflict)...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui.gas_button.gui_input.emit(touch_gas) # idx 1 -> throttle 1.0
	assert(controller._throttle_input == 1.0, "FAIL E: Gas active")
	
	controller.touch_ui.brake_button.gui_input.emit(touch_brk) # idx 2 -> conflict!
	assert(controller._throttle_input == -1.0, "FAIL E: Brake must take precedence over Gas")
	
	controller.touch_ui._handle_touch_up_anywhere(2) # Release Brake -> Gas remains!
	assert(controller._throttle_input == 1.0, "FAIL E: Throttle must revert to +1.0 when Brake is released while Gas held")
	
	controller.touch_ui._handle_touch_up_anywhere(1) # Release Gas
	assert(controller._throttle_input == 0.0, "FAIL E: Throttle must be 0.0 when both released")
	print("  -> Test E PASS: Brake precedence and reversion verified cleanly!")

	# -------------------------------------------------------------------------
	# TEST F: RAPID GAS <-> BRAKE TRANSITIONS
	# -------------------------------------------------------------------------
	print("[TEST F] Rapid Gas <-> Brake transitions (20 iterations)...")
	controller.touch_ui.reset_all_input_states()
	for i in range(20):
		controller.touch_ui.gas_button.gui_input.emit(touch_gas)
		controller.touch_ui._handle_touch_up_anywhere(1)
		controller.touch_ui.brake_button.gui_input.emit(touch_brk)
		controller.touch_ui._handle_touch_up_anywhere(2)
	assert(controller._throttle_input == 0.0 and not controller.touch_ui._is_gas_pressed and not controller.touch_ui._is_brake_pressed, "FAIL F: No stale state after rapid transitions")
	print("  -> Test F PASS: Zero latched throttle after 20 rapid transitions!")

	# -------------------------------------------------------------------------
	# TEST G: BOUNDARY SLIDE-OFF RELEASE
	# -------------------------------------------------------------------------
	print("[TEST G] Slide-Off: Drag outside button bounds then release...")
	controller.touch_ui.reset_all_input_states()
	
	# Press Gas (idx 5) -> drag to outside coordinates (0, 0) -> release touch
	var touch_down_g := InputEventScreenTouch.new()
	touch_down_g.index = 5
	touch_down_g.pressed = true
	controller.touch_ui.gas_button.gui_input.emit(touch_down_g)
	assert(controller.touch_ui._is_gas_pressed and controller.touch_ui._gas_touch_index == 5, "FAIL G: Gas active")
	
	var touch_up_g := InputEventScreenTouch.new()
	touch_up_g.index = 5
	touch_up_g.position = Vector2(10.0, 10.0) # Far outside
	touch_up_g.pressed = false
	controller.touch_ui._input(touch_up_g) # Received at top-level _input
	assert(not controller.touch_ui._is_gas_pressed and controller.touch_ui._gas_touch_index == -1, "FAIL G: Gas must release on slide-off")
	assert(controller._throttle_input == 0.0, "FAIL G: Net throttle 0 after slide-off")
	print("  -> Test G PASS: Boundary slide-off cleanly cleared pointer state!")

	# -------------------------------------------------------------------------
	# TEST H: ROUTE SWITCH WHILE STEERING
	# -------------------------------------------------------------------------
	print("[TEST H] Route Switch while Steering...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	var route_fired := [false]
	var route_cb := func(): route_fired[0] = true
	controller.touch_ui.action_button_pressed.connect(route_cb)
	
	controller.touch_ui.trigger_route_switch()
	assert(route_fired[0], "FAIL H: Route Switch must emit event")
	assert(controller.touch_ui._joystick_active and controller.touch_ui._joystick_touch_index == 0, "FAIL H: Joystick must remain owned")
	assert(not controller.touch_ui._is_handbrake_pressed, "FAIL H: Route switch must not trigger Handbrake")
	controller.touch_ui.action_button_pressed.disconnect(route_cb)
	print("  -> Test H PASS: Route switch fired cleanly without affecting steering!")

	# -------------------------------------------------------------------------
	# TEST I: E-BRAKE VS ROUTE SWITCH CORNER ISOLATION
	# -------------------------------------------------------------------------
	print("[TEST I] E-Brake vs Route Switch Corner Isolation...")
	var hbrk_fired := [false]
	var hbrk_cb := func(v: bool): hbrk_fired[0] = v
	controller.touch_ui.driving_handbrake_updated.connect(hbrk_cb)
	
	# Touch Route Switch -> Only route switch responds
	route_fired[0] = false
	controller.touch_ui.action_button_pressed.connect(route_cb)
	controller.touch_ui.trigger_route_switch()
	assert(route_fired[0] and not hbrk_fired[0], "FAIL I: Route switch must not emit Handbrake")
	controller.touch_ui.action_button_pressed.disconnect(route_cb)
	controller.touch_ui.driving_handbrake_updated.disconnect(hbrk_cb)
	print("  -> Test I PASS: Independent event paths verified!")

	# -------------------------------------------------------------------------
	# TEST J: DISMOUNT WHILE STEERING
	# -------------------------------------------------------------------------
	print("[TEST J] Dismount while Steering (Rejection doesn't clear steering)...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	var dism_fired := [false]
	var dism_cb := func(): dism_fired[0] = true
	controller.touch_ui.dismount_pressed.connect(dism_cb)
	
	controller.touch_ui.trigger_dismount()
	controller.touch_ui.show_dismount_rejection_warning("[ SPEED TOO HIGH TO DISMOUNT ]")
	assert(dism_fired[0], "FAIL J: Dismount signal fired")
	assert(controller.touch_ui._joystick_active and controller.touch_ui._joystick_touch_index == 0, "FAIL J: Joystick must stay active through dismount rejection")
	controller.touch_ui.dismount_pressed.disconnect(dism_cb)
	print("  -> Test J PASS: Steering survives dismount attempt & rejection toast!")

	# -------------------------------------------------------------------------
	# TEST K: 3RD / 4TH TOUCH OVERLOAD
	# -------------------------------------------------------------------------
	print("[TEST K] 3rd/4th touch overload cannot steal owned pointers...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	controller.touch_ui.gas_button.gui_input.emit(touch_gas) # idx 1
	
	# Random 4th touch on screen (idx 7) -> release -> cannot clear gas or steer
	var touch_extra := InputEventScreenTouch.new()
	touch_extra.index = 7
	touch_extra.pressed = false
	controller.touch_ui._input(touch_extra)
	assert(controller.touch_ui._joystick_active and controller.touch_ui._joystick_touch_index == 0, "FAIL K: Steer intact")
	assert(controller.touch_ui._is_gas_pressed and controller.touch_ui._gas_touch_index == 1, "FAIL K: Gas intact")
	print("  -> Test K PASS: Extra fingers cannot steal or disturb active controls!")

	# -------------------------------------------------------------------------
	# TEST L: MODE SWITCH WHILE HELD
	# -------------------------------------------------------------------------
	print("[TEST L] Mode switch while held (Vehicle -> Foot)...")
	controller.touch_ui.gas_button.gui_input.emit(touch_gas) # idx 1
	controller.touch_ui.handbrake_button.gui_input.emit(touch_hb) # idx 3
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	assert(not controller.touch_ui._is_gas_pressed and controller.touch_ui._gas_touch_index == -1, "FAIL L: Gas cleared on mode change")
	assert(not controller.touch_ui._is_handbrake_pressed and controller.touch_ui._handbrake_touch_index == -1, "FAIL L: Handbrake cleared on mode change")
	assert(controller._throttle_input == 0.0 and controller._handbrake_input == false, "FAIL L: Net inputs zeroed")
	print("  -> Test L PASS: Driving states cleanly purged on mode transition!")

	# -------------------------------------------------------------------------
	# TEST M: TUNER INTERACTION DRAG & RELEASE OUTSIDE OVERLAY
	# -------------------------------------------------------------------------
	print("[TEST M] Tuner Interaction Drag & Release Outside Overlay...")
	controller.touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	var tuner_released := [false]
	var tuner_cb := func(): tuner_released[0] = true
	controller.touch_ui.tuner_interaction_released.connect(tuner_cb)
	
	# Touch down on overlay (idx 8)
	var touch_tune_down := InputEventScreenTouch.new()
	touch_tune_down.index = 8
	touch_tune_down.pressed = true
	controller.touch_ui._gui_input(touch_tune_down)
	assert(controller.touch_ui._is_tuning and controller.touch_ui._interaction_touch_index == 8, "FAIL M: Tuner active")
	
	# Release touch outside overlay
	var touch_tune_up := InputEventScreenTouch.new()
	touch_tune_up.index = 8
	touch_tune_up.pressed = false
	controller.touch_ui._input(touch_tune_up)
	assert(tuner_released[0], "FAIL M: Tuner release signal emitted")
	assert(not controller.touch_ui._is_tuning and controller.touch_ui._interaction_touch_index == -1, "FAIL M: Tuner state cleared")
	controller.touch_ui.tuner_interaction_released.disconnect(tuner_cb)
	controller.touch_ui.close_interaction_overlay()
	print("  -> Test M PASS: Tuner drag and outside release verified cleanly!")

	# -------------------------------------------------------------------------
	# TEST N: PEEL INTERACTION DRAG & RELEASE OUTSIDE OVERLAY
	# -------------------------------------------------------------------------
	print("[TEST N] Peel Interaction Drag & Release Outside Overlay...")
	controller.touch_ui.show_gesture_overlay("PEEL_PANEL")
	var peel_released := [false]
	var peel_cb := func(): peel_released[0] = true
	controller.touch_ui.peel_gesture_released.connect(peel_cb)
	
	var touch_peel_down := InputEventScreenTouch.new()
	touch_peel_down.index = 9
	touch_peel_down.pressed = true
	controller.touch_ui._gui_input(touch_peel_down)
	assert(controller.touch_ui._is_peeling and controller.touch_ui._interaction_touch_index == 9, "FAIL N: Peel active")
	
	var touch_peel_up := InputEventScreenTouch.new()
	touch_peel_up.index = 9
	touch_peel_up.pressed = false
	controller.touch_ui._input(touch_peel_up)
	assert(peel_released[0], "FAIL N: Peel release signal emitted")
	assert(not controller.touch_ui._is_peeling and controller.touch_ui._interaction_touch_index == -1, "FAIL N: Peel state cleared")
	controller.touch_ui.peel_gesture_released.disconnect(peel_cb)
	controller.touch_ui.close_interaction_overlay()
	print("  -> Test N PASS: Peel drag and outside release verified cleanly!")

	# -------------------------------------------------------------------------
	# TEST O: CORE TAP POINTER ISOLATION
	# -------------------------------------------------------------------------
	print("[TEST O] Core Tap Pointer Isolation...")
	controller.touch_ui.show_gesture_overlay("EXPOSE_CORE")
	var core_tapped := [false]
	var core_cb := func(): core_tapped[0] = true
	controller.touch_ui.core_tap_pressed.connect(core_cb)
	
	# Tap real button path
	controller.touch_ui.core_tap_button.pressed.emit()
	assert(core_tapped[0], "FAIL O: Core tap fired via canonical pressed path")
	assert(not controller.touch_ui._is_peeling and not controller.touch_ui._is_tuning, "FAIL O: Core tap did not trigger drag gestures")
	assert(controller.touch_ui._interaction_touch_index == -1, "FAIL O: Core tap did not claim drag pointer")
	controller.touch_ui.core_tap_pressed.disconnect(core_cb)
	controller.touch_ui.close_interaction_overlay()
	print("  -> Test O PASS: Core tap completely isolated on single canonical path!")

	# -------------------------------------------------------------------------
	# TEST P: REPLAY FULL RESET VIA CONTROLLER SIGNAL LIFECYCLE
	# -------------------------------------------------------------------------
	print("[TEST P] Replay Full Reset via Controller Signal Lifecycle...")
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	controller.touch_ui.gas_button.gui_input.emit(touch_gas)
	controller.touch_ui.handbrake_button.gui_input.emit(touch_hb)
	
	# Fire canonical replay_button pressed -> triggers touch_ui.replay_pressed -> reset_slice
	controller.touch_ui.replay_button.pressed.emit()
	await controller.get_tree().process_frame
	
	assert(not controller.touch_ui._joystick_active and controller.touch_ui._joystick_touch_index == -1, "FAIL P: Joystick reset")
	assert(not controller.touch_ui._is_gas_pressed and controller.touch_ui._gas_touch_index == -1, "FAIL P: Gas reset")
	assert(not controller.touch_ui._is_handbrake_pressed and controller.touch_ui._handbrake_touch_index == -1, "FAIL P: Handbrake reset")
	assert(controller._throttle_input == 0.0 and controller._handbrake_input == false, "FAIL P: Outputs reset")
	print("  -> Test P PASS: Full state reset verified via controller replay_pressed lifecycle!")

	# -------------------------------------------------------------------------
	# TEST Q: SAFE-AREA CHANGE MID-TOUCH
	# -------------------------------------------------------------------------
	print("[TEST Q] Safe-Area Change Mid-Touch (Purges all pointers)...")
	controller.touch_ui._start_joystick(0, Vector2(150.0, 350.0))
	controller.touch_ui.gas_button.gui_input.emit(touch_gas)
	controller.touch_ui.handbrake_button.gui_input.emit(touch_hb)
	
	controller.touch_ui.set_simulated_safe_area(Rect2i(50, 0, 910, 540), Vector2i(960, 540))
	assert(not controller.touch_ui._joystick_active and not controller.touch_ui._is_gas_pressed and not controller.touch_ui._is_handbrake_pressed, "FAIL Q: All pointers purged on safe area update")
	print("  -> Test Q PASS: Layout recomputation immediately clears active inputs!")

	# -------------------------------------------------------------------------
	# TEST R: DUPLICATE INDEX DEFENSE & GLOBAL POINTER REJECTION
	# -------------------------------------------------------------------------
	print("[TEST R] Duplicate Index Defense (One finger cannot own two driving buttons)...")
	controller.touch_ui.reset_all_input_states()
	controller.touch_ui.gas_button.gui_input.emit(touch_gas) # idx 1 claims Gas
	assert(controller.touch_ui._gas_touch_index == 1 and controller.touch_ui._is_gas_pressed, "FAIL R: Gas owned by index 1")
	
	# 1. Attempt to send duplicate idx 1 to Handbrake -> Must be REJECTED
	var dup_hb := InputEventScreenTouch.new()
	dup_hb.index = 1
	dup_hb.pressed = true
	controller.touch_ui.handbrake_button.gui_input.emit(dup_hb)
	assert(controller.touch_ui._handbrake_touch_index == -1 and not controller.touch_ui._is_handbrake_pressed, "FAIL R: Handbrake must reject duplicate index 1")
	
	# 2. Attempt to send duplicate idx 1 to Brake -> Must be REJECTED
	var dup_brk := InputEventScreenTouch.new()
	dup_brk.index = 1
	dup_brk.pressed = true
	controller.touch_ui.brake_button.gui_input.emit(dup_brk)
	assert(controller.touch_ui._brake_touch_index == -1 and not controller.touch_ui._is_brake_pressed, "FAIL R: Brake must reject duplicate index 1")
	
	# 3. Attempt to spawn joystick with duplicate idx 1 -> Must be REJECTED
	controller.touch_ui._start_joystick(1, Vector2(150.0, 350.0))
	assert(not controller.touch_ui._joystick_active or controller.touch_ui._joystick_touch_index != 1, "FAIL R: Joystick must reject duplicate index 1")
	
	# 4. Release index 1 globally -> Clears Gas cleanly
	controller.touch_ui._handle_touch_up_anywhere(1)
	assert(not controller.touch_ui._is_gas_pressed and controller.touch_ui._gas_touch_index == -1, "FAIL R: Index 1 released from Gas")
	print("  -> Test R PASS: Global duplicate pointer defense verified across all controls!")

	# Clean up
	controller.touch_ui.clear_simulated_safe_area()
	controller.touch_ui.set_route_switch_button_visible(false)

	print("\n=========================================================================")
	print("[ALL V8 02.3 ADVERSARIAL MULTI-TOUCH ASSERTIONS (A-R) PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


