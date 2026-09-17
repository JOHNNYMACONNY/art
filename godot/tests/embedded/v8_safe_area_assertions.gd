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

static func run_safe_area_assertions(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V8 02.1A + 02.2] Starting Mobile Safe-Area, Transform & Control Hierarchy Suite...")
	print("=========================================================================\n")

	await controller.get_tree().process_frame
	var vp_rect := controller.touch_ui.get_viewport_rect()

	# -------------------------------------------------------------------------
	# 1. Profile 1: 960x540 16:9 Standard (No insets)
	# -------------------------------------------------------------------------
	print("[PROFILE 1] 16:9 Standard Baseline (960x540, 0 insets)...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 960, 540), Vector2i(960, 540))
	var safe1 := controller.touch_ui.get_resolved_safe_rect()
	assert(safe1 == vp_rect, "FAIL: Safe area 1 must equal full viewport")
	
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	var act_rect1: Rect2 = controller.touch_ui.action_button.get_global_rect()
	assert(safe1.encloses(act_rect1), "FAIL: Action button must be enclosed by safe rect in 16:9")
	
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	var gas_rect1: Rect2 = controller.touch_ui.gas_button.get_global_rect()
	var brk_rect1: Rect2 = controller.touch_ui.brake_button.get_global_rect()
	var hbrk_rect1: Rect2 = controller.touch_ui.handbrake_button.get_global_rect()
	var rs_rect1: Rect2 = controller.touch_ui.route_switch_button.get_global_rect()
	var dism_rect1: Rect2 = controller.touch_ui.dismount_button.get_global_rect()
	assert(safe1.encloses(gas_rect1), "FAIL: Gas button must be enclosed in 16:9")
	assert(safe1.encloses(brk_rect1), "FAIL: Brake button must be enclosed in 16:9")
	assert(safe1.encloses(hbrk_rect1), "FAIL: Handbrake button must be enclosed in 16:9")
	assert(safe1.encloses(rs_rect1), "FAIL: Route Switch button must be enclosed in 16:9")
	assert(safe1.encloses(dism_rect1), "FAIL: Dismount button must be enclosed in 16:9")
	print("  -> Profile 1 PASS: All controls enclosed | Safe Rect: %s" % safe1)

	# -------------------------------------------------------------------------
	# 2. Profile 2A: 19.5:9 Notch Inside Pillarbox (2340x1080, left inset 132px)
	# -------------------------------------------------------------------------
	print("[PROFILE 2A] 19.5:9 Notch Inside Pillarbox (2340x1080, Left Inset 132px)...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(132, 0, 2208, 1080), Vector2i(2340, 1080))
	var safe2a := controller.touch_ui.get_resolved_safe_rect()
	# Because 132px < 210px pillarbox, 16:9 game area is completely unobstructed
	assert(safe2a == vp_rect, "FAIL: 132px notch in 210px pillarbox must leave 16:9 canvas safe area at full viewport")
	print("  -> Profile 2A PASS: Pillarbox protects game canvas | Safe Rect: %s" % safe2a)

	# -------------------------------------------------------------------------
	# 2B. Profile 2B: 19.5:9 Deep Cutout Penetrating Canvas (2340x1080, left inset 290px)
	# -------------------------------------------------------------------------
	print("[PROFILE 2B] 19.5:9 Deep Cutout Penetrating Canvas (2340x1080, Left Inset 290px)...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(290, 0, 2050, 1080), Vector2i(2340, 1080))
	var safe2b := controller.touch_ui.get_resolved_safe_rect()
	assert(is_equal_approx(safe2b.position.x, 40.0), "FAIL: (290-210)/2.0 must produce 40px canvas inset")
	
	# Test notch rejection & valid spawn
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	var touch_in_notch := InputEventScreenTouch.new()
	touch_in_notch.index = 1
	touch_in_notch.position = Vector2(5.0, 300.0)
	touch_in_notch.pressed = true
	controller.touch_ui._gui_input(touch_in_notch)
	assert(not controller.touch_ui._joystick_active, "FAIL: Touch inside excluded notch must NOT spawn joystick")
	
	var touch_in_safe := InputEventScreenTouch.new()
	touch_in_safe.index = 1
	touch_in_safe.position = Vector2(50.0, 300.0)
	touch_in_safe.pressed = true
	controller.touch_ui._gui_input(touch_in_safe)
	assert(controller.touch_ui._joystick_active, "FAIL: Valid touch in safe area must spawn joystick")
	var joy_base_rect2: Rect2 = controller.touch_ui.joystick_base.get_global_rect()
	assert(joy_base_rect2.position.x >= safe2b.position.x - 0.1, "FAIL: Joystick base must clamp right of cutout inset")
	controller.touch_ui._stop_joystick()
	print("  -> Profile 2B PASS: Deep left cutout clamped & notch rejected | Safe Rect: %s" % safe2b)

	# -------------------------------------------------------------------------
	# 3. Profile 3: 19.5:9 Deep Right Cutout (2340x1080, right inset 290px -> safe rect width 2050px)
	# -------------------------------------------------------------------------
	print("[PROFILE 3] 19.5:9 Deep Right Cutout (2340x1080, Right Inset 290px)...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 2050, 1080), Vector2i(2340, 1080))
	var safe3 := controller.touch_ui.get_resolved_safe_rect()
	assert(is_equal_approx(safe3.end.x, 920.0), "FAIL: 290px right notch must produce 40px right margin (end.x=920)")
	
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	var gas_rect3: Rect2 = controller.touch_ui.gas_button.get_global_rect()
	assert(safe3.encloses(gas_rect3), "FAIL: Gas button must stay inside safe area with right cutout")
	assert(gas_rect3.end.x <= safe3.end.x + 0.1, "FAIL: Gas button must not bleed into right cutout zone")
	print("  -> Profile 3 PASS: Right cutout enclosed | Safe Rect: %s" % safe3)

	# -------------------------------------------------------------------------
	# 4. Profile 4: 20:9 Bottom Home Indicator (2400x1080, bottom inset 80px)
	# -------------------------------------------------------------------------
	print("[PROFILE 4] 20:9 Bottom Home Indicator (2400x1080, Bottom Inset 80px)...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 2400, 1000), Vector2i(2400, 1080))
	var safe4 := controller.touch_ui.get_resolved_safe_rect()
	assert(is_equal_approx(safe4.end.y, 500.0), "FAIL: 80px bottom home indicator must produce 40px bottom margin (end.y=500)")
	
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	var gas_rect4: Rect2 = controller.touch_ui.gas_button.get_global_rect()
	var brk_rect4: Rect2 = controller.touch_ui.brake_button.get_global_rect()
	assert(safe4.encloses(gas_rect4), "FAIL: Gas button must be above home indicator")
	assert(safe4.encloses(brk_rect4), "FAIL: Brake button must be above home indicator")
	print("  -> Profile 4 PASS: Bottom home bar avoided | Safe Rect: %s" % safe4)

	# -------------------------------------------------------------------------
	# 5. Profile 5: 20:9 Dual Cutouts + Bottom Home Bar (2400x1080, left 290px, right 290px, bottom 80px)
	# -------------------------------------------------------------------------
	print("[PROFILE 5] 20:9 Dual Cutouts + Bottom Home Bar (Left/Right 290px, Bottom 80px)...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(290, 0, 1820, 1000), Vector2i(2400, 1080))
	var safe5 := controller.touch_ui.get_resolved_safe_rect()
	assert(is_equal_approx(safe5.position.x, 25.0) and is_equal_approx(safe5.end.x, 935.0) and is_equal_approx(safe5.end.y, 500.0), "FAIL: Safe area 5 transform insets")
	
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	var gas_rect5: Rect2 = controller.touch_ui.gas_button.get_global_rect()
	var brk_rect5: Rect2 = controller.touch_ui.brake_button.get_global_rect()
	var hbrk_rect5: Rect2 = controller.touch_ui.handbrake_button.get_global_rect()
	var rs_rect5: Rect2 = controller.touch_ui.route_switch_button.get_global_rect()
	var dism_rect5: Rect2 = controller.touch_ui.dismount_button.get_global_rect()
	assert(safe5.encloses(gas_rect5), "FAIL: Gas enclosed in dual cutout")
	assert(safe5.encloses(brk_rect5), "FAIL: Brake enclosed in dual cutout")
	assert(safe5.encloses(hbrk_rect5), "FAIL: Handbrake enclosed in dual cutout")
	assert(safe5.encloses(rs_rect5), "FAIL: Route Switch enclosed in dual cutout")
	assert(safe5.encloses(dism_rect5), "FAIL: Dismount enclosed in dual cutout")
	print("  -> Profile 5 PASS: Dual cutouts + home bar enclosed | Safe Rect: %s" % safe5)

	# -------------------------------------------------------------------------
	# 6. Profile 6: 4:3 Tablet Landscape (2048x1536 iPad Sanity)
	# -------------------------------------------------------------------------
	print("[PROFILE 6] 4:3 Tablet Landscape (2048x1536 iPad Sanity)...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 2048, 1536), Vector2i(2048, 1536))
	var safe6 := controller.touch_ui.get_resolved_safe_rect()
	assert(safe6 == vp_rect, "FAIL: 4:3 iPad safe area must equal viewport")
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	assert(safe6.encloses(controller.touch_ui.gas_button.get_global_rect()), "FAIL: 4:3 Tablet gas enclosed")
	print("  -> Profile 6 PASS: 4:3 Tablet enclosed | Safe Rect: %s" % safe6)

	# -------------------------------------------------------------------------
	# 7. Ergonomic Control Hierarchy & Hitbox Separation (Ticket 02.2A)
	# -------------------------------------------------------------------------
	print("[ERGONOMICS] Testing Right-Thumb Button Hierarchy, Spacing & Overlap...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 960, 540), Vector2i(960, 540))
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	await controller.get_tree().process_frame

	var gas_r: Rect2 = controller.touch_ui.gas_button.get_global_rect()
	var brk_r: Rect2 = controller.touch_ui.brake_button.get_global_rect()
	var hbrk_r: Rect2 = controller.touch_ui.handbrake_button.get_global_rect()
	var rs_r: Rect2 = controller.touch_ui.route_switch_button.get_global_rect()
	var dism_r: Rect2 = controller.touch_ui.dismount_button.get_global_rect()

	# Pairwise non-intersection
	assert(not gas_r.intersects(brk_r), "FAIL: Gas and Brake must not overlap")
	assert(not gas_r.intersects(hbrk_r), "FAIL: Gas and Handbrake must not overlap")
	assert(not gas_r.intersects(rs_r), "FAIL: Gas and Route Switch must not overlap")
	assert(not brk_r.intersects(hbrk_r), "FAIL: Brake and Handbrake must not overlap")
	assert(not brk_r.intersects(rs_r), "FAIL: Brake and Route Switch must not overlap")
	assert(not hbrk_r.intersects(rs_r), "FAIL: Handbrake and Route Switch must not overlap")
	assert(not dism_r.intersects(rs_r), "FAIL: Dismount and Route Switch must not overlap")
	assert(not dism_r.intersects(hbrk_r), "FAIL: Dismount and Handbrake must not overlap")

	# Physical separation margins (16px grid)
	var gas_brk_gap: float = gas_r.position.x - brk_r.end.x
	assert(gas_brk_gap >= 15.0, "FAIL: Gas-Brake gap must be >= 15px (actual: %.1f)" % gas_brk_gap)

	var hbrk_brk_gap: float = brk_r.position.y - hbrk_r.end.y
	assert(hbrk_brk_gap >= 15.0, "FAIL: Handbrake-Brake gap must be >= 15px (actual: %.1f)" % hbrk_brk_gap)

	var rs_gas_gap: float = gas_r.position.y - rs_r.end.y
	assert(rs_gas_gap >= 15.0, "FAIL: RouteSwitch-Gas gap must be >= 15px (actual: %.1f)" % rs_gas_gap)

	var dism_gap: float = rs_r.position.y - dism_r.end.y
	assert(dism_gap >= 100.0, "FAIL: Dismount button must be >= 100px separated from driving cluster (actual: %.1f)" % dism_gap)
	print("  -> Ergonomic Hierarchy PASS: Clean margins (Gas-Brake: %.1fpx, E-Brake-Brake: %.1fpx, Route-Gas: %.1fpx, Dismount: %.1fpx)" % [gas_brk_gap, hbrk_brk_gap, rs_gas_gap, dism_gap])

	# -------------------------------------------------------------------------
	# 8. Stale Pointer Purge on Safe-Area Recomputation
	# -------------------------------------------------------------------------
	print("[INPUT PURGE] Testing touch state purge on layout resize/safe-area update...")
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 960, 540), Vector2i(960, 540))
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	
	# Simulate active gas touch
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 3
	touch_down.pressed = true
	controller.touch_ui.gas_button.gui_input.emit(touch_down)
	assert(controller.touch_ui._gas_touch_index == 3 and controller.touch_ui._is_gas_pressed, "FAIL: Gas must register active touch index 3")
	
	# Trigger simulated safe area change -> Must purge touch index 3
	controller.touch_ui.set_simulated_safe_area(Rect2i(100, 0, 860, 540), Vector2i(960, 540))
	assert(controller.touch_ui._gas_touch_index == -1 and not controller.touch_ui._is_gas_pressed, "FAIL: Gas touch must be purged on safe area recomputation")
	print("  -> Input Purge PASS: Zero stale touch state survived layout update!")

	# Clean up simulator
	controller.touch_ui.clear_simulated_safe_area()
	controller.touch_ui.set_route_switch_button_visible(false)

	print("\n=========================================================================")
	print("[ALL 02.1A TRANSFORM + 02.2 ERGONOMIC ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


static func export_safe_area_proof(controller: ScrapTestBlock) -> void:
	print("\n[V8 SAFE AREA PROOF] Exporting screenshots for all 6 simulation profiles...")
	await controller.get_tree().create_timer(0.1).timeout
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	controller.touch_ui.show_tension_hud("[ ALERT: PURSUIT ACTIVE ]")

	# Profile 1: 16:9 Standard
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 960, 540), Vector2i(960, 540))
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_safe_area_01_16x9_standard.png")
	print("  Saved: v8_safe_area_01_16x9_standard.png")

	# Profile 2: 19.5:9 Deep Left Cutout
	controller.touch_ui.set_simulated_safe_area(Rect2i(290, 0, 2050, 1080), Vector2i(2340, 1080))
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_safe_area_02_19_5x9_left_notch.png")
	print("  Saved: v8_safe_area_02_19_5x9_left_notch.png")

	# Profile 3: 19.5:9 Deep Right Cutout
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 2050, 1080), Vector2i(2340, 1080))
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_safe_area_03_19_5x9_right_notch.png")
	print("  Saved: v8_safe_area_03_19_5x9_right_notch.png")

	# Profile 4: 20:9 Bottom Home Bar
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 2400, 1000), Vector2i(2400, 1080))
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_safe_area_04_20x9_home_bar.png")
	print("  Saved: v8_safe_area_04_20x9_home_bar.png")

	# Profile 5: 20:9 Dual Cutout + Home Bar
	controller.touch_ui.set_simulated_safe_area(Rect2i(290, 0, 1820, 1000), Vector2i(2400, 1080))
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_safe_area_05_20x9_dual_cutout.png")
	print("  Saved: v8_safe_area_05_20x9_dual_cutout.png")

	# Profile 6: 4:3 Tablet
	controller.touch_ui.set_simulated_safe_area(Rect2i(0, 0, 2048, 1536), Vector2i(2048, 1536))
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_safe_area_06_4x3_tablet.png")
	print("  Saved: v8_safe_area_06_4x3_tablet.png")

	controller.touch_ui.clear_simulated_safe_area()
	controller.touch_ui.set_route_switch_button_visible(false)
	print("\n[ALL 6 SAFE AREA PROOFS EXPORTED SUCCESSFULLY!]")
	controller.get_tree().quit(0)


static func export_mobile_gameplay_states(controller: ScrapTestBlock) -> void:
	print("\n[V8 MOBILE GAMEPLAY STATES] Exporting 8 gameplay states under mobile UI...")
	
	# State 1: Cold Start / Foot Action
	controller.reset_slice()
	await controller.get_tree().create_timer(0.2).timeout
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	controller.touch_ui.close_interaction_overlay()
	controller.touch_ui.hide_tension_hud()
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_01_cold_start.png")
	print("  Saved: v8_mobile_01_cold_start.png (Cold Start / Foot Action)")

	# State 2: Tuner Approach / Overlay Active
	controller.reset_slice()
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.2)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller.touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	controller.camera.set_interaction_mode(true, controller.signal_tuner)
	await controller.get_tree().create_timer(0.25).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_02_tuner_active.png")
	print("  Saved: v8_mobile_02_tuner_active.png (Tuner Overlay Active)")

	# State 3: Corroded Panel / Peel & Core Extraction
	controller.reset_slice()
	controller.player.global_position = controller.corroded_panel.global_position + Vector3(0, 0, 1.2)
	controller.corroded_panel.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller.touch_ui.show_gesture_overlay("EXPOSE_CORE")
	controller.camera.set_interaction_mode(true, controller.corroded_panel)
	await controller.get_tree().create_timer(0.25).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_03_peel_extract.png")
	print("  Saved: v8_mobile_03_peel_extract.png (Peel & Core Extract Active)")

	# State 4: Bike Mounted / Staging
	controller.reset_slice()
	controller.touch_ui.close_interaction_overlay()
	controller.camera.set_interaction_mode(false)
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.is_player_in_range = true
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	await controller.get_tree().create_timer(0.15).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_04_bike_mounted.png")
	print("  Saved: v8_mobile_04_bike_mounted.png (Bike Mounted & Staged)")

	# State 5: Normal Driving / 2-Column Controls
	controller.reset_slice()
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	controller.courier_bike.global_position = Vector3(0.0, 0.0, -8.0)
	controller.courier_bike.current_speed = 10.0
	controller._throttle_input = 1.0
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(false)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_05_driving_2col.png")
	print("  Saved: v8_mobile_05_driving_2col.png (Normal Driving 2-Column)")

	# State 6: Pursuit Active / Route Switch Contextual
	controller.reset_slice()
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	controller.pursuer.activate_pursuit(controller.courier_bike)
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.PURSUIT_ACTIVE
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	controller.touch_ui.show_tension_hud("[ ALERT: PURSUIT ACTIVE ]")
	controller.touch_ui.update_tension_proximity(12.5, true)
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_06_pursuit_route.png")
	print("  Saved: v8_mobile_06_pursuit_route.png (Pursuit & Route Switch Active)")

	# State 7: Gate / Shortcut Decision at Speed
	controller.reset_slice()
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.request_mount(controller.player)
	await controller.get_tree().create_timer(0.35).timeout
	controller.courier_bike.global_position = Vector3(0.0, 0.0, -18.0)
	controller.courier_bike.current_speed = 13.5
	controller.touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	controller.touch_ui.set_route_switch_button_visible(true)
	controller.touch_ui.show_tension_hud("[ ALERT: PURSUIT ACTIVE ]")
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_07_gate_shortcut.png")
	print("  Saved: v8_mobile_07_gate_shortcut.png (Gate / Shortcut Decision at Speed)")

	# State 8: Quiet Aftermath / Replay Overlay Visible
	controller.reset_slice()
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.EVADED
	controller.touch_ui.hide_tension_hud()
	controller.touch_ui.show_replay_overlay()
	await controller.get_tree().create_timer(0.2).timeout
	controller.get_viewport().get_texture().get_image().save_png("res://verification/v8/v8_mobile_08_aftermath_replay.png")
	print("  Saved: v8_mobile_08_aftermath_replay.png (Quiet Aftermath & Replay)")

	print("\n[ALL 8 MOBILE GAMEPLAY STATES EXPORTED SUCCESSFULLY!]\n")
	controller.get_tree().quit(0)


