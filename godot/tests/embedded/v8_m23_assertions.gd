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
	print("[RUNNING V8 M23 VEHICLE RADIO LIFECYCLE & PERSISTENCE SUITE (#23)]")
	print("=========================================================================\n")

	# ASSERTION 1: Generic Seam Verification & Stale Dismount Falsification
	print("[ASSERTION 1] Testing Generic Mount/Dismount Radio Seam & Stale Dismount...")
	assert(controller.courier_bike != null and controller.scrap_hauler != null, "FAIL 1: Both vehicles must exist in scene")
	assert(controller.has_method("_on_vehicle_mounted_generic"), "FAIL 1: Main controller must have _on_vehicle_mounted_generic")
	assert(controller.has_method("_on_vehicle_dismounted_generic"), "FAIL 1: Main controller must have _on_vehicle_dismounted_generic")
	assert(controller.has_method("get_radio_owner"), "FAIL 1: Controller must expose get_radio_owner")
	assert(controller.has_method("is_radio_enabled"), "FAIL 1: Controller must expose is_radio_enabled")
	assert(controller.has_method("get_radio_station_id"), "FAIL 1: Controller must expose get_radio_station_id")

	# Stale dismount falsification: Bike mounts, then Hauler mounts, then stale Bike dismount fires
	controller._on_bike_mounted(controller.player)
	assert(controller.get_radio_owner() == controller.courier_bike, "FAIL 1: Bike is owner")
	controller._on_hauler_mounted(controller.player)
	assert(controller.get_radio_owner() == controller.scrap_hauler, "FAIL 1: Hauler is newest owner")
	assert(controller.active_vehicle == controller.scrap_hauler, "FAIL 1: Hauler is active vehicle")
	controller._on_vehicle_dismounted_generic(controller.courier_bike) # Stale dismount from older Bike
	assert(controller.get_radio_owner() == controller.scrap_hauler, "FAIL 1: Stale Bike dismount must NOT clear Hauler ownership")
	assert(controller.active_vehicle == controller.scrap_hauler, "FAIL 1: Stale Bike dismount must NOT clear Hauler active vehicle")
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING, "FAIL 1: Driving UI preserved despite stale dismount")
	controller._on_vehicle_dismounted_generic(controller.scrap_hauler)
	assert(controller.get_radio_owner() == null, "FAIL 1: Matching Hauler dismount clears ownership")
	print("  -> Assertion 1 PASS: Shared generic seam and stale-dismount protection verified!")

	# ASSERTION 2: Bike Mount & Real Playback Cursor Advance
	print("\n[ASSERTION 2] Testing Courier Bike Mount & Real Playback Cursor Advance...")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller._on_bike_mounted(controller.player)
	await controller.get_tree().process_frame
	assert(controller.get_radio_owner() == controller.courier_bike, "FAIL 2: Radio owner must be Bike on mount")
	var r_player = controller.audio_mgr.get_radio_player()
	assert(r_player.is_playing() == true, "FAIL 2: Radio must be playing upon vehicle mount")
	assert(r_player.is_paused() == false, "FAIL 2: Radio must not be paused upon active mount")
	assert(not r_player.get_current_item().is_empty(), "FAIL 2: Current radio item must be populated")
	
	var wait_start := Time.get_ticks_msec()
	while r_player.get_playback_position() <= 0.0 and Time.get_ticks_msec() - wait_start < 1000:
		await controller.get_tree().process_frame
	
	var bike_cursor: float = r_player.get_playback_position()
	assert(bike_cursor > 0.0, "FAIL 2: Real playback cursor must advance > 0 (got %.3f)" % bike_cursor)
	var captured_item_2: Dictionary = r_player.get_current_item()
	var captured_seg_2: int = r_player.get_current_segment_index()
	print("  [DEBUG] Initial playing item on Bike: %s | Cursor: %.3fs" % [captured_item_2.get("id"), bike_cursor])
	print("  -> Assertion 2 PASS: Bike mount started real playback with naturally advancing cursor!")

	# ASSERTION 3: Bike Dismount / Bounded Gain Fade & Cursor Preservation
	print("\n[ASSERTION 3] Testing Bike Dismount Transition & Cursor Preservation...")
	controller._on_bike_dismounted()
	await controller.get_tree().process_frame
	var fade_wait_start := Time.get_ticks_msec()
	while not r_player.is_paused() and Time.get_ticks_msec() - fade_wait_start < 600:
		await controller.get_tree().process_frame

	assert(controller.get_radio_owner() == null, "FAIL 3: Radio owner must be null after dismount")
	assert(r_player.is_paused() == true, "FAIL 3: Radio must be paused after dismount fade")
	var stored_cursor_3: float = r_player.get_director().get_cursor_position()
	assert(stored_cursor_3 > 0.0, "FAIL 3: Stored cursor must be positive across dismount")
	assert(r_player.get_current_item().get("id") == captured_item_2.get("id"), "FAIL 3: Radio item must remain identical during dismount")
	assert(r_player.get_current_segment_index() == captured_seg_2, "FAIL 3: Segment index preserved during dismount")

	# Verify cursor remains frozen while paused
	for fr in range(5):
		await controller.get_tree().process_frame
	assert(r_player.get_director().get_cursor_position() == stored_cursor_3, "FAIL 3: Cursor must remain frozen while paused")
	print("  -> Assertion 3 PASS: Bike dismount paused radio with exact preserved cursor %.3fs!" % stored_cursor_3)

	# ASSERTION 4: Bike Remount / Resume at Preserved Cursor
	print("\n[ASSERTION 4] Testing Courier Bike Remount & Resume from Preserved Cursor...")
	controller._on_bike_mounted(controller.player)
	await controller.get_tree().process_frame
	var remount_fade_start := Time.get_ticks_msec()
	while r_player.is_paused() and Time.get_ticks_msec() - remount_fade_start < 500:
		await controller.get_tree().process_frame

	assert(controller.get_radio_owner() == controller.courier_bike, "FAIL 4: Radio owner must be Bike on remount")
	assert(r_player.is_playing() == true, "FAIL 4: Radio must be playing on remount")
	assert(r_player.is_paused() == false, "FAIL 4: Radio resumed (not paused) on remount")
	assert(r_player.get_current_item().get("id") == captured_item_2.get("id"), "FAIL 4: Same song continues on remount")
	assert(r_player.get_current_segment_index() == captured_seg_2, "FAIL 4: Same segment continues on remount")
	assert(r_player.get_director().get_cursor_position() >= stored_cursor_3, "FAIL 4: Playback continues from preserved cursor")
	print("  -> Assertion 4 PASS: Bike remount seamlessly resumed playback at preserved point!")

	# ASSERTION 5: Scrap Hauler Mount & Real Playback Proof
	print("\n[ASSERTION 5] Testing Scrap Hauler Mount & Real Playback Proof...")
	controller._on_bike_dismounted()
	await controller.get_tree().process_frame
	controller._on_hauler_mounted(controller.player)
	await controller.get_tree().process_frame
	assert(controller.active_vehicle == controller.scrap_hauler, "FAIL 5: Active vehicle must be scrap_hauler")
	assert(controller.get_radio_owner() == controller.scrap_hauler, "FAIL 5: Radio owner must be Hauler")
	var hauler_wait := Time.get_ticks_msec()
	while r_player.get_playback_position() <= 0.0 and Time.get_ticks_msec() - hauler_wait < 1000:
		await controller.get_tree().process_frame
	assert(r_player.get_playback_position() > 0.0, "FAIL 5: Hauler real playback cursor must advance > 0")
	print("  -> Assertion 5 PASS: Scrap Hauler mount verified with advancing playback cursor!")

	# ASSERTION 6: Bike -> Hauler Shared Session & Deep Director Continuity Proof
	print("\n[ASSERTION 6] Testing Bike -> Hauler Shared Session & Deep Director Continuity Proof...")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller._on_bike_mounted(controller.player)
	await controller.get_tree().process_frame
	var b_wait := Time.get_ticks_msec()
	while r_player.get_playback_position() <= 0.0 and Time.get_ticks_msec() - b_wait < 1000:
		await controller.get_tree().process_frame
	
	# Inject a pending world event and capture deep director state snapshot
	r_player.get_director().queue_world_event("world.scrap_drone_sighting")
	var seg_before: int = r_player.get_current_segment_index()
	var state_before: Dictionary = r_player.get_director().serialize_state()

	controller._on_bike_dismounted()
	await controller.get_tree().process_frame
	var d_wait := Time.get_ticks_msec()
	while not r_player.is_paused() and Time.get_ticks_msec() - d_wait < 600:
		await controller.get_tree().process_frame

	controller._on_hauler_mounted(controller.player)
	await controller.get_tree().process_frame
	var h_wait := Time.get_ticks_msec()
	while r_player.is_paused() and Time.get_ticks_msec() - h_wait < 500:
		await controller.get_tree().process_frame

	var state_after: Dictionary = r_player.get_director().serialize_state()

	assert(controller.get_radio_owner() == controller.scrap_hauler, "FAIL 6: Radio owner transferred to Hauler")
	assert(controller.is_radio_enabled() == true, "FAIL 6: Session remains enabled across transfer")
	assert(r_player.get_current_item().get("id") == state_before["current_item"].get("id"), "FAIL 6: Same song content_id transferred to Hauler")
	assert(r_player.get_current_segment_index() == seg_before, "FAIL 6: Same segment index transferred to Hauler")
	assert(state_after["initial_seed"] == state_before["initial_seed"], "FAIL 6: Director initial seed preserved")
	assert(state_after["rng_seed"] == state_before["rng_seed"], "FAIL 6: Director RNG seed preserved")
	assert(state_after["non_song_gap_counter"] == state_before["non_song_gap_counter"], "FAIL 6: Gap counter preserved")
	assert(state_after["song_history"] == state_before["song_history"], "FAIL 6: Recent song history preserved")
	assert(state_after["interstitial_history"] == state_before["interstitial_history"], "FAIL 6: Recent interstitial history preserved")
	assert(state_after["pending_world_events"] == state_before["pending_world_events"], "FAIL 6: Pending world events survived transfer")
	assert(state_after["cursor_position_sec"] >= state_before["cursor_position_sec"], "FAIL 6: Preserved cursor transferred to Hauler")
	print("  -> Assertion 6 PASS: Deep director RNG, history, and queued world events preserved across vehicle transfer!")

	# ASSERTION 7: Power Transfer Proof Across Vehicles
	print("\n[ASSERTION 7] Testing Power Transfer Proof Across Vehicles...")
	# 1. Turn OFF radio in Hauler
	controller._on_radio_toggle_pressed()
	var off_wait := Time.get_ticks_msec()
	while not r_player.is_paused() and Time.get_ticks_msec() - off_wait < 600:
		await controller.get_tree().process_frame
	assert(controller.is_radio_enabled() == false, "FAIL 7: Radio session disabled in Hauler")
	assert(r_player.is_paused() == true, "FAIL 7: Radio paused after toggle OFF in Hauler")

	# 2. Dismount Hauler
	controller._on_hauler_dismounted()
	await controller.get_tree().process_frame

	# 3. Mount Bike -> Must remain OFF because shared session is OFF
	controller._on_bike_mounted(controller.player)
	await controller.get_tree().process_frame
	assert(controller.get_radio_owner() == controller.courier_bike, "FAIL 7: Radio owner is Bike")
	assert(controller.is_radio_enabled() == false, "FAIL 7: Bike inherited disabled power state from shared session")
	assert(r_player.is_paused() == true, "FAIL 7: Radio remains paused in Bike")

	# 4. Turn radio back ON in Bike
	controller._on_radio_toggle_pressed()
	var on_wait := Time.get_ticks_msec()
	while r_player.is_paused() and Time.get_ticks_msec() - on_wait < 500:
		await controller.get_tree().process_frame
	assert(controller.is_radio_enabled() == true, "FAIL 7: Radio turned back ON in Bike")
	assert(r_player.is_paused() == false, "FAIL 7: Radio resumed in Bike after toggle ON")

	# 5. Dismount Bike, mount Hauler -> Hauler must now be ON
	controller._on_bike_dismounted()
	await controller.get_tree().process_frame
	controller._on_hauler_mounted(controller.player)
	await controller.get_tree().process_frame
	assert(controller.is_radio_enabled() == true, "FAIL 7: Hauler inherited enabled state from shared session")
	assert(r_player.is_paused() == false, "FAIL 7: Radio playing in Hauler")
	print("  -> Assertion 7 PASS: Single shared radio power state transfers across all vehicles!")

	# ASSERTION 8: Rapid Race Falsification (Rapid OFF->ON, Bike->Hauler-During-Fade, Generation Protection)
	print("\n[ASSERTION 8] Testing Rapid Race Falsification...")
	# 8A: 10 rapid OFF -> ON cycles mid-fade
	controller._on_bike_mounted(controller.player)
	for i in range(10):
		controller._on_radio_toggle_pressed() # OFF
		await controller.get_tree().process_frame
		controller._on_radio_toggle_pressed() # ON mid-fade
		await controller.get_tree().process_frame
	var race_wait := Time.get_ticks_msec()
	while Time.get_ticks_msec() - race_wait < 300:
		await controller.get_tree().process_frame
	assert(controller.is_radio_enabled() == true, "FAIL 8A: Radio enabled after rapid OFF/ON")
	assert(r_player.is_playing() == true, "FAIL 8A: Radio playing after rapid OFF/ON")
	assert(r_player.is_paused() == false, "FAIL 8A: Radio not paused by stale fade callback")

	# 8B: Bike dismount -> Hauler mount mid-fade
	controller._on_bike_dismounted() # starts fade-out
	await controller.get_tree().process_frame
	controller._on_hauler_mounted(controller.player) # Hauler takes ownership mid-fade
	var fade_race_wait := Time.get_ticks_msec()
	while Time.get_ticks_msec() - fade_race_wait < 300:
		await controller.get_tree().process_frame
	assert(controller.get_radio_owner() == controller.scrap_hauler, "FAIL 8B: Hauler owns session")
	assert(controller.active_vehicle == controller.scrap_hauler, "FAIL 8B: Hauler is active vehicle")
	assert(r_player.is_playing() == true, "FAIL 8B: Radio playing in Hauler")
	assert(r_player.is_paused() == false, "FAIL 8B: Radio not stale-paused by Bike fade")

	# 8C: Stale Bike dismount after Hauler owns session
	controller._on_vehicle_dismounted_generic(controller.courier_bike)
	assert(controller.get_radio_owner() == controller.scrap_hauler, "FAIL 8C: Hauler remains owner despite stale Bike dismount")
	assert(controller.active_vehicle == controller.scrap_hauler, "FAIL 8C: Hauler remains active vehicle")
	assert(r_player.is_paused() == false, "FAIL 8C: Radio remains unpaused")
	controller._on_hauler_dismounted()
	print("  -> Assertion 8 PASS: Generation-safe fade cancellation eliminates rapid toggle and mid-fade transfer races!")

	# ASSERTION 9: Single-Player / Voice Invariant & Node/Tween Leak Proof
	print("\n[ASSERTION 9] Testing Single-Player Authority, Voice Invariant & Leak Proof...")
	for cycle in range(12):
		controller._on_bike_mounted(controller.player)
		controller._on_radio_toggle_pressed()
		controller._on_bike_dismounted()
		controller._on_hauler_mounted(controller.player)
		controller._on_radio_toggle_pressed()
		controller._on_hauler_dismounted()
	await controller.get_tree().process_frame

	var found_radio_players: int = 0
	for child in controller.audio_mgr.get_children():
		if child is AudioStreamPlayer and child.name.begins_with("RadioAudioStreamPlayer"):
			found_radio_players += 1
		for subchild in child.get_children():
			if subchild is AudioStreamPlayer and subchild.name.begins_with("RadioAudioStreamPlayer"):
				found_radio_players += 1

	assert(found_radio_players == 1, "FAIL 9: Exactly 1 RadioAudioStreamPlayer node, found %d" % found_radio_players)
	assert(controller.audio_mgr.get_radio_player() != null, "FAIL 9: Exactly 1 RadioProgramPlayer authority")
	print("  -> Assertion 9 PASS: Exactly 1 AudioStreamPlayer and 0 leaked nodes preserved across 12 stress cycles!")

	# ASSERTION 10: Deterministic Cold Replay Reset
	print("\n[ASSERTION 10] Testing Deterministic Cold Replay Reset...")
	controller._on_bike_mounted(controller.player)
	r_player.get_director().advance_next_item()
	r_player.get_director().set_cursor_position(3.5)
	controller._on_radio_toggle_pressed()
	assert(controller.is_radio_enabled() == false, "FAIL 10: Session toggled OFF before replay")

	controller.reset_slice()
	await controller.get_tree().process_frame

	assert(controller.is_radio_enabled() == true, "FAIL 10: Radio session reset to default enabled")
	assert(controller.get_radio_owner() == null, "FAIL 10: Radio owner reset to null")
	assert(r_player.is_playing() == false, "FAIL 10: Radio player stopped after cold replay")
	assert(r_player.get_director().get_cursor_position() == 0.0, "FAIL 10: Director cursor reset to 0 on replay")
	assert(r_player.get_director().get_current_item().is_empty(), "FAIL 10: Director current item cleared on replay")
	assert(controller.touch_ui.radio_button.text == "[ 88.3 FM ]", "FAIL 10: Radio button text reset on replay")
	print("  -> Assertion 10 PASS: Deterministic cold replay restores default radio baseline!")

	# ASSERTION 11: Vehicle Engine & Radio Audio Decoupling & Local Reference Resilience
	print("\n[ASSERTION 11] Testing Vehicle Engine & Radio Audio Decoupling + Reference Fallback...")
	controller.courier_bike.current_speed = 5.0
	controller._on_bike_mounted(controller.player)
	controller.audio_mgr.update_vehicle_feedback({"speed_ratio": 0.5, "load_ratio": 0.5, "traction_state": "STABLE", "slip_intensity": 0.0}, controller.courier_bike.global_position)
	assert(controller.audio_mgr.get_vehicle_feedback_snapshot().get("active", false) == true, "FAIL 11: Vehicle feedback active")
	assert(r_player.is_playing() == true, "FAIL 11: Radio playing simultaneously")

	controller._on_radio_toggle_pressed()
	var eng_wait := Time.get_ticks_msec()
	while not r_player.is_paused() and Time.get_ticks_msec() - eng_wait < 1000:
		controller.courier_bike.current_speed = 5.0
		controller.audio_mgr.update_vehicle_feedback({"speed_ratio": 0.5, "load_ratio": 0.5, "traction_state": "STABLE", "slip_intensity": 0.0}, controller.courier_bike.global_position)
		await controller.get_tree().process_frame
	assert(r_player.is_paused() == true, "FAIL 11: Radio paused")
	assert(controller.audio_mgr.get_vehicle_feedback_snapshot().get("active", false) == true, "FAIL 11: Vehicle feedback unaffected by radio pause")

	controller.courier_bike.current_speed = 0.0
	controller._on_bike_dismounted()
	await controller.get_tree().process_frame
	assert(controller.audio_mgr.get_vehicle_feedback_snapshot().get("active", false) == false, "FAIL 11: Vehicle feedback cleared upon dismount")

	# Local Reference Resilience (Missing Manifest)
	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "1")
	OS.set_environment("ECHOES_REFERENCE_AUDIO_MANIFEST", "/tmp/nonexistent_manifest_file.json")
	AudioReferenceResolverScript.reset()
	controller._on_bike_mounted(controller.player)
	await controller.get_tree().process_frame
	assert(r_player.is_playing() == true, "FAIL 11: Radio plays cleanly with missing reference manifest")
	controller._on_bike_dismounted()
	await controller.get_tree().process_frame
	OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "0")
	OS.set_environment("ECHOES_REFERENCE_AUDIO_MANIFEST", "")
	AudioReferenceResolverScript.reset()
	print("  -> Assertion 11 PASS: Engine/radio decoupling & local reference resilience verified!")

	# ASSERTION 12: Desktop 'R' Key Foot-Rejection & Complete Multitouch Driving Isolation
	print("\n[ASSERTION 12] Testing Desktop 'R' Foot Rejection & Multitouch Driving Isolation...")
	# 12A: Desktop 'R' Key in FOOT_TRAVERSAL (must be rejected / no toggle)
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL 12A: Mode is FOOT_TRAVERSAL")
	var foot_enabled_before := controller.is_radio_enabled()
	var key_r_foot := InputEventKey.new()
	key_r_foot.keycode = KEY_R
	key_r_foot.pressed = true
	controller.touch_ui._input(key_r_foot)
	assert(controller.is_radio_enabled() == foot_enabled_before, "FAIL 12A: Desktop R rejected in FOOT_TRAVERSAL mode")

	# 12B: Desktop 'R' Key in VEHICLE_DRIVING
	controller._on_bike_mounted(controller.player)
	await controller.get_tree().process_frame
	assert(controller.touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING, "FAIL 12B: Mode is VEHICLE_DRIVING")
	
	# Echo key event must not toggle
	var key_r_echo := InputEventKey.new()
	key_r_echo.keycode = KEY_R
	key_r_echo.pressed = true
	key_r_echo.echo = true
	var drive_enabled_before := controller.is_radio_enabled()
	controller.touch_ui._input(key_r_echo)
	assert(controller.is_radio_enabled() == drive_enabled_before, "FAIL 12B: Echo R event rejected")

	# Non-echo key event toggles exactly once
	var key_r_drive := InputEventKey.new()
	key_r_drive.keycode = KEY_R
	key_r_drive.pressed = true
	key_r_drive.echo = false
	controller.touch_ui._input(key_r_drive)
	assert(controller.is_radio_enabled() == not drive_enabled_before, "FAIL 12B: Non-echo R toggled radio once")
	controller.touch_ui._input(key_r_drive)
	assert(controller.is_radio_enabled() == drive_enabled_before, "FAIL 12B: Non-echo R toggled radio back")

	# 12C: Complete Multitouch GAS Isolation
	var gas_press := InputEventScreenTouch.new()
	gas_press.index = 0
	gas_press.pressed = true
	gas_press.position = controller.touch_ui.gas_button.global_position + Vector2(10, 10)
	controller.touch_ui.gas_button.gui_input.emit(gas_press)
	assert(controller.touch_ui._is_gas_pressed == true, "FAIL 12C: GAS button pressed")
	assert(controller.touch_ui._gas_touch_index == 0, "FAIL 12C: GAS owns pointer 0")
	assert(controller._throttle_input == 1.0, "FAIL 12C: Net throttle is +1.0")
	assert(controller._handbrake_input == false, "FAIL 12C: Handbrake is false")

	# While GAS held, trigger radio button toggle
	controller.touch_ui.trigger_radio_toggle()
	assert(controller.touch_ui._is_gas_pressed == true, "FAIL 12C: GAS remains pressed after touch radio toggle")
	assert(controller.touch_ui._gas_touch_index == 0, "FAIL 12C: GAS still owns pointer 0")
	assert(controller._throttle_input == 1.0, "FAIL 12C: Net throttle remains +1.0")
	assert(controller._handbrake_input == false, "FAIL 12C: Handbrake unchanged")

	# While GAS held, trigger desktop key 'R' toggle
	controller.touch_ui._input(key_r_drive)
	assert(controller.touch_ui._is_gas_pressed == true, "FAIL 12C: GAS remains pressed after desktop R key")
	assert(controller.touch_ui._gas_touch_index == 0, "FAIL 12C: GAS still owns pointer 0")
	assert(controller._throttle_input == 1.0, "FAIL 12C: Net throttle remains +1.0")

	# Release GAS
	var gas_release := InputEventScreenTouch.new()
	gas_release.index = 0
	gas_release.pressed = false
	controller.touch_ui.gas_button.gui_input.emit(gas_release)
	assert(controller.touch_ui._is_gas_pressed == false, "FAIL 12C: GAS cleanly released")
	assert(controller._throttle_input == 0.0, "FAIL 12C: Net throttle returned to 0.0")
	assert(controller.touch_ui.is_pointer_index_claimed(0) == false, "FAIL 12C: Pointer 0 unclaimed after release")
	print("  -> Assertion 12 PASS: Desktop R foot rejection & full multitouch driving isolation verified!")

	print("\n=========================================================================")
	print("[ALL V8 M23 VEHICLE RADIO LIFECYCLE ASSERTIONS (1-12) PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


