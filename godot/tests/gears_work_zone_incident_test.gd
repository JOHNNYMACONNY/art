extends SceneTree

const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")

var _scene: Node = null
var _runtime: Node = null
var _incident: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _runtime != null:
		_runtime.call("reset_runtime")
	quit(code)

func _fail(message: String) -> void:
	push_error("[GEARS_WORK_ZONE_INCIDENT] %s" % message)
	await _finish(1)

func _heat() -> int:
	return int(_runtime.call("get_heat_level"))

func _wanted_state() -> String:
	return String(_runtime.call("get_wanted_state_name"))

func _reset_incident_and_authority() -> void:
	_runtime.call("reset_runtime")
	if _incident != null and _incident.has_method("reset_incident"):
		_incident.call("reset_incident")
	await process_frame
	await physics_frame

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

func _jam_report_link() -> String:
	var player := _scene.get_node_or_null("Runner") as Node3D
	var access := _scene.get_node_or_null("CivicReportAccess")
	if player == null or access == null:
		return "Civic report access fixture is missing"
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	_scene.set("_active_target", access)
	if not bool(_runtime.call("handle_action_pressed")):
		return "Could not jam civic report link through retained action routing"
	return ""

func _place_vehicle_for_sample(vehicle: CharacterBody3D, actor: Node3D, speed: float, distance: float) -> void:
	vehicle.global_position = actor.global_position + Vector3(0.0, 0.0, distance)
	vehicle.velocity = Vector3(0.0, 0.0, -speed)
	if "current_speed" in vehicle:
		vehicle.set("current_speed", speed)

func _run() -> void:
	_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _runtime == null:
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
	if not bool(_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to the production scene")
		return

	# RED frontier: retained yard life exists, but no consequence-bearing Gears
	# work-zone sibling currently exists in the qualified production scene.
	_incident = _scene.get_node_or_null("GearsWorkZoneIncident")
	if _incident == null:
		await _fail("Production root has no GearsWorkZoneIncident anchored to the Gears crossing")
		return
	if not _incident.has_method("get_incident_contract") or not _incident.has_method("process_player_sample") or not _incident.has_method("reset_incident"):
		await _fail("Gears work-zone incident lacks its bounded production contract/runtime seam")
		return

	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	if district == null or not district.has_method("get_production_contract"):
		await _fail("Retained Gears district production contract is missing")
		return
	var district_contract: Dictionary = district.call("get_production_contract")
	if not bool(district_contract.get("owns_no_gameplay_authority", false)):
		await _fail("Production 04 violated the declarative Gears district authority boundary")
		return

	var proof := _scene.get_node_or_null("GearsStyleProof") as Node3D
	if proof == null or proof.visible:
		await _fail("Production 04 must not restore visible GearsStyleProof rendering")
		return
	for retained_name in ["ScrapWorker1", "ScrapWorker2", "UtilityCrawler"]:
		if _scene.get_node_or_null(retained_name) == null:
			await _fail("Retained yard actor %s was removed by Production 04" % retained_name)
			return

	var worker := _incident.get_node_or_null("GearsWorker") as CharacterBody3D
	var crawler := _incident.get_node_or_null("GearsCrawler") as CharacterBody3D
	var bike := _scene.get("courier_bike") as CharacterBody3D
	if worker == null or crawler == null or bike == null:
		await _fail("Work-zone actor pair or CourierBike fixture is missing")
		return

	var contract: Dictionary = _incident.call("get_incident_contract")
	if float(contract.get("material_speed_mps", 0.0)) != 8.0 or float(contract.get("material_actor_distance_m", 0.0)) != 1.25:
		await _fail("Material disruption thresholds drifted from #127 spec")
		return
	if not bool(contract.get("anchored_to_gears_industrial_intersection", false)):
		await _fail("Work-zone incident is not anchored to the authored Gears industrial crossing")
		return
	if String(_incident.call("get_incident_state_name")) != "ROUTINE":
		await _fail("Work-zone incident did not start in ROUTINE")
		return

	# Ordinary/slow approach: actor yields, city authority remains untouched.
	_place_vehicle_for_sample(bike, worker, 4.0, 2.0)
	_incident.call("process_player_sample", bike, true, 0.016)
	await physics_frame
	if int(worker.get("current_state")) != 1:
		await _fail("Ordinary close approach did not use retained YIELDING behavior")
		return
	if _heat() != 0 or _wanted_state() != "CLEAR":
		await _fail("Yield-only passage incorrectly created Wanted")
		return

	await _reset_incident_and_authority()
	worker = _incident.get_node_or_null("GearsWorker") as CharacterBody3D
	crawler = _incident.get_node_or_null("GearsCrawler") as CharacterBody3D

	# Live report path: high-speed close call alarms local life and becomes ordinary Heat 1.
	_place_vehicle_for_sample(bike, worker, 9.0, 0.6)
	_incident.call("process_player_sample", bike, true, 0.016)
	await process_frame
	if String(_incident.call("get_incident_state_name")) != "ALARMED":
		await _fail("Material work-zone disruption did not escalate incident-local state")
		return
	if int(worker.get("current_state")) != 2 or int(crawler.get("current_state")) != 2:
		await _fail("Material work-zone disruption did not alarm both local actors")
		return
	if _heat() != 1 or _wanted_state() != "CONTACT":
		await _fail("Live work-zone civic Report did not create Heat 1 + Contact")
		return

	# Local recovery is not authority recovery.
	bike.global_position = _incident.global_position + Vector3(12.0, 0.0, 0.0)
	bike.velocity = Vector3.ZERO
	_incident.call("process_player_sample", bike, true, 4.2)
	await process_frame
	if String(_incident.call("get_incident_state_name")) != "ROUTINE":
		await _fail("Work-zone local life did not recover after player left the incident")
		return
	if _heat() != 1:
		await _fail("Local actor recovery incorrectly cleared Wanted authority")
		return

	# Pre-existing Wanted: local alarm still occurs, but incident must not clear or replace authority.
	await _reset_incident_and_authority()
	if not bool(_runtime.call("request_civic_report", bike.global_position)):
		await _fail("Could not establish pre-existing Wanted fixture")
		return
	if _heat() != 1:
		await _fail("Pre-existing Wanted fixture did not reach Heat 1")
		return
	worker = _incident.get_node_or_null("GearsWorker") as CharacterBody3D
	_place_vehicle_for_sample(bike, worker, 9.0, 0.6)
	_incident.call("process_player_sample", bike, true, 0.016)
	await process_frame
	if _heat() != 1 or String(_incident.call("get_incident_state_name")) != "ALARMED":
		await _fail("Pre-existing Wanted was cleared/replaced or local alarm failed")
		return
	if int(_incident.call("get_report_attempt_count")) != 0:
		await _fail("Incident requested a second civic report while Wanted was already valid")
		return

	# Jammed report path + Production-03 ordering regression.
	await _reset_incident_and_authority()
	var setup_error := await _complete_mission_one()
	if not setup_error.is_empty():
		await _fail(setup_error)
		return
	var jam_error := _jam_report_link()
	if not jam_error.is_empty():
		await _fail(jam_error)
		return
	worker = _incident.get_node_or_null("GearsWorker") as CharacterBody3D
	crawler = _incident.get_node_or_null("GearsCrawler") as CharacterBody3D
	_place_vehicle_for_sample(bike, worker, 9.0, 0.6)
	_incident.call("process_player_sample", bike, true, 0.016)
	await process_frame
	if _heat() != 0 or _wanted_state() != "CLEAR":
		await _fail("Jammed work-zone Report incorrectly created Wanted")
		return
	if String(_incident.call("get_incident_state_name")) != "ALARMED" or int(worker.get("current_state")) != 2 or int(crawler.get("current_state")) != 2:
		await _fail("Field Hacking suppression incorrectly erased local actor reaction")
		return
	if int(_incident.call("get_report_attempt_count")) != 1:
		await _fail("Jammed work-zone incident did not perform exactly one bounded Report attempt")
		return

	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	if alarm == null or not bool(alarm.get("is_triggered")) or bool(alarm.get("report_enabled")):
		await _fail("Jammed work-zone event did not consume the expected local alarm-fault state")
		return
	var civic_runtime := _scene.get_node_or_null("CivicRepossessionRuntime")
	var player := _scene.get_node_or_null("Runner") as Node3D
	var hauler = _scene.get("scrap_hauler")
	if civic_runtime == null or player == null or hauler == null:
		await _fail("Mission 02 ordering fixture is incomplete")
		return
	hauler.mounted.emit(player)
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.DELIVERY:
		await _fail("Jammed work-zone alarm consumption stranded Mission 02 instead of CLEAN TAKE")
		return
	if _heat() != 0 or _wanted_state() != "CLEAR":
		await _fail("Mission 02 clean take after work-zone suppression fabricated Wanted")
		return

	# Replay-style reset restores incident-local deterministic state.
	_scene.call("reset_slice")
	await process_frame
	if String(_incident.call("get_incident_state_name")) != "ROUTINE" or int(_incident.call("get_report_attempt_count")) != 0:
		await _fail("Replay reset left stale work-zone incident state")
		return

	print("[GEARS_WORK_ZONE_INCIDENT] PASS")
	await _finish(0)
