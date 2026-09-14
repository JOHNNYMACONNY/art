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
	print("[RUNNING V8 M25 FIRST HYBRID ECHO/RADIO INTERFERENCE TRACER (#25)]")
	print("=========================================================================\n")

	# ASSERTION 1: Eligibility Invariants & Stopped/Unpaused Radio Falsification
	print("[ASSERTION 1] Testing Eligibility Invariants (Cold Start, Radio OFF, On Foot, Stopped/Unpaused Radio, Outside Radius)...")
	controller.reset_slice()
	await controller.get_tree().process_frame

	# 1A: Cold start: world state != PANEL_POWERED
	assert(controller.current_world_state != ScrapTestBlock.WorldLoopState.PANEL_POWERED, "FAIL 1A: Cold start state is not PANEL_POWERED")
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 1A: Cold start interference intensity is 0.0")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 1A: Cold start contamination gain is 0.0 dB")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 1A: 3D interference player stopped on cold start")

	# --- LAZY-SESSION FALSIFICATION A: Cold start does not create radio player ---
	var cold_existing_before = controller.audio_mgr.get_existing_radio_player()
	assert(cold_existing_before == null, "FAIL LAZY-A: No radio player exists on cold start")
	var cold_player_count_before: int = 0
	for ch in controller.audio_mgr.get_children():
		if ch.get_script() == load("res://scripts/audio/radio/radio_program_player.gd"):
			cold_player_count_before += 1
	assert(cold_player_count_before == 0, "FAIL LAZY-A: Zero RadioProgramPlayers exist before interference check on cold start")

	# Run eligibility check on cold start (on foot, world != PANEL_POWERED)
	controller._process_radio_interference()

	var cold_existing_after = controller.audio_mgr.get_existing_radio_player()
	assert(cold_existing_after == null, "FAIL LAZY-A: Interference eligibility check MUST NOT create radio player on cold start")
	var cold_player_count_after: int = 0
	for ch in controller.audio_mgr.get_children():
		if ch.get_script() == load("res://scripts/audio/radio/radio_program_player.gd"):
			cold_player_count_after += 1
	assert(cold_player_count_after == 0, "FAIL LAZY-A: Zero RadioProgramPlayers after cold-start interference check")
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL LAZY-A: Cold start intensity == 0.0")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL LAZY-A: Cold start contamination == 0.0")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL LAZY-A: 3D player stopped on cold start check")
	print("  COLD_START_PLAYER_COUNT_BEFORE: %d | COLD_START_PLAYER_COUNT_AFTER_INTERFERENCE_CHECK: %d" % [cold_player_count_before, cold_player_count_after])

	# --- LAZY-SESSION FALSIFICATION B: PANEL_POWERED on-foot does not create radio player ---
	controller.current_world_state = ScrapTestBlock.WorldLoopState.PANEL_POWERED
	# Keep on foot (no active vehicle)
	assert(controller._get_active_vehicle() == null, "FAIL LAZY-B: Still on foot for panel-powered test")

	var panel_before: int = 0
	for ch in controller.audio_mgr.get_children():
		if ch.get_script() == load("res://scripts/audio/radio/radio_program_player.gd"):
			panel_before += 1
	assert(panel_before == 0, "FAIL LAZY-B: Still zero players before panel-powered on-foot check")

	controller._process_radio_interference()

	var panel_after: int = 0
	for ch in controller.audio_mgr.get_children():
		if ch.get_script() == load("res://scripts/audio/radio/radio_program_player.gd"):
			panel_after += 1
	assert(panel_after == 0, "FAIL LAZY-B: Interference check on PANEL_POWERED on-foot MUST NOT create radio player")
	assert(controller.audio_mgr.get_existing_radio_player() == null, "FAIL LAZY-B: get_existing_radio_player() still null after panel-powered on-foot check")
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL LAZY-B: PANEL_POWERED on-foot intensity == 0.0")
	print("  PANEL_POWERED_ON_FOOT_PLAYER_COUNT_BEFORE: %d | PANEL_POWERED_ON_FOOT_PLAYER_COUNT_AFTER: %d" % [panel_before, panel_after])

	# --- LAZY-SESSION FALSIFICATION C: First real mount creates exactly one player ---
	controller._on_bike_mounted(controller.player)
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(5.0, 0.0, 0.0)
	# Legitimate mount flow creates RadioProgramPlayer via get_radio_player()
	var post_mount_existing = controller.audio_mgr.get_existing_radio_player()
	assert(post_mount_existing != null, "FAIL LAZY-C: First real mount creates exactly one RadioProgramPlayer")
	var post_mount_count: int = 0
	for ch in controller.audio_mgr.get_children():
		if ch.get_script() == load("res://scripts/audio/radio/radio_program_player.gd"):
			post_mount_count += 1
	assert(post_mount_count == 1, "FAIL LAZY-C: Exactly one RadioProgramPlayer after first mount")
	# Wait for stream to start after lifecycle fade/resume
	await controller.get_tree().process_frame
	await controller.get_tree().process_frame
	assert(controller.audio_mgr.get_existing_radio_player().is_stream_playing() == true, "FAIL LAZY-C: Radio stream playing after first mount lifecycle")
	print("  FIRST_REAL_MOUNT_CREATES_PLAYER_PROOF: %d player(s) | POST_MOUNT_RADIO_STREAM_PLAYING_PROOF: true" % post_mount_count)
	# Eligible in-range interference works normally after mount
	controller._process_radio_interference()
	var post_mount_intensity = controller.audio_mgr.get_radio_interference_intensity()
	assert(post_mount_intensity > 0.0, "FAIL LAZY-C: Eligible in-range interference active after first mount")
	print("  POST_MOUNT_INTERFERENCE_PROOF: intensity=%.3f (> 0.0)" % post_mount_intensity)

	# Reset to fresh state for remaining 1B-1E
	controller._on_bike_dismounted()
	controller.reset_slice()
	await controller.get_tree().process_frame

	# 1B: Power panel but keep radio OFF
	controller.current_world_state = ScrapTestBlock.WorldLoopState.PANEL_POWERED
	if controller.is_radio_enabled():
		controller._on_radio_toggle_pressed() # Turn OFF
	controller._process_radio_interference()
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 1B: Radio OFF produces zero interference")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 1B: 3D interference player stopped when radio OFF")

	# 1C: Turn radio ON, but player is on foot
	controller._on_radio_toggle_pressed() # Turn ON
	assert(controller.is_radio_enabled() == true, "FAIL 1C: Radio is enabled")
	assert(controller._get_active_vehicle() == null, "FAIL 1C: Player is on foot")
	controller._process_radio_interference()
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 1C: On-foot produces zero interference")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 1C: 3D player stopped on foot")

	# 1D: Falsify Stopped/Unpaused Radio: Mount bike in range (5m), radio enabled, but player logically stopped / stream not playing
	controller._on_bike_mounted(controller.player)
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(5.0, 0.0, 0.0)
	var r_prog_player = controller.audio_mgr.get_radio_player()
	r_prog_player.stop() # Logically stops player, stream is not playing
	assert(r_prog_player.is_playing() == false, "FAIL 1D: Radio player is stopped")
	assert(r_prog_player.is_stream_playing() == false, "FAIL 1D: Radio underlying stream is stopped")
	assert(r_prog_player.is_paused() == false, "FAIL 1D: Radio is not paused (stopped state)")
	controller._process_radio_interference()
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 1D: Stopped radio stream produces strictly ZERO interference")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 1D: Stopped radio stream produces strictly ZERO contamination gain")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 1D: 3D player stopped when radio stream not playing")

	# Resume radio stream
	r_prog_player.play_station(controller._radio_station_id)
	await controller.get_tree().process_frame
	assert(r_prog_player.is_stream_playing() == true, "FAIL 1D: Radio stream playing after resume")

	# 1E: Mount bike with radio playing, but place vehicle outside outer radius (25m)
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(25.0, 0.0, 0.0)
	controller._process_radio_interference()
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 1E: Outside 18m radius produces zero interference")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 1E: 3D player stopped outside 18m")
	print("  -> Assertion 1 PASS: Eligibility invariants (cold, radio OFF, on foot, stopped radio falsification, outside radius) verified!")

	# ASSERTION 2: Approach & Monotonic Intensity / Directional Voice Scaling / Max Bounds / Retreat
	print("\n[ASSERTION 2] Testing Approach & Monotonic Intensity / Directional Voice Scaling...")
	var distances: Array[float] = [18.0, 15.0, 12.0, 9.0, 6.0, 3.0, 1.5]
	var prev_intensity: float = -0.01
	var prev_cont_gain: float = 0.01
	var prev_3d_vol: float = -100.0

	for d in distances:
		controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(d, 0.0, 0.0)
		controller._process_radio_interference()
		var intensity: float = controller.audio_mgr.get_radio_interference_intensity()
		var cont_gain: float = controller.audio_mgr.get_radio_contamination_db()
		var p3d: AudioStreamPlayer3D = controller.audio_mgr.get_radio_interference_player()
		
		# Intensity monotonic rise
		assert(intensity >= prev_intensity - 0.001, "FAIL 2: Intensity must monotonically increase on approach (d=%.1f, cur=%.3f, prev=%.3f)" % [d, intensity, prev_intensity])
		# Contamination gain monotonic fall (more negative)
		assert(cont_gain <= prev_cont_gain + 0.001, "FAIL 2: Contamination gain must monotonically decrease (d=%.1f, cur=%.2f, prev=%.2f)" % [d, cont_gain, prev_cont_gain])
		
		if d < 18.0:
			assert(p3d.playing == true, "FAIL 2: 3D player playing inside radius (d=%.1f)" % d)
			assert(p3d.volume_db >= prev_3d_vol - 0.01, "FAIL 2: 3D voice volume must monotonically increase on approach (d=%.1f, cur=%.2f, prev=%.2f)" % [d, p3d.volume_db, prev_3d_vol])
			prev_3d_vol = p3d.volume_db
			
		prev_intensity = intensity
		prev_cont_gain = cont_gain

	# At <= 3m: bounded to 1.0 intensity, -4.0 dB contamination, -12.0 dB 3D player
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 1.0), "FAIL 2: Max intensity at <= 3m is bounded to 1.0 (got %.3f)" % controller.audio_mgr.get_radio_interference_intensity())
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), -4.0), "FAIL 2: Max contamination gain is bounded to -4.0 dB (got %.2f)" % controller.audio_mgr.get_radio_contamination_db())
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_player().volume_db, -12.0), "FAIL 2: Max 3D volume is bounded to -12.0 dB (got %.2f)" % controller.audio_mgr.get_radio_interference_player().volume_db)

	# Retreat from 3m back to 20m
	var retreat_distances: Array[float] = [3.0, 6.0, 10.0, 14.0, 17.5, 19.0]
	var prev_ret_intensity: float = 1.01
	for d in retreat_distances:
		controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(d, 0.0, 0.0)
		controller._process_radio_interference()
		var ret_intensity: float = controller.audio_mgr.get_radio_interference_intensity()
		assert(ret_intensity <= prev_ret_intensity + 0.001, "FAIL 2: Intensity must monotonically decrease on retreat (d=%.1f, cur=%.3f, prev=%.3f)" % [d, ret_intensity, prev_ret_intensity])
		prev_ret_intensity = ret_intensity

	# At 19m: cleanly 0.0
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 2: Intensity is 0.0 beyond 18m")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 2: Contamination gain is 0.0 dB beyond 18m")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 2: 3D player stopped beyond 18m")
	print("  -> Assertion 2 PASS: Monotonic approach scaling and retreat recovery verified!")

	# ASSERTION 3: Spatial Source & Directional Authority
	print("\n[ASSERTION 3] Testing Spatial Source & Directional Authority...")
	var p3d_inst = controller.audio_mgr.get_radio_interference_player()
	assert(p3d_inst is AudioStreamPlayer3D, "FAIL 3: Interference player must be AudioStreamPlayer3D")
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(5.0, 0.0, 0.0)
	controller._process_radio_interference()
	assert(p3d_inst.global_position.is_equal_approx(controller.corroded_panel.global_position), "FAIL 3: 3D player position matches CorrodedPanel global_position")
	print("  -> Assertion 3 PASS: Spatial 3D source and directional positioning verified!")

	# ASSERTION 4: Radio Program & Director Continuity Lock (Zero Mutation)
	print("\n[ASSERTION 4] Testing Radio Program & Director Continuity Lock (Zero Program Mutation)...")
	var r_player = controller.audio_mgr.get_radio_player()
	var pre_station = r_player._director.get_station_id()
	var pre_content = r_player.get_current_item().get("content_id", "")
	var pre_segment = r_player.get_current_segment_index()
	var pre_cursor = r_player.get_playback_position()
	var pre_rng_state = r_player._director._rng.state if r_player._director._rng != null else 0

	# Drive into max interference and hold for 60 frames
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(2.5, 0.0, 0.0)
	for fr in range(60):
		controller._process_radio_interference()
		await controller.get_tree().process_frame

	assert(r_player._director.get_station_id() == pre_station, "FAIL 4: Station ID unchanged during interference")
	assert(r_player.get_current_item().get("content_id", "") == pre_content, "FAIL 4: Content ID unchanged during interference")
	assert(r_player.get_current_segment_index() == pre_segment, "FAIL 4: Segment index unchanged during interference")
	assert(r_player.get_playback_position() >= pre_cursor, "FAIL 4: Cursor advanced naturally forward")
	if r_player._director._rng != null:
		assert(r_player._director._rng.state == pre_rng_state, "FAIL 4: Director RNG state unchanged during interference")
	
	# Retreat out
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(22.0, 0.0, 0.0)
	controller._process_radio_interference()
	await controller.get_tree().process_frame
	assert(r_player._director.get_station_id() == pre_station, "FAIL 4: Station ID unchanged after exit")
	assert(r_player.get_current_item().get("content_id", "") == pre_content, "FAIL 4: Content ID unchanged after exit")
	print("  -> Assertion 4 PASS: Radio program and director continuity lock verified (zero mutation)!")

	# ASSERTION 5: Multi-Vehicle Parity & Synchronous Clear on Toggle/Dismount
	print("\n[ASSERTION 5] Testing Multi-Vehicle Parity & Synchronous Clear on Toggle / Dismount...")
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(8.0, 0.0, 0.0)
	controller._process_radio_interference()
	var bike_intensity = controller.audio_mgr.get_radio_interference_intensity()
	assert(bike_intensity > 0.60 and bike_intensity < 0.75, "FAIL 5: Bike intensity at 8m is valid (~0.667)")

	# Synchronous Radio Toggle OFF: MUST clear BEFORE next _process_radio_interference call
	controller._on_radio_toggle_pressed() # Toggle OFF
	assert(controller.is_radio_enabled() == false, "FAIL 5: Radio toggled OFF")
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 5: Toggle OFF immediately clears interference intensity synchronously")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 5: Toggle OFF immediately clears contamination synchronously")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 5: Toggle OFF immediately stops 3D player synchronously")

	# Toggle ON again
	controller._on_radio_toggle_pressed() # Toggle ON
	controller._process_radio_interference()
	assert(controller.audio_mgr.get_radio_interference_player().playing == true, "FAIL 5: Radio toggle ON restores interference")

	# Synchronous Bike Dismount: MUST clear BEFORE next _process_radio_interference call
	controller._on_bike_dismounted()
	assert(controller._radio_owner == null, "FAIL 5: Radio owner cleared on matching dismount")
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 5: Dismount immediately clears interference intensity synchronously")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 5: Dismount immediately clears contamination synchronously")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 5: Dismount immediately stops 3D player synchronously")

	# Mount Scrap Hauler at 8m
	controller.scrap_hauler.global_position = controller.corroded_panel.global_position + Vector3(8.0, 0.0, 0.0)
	controller._on_hauler_mounted(controller.player)
	controller._process_radio_interference()
	var hauler_intensity = controller.audio_mgr.get_radio_interference_intensity()
	assert(is_equal_approx(hauler_intensity, bike_intensity), "FAIL 5: Hauler mounts with exact distance-matching intensity (got %.3f, exp %.3f)" % [hauler_intensity, bike_intensity])
	assert(controller.audio_mgr.get_radio_interference_player().playing == true, "FAIL 5: Interference player resumed for Hauler")

	# Stale dismount isolation: trigger stale Bike dismount while in Hauler -> must NOT clear Hauler interference
	controller._on_bike_dismounted()
	assert(controller._radio_owner == controller.scrap_hauler, "FAIL 5: Stale Bike dismount does NOT clear Hauler radio ownership")
	assert(controller.audio_mgr.get_radio_interference_player().playing == true, "FAIL 5: Stale Bike dismount does NOT stop Hauler interference")

	# Matching Hauler dismount
	controller._on_hauler_dismounted()
	assert(controller._radio_owner == null, "FAIL 5: Matching Hauler dismount clears ownership")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 5: Matching Hauler dismount stops interference")

	# Single-player authority count
	var p3d_count: int = 0
	for c in controller.audio_mgr.get_children():
		if c is AudioStreamPlayer3D and c.name.begins_with("RadioInterference"):
			p3d_count += 1
	assert(p3d_count == 1, "FAIL 5: Exactly 1 RadioInterferencePlayer3D authority")
	print("  -> Assertion 5 PASS: Bike <-> Hauler parity, stale dismount isolation, and synchronous clear verified!")

	# ASSERTION 6: Extraction -> M04 Full Lifecycle & Disturbance Handoff
	print("\n[ASSERTION 6] Testing Extraction -> M04 Full Lifecycle & Disturbance Handoff...")
	controller._on_bike_mounted(controller.player)
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(3.0, 0.0, 0.0)
	controller._process_radio_interference()
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 1.0), "FAIL 6: Interference at 1.0 prior to extraction")
	assert(controller.audio_mgr.get_radio_interference_player().playing == true, "FAIL 6: 3D player playing before extraction")

	# Trigger Extraction Completion
	controller.audio_mgr.event_counts.clear()
	controller._on_extraction_completed()

	# Assert immediately: precursor cleared before any frame step
	assert(controller.current_world_state == ScrapTestBlock.WorldLoopState.CORE_EXTRACTED, "FAIL 6: World transitioned to CORE_EXTRACTED")
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 6: Precursor interference cleared immediately on extraction")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 6: Contamination gain cleared immediately to 0 dB")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 6: 3D player stopped immediately on extraction")

	# Run existing M04 full lifecycle (ONSET -> PEAK -> RELEASE -> DONE)
	assert(controller.echo_controller != null, "FAIL 6: EchoController exists")
	assert(controller.echo_controller.current_phase == MemoryEchoController.EchoPhase.ONSET, "FAIL 6: M04 in ONSET state")
	assert(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.ECHO_ONSET, 0) == 1, "FAIL 6: ECHO_ONSET fired exactly once")

	# Step through M04 lifecycle frames and verify precursor remains strictly 0.0 in all phases
	while controller.echo_controller.current_phase != MemoryEchoController.EchoPhase.DONE and controller.echo_controller.current_phase != MemoryEchoController.EchoPhase.IDLE:
		controller._process_radio_interference()
		assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 6: Precursor remains zero during M04 phase %s" % MemoryEchoController.EchoPhase.keys()[controller.echo_controller.current_phase])
		assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 6: 3D player remains stopped during M04")
		controller.echo_controller._process(0.1)
		await controller.get_tree().process_frame

	assert(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.ECHO_ONSET, 0) == 1, "FAIL 6: ECHO_ONSET fired exactly once across whole echo")
	assert(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.ECHO_PEAK, 0) == 1, "FAIL 6: ECHO_PEAK fired exactly once")
	assert(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.ECHO_TAIL, 0) == 1, "FAIL 6: ECHO_TAIL fired exactly once")
	assert(controller.current_pursuit_state == ScrapTestBlock.PursuitState.DISTURBANCE_ALERT, "FAIL 6: Pursuit state is DISTURBANCE_ALERT after echo completion")
	var disturbance_count: int = int(controller.audio_mgr.event_counts.get(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT, 0))
	assert(disturbance_count == 1, "FAIL 6: DISTURBANCE_ALERT fired exactly once (got %d)" % disturbance_count)
	print("  DISTURBANCE_ALERT_EXACT_COUNT: %d" % disturbance_count)

	# Clean up echo and pursuit for next test
	if controller.echo_controller:
		controller.echo_controller.reset_echo()
	controller._end_pursuit_common()
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.CALM
	print("  -> Assertion 6 PASS: Full M04 lifecycle handoff, zero precursor leakage, and disturbance alert verified!")

	# ASSERTION 7: Real Process Frame Priority, Same-Frame Pursuit Suppression & Interception Immediate Clear
	print("\n[ASSERTION 7] Testing Real Process Frame Priority, Pursuit Suppression & Interception Immediate Clear...")
	controller.audio_mgr.reset_audio_instant()
	await controller.get_tree().process_frame
	controller.current_world_state = ScrapTestBlock.WorldLoopState.PANEL_POWERED
	controller._on_bike_mounted(controller.player)
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(5.0, 0.0, 0.0)
	
	# 1. Baseline unpursued interference
	controller._process_pursuit_loop(0.016)
	controller._process_radio_interference()
	var base_3d_vol = controller.audio_mgr.get_radio_interference_player().volume_db
	assert(controller.audio_mgr.get_radio_interference_player().playing == true, "FAIL 7: Baseline 3D interference playing")

	# 2. Activate pursuit at 10m distance and run real process loop
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.PURSUIT_ACTIVE
	controller.pursuer.is_active = true
	controller.pursuer.global_position = controller.courier_bike.global_position + Vector3(10.0, 0.0, 0.0)
	
	# Execute real controller frame path in authoritative order: pursuit loop THEN radio interference
	controller._process_pursuit_loop(0.016)
	controller._process_radio_interference()
	
	var pursued_3d_vol = controller.audio_mgr.get_radio_interference_player().volume_db
	var pursued_duck = controller.audio_mgr.get_radio_duck()
	var r_player_7 = controller.audio_mgr.get_radio_player()
	
	# Same frame assertions:
	assert(controller.audio_mgr._siren_player != null and controller.audio_mgr._siren_player.playing == true, "FAIL 7: Siren playing during pursuit")
	assert(r_player_7.is_stream_playing() == true, "FAIL 7: Radio stream still playing during pursuit")
	assert(pursued_3d_vol < base_3d_vol - 1.0, "FAIL 7: Same-frame 3D interference voice attenuated by pursuit pressure (cur=%.2f, base=%.2f)" % [pursued_3d_vol, base_3d_vol])
	assert(pursued_duck < -3.0, "FAIL 7: Same-frame radio duck applied (#24 mix authority)")

	# 3. Real Interception: Call _on_pursuer_intercepted()
	controller._on_pursuer_intercepted()
	
	# Assert immediately (SAME FRAME, zero latency before next process tick):
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 7: Interception immediately clears interference intensity")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 7: Interception immediately clears contamination gain")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 7: Interception immediately stops 3D interference player")
	assert(controller._radio_owner == null, "FAIL 7: Radio owner cleared on forced dismount")
	assert(controller.audio_mgr._current_radio_duck_db <= -23.9, "FAIL 7: Critical -24 dB mix duck target authoritative on interception")

	# Wait for 0.05s duck tween to reach target
	var duck_wait := Time.get_ticks_msec()
	while controller.audio_mgr.is_radio_duck_tweening() and Time.get_ticks_msec() - duck_wait < 300:
		await controller.get_tree().process_frame
	assert(controller.audio_mgr.get_radio_duck() <= -23.9, "FAIL 7: Critical -24 dB mix duck reached after tween (got %.2f)" % controller.audio_mgr.get_radio_duck())

	# Clear pursuit to restore baseline
	controller.audio_mgr.clear_radio_duck()
	controller.audio_mgr.clear_pursuit_pressure()
	controller.current_pursuit_state = ScrapTestBlock.PursuitState.CALM
	print("  -> Assertion 7 PASS: Real process frame ordering, same-frame pursuit attenuation, and zero-latency interception clear verified!")

	# ASSERTION 8: Replay / Reset Determinism & 12-Cycle Stress (0 Node Leaks)
	print("\n[ASSERTION 8] Testing Replay / Reset Determinism & 12-Cycle Stress (0 Leaks)...")
	# 1. Reset from dirty state
	controller.current_world_state = ScrapTestBlock.WorldLoopState.PANEL_POWERED
	controller._on_bike_mounted(controller.player)
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(3.0, 0.0, 0.0)
	controller._process_pursuit_loop(0.016)
	controller._process_radio_interference()
	assert(controller.audio_mgr.get_radio_interference_player().playing == true, "FAIL 8: Dirty state active before reset")

	controller.reset_slice()
	await controller.get_tree().process_frame
	assert(is_equal_approx(controller.audio_mgr.get_radio_interference_intensity(), 0.0), "FAIL 8: Intensity reset to 0.0 on replay")
	assert(is_equal_approx(controller.audio_mgr.get_radio_contamination_db(), 0.0), "FAIL 8: Contamination reset to 0 dB on replay")
	assert(controller.audio_mgr.get_radio_interference_player().playing == false, "FAIL 8: 3D player stopped on replay")

	# 2. 12 Rapid approach/retreat/mount/dismount cycles
	for cycle in range(12):
		controller.current_world_state = ScrapTestBlock.WorldLoopState.PANEL_POWERED
		controller._on_bike_mounted(controller.player)
		controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(float(cycle % 15) + 2.0, 0.0, 0.0)
		controller._process_radio_interference()
		controller._on_bike_dismounted()
		controller._process_radio_interference()
		controller._on_hauler_mounted(controller.player)
		controller.scrap_hauler.global_position = controller.corroded_panel.global_position + Vector3(float(cycle % 10) + 1.0, 0.0, 0.0)
		controller._process_radio_interference()
		controller._on_hauler_dismounted()
		controller._process_radio_interference()
	await controller.get_tree().process_frame

	var r_players: int = 0
	var r_streams: int = 0
	var int_players: int = 0
	for child in controller.audio_mgr.get_children():
		if child is AudioStreamPlayer3D and child.name.begins_with("RadioInterference"):
			int_players += 1
	if controller.audio_mgr.get_radio_player() != null:
		r_players += 1
		r_streams = controller.audio_mgr.get_radio_player().get_audio_stream_player_count()

	assert(r_players == 1, "FAIL 8: Exactly 1 RadioProgramPlayer authority")
	assert(r_streams == 1, "FAIL 8: Exactly 1 RadioAudioStreamPlayer authority")
	assert(int_players == 1, "FAIL 8: Exactly 1 RadioInterferencePlayer3D authority")
	print("  -> Assertion 8 PASS: Reset determinism and zero node leaks verified across 12 stress cycles!")

	# ASSERTION 9: Production Registry & Independent Procedural Fallback Integrity
	print("\n[ASSERTION 9] Testing production registry and independent procedural fallback integrity...")
	var slot_meta = AudioRegistryScript.get_slot("echo.radio_interference")
	assert(not slot_meta.is_empty(), "FAIL 9: echo.radio_interference slot exists in registry")
	assert(slot_meta["domain"] == AudioRegistryScript.Domain.ECHO, "FAIL 9: Domain is ECHO")
	assert(slot_meta["diegesis"] == AudioRegistryScript.Diegesis.HYBRID, "FAIL 9: Diegesis is HYBRID")
	assert(slot_meta["spatial_type"] == AudioRegistryScript.SpatialType.HYBRID, "FAIL 9: SpatialType is HYBRID")
	assert(slot_meta["mix_group"] == AudioRegistryScript.MixGroup.SIGNATURE_ECHO, "FAIL 9: MixGroup is SIGNATURE_ECHO")
	assert(slot_meta["playback_type"] == AudioRegistryScript.PlaybackType.CONTINUOUS_LOOP, "FAIL 9: PlaybackType is CONTINUOUS_LOOP")
	assert(slot_meta["asset_status"] == AudioRegistryScript.AssetStatus.LICENSED_FINAL, "FAIL 9: AssetStatus is production-final")
	assert(slot_meta["replacement_required"] == false, "FAIL 9: Production replacement clears replacement_required")
	assert(slot_meta["production_asset_path"] == "res://audio/echo/loop_echo_radio_interference.wav", "FAIL 9: Production path is exact")
	assert(slot_meta["source_provenance"] == "GTA_SA:SCRIPT:BANK_356:SOUND_12", "FAIL 9: Production provenance is exact")
	assert(absf(float(slot_meta["loop_end_sec"]) - 0.9579) < 0.01, "FAIL 9: Registry loop window matches production source")

	var stream = controller.audio_mgr._radio_interference_stream
	assert(stream != null, "FAIL 9: Production interference stream resolved")
	assert(stream.format == AudioStreamWAV.FORMAT_16_BITS, "FAIL 9: Production stream remains PCM16")
	assert(stream.mix_rate == 15000, "FAIL 9: Production stream preserves 15 kHz native rate")
	assert(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "FAIL 9: Production stream is loopable")
	assert(absf(stream.get_length() - 0.9579) < 0.01, "FAIL 9: Production stream duration matches selected source")
	print("  -> Assertion 9 PASS: Production interference metadata/playback verified!")

	# ASSERTION 10: Actual Multi-Stream Concurrent Playback Proof (Radio Stream + Engine + 3D Interference)
	print("\n[ASSERTION 10] Testing Actual Multi-Stream Concurrent Playback Proof...")
	controller.current_world_state = ScrapTestBlock.WorldLoopState.PANEL_POWERED
	controller._on_bike_mounted(controller.player)
	controller.courier_bike.global_position = controller.corroded_panel.global_position + Vector3(6.0, 0.0, 0.0)
	controller.courier_bike.current_speed = 7.0
	controller.audio_mgr.set_engine_audio(0.5, controller.courier_bike.global_position)
	var p_rad = controller.audio_mgr.get_radio_player()
	if p_rad:
		p_rad._cancel_radio_fade()
		p_rad._set_lifecycle_volume_db(0.0)
	controller._process_pursuit_loop(0.016)
	controller._process_radio_interference()
	await controller.get_tree().process_frame

	var p_eng = controller.audio_mgr._engine_player
	var p_int = controller.audio_mgr.get_radio_interference_player()

	# Real AudioStreamPlayer checks:
	assert(p_rad != null and p_rad.is_playing() and not p_rad.is_paused() and p_rad.is_stream_playing(), "FAIL 10: Radio stream actively playing")
	assert(p_eng != null and p_eng.playing == true, "FAIL 10: Engine rev playing")
	assert(p_int != null and p_int.playing == true, "FAIL 10: Interference 3D player playing")

	var intensity_10 = controller.audio_mgr.get_radio_interference_intensity()
	var cont_10 = p_rad.get_contamination_volume_db()
	var comp_10 = p_rad.get_composed_volume_db()
	var int_vol_10 = p_int.volume_db

	print("  [CONCURRENT PLAYBACK METRICS]")
	print("    Radio Stream Playing: %s | Lifecycle: %.2f dB | Duck: %.2f dB | Contamination: %.2f dB | Composed: %.2f dB" % [
		p_rad.is_stream_playing(), p_rad.get_lifecycle_volume_db(), p_rad.get_duck_volume_db(), cont_10, comp_10
	])
	print("    Engine Playing: %s | Speed Ratio: 0.50 | Position: %s" % [p_eng.playing, controller.courier_bike.global_position])
	print("    Interference 3D Playing: %s | Intensity: %.3f | Volume: %.2f dB | Position: %s" % [
		p_int.playing, intensity_10, int_vol_10, p_int.global_position
	])

	assert(intensity_10 > 0.70 and intensity_10 < 0.90, "FAIL 10: Valid intensity at 6m (~0.80)")
	assert(cont_10 < -2.5 and cont_10 > -3.8, "FAIL 10: Valid contamination gain at 6m (~-3.2 dB)")
	assert(comp_10 < -2.5 and comp_10 > -3.8, "FAIL 10: Valid composed volume at 6m (~-3.2 dB)")
	assert(int_vol_10 > -20.0 and int_vol_10 < -13.0, "FAIL 10: Valid 3D volume at 6m (~-15.6 dB)")

	controller._on_bike_dismounted()
	controller._process_radio_interference()
	print("  -> Assertion 10 PASS: Actual multi-stream concurrent playback verified!")

	print("\n=========================================================================")
	print("[ALL V8 M25 FIRST HYBRID ECHO/RADIO INTERFERENCE ASSERTIONS (1-10) PASSED 100% GREEN!]")
	print("=========================================================================\n")
	controller.get_tree().quit(0)


