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
	print("[V7_TICKET03_ASSERTIONS] Starting Signal Tuning Gesture Coherence Suite (Ticket 03)...")
	print("Target Build: main@02445d3 | Testing prompt coherence & drag tuning curve")
	print("=========================================================================\n")
	
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	
	# 1. Approach SignalTuner & Begin Interaction
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.0)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	
	await controller.get_tree().create_timer(0.2).timeout
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: Tuner must enter TUNING state")
	var tuner_hint: String = controller.touch_ui.gesture_hint_label.text
	assert(tuner_hint.contains("SWIPE"), "FAIL: Tuner hint must preserve touch swipe guidance")
	assert(tuner_hint.contains("LEFT MOUSE") and tuner_hint.contains("DRAG"), "FAIL: Tuner hint must expose desktop mouse-drag guidance")
	print("[TICKET 03 TEST 1 PASSED] UI prompt exposes touch + desktop tuning affordances: %s" % tuner_hint)
	
	# 2. Simulate InputEventScreenTouch & InputEventScreenDrag for horizontal tuning
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(400, 300)
	controller.touch_ui._gui_input(touch_down)
	
	# 2. 60Hz vs 120Hz displacement invariance at 100px (small) and 300px (moderate)
	var drag_ev := InputEventScreenDrag.new()
	drag_ev.index = 0
	
	# Test A: 1×100px vs 10×10px
	controller.signal_tuner.current_frequency = 0.15; controller.signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(100.0, 0.0); controller.touch_ui._tuning_accum_px = 0.0
	controller.touch_ui._gui_input(drag_ev)
	var a1_freq := controller.signal_tuner.current_frequency
	controller.signal_tuner.current_frequency = 0.15; controller.signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(10.0, 0.0); controller.touch_ui._tuning_accum_px = 0.0
	for i in range(10): controller.touch_ui._gui_input(drag_ev)
	var a2_freq := controller.signal_tuner.current_frequency
	assert(abs(a1_freq - a2_freq) < 0.0001, "FAIL: 1x100px vs 10x10px must be invariant")
	print("[TICKET 03 TEST 2 PASSED] 60Hz/120Hz invariance 100px: single=%.4f multi=%.4f" % [a1_freq, a2_freq])
	
	# Test B: 3×100px (total 300px) vs 30×10px — larger displacement
	controller.signal_tuner.current_frequency = 0.15; controller.signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(100.0, 0.0); controller.touch_ui._tuning_accum_px = 0.0
	for i in range(3): controller.touch_ui._gui_input(drag_ev)
	var b1_freq := controller.signal_tuner.current_frequency
	controller.signal_tuner.current_frequency = 0.15; controller.signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(10.0, 0.0); controller.touch_ui._tuning_accum_px = 0.0
	for i in range(30): controller.touch_ui._gui_input(drag_ev)
	var b2_freq := controller.signal_tuner.current_frequency
	assert(abs(b1_freq - b2_freq) < 0.0001, "FAIL: 3x100px vs 30x10px must be invariant")
	print("[TICKET 03 TEST 3 PASSED] 60Hz/120Hz invariance 300px: 3x100=%.4f 30x10=%.4f" % [b1_freq, b2_freq])
	
	# Test C: Extreme swipe saturation — 2000px must NOT slam to 0/1 instantly
	controller.signal_tuner.current_frequency = 0.15; controller.signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(2000.0, 0.0); controller.touch_ui._tuning_accum_px = 0.0
	controller.touch_ui._gui_input(drag_ev)
	var extreme_freq := controller.signal_tuner.current_frequency
	assert(extreme_freq < 1.0, "FAIL: Extreme swipe must NOT instantly reach 1.0 (tanh saturation required)")
	assert(extreme_freq > 0.6, "FAIL: Extreme swipe from 0.15 must reach upper range")
	print("[TICKET 03 TEST 4 PASSED] Extreme swipe saturation: freq=%.4f (bounded, not 1.0)" % extreme_freq)
	
	# 3. Near-lock exit lifecycle: NEAR_LOCK_ENTER/EXIT events
	controller.signal_tuner.current_frequency = 0.15; controller.signal_tuner._drag_start_freq = 0.15
	controller.signal_tuner._near_lock_active = false
	var near_lock_events: Array = []
	var evt_cb := func(ev: String, _pos: Vector3): near_lock_events.append(ev)
	controller.signal_tuner.audio_event_triggered.connect(evt_cb)
	
	# Drag into lock range to trigger ENTER
	controller.signal_tuner.current_frequency = 0.72 # place inside lock range
	controller.signal_tuner._process(0.016) # one frame
	assert("TUNER_NEAR_LOCK_ENTER" in near_lock_events, "FAIL: Must emit TUNER_NEAR_LOCK_ENTER on entering lock range")
	var enter_count := near_lock_events.count("TUNER_NEAR_LOCK_ENTER")
	controller.signal_tuner._process(0.016) # second frame — must NOT re-emit ENTER
	assert(near_lock_events.count("TUNER_NEAR_LOCK_ENTER") == enter_count, "FAIL: TUNER_NEAR_LOCK_ENTER must emit ONCE, not every frame")
	print("[TICKET 03 TEST 5 PASSED] TUNER_NEAR_LOCK_ENTER emitted once on entering tolerance")
	
	# Drag out of lock range to trigger EXIT
	controller.signal_tuner.current_frequency = 0.90 # outside lock range
	controller.signal_tuner._process(0.016)
	assert("TUNER_NEAR_LOCK_EXIT" in near_lock_events, "FAIL: Must emit TUNER_NEAR_LOCK_EXIT when leaving lock range")
	var exit_count := near_lock_events.count("TUNER_NEAR_LOCK_EXIT")
	controller.signal_tuner._process(0.016) # second frame — must NOT re-emit EXIT
	assert(near_lock_events.count("TUNER_NEAR_LOCK_EXIT") == exit_count, "FAIL: TUNER_NEAR_LOCK_EXIT must emit ONCE, not every frame")
	print("[TICKET 03 TEST 6 PASSED] TUNER_NEAR_LOCK_EXIT emitted once on leaving tolerance")
	
	controller.signal_tuner.audio_event_triggered.disconnect(evt_cb)
	
	# 4. Fine-tune using tanh accumulator to reach lock range and complete lock payoff
	# Force READY so begin_interaction can succeed (near-lock tests left tuner in TUNING)
	controller.signal_tuner._set_state(SignalTuner.TunerState.READY)
	controller.signal_tuner.current_frequency = 0.15
	# Reset touch_ui accumulator state — extreme swipe test (2000px) left _tuning_accum_px dirty
	controller.touch_ui._tuning_accum_px = 0.0
	controller.touch_ui._is_tuning = false
	controller.touch_ui._interaction_touch_index = -1
	controller.signal_tuner.begin_interaction(controller.player.global_position)
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: begin_interaction must set TUNING")
	var re_touch_down := InputEventScreenTouch.new()
	re_touch_down.index = 0; re_touch_down.pressed = true
	re_touch_down.position = Vector2(400, 300)
	controller.touch_ui._gui_input(re_touch_down)
	# tanh(295*0.003/0.65) = tanh(1.362) = 0.878; 0.65*0.878 = 0.571; 0.15+0.571 = 0.721 ∈ [0.67, 0.77]
	var fine_drag := InputEventScreenDrag.new()
	fine_drag.index = 0; fine_drag.relative = Vector2(295.0, 0.0)
	controller.touch_ui._gui_input(fine_drag)
	print("[TICKET 03 TEST 7 DEBUG] freq=%.4f target=%.4f tol=%.4f" % [controller.signal_tuner.current_frequency, controller.signal_tuner.target_frequency, controller.signal_tuner.lock_tolerance])
	assert(abs(controller.signal_tuner.current_frequency - controller.signal_tuner.target_frequency) <= controller.signal_tuner.lock_tolerance, "FAIL: 295px drag must reach lock tolerance via tanh curve")
	print("[TICKET 03 TEST 7 PASSED] Fine-tuning reached lock range: current=%.3f, target=%.3f" % [controller.signal_tuner.current_frequency, controller.signal_tuner.target_frequency])
	
	# 5. Dwell lock payoff — fires exactly once
	# Use array ref to avoid GDScript int capture-by-value in lambda
	var lock_count := [0]
	var lock_cb := func(_t: SignalTuner): lock_count[0] += 1
	controller.signal_tuner.signal_locked.connect(lock_cb)
	await controller.get_tree().create_timer(0.5).timeout
	controller.signal_tuner.signal_locked.disconnect(lock_cb)
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL: SignalTuner must enter LOCKED state after dwell")
	assert(lock_count[0] == 1, "FAIL: signal_locked must fire exactly once (got %d)" % lock_count[0])
	print("[TICKET 03 TEST 8 PASSED] Signal lock achieved cleanly! Lock count = %d" % lock_count[0])
	
	print("\n=========================================================================")
	print("[ALL V7 TICKET 03 ASSERTIONS PASSED CLEANLY]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


static func run_stress_retest(controller: ScrapTestBlock) -> void:
	print("\n=========================================================================")
	print("[V7_TICKET03_STRESS_RETEST] Starting Adversarial Input Stress & Multi-Frame Retest Suite...")
	print("Target Build: main@a13b018 | Scene: scrap_test_block.tscn")
	print("=========================================================================\n")
	
	controller.reset_slice()
	await controller.get_tree().create_timer(0.1).timeout
	
	# Enter interaction mode with SignalTuner
	controller.player.global_position = controller.signal_tuner.global_position + Vector3(0, 0, 1.0)
	controller.signal_tuner.update_player_distance(controller.player.global_position)
	controller._evaluate_target_selection()
	controller._on_action_pressed()
	await controller.get_tree().create_timer(0.2).timeout
	
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: SignalTuner must be in TUNING state")
	assert(controller.touch_ui._current_gesture_type == "TUNE_SIGNAL", "FAIL: Gesture overlay must be TUNE_SIGNAL")
	
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(400, 300)
	controller.touch_ui._gui_input(touch_down)
	assert(controller.touch_ui._interaction_touch_index == 0, "FAIL: Touch down must acquire pointer index 0")
	assert(controller.touch_ui._is_tuning == true, "FAIL: _is_tuning must be true after touch down")
	
	# -------------------------------------------------------------------------
	# TEST 1: Rapid Horizontal Swipe Bursts (Extreme Velocities)
	# -------------------------------------------------------------------------
	print("--- [TEST 1] Rapid Horizontal Swipe Bursts (Extreme Velocities) ---")
	controller.signal_tuner.current_frequency = 0.50
	controller.signal_tuner._drag_start_freq = 0.50
	controller.touch_ui._tuning_accum_px = 0.0
	var drag_ev := InputEventScreenDrag.new()
	drag_ev.index = 0
	
	var test1_clamped_correctly := true
	var test1_bounded := true
	
	var swipe_deltas: Array[float] = [1500.0, -1500.0, 3000.0, -3000.0, 5000.0, -5000.0, 200.0, -200.0, 800.0, -800.0]
	for idx in range(swipe_deltas.size()):
		var raw_dx: float = swipe_deltas[idx]
		var pre_accum: float = controller.touch_ui._tuning_accum_px
		var post_accum: float = pre_accum + raw_dx
		var raw: float = post_accum * 0.003
		var mapped: float = 0.65 * tanh(raw / 0.65)
		var expected_freq := clampf(0.50 + mapped, 0.0, 1.0)
		
		var pre_freq := controller.signal_tuner.current_frequency
		drag_ev.relative = Vector2(raw_dx, 0.0)
		controller.touch_ui._gui_input(drag_ev)
		
		var post_freq := controller.signal_tuner.current_frequency
		
		if post_freq < 0.0 or post_freq > 1.0:
			test1_bounded = false
		if abs(post_freq - expected_freq) > 0.0001:
			test1_clamped_correctly = false
			
		print("[TEST 1 SWIPE %d] raw_dx=%.1f | accum=%.1f | expected_freq=%.3f | pre_freq=%.3f -> post_freq=%.3f" % [
			idx, raw_dx, controller.touch_ui._tuning_accum_px, expected_freq, pre_freq, post_freq
		])
	
	assert(test1_clamped_correctly, "FAIL: Swipe bursts must match accumulated tanh curve")
	assert(test1_bounded, "FAIL: Swipe bursts must stay bounded in [0, 1]")
	print("[TEST 1 RESULT] Clamped Correctly = %s | Strictly Bounded [0,1] = %s" % [
		test1_clamped_correctly, test1_bounded
	])
	
	# -------------------------------------------------------------------------
	# TEST 2: Micro-adjustments Near Lock Tolerance (Target Frequency 0.72 +/- 0.05)
	# -------------------------------------------------------------------------
	print("\n--- [TEST 2] Micro-adjustments Near Lock Tolerance (0.72 +/- 0.05) ---")
	controller.signal_tuner.current_frequency = 0.65
	controller.signal_tuner._drag_start_freq = 0.65
	controller.signal_tuner._dwell_timer = 0.0
	controller.signal_tuner.is_powered = true
	controller.signal_tuner.is_player_in_range = true
	controller.signal_tuner.current_state = SignalTuner.TunerState.TUNING
	
	controller.touch_ui._tuning_accum_px = 0.0
	controller.touch_ui._is_tuning = true
	controller.touch_ui._interaction_touch_index = 0
	
	# Small micro-adjustment: 5px
	drag_ev.relative = Vector2(5.0, 0.0)
	controller.touch_ui._gui_input(drag_ev)
	var exp_f1: float = 0.65 + 0.65 * tanh((5.0 * 0.003) / 0.65)
	assert(abs(controller.signal_tuner.current_frequency - exp_f1) < 0.001, "FAIL: 5px micro-adjustment must match tanh curve")
	await controller.get_tree().process_frame
	assert(controller.signal_tuner._dwell_timer == 0.0, "FAIL: Dwell timer must be 0 outside tolerance")
	
	# Move into lock range: [0.67, 0.77]. Relative = +20px -> total accum = 25px -> freq ≈ 0.7247
	drag_ev.relative = Vector2(20.0, 0.0)
	controller.touch_ui._gui_input(drag_ev)
	print("[TEST 2 LOG] Entered lock tolerance: frequency = %.3f (Target 0.72 +/- 0.05)" % controller.signal_tuner.current_frequency)
	assert(abs(controller.signal_tuner.current_frequency - controller.signal_tuner.target_frequency) <= controller.signal_tuner.lock_tolerance, "FAIL: Must be inside lock tolerance")
	
	await controller.get_tree().create_timer(0.05).timeout
	var dwell_mid := controller.signal_tuner._dwell_timer
	assert(dwell_mid > 0.0, "FAIL: Dwell timer must accumulate while in lock range")
	print("[TEST 2 LOG] Dwell timer accumulating: %.3fs / 0.400s" % dwell_mid)
	
	# Push past upper bound (0.77): relative = +80px -> total accum = 105px -> freq ≈ 0.944
	drag_ev.relative = Vector2(80.0, 0.0)
	controller.touch_ui._gui_input(drag_ev)
	print("[TEST 2 LOG] Nudge past upper bound: frequency = %.3f" % controller.signal_tuner.current_frequency)
	assert(controller.signal_tuner.current_frequency > 0.77, "FAIL: Frequency must be past upper bound")
	
	await controller.get_tree().create_timer(0.05).timeout
	var dwell_decay := controller.signal_tuner._dwell_timer
	print("[TEST 2 LOG] Dwell timer decayed from %.3fs to %.3fs outside tolerance" % [dwell_mid, dwell_decay])
	assert(dwell_decay < dwell_mid, "FAIL: Dwell timer must decay outside tolerance")
	
	# Pull back into lock range near center: relative = -82px -> total accum = 23px -> freq ≈ 0.7188
	drag_ev.relative = Vector2(-82.0, 0.0)
	controller.touch_ui._gui_input(drag_ev)
	print("[TEST 2 LOG] Re-entered lock range near center: frequency = %.3f" % controller.signal_tuner.current_frequency)
	assert(abs(controller.signal_tuner.current_frequency - controller.signal_tuner.target_frequency) <= controller.signal_tuner.lock_tolerance, "FAIL: Must re-enter lock tolerance")
	
	await controller.get_tree().create_timer(0.45).timeout
	assert(controller.signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL: Tuner must enter LOCKED state after holding in range")
	print("[TEST 2 RESULT] Micro-adjustments & Lock Dwell verified cleanly! Lock achieved at freq = %.3f" % controller.signal_tuner.current_frequency)
	
	# -------------------------------------------------------------------------
	# TEST 3: Rapid Touch-On Touch-Off Releases Mid-Tuning
	# -------------------------------------------------------------------------
	print("\n--- [TEST 3] Rapid Touch-On Touch-Off Releases Mid-Tuning ---")
	controller.signal_tuner.current_state = SignalTuner.TunerState.TUNING
	controller.signal_tuner.current_frequency = 0.30
	controller.signal_tuner._dwell_timer = 0.0
	controller.touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	
	print("[TEST 3 LOG] Rapidly toggling touch-down / touch-up 10 times mid-tuning...")
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	
	var touch_index_cleared_cleanly := true
	for cycle in range(10):
		touch_down.pressed = true
		touch_down.index = cycle
		controller.touch_ui._gui_input(touch_down)
		if controller.touch_ui._interaction_touch_index != cycle:
			touch_index_cleared_cleanly = false
			
		drag_ev.index = cycle
		drag_ev.relative = Vector2(10.0, 0.0)
		controller.touch_ui._gui_input(drag_ev)
		
		touch_up.index = cycle
		controller.touch_ui._gui_input(touch_up)
		if controller.touch_ui._interaction_touch_index != -1:
			touch_index_cleared_cleanly = false
			
	print("[TEST 3 LOG] Touch index ownership cleared cleanly across 10 rapid touch cycles = %s" % touch_index_cleared_cleanly)
	
	print("[TEST 3 LOG] Testing touch release mid-tuning inside lock tolerance (freq = 0.72)...")
	touch_down.index = 0
	touch_down.pressed = true
	controller.touch_ui._gui_input(touch_down)
	controller.signal_tuner.current_frequency = 0.72
	controller.signal_tuner._dwell_timer = 0.0
	
	touch_up.index = 0
	controller.touch_ui._gui_input(touch_up)
	assert(controller.touch_ui._is_tuning == false, "FAIL: _is_tuning in touch_ui must be false on release")
	
	var state_before_wait := controller.signal_tuner.current_state
	print("[TEST 3 LOG] Finger released: touch_ui._is_tuning = %s | signal_tuner.current_state = %s" % [
		controller.touch_ui._is_tuning, SignalTuner.TunerState.keys()[state_before_wait]
	])
	
	await controller.get_tree().create_timer(0.45).timeout
	var state_after_wait := controller.signal_tuner.current_state
	print("[TEST 3 LOG] After 0.45s hands-free dwell: signal_tuner.current_state = %s" % SignalTuner.TunerState.keys()[state_after_wait])
	
	var hands_free_lock_triggered := (state_after_wait == SignalTuner.TunerState.LOCKED)
	print("[TEST 3 RESULT] Touch-off pointer clearing = %s | Hands-free auto-lock when finger lifted = %s" % [
		touch_index_cleared_cleanly, hands_free_lock_triggered
	])
	
	# -------------------------------------------------------------------------
	# TEST 4: Accumulated tanh Saturation & Monotonicity Verification
	# -------------------------------------------------------------------------
	print("\n--- [TEST 4] Accumulated tanh Saturation & Monotonicity Verification ---")
	controller.touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	controller.signal_tuner.current_state = SignalTuner.TunerState.TUNING
	controller.signal_tuner.current_frequency = 0.50
	controller.signal_tuner._drag_start_freq = 0.50
	
	touch_down.index = 0
	touch_down.pressed = true
	controller.touch_ui._gui_input(touch_down)
	
	var scaling_monotonic := true
	var accum_displacements: Array[float] = [-500.0, -200.0, -100.0, -50.0, -10.0, 0.0, 10.0, 50.0, 100.0, 200.0, 500.0]
	var scale_results: Array[Array] = []
	
	var last_mapped := -100.0
	for target_accum in accum_displacements:
		var delta_to_apply: float = target_accum - controller.touch_ui._tuning_accum_px
		drag_ev.index = 0
		drag_ev.relative = Vector2(delta_to_apply, 0.0)
		controller.touch_ui._gui_input(drag_ev)
		
		var raw: float = target_accum * 0.003
		var expected_mapped: float = 0.65 * tanh(raw / 0.65)
		var expected_freq: float = clampf(0.50 + expected_mapped, 0.0, 1.0)
		var actual_freq := controller.signal_tuner.current_frequency
		
		scale_results.append([target_accum, expected_freq, actual_freq])
		if abs(actual_freq - expected_freq) > 0.0001:
			scaling_monotonic = false
		if expected_mapped < last_mapped:
			scaling_monotonic = false
		last_mapped = expected_mapped
			
	print("[TEST 4 LOG] Touch Drag Tanh Saturation Table:")
	print("  Accum (px) | Expected Freq | Actual Freq | Match")
	print("  -------------------------------------------------")
	for r in scale_results:
		var r_acc: float = float(r[0])
		var r_exp: float = float(r[1])
		var r_act: float = float(r[2])
		print("  %10.1f | %13.4f | %11.4f | %s" % [r_acc, r_exp, r_act, abs(r_act - r_exp) <= 0.0001])
		
	# Extreme negative saturation: smooth bounding towards 0.50 - 0.65 = -0.15 -> clamped to 0.0
	controller.touch_ui._tuning_accum_px = 0.0
	controller.signal_tuner.current_frequency = 0.50
	controller.signal_tuner._drag_start_freq = 0.50
	
	drag_ev.relative = Vector2(-10000.0, 0.0)
	controller.touch_ui._gui_input(drag_ev)
	var freq_left_clamp := controller.signal_tuner.current_frequency
	assert(freq_left_clamp == 0.0, "FAIL: Extreme left drag clamped smoothly to 0.0")
	
	# Extreme positive saturation: 0.50 + 0.65 = 1.15 -> clamped to 1.0
	controller.touch_ui._tuning_accum_px = 0.0
	controller.signal_tuner.current_frequency = 0.50
	controller.signal_tuner._drag_start_freq = 0.50
	
	drag_ev.relative = Vector2(10000.0, 0.0)
	controller.touch_ui._gui_input(drag_ev)
	var freq_right_clamp := controller.signal_tuner.current_frequency
	assert(freq_right_clamp == 1.0, "FAIL: Extreme right drag clamped smoothly to 1.0")
	
	assert(scaling_monotonic, "FAIL: Tanh scaling must be strictly monotonic and match formula")
	print("[TEST 4 RESULT] Tanh saturation formula mapped = 0.65 * tanh(raw / 0.65) verified! Monotonic = %s, Boundaries [0.0, 1.0] solid!" % scaling_monotonic)
	
	print("\n=========================================================================")
	print("[V7 TICKET 03 ADVERSARIAL STRESS RETEST SUITE COMPLETED]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


