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
	if district == null or player == null or runtime == null:
		await _fail("P05 environment fixture is incomplete")
		return
	var district_contract: Dictionary = district.call("get_production_contract")
	if not bool(district_contract.get("owns_no_gameplay_authority", false)):
		await _fail("Retained Gears district authority boundary regressed")
		return
	if not player.has_method("get_facing_direction"):
		await _fail("Player facing read seam is missing")
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

	var pickup := runtime.call("get_pickup") as Node3D
	if pickup == null:
		await _fail("Scrapper pickup fixture is missing")
		return
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	if not bool(runtime.call("acquire_active_pickup")):
		await _fail("Could not acquire Scrapper for environment tracer")
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

	# In range and in front: force exactly one authored barrier open.
	player.global_position = barrier.global_position + Vector3(0.0, -0.7, 1.15)
	pivot.rotation.y = 0.0
	var pre_mesh_position := (barrier.get_node("BarrierMesh") as Node3D).position
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Valid access swing was not accepted")
		return
	runtime.call("process_tool_state", 0.15)
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
	runtime.call("process_tool_state", 0.50)

	# Already-open access is not damageable; later swings evaluate once and miss it.
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Post-open recovery did not permit another swing")
		return
	runtime.call("process_tool_state", 0.15)
	if int(runtime.call("get_contact_evaluation_count")) != 4 or String(runtime.call("get_last_contact_name")) == "SERVICE_ACCESS":
		await _fail("Already-open access accepted repeated damage/contact")
		return

	var incident := _scene.get_node_or_null("GearsWorkZoneIncident")
	if incident == null or not incident.has_method("trigger_service_access_disruption"):
		await _fail("Production 05 P04 service-access disruption seam is absent")
		return

	print("[GEARS_SCRAPPER_TOOL_ENVIRONMENT] PASS")
	await _finish(0)
