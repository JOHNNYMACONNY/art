extends SceneTree

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
	push_error("[GEARS_SCRAPPER_TOOL_ENVIRONMENT] %s" % message)
	await _finish(1)

func _heat() -> int:
	return int(_wanted_runtime.call("get_heat_level"))

func _wanted_state() -> String:
	return String(_wanted_runtime.call("get_wanted_state_name"))

func _acquire_tool(runtime: Node, player: Node3D) -> String:
	var pickup := runtime.call("get_pickup") as Node3D
	if pickup == null:
		return "Scrapper pickup fixture is missing"
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	if not bool(runtime.call("acquire_active_pickup")):
		return "Could not acquire Scrapper for environment tracer"
	return ""

func _prepare_access_swing(runtime: Node, player: Node3D, pivot: Node3D) -> String:
	var barrier := runtime.call("get_access_barrier") as StaticBody3D
	if barrier == null:
		return "Jammed service access fixture is missing"
	player.global_position = barrier.global_position + Vector3(0.0, -0.7, 1.15)
	pivot.rotation.y = 0.0
	if not bool(runtime.call("handle_tool_action_pressed")):
		return "Valid access swing was not accepted"
	runtime.call("process_tool_state", 0.15)
	return ""

func _reset_scenario(runtime: Node, incident: Node) -> void:
	runtime.call("reset_runtime")
	incident.call("reset_incident")
	_wanted_runtime.call("reset_runtime")
	await process_frame
	await physics_frame
	await process_frame

func _jam_report_link(player: Node3D) -> String:
	var access := _scene.get_node_or_null("CivicReportAccess")
	if access == null:
		return "Civic report access fixture is missing"
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	_scene.set("_active_target", access)
	if not bool(_wanted_runtime.call("handle_action_pressed")):
		return "Could not jam civic report link through retained action routing"
	return ""

func _local_actors_alarmed(incident: Node) -> bool:
	var worker := incident.get_node_or_null("GearsWorker")
	var crawler := incident.get_node_or_null("GearsCrawler")
	return worker != null and crawler != null and int(worker.get("current_state")) == 2 and int(crawler.get("current_state")) == 2

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
	await process_frame
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to the production scene")
		return

	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	var player := _scene.get_node_or_null("Runner") as Node3D
	var runtime := _scene.get_node_or_null("GearsScrapperToolRuntime")
	var incident := _scene.get_node_or_null("GearsWorkZoneIncident")
	if district == null or player == null or runtime == null or incident == null:
		await _fail("P05 environment fixture is incomplete")
		return
	var district_contract: Dictionary = district.call("get_production_contract")
	if not bool(district_contract.get("owns_no_gameplay_authority", false)):
		await _fail("Retained Gears district authority boundary regressed")
		return
	if not player.has_method("get_facing_direction"):
		await _fail("Player facing read seam is missing")
		return
	if not incident.has_method("trigger_service_access_disruption"):
		await _fail("Production 05 P04 service-access disruption seam is absent")
		return
	for method_name in ["get_access_barrier", "get_access_state_name", "is_service_access_blocking", "process_tool_state", "get_contact_evaluation_count", "get_last_contact_name"]:
		if not runtime.has_method(method_name):
			await _fail("Scrapper runtime missing swing/access seam: %s" % method_name)
			return

	var barrier := runtime.call("get_access_barrier") as StaticBody3D
	if barrier == null or String(runtime.call("get_access_state_name")) != "JAMMED" or not bool(runtime.call("is_service_access_blocking")):
		await _fail("ServiceAlley access did not begin physically JAMMED")
		return
	if _scene.get_node_or_null("GearsDistrictSlice01B/ServiceAlley") == null or _scene.get_node_or_null("GearsDistrictSlice01B/NorthConnector") == null:
		await _fail("Retained ServiceAlley/NorthConnector route seam is missing")
		return

	var acquire_error := _acquire_tool(runtime, player)
	if not acquire_error.is_empty():
		await _fail(acquire_error)
		return
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if pivot == null:
		await _fail("Player MeshPivot fixture is missing")
		return
	pivot.rotation.y = 0.0

	# Out of range: one committed swing evaluates exactly once and misses.
	player.global_position = barrier.global_position + Vector3(0.0, -0.7, 3.0)
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Out-of-range committed swing was not accepted")
		return
	runtime.call("process_tool_state", 0.15)
	if int(runtime.call("get_contact_evaluation_count")) != 1 or String(runtime.call("get_last_contact_name")) != "MISS":
		await _fail("Out-of-range swing did not resolve exactly one miss")
		return
	if String(runtime.call("get_access_state_name")) != "JAMMED":
		await _fail("Out-of-range swing forced the service access")
		return
	runtime.call("process_tool_state", 0.50)

	# Behind the player's captured facing: still a miss.
	player.global_position = barrier.global_position + Vector3(0.0, -0.7, -1.1)
	pivot.rotation.y = 0.0
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Directional miss swing was not accepted")
		return
	runtime.call("process_tool_state", 0.15)
	if int(runtime.call("get_contact_evaluation_count")) != 2 or String(runtime.call("get_last_contact_name")) != "MISS":
		await _fail("Behind-facing access incorrectly qualified")
		return
	runtime.call("process_tool_state", 0.50)

	# CLEAR + live reporting: physical force alarms local life and becomes existing Heat 1 + Contact.
	var pre_mesh_position := (barrier.get_node("BarrierMesh") as Node3D).position
	var swing_error := _prepare_access_swing(runtime, player, pivot)
	if not swing_error.is_empty():
		await _fail(swing_error)
		return
	await physics_frame
	if int(runtime.call("get_contact_evaluation_count")) != 3 or String(runtime.call("get_last_contact_name")) != "SERVICE_ACCESS":
		await _fail("Valid swing did not select the authored service access exactly once")
		return
	if String(runtime.call("get_access_state_name")) != "FORCED_OPEN" or bool(runtime.call("is_service_access_blocking")):
		await _fail("Valid Scrapper contact did not materially open ServiceAlley traversal")
		return
	if (barrier.get_node("BarrierMesh") as Node3D).position == pre_mesh_position:
		await _fail("Forced access did not visibly move the jammed barrier")
		return
	if String(incident.call("get_incident_state_name")) != "ALARMED" or not _local_actors_alarmed(incident):
		await _fail("Forced access did not reuse P04 local actor alarm reaction")
		return
	if int(incident.call("get_report_attempt_count")) != 1 or _heat() != 1 or _wanted_state() != "CONTACT":
		await _fail("Live forced-access Report did not compose into existing Heat 1 + Contact")
		return
	runtime.call("process_tool_state", 0.50)

	# Already-open access is not damageable or reportable again.
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Post-open recovery did not permit another swing")
		return
	runtime.call("process_tool_state", 0.15)
	if int(runtime.call("get_contact_evaluation_count")) != 4 or String(runtime.call("get_last_contact_name")) == "SERVICE_ACCESS":
		await _fail("Already-open access accepted repeated damage/contact")
		return
	if int(incident.call("get_report_attempt_count")) != 1:
		await _fail("Already-open access requested a duplicate civic Report")
		return

	# CLEAR + jammed reporting: same local physical reaction, no new city knowledge.
	await _reset_scenario(runtime, incident)
	barrier = runtime.call("get_access_barrier") as StaticBody3D
	if barrier == null or String(runtime.call("get_access_state_name")) != "JAMMED" or not bool(runtime.call("is_service_access_blocking")):
		await _fail("Scenario reset did not restore physical service-access JAMMED state")
		return
	var jam_error := _jam_report_link(player)
	if not jam_error.is_empty():
		await _fail(jam_error)
		return
	acquire_error = _acquire_tool(runtime, player)
	if not acquire_error.is_empty():
		await _fail(acquire_error)
		return
	swing_error = _prepare_access_swing(runtime, player, pivot)
	if not swing_error.is_empty():
		await _fail(swing_error)
		return
	await physics_frame
	if String(incident.call("get_incident_state_name")) != "ALARMED" or not _local_actors_alarmed(incident):
		await _fail("Jammed forced access erased the local P04 alarm reaction")
		return
	if int(incident.call("get_report_attempt_count")) != 1:
		await _fail("Jammed forced access did not perform exactly one bounded Report attempt")
		return
	if _heat() != 0 or _wanted_state() != "CLEAR":
		await _fail("Jammed forced-access Report incorrectly created Wanted")
		return
	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	if alarm == null or not bool(alarm.get("is_triggered")) or bool(alarm.get("report_enabled")):
		await _fail("Jammed forced access did not preserve the expected consumed local alarm fault state")
		return

	# Pre-existing Wanted: force still alarms local life but cannot replace/clear authority or request again.
	await _reset_scenario(runtime, incident)
	barrier = runtime.call("get_access_barrier") as StaticBody3D
	if not bool(_wanted_runtime.call("request_civic_report", barrier.global_position)):
		await _fail("Could not establish pre-existing Wanted fixture")
		return
	var preexisting_heat := _heat()
	var preexisting_state := _wanted_state()
	if preexisting_heat != 1 or preexisting_state != "CONTACT":
		await _fail("Pre-existing Wanted fixture did not reach Heat 1 + Contact")
		return
	acquire_error = _acquire_tool(runtime, player)
	if not acquire_error.is_empty():
		await _fail(acquire_error)
		return
	swing_error = _prepare_access_swing(runtime, player, pivot)
	if not swing_error.is_empty():
		await _fail(swing_error)
		return
	await physics_frame
	if String(incident.call("get_incident_state_name")) != "ALARMED" or not _local_actors_alarmed(incident):
		await _fail("Pre-existing Wanted suppressed the local forced-access reaction")
		return
	if _heat() != preexisting_heat or _wanted_state() != preexisting_state:
		await _fail("Forced access cleared or replaced pre-existing Wanted authority")
		return
	if int(incident.call("get_report_attempt_count")) != 0:
		await _fail("Forced access requested a redundant civic Report while Wanted was already valid")
		return

	print("[GEARS_SCRAPPER_TOOL_ENVIRONMENT] PASS")
	await _finish(0)
