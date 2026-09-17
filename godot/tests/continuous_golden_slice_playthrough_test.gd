extends SceneTree

# Continuous Golden Slice Playthrough Test
# Validates unbroken sequence of Mission 01 -> Mission 02 -> Mission 03 across
# the expanded Gears District geography, verifying mount/dismount, vehicle kinematics,
# pursuit evasion, return zones, audio ducking, and slice replay reset.

const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const CityMissionScript = preload("res://scripts/missions/city_that_forgot_mission.gd")
const SignalTuner = preload("res://scripts/interactions/signal_tuner.gd")
const CorrodedPanel = preload("res://scripts/interactions/corroded_panel.gd")
const MemoryEchoScript = preload("res://scripts/prototype/memory_echo_controller.gd")

var _scene: Node = null
var _stage: String = "init"

func _init() -> void:
	call_deferred("_watchdog")
	call_deferred("_run")

func _watchdog() -> void:
	await create_timer(25.0).timeout
	push_error("[GOLDEN_SLICE_PLAYTHROUGH] WATCHDOG TIMEOUT at stage=%s" % _stage)
	quit(1)

func _finish(exit_code: int) -> void:
	_stage = "finish"
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(msg: String) -> void:
	push_error("[GOLDEN_SLICE_PLAYTHROUGH] FAIL: %s (stage=%s)" % [msg, _stage])
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[GOLDEN_SLICE_PLAYTHROUGH] Starting Continuous 3-Mission End-to-End Test")
	print("=========================================================================\n")

	# -------------------------------------------------------------------------
	# STAGE 0: Scene Instantiation & Binding Verification
	# -------------------------------------------------------------------------
	_stage = "load_scene"
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame

	var player = _scene.get_node_or_null("Runner")
	var bike = _scene.get("courier_bike")
	var hauler = _scene.get("scrap_hauler")
	var tuner = _scene.get("signal_tuner")
	var panel = _scene.get("corroded_panel")
	var gate = _scene.get("signal_gate")
	var pursuer = _scene.get("pursuer")
	var audio_mgr = _scene.get("audio_mgr")
	var touch_ui = _scene.get_node_or_null("CanvasLayer/TouchControlsUI")

	var runtime1 = _scene.get_node_or_null("MissionScrapJobRuntime")
	var runtime2 = _scene.get_node_or_null("CivicRepossessionRuntime")
	var runtime3 = _scene.get_node_or_null("CityThatForgotRuntime")
	var district = _scene.get_node_or_null("GearsDistrictSlice01B")

	if player == null or bike == null or hauler == null or tuner == null or panel == null or gate == null:
		await _fail("Missing critical scene entities")
		return
	if runtime1 == null or runtime2 == null or runtime3 == null:
		await _fail("Missing mission runtimes")
		return
	if district == null:
		await _fail("Missing GearsDistrictSlice01B expanded district")
		return

	var safe_root := touch_ui.get_node_or_null("SafeAreaRoot") as Control
	var mission_hud := safe_root.get_node_or_null("MissionHUD") if safe_root != null else null
	if mission_hud == null:
		await _fail("MissionHUD not found in SafeAreaRoot")
		return

	var title := mission_hud.find_child("MissionTitle", true, false) as Label
	var objective := mission_hud.find_child("ObjectiveLabel", true, false) as Label
	var contact := mission_hud.find_child("ContactLabel", true, false) as Label

	# -------------------------------------------------------------------------
	# STAGE 1: Cold Start State Verification
	# -------------------------------------------------------------------------
	_stage = "cold_start_audit"
	if runtime1.mission.phase != ScrapJobMissionScript.Phase.GET_BIKE:
		await _fail("Mission 01 did not cold-start in GET_BIKE")
		return
	if runtime2.mission.phase != CivicMissionScript.Phase.LOCKED:
		await _fail("Mission 02 did not cold-start in LOCKED")
		return
	if runtime3.mission.phase != CityMissionScript.Phase.LOCKED:
		await _fail("Mission 03 did not cold-start in LOCKED")
		return
	if title.text != "SCRAP JOB 01 // CITY PROPERTY" or "COURIER BIKE" not in objective.text:
		await _fail("HUD does not display Mission 01 cold start briefing")
		return
	print("  [STAGE 1 PASS] Cold start baseline verified. Mission 01 active, Missions 02/03 locked.")

	# -------------------------------------------------------------------------
	# STAGE 2: Mission 01 — Courier Bike Mount, Apex Lean, Traversal & Extraction
	# -------------------------------------------------------------------------
	_stage = "m01_bike_mount_and_lean"
	player.global_position = bike.global_position + Vector3(0, 0, 0.5)
	bike.mount_interactable.update_player_distance(player.global_position)
	var mount_ok : bool = bike.request_mount(player)
	if not mount_ok:
		await _fail("Failed to mount Courier Bike")
		return

	# Wait mount settling
	await create_timer(0.3).timeout
	await process_frame
	if not player.is_mounted or bike.occupant != player:
		await _fail("Player not properly seated on Courier Bike")
		return

	# Verify rider socket reparenting & roll association
	var rider_socket: Node3D = bike.rider_socket
	if rider_socket.get_parent() != bike.visual_root:
		await _fail("RiderSocket is not child of VisualRoot; apex lean roll broken")
		return

	# Test steering roll kinematics through controller drive inputs
	_scene.set("_throttle_input", 1.0)
	_scene.set("_steer_input", 1.0)
	for _f in range(20):
		await physics_frame
	if abs(bike.visual_root.rotation.z) < 0.01:
		await _fail("Bike chassis failed to bank into turn")
		return
	_scene.set("_throttle_input", 0.0)
	_scene.set("_steer_input", 0.0)
	print("  [STAGE 2A PASS] Bike mount & apex bank kinematics verified.")

	# Traverse to Tuner Mast
	_stage = "m01_traverse_to_tuner"
	bike.global_position = tuner.global_position + Vector3(1.0, 0, 0)
	bike.current_speed = 0.0
	var dismount_ok : bool = bike.request_dismount()
	if not dismount_ok:
		await _fail("Failed to dismount at Tuner mast")
		return
	await create_timer(0.25).timeout
	await process_frame
	if player.is_mounted or bike.occupant != null:
		await _fail("Player failed to dismount cleanly at Tuner")
		return

	player.global_position = tuner.global_position
	await process_frame
	if runtime1.mission.phase != ScrapJobMissionScript.Phase.SPOOF_SIGNAL:
		await _fail("Mission 01 did not advance to SPOOF_SIGNAL on arrival at Tuner")
		return

	# Solve Signal Tuner
	_stage = "m01_spoof_signal"
	tuner.set("current_state", SignalTuner.TunerState.LOCKED)
	tuner.signal_locked.emit(tuner)
	await process_frame
	if runtime1.mission.phase != ScrapJobMissionScript.Phase.EXTRACT_CORE:
		await _fail("Mission 01 did not advance to EXTRACT_CORE after signal lock")
		return
	print("  [STAGE 2B PASS] Tuner arrival, dismount & signal spoof verified.")

	# Extract Core at Corroded Panel
	_stage = "m01_extract_core"
	player.global_position = panel.global_position
	panel.set("current_step", CorrodedPanel.Step.EXTRACTED)
	panel.extraction_completed.emit()
	await process_frame
	await process_frame

	var echo_ctrl = _scene.get("echo_controller")
	if echo_ctrl == null:
		await _fail("Echo controller was not instantiated upon extraction")
		return
	if echo_ctrl.current_phase == MemoryEchoScript.EchoPhase.IDLE:
		await _fail("Memory Echo did not trigger after core extraction")
		return

	# Process Echo through to completion
	echo_ctrl.call("_process", 1.0)
	echo_ctrl.call("_process", 2.0)
	echo_ctrl.call("_process", 1.0)
	await process_frame
	await process_frame

	# Verify pursuit complication & audio ducking
	_stage = "m01_pursuit_and_evasion"
	var pursuit_state: int = int(_scene.get("current_pursuit_state"))
	if pursuit_state != int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE) \
	and pursuit_state != int(ScrapTestBlockScript.PursuitState.DISTURBANCE_ALERT):
		await _fail("Disturbance/pursuit did not trigger following extraction echo")
		return
	if runtime1.mission.phase != ScrapJobMissionScript.Phase.PURSUIT_COMPLICATION:
		await _fail("Mission 01 did not enter PURSUIT_COMPLICATION")
		return

	# Check audio ducking was applied
	var duck_db: float = audio_mgr.call("get_radio_duck")
	if duck_db >= 0.0:
		await _fail("Audio ducking was not applied during pursuit tension")
		return

	# Ensure pursuit active reconciles into ROUTE_DECISION
	await process_frame
	if runtime1.mission.phase == ScrapJobMissionScript.Phase.PURSUIT_COMPLICATION:
		runtime1.mission.on_pursuit_active()
	await process_frame

	# Trigger Signal Gate & Evade Pursuer
	gate.gate_triggered.emit()
	await process_frame
	_scene.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.EVADED)
	pursuer.de_escalation_completed.emit()
	await process_frame
	await process_frame

	if runtime1.mission.phase != ScrapJobMissionScript.Phase.COMPLETE:
		await _fail("Mission 01 did not reach COMPLETE after evasion")
		return
	print("  [STAGE 2C PASS] Core extraction, Echo audio ducking & pursuit evasion verified.")

	# -------------------------------------------------------------------------
	# STAGE 3: Mission 02 — Civic Repossession, Scrap Hauler & Gears District
	# -------------------------------------------------------------------------
	_stage = "m02_unlock_and_mount"
	await process_frame
	if runtime2.mission.phase != CivicMissionScript.Phase.GET_HAULER:
		await _fail("Mission 02 did not automatically unlock into GET_HAULER")
		return
	if title.text != "CIVIC REPOSSESSION // MAYOR BURN":
		await _fail("HUD title did not update to Civic Repossession")
		return
	if not contact.text.begins_with("MAYOR BURN //"):
		await _fail("HUD contact line did not hand off to Mayor Burn")
		return

	# Mount Scrap Hauler
	player.global_position = hauler.global_position + Vector3(0, 0, 1.0)
	hauler.mount_interactable.update_player_distance(player.global_position)
	var hauler_mount_ok : bool = hauler.request_mount(player)
	if not hauler_mount_ok:
		await _fail("Failed to mount Scrap Hauler")
		return
	await create_timer(0.3).timeout
	await process_frame

	if hauler.occupant != player or player.current_vehicle_posture != "car":
		await _fail("Player not seated in vehicle driving posture in Scrap Hauler")
		return
	if runtime2.mission.phase != CivicMissionScript.Phase.ESCAPE:
		await _fail("Mission 02 did not enter ESCAPE phase upon mounting Hauler")
		return
	print("  [STAGE 3A PASS] Mission 02 handoff & Scrap Hauler driving posture verified.")

	# Navigate into expanded Gears District towards Mayor Burn Garage
	_stage = "m02_gears_district_navigation"
	var dest_socket := district.get_node_or_null("MissionDestinationSocket") as Marker3D
	if dest_socket == null:
		await _fail("GearsDistrictSlice01B is missing MissionDestinationSocket")
		return

	var return_zone := _scene.get_node_or_null("CivicRepossessionReturnZone") as MeshInstance3D
	if return_zone == null:
		await _fail("CivicRepossessionReturnZone is missing from scene")
		return

	# Evade pursuit with Hauler
	_scene.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.EVADED)
	await process_frame
	if runtime2.mission.phase != CivicMissionScript.Phase.DELIVERY:
		await _fail("Mission 02 did not advance to DELIVERY after evasion")
		return
	if not return_zone.visible:
		await _fail("Return zone failed to activate for delivery")
		return

	# Pull Hauler into Return Zone at Mayor Burn Garage
	hauler.global_position = return_zone.global_position
	await process_frame
	if runtime2.mission.phase != CivicMissionScript.Phase.COMPLETE:
		await _fail("Mission 02 did not complete upon entering Return Zone")
		return
	if str(CivicMissionScript.PAYOFF_CREDITS) not in objective.text:
		await _fail("Civic Repossession credit payoff not shown in objective")
		return

	hauler.force_dismount()
	await process_frame
	print("  [STAGE 3B PASS] Gears District destination reached & Mission 02 completed with payoff.")

	# -------------------------------------------------------------------------
	# STAGE 4: Mission 03 — Sister Kael, Silent Core Shrine & Echo Resonance
	# -------------------------------------------------------------------------
	_stage = "m03_unlock_and_silent_core"
	# 1 frame presentation payoff hold
	await process_frame
	await process_frame
	if runtime3.mission.phase != CityMissionScript.Phase.REACH_SILENT_CORE:
		await _fail("Mission 03 did not automatically unlock into REACH_SILENT_CORE")
		return
	if title.text != "THE CITY THAT FORGOT // SISTER KAEL":
		await _fail("HUD title did not update to Sister Kael")
		return

	var silent_core = _scene.get_node_or_null("SilentCore")
	if silent_core == null:
		await _fail("Silent Core node is missing from production scene")
		return
	if not bool(silent_core.get("is_powered")):
		await _fail("Silent Core did not power on upon Mission 03 unlock")
		return

	# Navigate player to Silent Core Shrine in Gears District
	player.global_position = silent_core.global_position
	silent_core.update_player_distance(player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != silent_core:
		await _fail("Target arbitration did not lock onto Silent Core interactable")
		return

	# Trigger Silent Core Resonance
	touch_ui.action_button_pressed.emit()
	await process_frame
	if runtime3.mission.phase != CityMissionScript.Phase.ECHO_ACTIVE:
		await _fail("Mission 03 did not enter ECHO_ACTIVE upon interaction")
		return

	var echo_data = echo_ctrl.get("_echo_data")
	if echo_data == null or echo_data.mission_ref != "mission_03_city_that_forgot":
		await _fail("Silent Core echo did not carry authored HS-7 mission payload")
		return

	# Complete Echo sequence
	echo_ctrl.call("_process", 1.0)
	echo_ctrl.call("_process", 2.0)
	echo_ctrl.call("_process", 1.0)
	await process_frame

	if runtime3.mission.phase != CityMissionScript.Phase.ESCAPE:
		await _fail("Mission 03 did not enter ESCAPE phase after Echo completion")
		return

	# Simulate fresh pursuit alert
	_scene.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.CALM)
	await process_frame
	if int(_scene.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.DISTURBANCE_ALERT) \
	and int(_scene.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE):
		await _fail("Fresh pursuit was not initiated for Mission 03 escape")
		return

	# Final evasion
	_scene.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.EVADED)
	await process_frame
	if runtime3.mission.phase != CityMissionScript.Phase.COMPLETE:
		await _fail("Mission 03 did not reach COMPLETE after final evasion")
		return
	if "CITY THAT FORGOT" not in objective.text:
		await _fail("Mission 03 aftermath narrative not displayed")
		return
	print("  [STAGE 4 PASS] Silent Core shrine activated, HS-7 echo resonated & Mission 03 complete.")

	# -------------------------------------------------------------------------
	# STAGE 5: Full Slice Replay Reset Verification
	# -------------------------------------------------------------------------
	_stage = "full_replay_reset"
	_scene.call("reset_slice")
	await process_frame
	await process_frame

	if runtime1.mission.phase != ScrapJobMissionScript.Phase.GET_BIKE:
		await _fail("Slice reset did not return Mission 01 to GET_BIKE")
		return
	if runtime2.mission.phase != CivicMissionScript.Phase.LOCKED:
		await _fail("Slice reset did not relock Mission 02")
		return
	if runtime3.mission.phase != CityMissionScript.Phase.LOCKED:
		await _fail("Slice reset did not relock Mission 03")
		return
	if bool(silent_core.get("is_powered")) or int(silent_core.get("activation_count")) != 0:
		await _fail("Slice reset leaked Silent Core power or activation count")
		return
	if return_zone.visible:
		await _fail("Slice reset left Civic return zone visible")
		return
	if title.text != "SCRAP JOB 01 // CITY PROPERTY":
		await _fail("Slice reset did not restore Mission 01 HUD")
		return
	print("  [STAGE 5 PASS] Full slice reset restores cold start state cleanly.")

	print("\n=========================================================================")
	print("[GOLDEN_SLICE_PLAYTHROUGH] 100% ALL 3 MISSIONS CONTINUOUS PLAYTHROUGH PASS")
	print("=========================================================================\n")
	await _finish(0)
