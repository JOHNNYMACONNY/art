extends SceneTree

const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	quit(code)

func _fail(message: String) -> void:
	push_error("[GEARS_SCRAPPER_TOOL_MISSION_ORDERING] %s" % message)
	await _finish(1)

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
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to the production scene")
		return

	var incident := _scene.get_node_or_null("GearsWorkZoneIncident")
	var civic_runtime := _scene.get_node_or_null("CivicRepossessionRuntime")
	var scrapper := _scene.get_node_or_null("GearsScrapperToolRuntime")
	if incident == null or civic_runtime == null or scrapper == null:
		await _fail("Retained Production 04 / Mission 02 / P05 fixture is incomplete")
		return
	if not incident.has_method("trigger_service_access_disruption"):
		await _fail("Production 05 forced-access suppressed-report capability is absent")
		return

	var setup_error := await _complete_mission_one()
	if not setup_error.is_empty():
		await _fail(setup_error)
		return

	var player := _scene.get_node_or_null("Runner") as Node3D
	var access := _scene.get_node_or_null("CivicReportAccess")
	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	var hauler = _scene.get("scrap_hauler")
	var worker := incident.get_node_or_null("GearsWorker")
	var crawler := incident.get_node_or_null("UtilityCrawler")
	if player == null or access == null or alarm == null or hauler == null or worker == null or crawler == null:
		await _fail("Mission 02 Production-05 ordering fixture is incomplete")
		return

	# Jam CivicReportAccess through the retained generic Action route.
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	_scene.set("_active_target", access)
	if not bool(_wanted_runtime.call("handle_action_pressed")):
		await _fail("Could not jam civic report link through retained Action")
		return
	if bool(alarm.get("report_enabled")):
		await _fail("Civic report link did not suppress the qualified local Report path")
		return

	# Acquire the physical Scrapper through contextual Action.
	var pickup := scrapper.call("get_pickup") as Node3D
	if pickup == null:
		await _fail("P05 Scrapper pickup is missing")
		return
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	if not bool(scrapper.call("acquire_active_pickup")):
		await _fail("Could not acquire Scrapper for Mission-02 ordering tracer")
		return

	# Force the authored jammed access with the real captured-facing Tool swing.
	var barrier := scrapper.call("get_access_barrier") as Node3D
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if barrier == null or pivot == null:
		await _fail("P05 barrier/facing fixture is missing")
		return
	player.global_position = barrier.global_position + Vector3(0.0, -0.7, 1.15)
	pivot.rotation.y = 0.0
	if not bool(scrapper.call("handle_tool_action_pressed")):
		await _fail("Mission-02 forced-access Tool swing was not accepted")
		return
	scrapper.call("process_tool_state", 0.15)
	await process_frame
	await physics_frame
	if String(scrapper.call("get_access_state_name")) != "FORCED_OPEN" or String(scrapper.call("get_last_contact_name")) != "SERVICE_ACCESS":
		await _fail("Mission-02 Scrapper swing did not force the authored service access")
		return

	# Local actors react, the one-shot alarm source is consumed/faulted, but jammed city knowledge stays CLEAR.
	if String(incident.call("get_incident_state_name")) != "ALARMED":
		await _fail("Forced access did not alarm the retained local actors")
		return
	if int(incident.call("get_report_attempt_count")) != 1:
		await _fail("Forced access did not perform exactly one bounded Report attempt")
		return
	if String(worker.call("get_reaction_state_name")) != "ALARMED" or String(crawler.call("get_reaction_state_name")) != "ALARMED":
		await _fail("Forced access did not visibly propagate the local ALARMED reaction")
		return
	if int(_wanted_runtime.call("get_heat_level")) != 0 or String(_wanted_runtime.call("get_wanted_state_name")) != "CLEAR":
		await _fail("Jammed forced-access Report incorrectly created Wanted")
		return
	if not bool(alarm.get("is_triggered")) or bool(alarm.get("report_enabled")):
		await _fail("Forced-access suppression did not consume/fault the bounded alarm source")
		return

	# The later Mission-02 theft must still be CLEAN TAKE and enter DELIVERY.
	hauler.mounted.emit(player)
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.DELIVERY:
		await _fail("Forced-access suppression stranded Mission 02 instead of producing CLEAN TAKE")
		return
	if int(_wanted_runtime.call("get_heat_level")) != 0 or String(_wanted_runtime.call("get_wanted_state_name")) != "CLEAR":
		await _fail("Mission 02 clean take after P05 suppression fabricated Wanted")
		return

	print("[GEARS_SCRAPPER_TOOL_MISSION_ORDERING] PASS")
	await _finish(0)
