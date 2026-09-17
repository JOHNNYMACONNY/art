extends SceneTree

const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")

var _scene: Node = null
var _runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[GEARS_WORK_ZONE_MISSION_ORDERING] %s" % message)
	if is_instance_valid(_scene):
		_scene.queue_free()
	quit(1)

func _complete_mission_one() -> String:
	var mission_one_runtime := _scene.get_node_or_null("MissionScrapJobRuntime")
	var civic_runtime := _scene.get_node_or_null("CivicRepossessionRuntime")
	var tuner = _scene.get("signal_tuner")
	var panel = _scene.get("corroded_panel")
	if mission_one_runtime == null or civic_runtime == null or tuner == null or panel == null:
		return "Mission fixture dependencies are missing"
	tuner.set("current_state", SignalTuner.TunerState.LOCKED)
	panel.set("current_step", CorrodedPanel.Step.EXTRACTED)
	var mission = mission_one_runtime.mission
	if mission.phase == ScrapJobMissionScript.Phase.BRIEFING:
		mission.start()
	if mission.phase == ScrapJobMissionScript.Phase.GET_BIKE:
		mission.on_courier_bike_mounted()
	if mission.phase == ScrapJobMissionScript.Phase.TRAVERSE_TO_TUNER:
		mission.on_tuner_arrived()
	if mission.phase == ScrapJobMissionScript.Phase.SPOOF_SIGNAL:
		mission.on_signal_locked()
	if mission.phase == ScrapJobMissionScript.Phase.EXTRACT_CORE:
		mission.on_core_extracted()
	if mission.phase == ScrapJobMissionScript.Phase.PURSUIT_COMPLICATION:
		mission.on_pursuit_active()
	if mission.phase == ScrapJobMissionScript.Phase.ROUTE_DECISION:
		mission.on_escape_complete()
	if mission.phase != ScrapJobMissionScript.Phase.COMPLETE:
		return "Mission 01 fixture could not complete"
	mission_one_runtime.call("_refresh_hud")
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.GET_HAULER:
		return "Mission 02 did not unlock"
	return ""

func _run() -> void:
	_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _runtime == null:
		_fail("BurnsideWantedRuntime is missing")
		return
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		_fail("Production scene is missing")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	if not bool(_runtime.call("bind_to_scene", _scene)):
		_fail("Wanted runtime did not bind")
		return

	var incident := _scene.get_node_or_null("GearsWorkZoneIncident")
	if incident == null:
		_fail("Production 04 work-zone incident did not mount")
		return
	var worker := incident.get_node_or_null("GearsWorker") as CharacterBody3D
	var bike := _scene.get("courier_bike") as CharacterBody3D
	if worker == null or bike == null:
		_fail("Production 04 work-zone fixture is incomplete")
		return

	var setup_error := await _complete_mission_one()
	if not setup_error.is_empty():
		_fail(setup_error)
		return

	var civic_runtime := _scene.get_node_or_null("CivicRepossessionRuntime")
	var player := _scene.get_node_or_null("Runner") as Node3D
	var access := _scene.get_node_or_null("CivicReportAccess")
	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	var hauler = _scene.get("scrap_hauler")
	if civic_runtime == null or player == null or access == null or alarm == null or hauler == null:
		_fail("Mission 02 production fixture is incomplete")
		return

	# Jam the qualified local report path through retained action routing.
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	_scene.set("_active_target", access)
	if not bool(_runtime.call("handle_action_pressed")):
		_fail("Could not jam civic report link")
		return

	# Production 04, not a direct alarm interaction, consumes the same local
	# one-shot report source while jammed.
	bike.global_position = worker.global_position + Vector3(0.0, 0.0, 0.6)
	bike.velocity = Vector3(0.0, 0.0, -9.0)
	if "current_speed" in bike:
		bike.set("current_speed", 9.0)
	incident.call("process_player_sample", bike, true, 0.016)
	await process_frame
	if String(incident.call("get_incident_state_name")) != "ALARMED":
		_fail("Work-zone close call did not alarm local actors")
		return
	if int(incident.call("get_report_attempt_count")) != 1:
		_fail("Work-zone did not perform exactly one bounded Report attempt")
		return
	if int(_runtime.call("get_heat_level")) != 0 or String(_runtime.call("get_wanted_state_name")) != "CLEAR":
		_fail("Jammed work-zone Report incorrectly created Wanted")
		return
	if not bool(alarm.get("is_triggered")) or bool(alarm.get("report_enabled")):
		_fail("Work-zone suppression did not leave the expected one-shot alarm fault state")
		return

	# Production-03 repair must still treat the later Mission-02 theft as CLEAN TAKE.
	hauler.mounted.emit(player)
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.DELIVERY:
		_fail("Work-zone alarm consumption stranded Mission 02 instead of producing CLEAN TAKE")
		return
	if int(_runtime.call("get_heat_level")) != 0 or String(_runtime.call("get_wanted_state_name")) != "CLEAR":
		_fail("Mission 02 clean take after work-zone suppression fabricated Wanted")
		return

	print("[GEARS_WORK_ZONE_MISSION_ORDERING] PASS")
	_scene.queue_free()
	await process_frame
	_runtime.call("reset_runtime")
	quit(0)
