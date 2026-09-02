extends SceneTree

const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")

var _runtime: Node = null
var _scene_under_test: Node = null
var _stage: String = "init"

func _init() -> void:
	call_deferred("_watchdog")
	call_deferred("_run")

func _watchdog() -> void:
	await create_timer(20.0).timeout
	push_error("[CIVIC_REPOSSESSION_WANTED_COMPOSITION] WATCHDOG TIMEOUT stage=%s" % _stage)
	quit(1)

func _finish(exit_code: int) -> void:
	_stage = "finish"
	await _free_scene()
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[CIVIC_REPOSSESSION_WANTED_COMPOSITION] %s (stage=%s)" % [message, _stage])
	await _finish(1)

func _heat() -> int:
	return int(_runtime.call("get_heat_level"))

func _state() -> String:
	return String(_runtime.call("get_wanted_state_name"))

func _free_scene() -> void:
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	_scene_under_test = null
	if _runtime != null and _runtime.has_method("reset_runtime"):
		_runtime.call("reset_runtime")

func _fresh_scene() -> Node:
	await _free_scene()
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		return null
	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	await process_frame
	_runtime.call("bind_to_scene", _scene_under_test)
	await process_frame
	return _scene_under_test

func _complete_mission_one(scene: Node) -> String:
	var mission_one_runtime := scene.get_node_or_null("MissionScrapJobRuntime")
	var civic_runtime := scene.get_node_or_null("CivicRepossessionRuntime")
	var tuner = scene.get("signal_tuner")
	var panel = scene.get("corroded_panel")
	if mission_one_runtime == null or civic_runtime == null or tuner == null or panel == null:
		return "Production mission runtimes or retained Mission-01 interactions are missing"

	# Keep retained solved-state consistent so Mission 01 cannot interpret this fixture
	# as a full replay and immediately restart after authored completion.
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
		return "Mission 01 fixture could not reach COMPLETE"
	mission_one_runtime.call("_refresh_hud")
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.GET_HAULER:
		return "Mission 01 completion did not unlock Civic Repossession"
	return ""

func _force_legitimate_evasion() -> String:
	var authority = _runtime.get("wanted_authority")
	if authority == null:
		return "WantedAuthority is absent"
	if String(authority.call("get_wanted_state_name")) != "CONTACT":
		return "Evasion fixture did not begin from Contact"
	if not bool(authority.call(
		"lose_contact",
		authority.call("get_last_known_position"),
		authority.call("get_last_known_direction"),
		"production03_test_contact_break"
	)):
		return "Authority rejected a valid Contact -> Search transition"
	if String(authority.call("get_wanted_state_name")) != "SEARCH":
		return "Contact loss did not enter Search"
	var search_seconds := float(authority.get("search_evasion_seconds"))
	if not bool(authority.call("advance_search", search_seconds + 0.1)):
		return "Search timeout did not produce Evasion"
	if int(authority.call("get_heat_level")) != 0 or String(authority.call("get_wanted_state_name")) != "CLEAR":
		return "Legitimate Evasion did not clear Wanted"
	return ""

func _run() -> void:
	_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _runtime == null:
		await _fail("BurnsideWantedRuntime autoload is absent")
		return

	# Intentional RED gate. Mission 02 must not reach into private alarm/authority
	# internals; Production 03 adds only this narrow public composition seam.
	if not _runtime.has_method("request_civic_report"):
		await _fail("Mission-facing civic report seam is absent")
		return
	if not _runtime.has_method("get_heat_level") or not _runtime.has_method("get_wanted_state_name"):
		await _fail("Mission-facing Wanted read seam is absent")
		return

	_stage = "live_report"
	var live_scene := await _fresh_scene()
	if live_scene == null:
		await _fail("Could not load production scrap_test_block scene")
		return
	var setup_error := await _complete_mission_one(live_scene)
	if not setup_error.is_empty():
		await _fail(setup_error)
		return

	var live_civic := live_scene.get_node_or_null("CivicRepossessionRuntime")
	var live_hauler = live_scene.get("scrap_hauler")
	if live_civic == null or live_hauler == null:
		await _fail("Civic Repossession runtime or Scrap Hauler is absent")
		return

	live_hauler.mounted.emit(live_scene.get_node("Runner"))
	await process_frame
	if int(live_scene.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.CALM):
		await _fail("Mission 02 Hauler theft still starts legacy pursuit directly")
		return
	if _heat() != 1 or _state() != "CONTACT":
		await _fail("Live civic theft Report did not produce Heat 1 + Contact")
		return
	if live_civic.mission.phase != CivicMissionScript.Phase.ESCAPE:
		await _fail("Live-report Hauler theft did not remain in ESCAPE while Wanted is active")
		return

	var evasion_error := _force_legitimate_evasion()
	if not evasion_error.is_empty():
		await _fail(evasion_error)
		return
	await process_frame
	if live_civic.mission.phase != CivicMissionScript.Phase.DELIVERY:
		await _fail("Legitimate open-world Evasion did not advance Civic Repossession to DELIVERY")
		return

	_stage = "jammed_report"
	var jam_scene := await _fresh_scene()
	if jam_scene == null:
		await _fail("Could not reload production scene for jammed path")
		return
	setup_error = await _complete_mission_one(jam_scene)
	if not setup_error.is_empty():
		await _fail(setup_error)
		return

	var jam_civic := jam_scene.get_node_or_null("CivicRepossessionRuntime")
	var jam_hauler = jam_scene.get("scrap_hauler")
	var player := jam_scene.get_node_or_null("Runner") as Node3D
	var access := jam_scene.get_node_or_null("CivicReportAccess")
	var alarm := jam_scene.get_node_or_null("CivicServiceAlarm")
	if jam_civic == null or jam_hauler == null or player == null or access == null or alarm == null:
		await _fail("Jammed-path production fixture is missing Mission 02, Hauler, player, or civic infrastructure")
		return

	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	jam_scene.set("_active_target", access)
	if not bool(_runtime.call("handle_action_pressed")):
		await _fail("Physical civic service access did not jam the report link")
		return
	if bool(alarm.get("report_enabled")):
		await _fail("Field Hacking did not suppress the civic report path before Hauler theft")
		return

	jam_hauler.mounted.emit(player)
	await process_frame
	if int(jam_scene.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.CALM):
		await _fail("Jammed Mission 02 theft fabricated a legacy pursuit")
		return
	if _heat() != 0 or _state() != "CLEAR":
		await _fail("Suppressed Mission 02 theft Report incorrectly created Wanted")
		return
	if jam_civic.mission.phase != CivicMissionScript.Phase.DELIVERY:
		await _fail("Report-suppressed Hauler theft did not advance directly to DELIVERY")
		return

	# Mission completion is not an authority reset. Restore civic service directly,
	# create another valid incident while Mission 02 is already in DELIVERY, then
	# deliver the Hauler and prove the valid Wanted state survives completion.
	_runtime.call("reset_runtime")
	if not bool(_runtime.call("request_civic_report", player.global_position)):
		await _fail("Restored civic service could not create a post-theft valid Report")
		return
	if _heat() != 1 or _state() != "CONTACT":
		await _fail("Post-theft valid Report did not create Heat 1 + Contact")
		return
	var return_zone := jam_scene.get_node_or_null("CivicRepossessionReturnZone") as Node3D
	if return_zone == null:
		await _fail("Civic Repossession return zone is absent")
		return
	jam_hauler.global_position = return_zone.global_position
	await process_frame
	if jam_civic.mission.phase != CivicMissionScript.Phase.COMPLETE:
		await _fail("Garage delivery did not complete Civic Repossession")
		return
	if _heat() != 1 or _state() != "CONTACT":
		await _fail("Mission completion silently cleared valid Wanted knowledge")
		return

	print("[CIVIC_REPOSSESSION_WANTED_COMPOSITION] PASS")
	await _finish(0)
