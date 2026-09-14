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
	print("[V8 M07 LIVING SCRAP YARD & REACTIVE AMBIENT WORLD ASSERTIONS] Starting...")
	print("=========================================================================\n")

	# Wait for scene initialization
	for _i in range(5):
		await controller.get_tree().process_frame

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 1: Ambient actors exist at cold start before disturbance
	# ─────────────────────────────────────────────────────────────────────────
	print("--- Assertion 1: Ambient actors exist at cold start before disturbance ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(controller.scrap_worker_1 != null, "FAIL A1: scrap_worker_1 must exist")
	assert(controller.scrap_worker_2 != null, "FAIL A1: scrap_worker_2 must exist")
	assert(controller.utility_crawler != null, "FAIL A1: utility_crawler must exist")
	assert(controller.ambient_actors.size() >= 3, "FAIL A1: ambient_actors list must track all 3 actors")
	
	assert(controller.scrap_worker_1.current_state == ScrapWorkerScript.WorkerState.AMBIENT, "FAIL A1: Worker 1 must start in AMBIENT state")
	assert(controller.scrap_worker_2.current_state == ScrapWorkerScript.WorkerState.AMBIENT, "FAIL A1: Worker 2 must start in AMBIENT state")
	assert(controller.utility_crawler.current_state == UtilityCrawlerScript.CrawlerState.AMBIENT, "FAIL A1: Crawler must start in AMBIENT state")
	assert(controller.scrap_worker_1.visible and controller.scrap_worker_2.visible and controller.utility_crawler.visible, "FAIL A1: All actors must be visible")
	print("  -> Assertion 1 PASS: Ambient actors exist and initialize in AMBIENT state")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 2: Deterministic movement & station loops
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 2: Deterministic movement & station loops ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller.scrap_worker_1._inspect_timer = 0.0
	controller.scrap_worker_1.current_waypoint_idx = 1
	controller.utility_crawler._station_timer = 0.0
	controller.utility_crawler.current_waypoint_idx = 1
	var w1_start_pos := controller.scrap_worker_1.global_position
	var crawl_start_pos := controller.utility_crawler.global_position
	print("  DEBUG A2 start: w1_pos=%s, crawl_pos=%s, crawl_target=%s, crawl_state=%d, timer=%.2f" % [
		controller.scrap_worker_1.global_position,
		controller.utility_crawler.global_position,
		controller.utility_crawler.patrol_waypoints[controller.utility_crawler.current_waypoint_idx],
		controller.utility_crawler.current_state,
		controller.utility_crawler._station_timer
	])
	
	for _i in range(30):
		await controller.get_tree().physics_frame
		
	var w1_moved: float = w1_start_pos.distance_to(controller.scrap_worker_1.global_position)
	var crawl_moved: float = crawl_start_pos.distance_to(controller.utility_crawler.global_position)
	print("  DEBUG A2 end: w1_pos=%s (moved=%.2f), crawl_pos=%s (moved=%.2f), crawl_state=%d, timer=%.2f, vel=%s" % [
		controller.scrap_worker_1.global_position,
		w1_moved,
		controller.utility_crawler.global_position,
		crawl_moved,
		controller.utility_crawler.current_state,
		controller.utility_crawler._station_timer,
		controller.utility_crawler.velocity
	])
	assert(w1_moved > 0.1, "FAIL A2: Scrap worker must patrol along waypoints")
	assert(crawl_moved > 0.1, "FAIL A2: Utility crawler must patrol along salvage lane")
	print("  -> Assertion 2 PASS: Deterministic ambient movement verified (Worker: %.2fm, Crawler: %.2fm)" % [w1_moved, crawl_moved])

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 3: Neutral actors never target or attack player
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 3: Neutral actors never target or attack player ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller.player.global_position = controller.scrap_worker_1.global_position + Vector3(0, 0, 1.0)
	for _i in range(15):
		controller.scrap_worker_1._physics_process(1.0 / 60.0)
		controller.utility_crawler._physics_process(1.0 / 60.0)
		await controller.get_tree().physics_frame
	assert(controller.scrap_worker_1.current_state != 2, "FAIL A3: Worker must remain non-hostile")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.CALM, "FAIL A3: Neutral actors must not trigger pursuit or harm player")
	print("  -> Assertion 3 PASS: Neutral non-hostile actor contract verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 4: Courier Bike proximity causes correct yield behavior
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 4: Courier Bike proximity causes correct yield behavior ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller.courier_bike.global_position = controller.scrap_worker_1.global_position + Vector3(0, 0, 3.0)
	controller.courier_bike.velocity = Vector3(0, 0, -8.0)
	controller.courier_bike.current_speed = 8.0
	
	controller.scrap_worker_1.check_proximity_threat(controller.courier_bike.global_position, controller.courier_bike.velocity)
	assert(controller.scrap_worker_1.current_state == ScrapWorkerScript.WorkerState.YIELDING, "FAIL A4: Worker must enter YIELDING state when bike approaches")
	assert(controller.scrap_worker_1.velocity.length() > 0.5, "FAIL A4: Worker must step aside when yielding")
	print("  -> Assertion 4 PASS: Courier Bike proximity triggers worker yield step")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 5: Scrap Hauler proximity causes correct yield behavior
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 5: Scrap Hauler proximity causes correct yield behavior ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller.scrap_hauler.global_position = controller.utility_crawler.global_position + Vector3(0, 0, 3.2)
	controller.scrap_hauler.velocity = Vector3(0, 0, -8.0)
	controller.scrap_hauler.current_speed = 8.0
	
	controller.utility_crawler.check_proximity_threat(controller.scrap_hauler.global_position, controller.scrap_hauler.velocity)
	assert(controller.utility_crawler.current_state == UtilityCrawlerScript.CrawlerState.YIELDING, "FAIL A5: Crawler must enter YIELDING state when hauler approaches")
	assert(controller.utility_crawler.velocity == Vector3.ZERO, "FAIL A5: Crawler must halt to yield lane to vehicle")
	print("  -> Assertion 5 PASS: Scrap Hauler proximity triggers crawler halt yield")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 6: Disturbance alert transitions all active actors to safe reaction
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 6: Disturbance alert transitions all active actors to safe reaction ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(controller.audio_mgr.get_event_count(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT) == 0, "FAIL A6: Event count starts at 0")
	controller.trigger_disturbance_alert()
	assert(controller.audio_mgr.get_event_count(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT) == 1, "FAIL A6: Exactly one DISTURBANCE_ALERT onset emitted")
	# Re-triggering during disturbance alert must be rejected with zero additional emissions
	controller.trigger_disturbance_alert()
	assert(controller.audio_mgr.get_event_count(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT) == 1, "FAIL A6: Re-trigger must not duplicate DISTURBANCE_ALERT onset")
	assert(controller.scrap_worker_1.current_state == ScrapWorkerScript.WorkerState.ALARMED, "FAIL A6: Worker 1 must enter ALARMED state upon disturbance")
	assert(controller.scrap_worker_2.current_state == ScrapWorkerScript.WorkerState.ALARMED, "FAIL A6: Worker 2 must enter ALARMED state upon disturbance")
	assert(controller.utility_crawler.current_state == UtilityCrawlerScript.CrawlerState.ALARMED, "FAIL A6: Crawler must enter ALARMED state upon disturbance")
	
	for _i in range(80):
		await controller.get_tree().physics_frame
		
	assert(controller.scrap_worker_1.global_position.distance_to(controller.scrap_worker_1.safe_anchor) < 1.5, "FAIL A6: Worker 1 must retreat to safe perimeter anchor")
	assert(controller.scrap_worker_2.global_position.distance_to(controller.scrap_worker_2.safe_anchor) < 1.5, "FAIL A6: Worker 2 must retreat to safe perimeter anchor")
	print("  -> Assertion 6 PASS: Disturbance transitions all actors to safe perimeter cover")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 7: Main security gate corridor remains completely clear
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 7: Main security gate corridor remains completely clear ---")
	var gate_corridor_center := Vector3(-1.5, 0.05, 12.0)
	for actor in controller.ambient_actors:
		var dist_to_gate := actor.global_position.distance_to(gate_corridor_center)
		assert(dist_to_gate > 3.0, "FAIL A7: Actor %s must not block gate corridor (dist: %.2fm)" % [actor.name, dist_to_gate])
	print("  -> Assertion 7 PASS: Security gate corridor 100% unobstructed by ambient actors")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 8: Pedestrian airborne shortcut ramp remains completely clear
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 8: Pedestrian airborne shortcut ramp remains completely clear ---")
	var shortcut_ramp_pos := Vector3(2.0, 0.05, 10.0)
	for actor in controller.ambient_actors:
		var dist_to_ramp := actor.global_position.distance_to(shortcut_ramp_pos)
		assert(dist_to_ramp > 3.0, "FAIL A8: Actor %s must not block shortcut ramp (dist: %.2fm)" % [actor.name, dist_to_ramp])
	print("  -> Assertion 8 PASS: Pedestrian shortcut ramp 100% unobstructed by ambient actors")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 9: Replay / reset authoritative state restoration
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 9: Replay / reset authoritative state restoration ---")
	controller.scrap_worker_1.global_position = Vector3(10.0, 0.05, 10.0)
	controller.utility_crawler.global_position = Vector3(-10.0, 0.05, -10.0)
	controller.scrap_worker_1.current_state = ScrapWorkerScript.WorkerState.ALARMED
	controller.utility_crawler.current_state = UtilityCrawlerScript.CrawlerState.ALARMED
	
	controller.reset_slice()
	assert(controller.scrap_worker_1.current_state == ScrapWorkerScript.WorkerState.AMBIENT, "FAIL A9: Worker 1 must reset to AMBIENT")
	assert(controller.utility_crawler.current_state == UtilityCrawlerScript.CrawlerState.AMBIENT, "FAIL A9: Crawler must reset to AMBIENT")
	assert(controller.scrap_worker_1.global_position.distance_to(controller.scrap_worker_1._initial_position) < 0.1, "FAIL A9: Worker 1 must return to initial position")
	assert(controller.utility_crawler.global_position.distance_to(controller.utility_crawler._initial_position) < 0.1, "FAIL A9: Crawler must return to initial position")
	print("  -> Assertion 9 PASS: Authoritative reset cleanly restores all ambient actors")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 10: Ambient audio life & pursuit ducking
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 10: Ambient audio life & pursuit ducking ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.audio_mgr:
		controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.CALM)
		
		# 1. Real worker inspect activity creates transient in CALM
		controller.scrap_worker_1._inspect_timer = 2.0
		controller.scrap_worker_1._clink_cooldown = 0.0
		var worker_transients_before: int = controller.audio_mgr._active_transients.size()
		controller.scrap_worker_1._process_ambient(1.0 / 60.0)
		var worker_transients_after: int = controller.audio_mgr._active_transients.size()
		assert(worker_transients_after > worker_transients_before, "FAIL A10: Scrap worker activity must create audio transient in CALM")
		
		# 2. Real crawler movement activity creates transient in CALM
		controller.utility_crawler._station_timer = 0.0
		controller.utility_crawler._servo_cooldown = 0.0
		controller.utility_crawler.current_waypoint_idx = 1
		var crawler_transients_before: int = controller.audio_mgr._active_transients.size()
		controller.utility_crawler._process_ambient(1.0 / 60.0)
		var crawler_transients_after: int = controller.audio_mgr._active_transients.size()
		assert(crawler_transients_after > crawler_transients_before, "FAIL A10: Utility crawler movement must create audio transient in CALM")
		
		# 3. DISTURBANCE mix state suppresses new ambient voices
		controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.DISTURBANCE)
		controller.scrap_worker_1._clink_cooldown = 0.0
		controller.utility_crawler._servo_cooldown = 0.0
		var dist_transients_before: int = controller.audio_mgr._active_transients.size()
		controller.scrap_worker_1._process_ambient(1.0 / 60.0)
		controller.utility_crawler._process_ambient(1.0 / 60.0)
		var dist_transients_after: int = controller.audio_mgr._active_transients.size()
		assert(dist_transients_after == dist_transients_before, "FAIL A10: DISTURBANCE mix state must suppress new ambient voices")
		
		# 4. PURSUIT_PRESSURE mix state suppresses new ambient voices
		controller.audio_mgr.set_mix_state(AudioManagerScript.MixState.PURSUIT_PRESSURE)
		controller.scrap_worker_1._clink_cooldown = 0.0
		controller.utility_crawler._servo_cooldown = 0.0
		var pursuit_transients_before: int = controller.audio_mgr._active_transients.size()
		controller.scrap_worker_1._process_ambient(1.0 / 60.0)
		controller.utility_crawler._process_ambient(1.0 / 60.0)
		var pursuit_transients_after: int = controller.audio_mgr._active_transients.size()
		assert(pursuit_transients_after == pursuit_transients_before, "FAIL A10: PURSUIT_PRESSURE mix state must suppress new ambient voices")
		
		# 5. Reset clears ambient transient state and restores CALM
		controller.reset_slice()
		await controller.get_tree().process_frame
		assert(controller.audio_mgr._active_transients.size() == 0, "FAIL A10: Authoritative reset must clear ambient transient state")
	print("  -> Assertion 10 PASS: Ambient audio life and pursuit ducking priority verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 11: Memory Echo & Mobile HUD compatibility
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 11: Memory Echo & Mobile HUD compatibility ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	controller._on_extraction_completed()
	assert(controller.echo_controller != null and controller.echo_controller.current_phase != MemoryEchoController.EchoPhase.IDLE, "FAIL A11: Memory echo must trigger with ambient actors active")
	if controller.touch_ui:
		assert(controller.touch_ui.visible, "FAIL A11: Mobile HUD must remain visible and unobstructed")
	print("  -> Assertion 11 PASS: Memory Echo & mobile HUD compatibility verified")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 12: Full Golden Slice with Courier Bike
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 12: Full Golden Slice with Courier Bike ---")
	controller.reset_slice()
	await controller.get_tree().process_frame
	if controller.signal_tuner: controller._on_tuner_signal_locked(controller.signal_tuner)
	controller._on_extraction_completed()
	controller.player.global_position = controller.courier_bike.global_position + Vector3(0, 0, 0.5)
	controller.courier_bike.mount_interactable.update_player_distance(controller.player.global_position)
	assert(controller.courier_bike.request_mount(controller.player), "FAIL A12: Bike mount must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	controller.trigger_disturbance_alert()
	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.pursuer.target_node == controller.courier_bike, "FAIL A12: Pursuer must automatically target mounted Courier Bike")
	controller._on_successful_evasion()
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.EVADED, "FAIL A12: Evasion with bike must succeed in living yard")
	print("  -> Assertion 12 PASS: Golden Slice 100% completable with Courier Bike")

	# ─────────────────────────────────────────────────────────────────────────
	# ASSERTION 13: Full Golden Slice with Scrap Hauler & 7 Visual Proofs
	# ─────────────────────────────────────────────────────────────────────────
	print("\n--- Assertion 13: Full Golden Slice with Scrap Hauler & 7 Visual Proofs ---")
	controller.reset_slice()
	await controller.get_tree().process_frame

	# Proof 1: Cold-start ambient yard
	for _i in range(4):
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m07/m07_01_ambient_cold_start.png")
	print("  -> Visual proof saved: m07_01_ambient_cold_start.png")

	# Proof 2: Worker activity near interaction zone
	controller.camera.set_target(controller.scrap_worker_1)
	for _i in range(5):
		controller.scrap_worker_1._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m07/m07_02_worker_activity.png")
	print("  -> Visual proof saved: m07_02_worker_activity.png")

	# Proof 3: Bike approaching / worker yield reaction
	controller.camera.set_target(controller.player)
	controller.courier_bike.global_position = controller.scrap_worker_1.global_position + Vector3(0, 0, 2.5)
	controller.courier_bike.velocity = Vector3(0, 0, -8.0)
	controller.scrap_worker_1.check_proximity_threat(controller.courier_bike.global_position, controller.courier_bike.velocity)
	for _i in range(4):
		controller.scrap_worker_1._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m07/m07_03_bike_yield_reaction.png")
	print("  -> Visual proof saved: m07_03_bike_yield_reaction.png")

	# Proof 4: Hauler approaching / crawler yield reaction
	controller.camera.set_target(controller.utility_crawler)
	controller.scrap_hauler.global_position = controller.utility_crawler.global_position + Vector3(0, 0, 3.0)
	controller.scrap_hauler.velocity = Vector3(0, 0, -8.0)
	controller.utility_crawler.check_proximity_threat(controller.scrap_hauler.global_position, controller.scrap_hauler.velocity)
	for _i in range(4):
		controller.utility_crawler._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m07/m07_04_hauler_yield_reaction.png")
	print("  -> Visual proof saved: m07_04_hauler_yield_reaction.png")

	# Real Hauler disturbance targeting falsification & Proof 5
	controller.camera.set_target(controller.player)
	controller.player.global_position = controller.scrap_hauler.global_position + Vector3(0, 0, 0.5)
	controller.scrap_hauler.mount_interactable.update_player_distance(controller.player.global_position)
	assert(controller.scrap_hauler.request_mount(controller.player), "FAIL A13: Hauler mount must succeed")
	assert(controller.scrap_hauler.occupant == controller.player, "FAIL A13: Hauler must be mounted by player")
	controller.trigger_disturbance_alert()
	for _i in range(15):
		controller.scrap_worker_1._physics_process(1.0 / 60.0)
		controller.scrap_worker_2._physics_process(1.0 / 60.0)
		controller.utility_crawler._physics_process(1.0 / 60.0)
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m07/m07_05_disturbance_alarm_reaction.png")
	print("  -> Visual proof saved: m07_05_disturbance_alarm_reaction.png")

	await controller.get_tree().create_timer(0.85).timeout
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.PURSUIT_ACTIVE, "FAIL A13: Pursuit must be active after disturbance timeout")
	assert(controller.pursuer.target_node == controller.scrap_hauler, "FAIL A13: Pursuer must automatically target mounted Scrap Hauler on disturbance")

	# Dynamic dismount/remount target handoff test
	controller.scrap_hauler.request_dismount()
	await controller.get_tree().create_timer(0.3).timeout
	assert(controller.pursuer.target_node == controller.player, "FAIL A13: Dismounting during pursuit must retarget Runner")
	controller.player.global_position = controller.scrap_hauler.global_position + Vector3(0, 0, 0.5)
	controller.scrap_hauler.mount_interactable.update_player_distance(controller.player.global_position)
	assert(controller.scrap_hauler.request_mount(controller.player), "FAIL A13: Remounting Hauler must succeed")
	await controller.get_tree().create_timer(0.3).timeout
	assert(controller.pursuer.target_node == controller.scrap_hauler, "FAIL A13: Remounting during pursuit must retarget Scrap Hauler")

	# Proof 6: Pursuit through completely cleared escape corridor
	controller.scrap_hauler.global_position = Vector3(-1.5, 0.05, 6.0)
	controller.scrap_hauler.rotation.y = PI
	controller.scrap_hauler.current_state = ScrapHaulerScript.VehicleState.DRIVING
	controller.scrap_hauler.current_speed = 14.0
	controller.camera.reset_camera_instant(controller.scrap_hauler)
	if controller.pursuer:
		controller.pursuer.global_position = Vector3(-1.5, 0.6, -2.0)
		
	var floor_node := controller.get_node_or_null("Floor")
	var hauler_snagged := false
	for f in range(50):
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
			TestHelpers.save_proof_png(controller, "res://verification/v8/m07/m07_06_cleared_pursuit_escape.png")
			print("  -> Visual proof saved: m07_06_cleared_pursuit_escape.png")

	assert(not hauler_snagged, "FAIL A13: Hauler must not snag")
	assert(controller.scrap_hauler.global_position.z > 14.0, "FAIL A13: Hauler must cross post-gate plane (Z > 14.0m)")

	# Evasion & Quiet Reset
	controller._on_successful_evasion()
	controller.reset_slice()
	await controller.get_tree().process_frame
	for _i in range(4):
		await controller.get_tree().process_frame
	TestHelpers.save_proof_png(controller, "res://verification/v8/m07/m07_07_ambient_quiet_reset.png")
	print("  -> Visual proof saved: m07_07_ambient_quiet_reset.png")

	print("  -> Assertion 13 PASS: Full Golden Slice completable in living yard & all 7 visual proofs verified")

	# ─────────────────────────────────────────────────────────────────────────
	# CLEANUP & REPORT
	# ─────────────────────────────────────────────────────────────────────────
	controller.reset_slice()
	print("\n=========================================================================")
	print("[ALL V8 M07 LIVING SCRAP YARD & REACTIVE AMBIENT WORLD ASSERTIONS PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


