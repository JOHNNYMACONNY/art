extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const ROUTE_ID := "gears.service_alley_north_connector"
const AUTO_TEST_PATH := "user://tests/p06_gears_surveyed_service_cut_test.json"

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _remove_test_progress() -> void:
	if FileAccess.file_exists(AUTO_TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTO_TEST_PATH))

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	_remove_test_progress()
	quit(code)

func _fail(message: String) -> void:
	push_error("[GEARS_SURVEYED_SERVICE_CUT] %s" % message)
	await _finish(1)

func _sample_path(survey: Node, positions: Array) -> void:
	for position in positions:
		if position is Vector3:
			survey.call("sample_player_position", position)

func _run() -> void:
	_remove_test_progress()
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return
	var packed := load(SCENE_PATH) as PackedScene
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
		await _fail("Wanted runtime did not bind to production scene")
		return

	var district := _scene.get_node_or_null("GearsDistrictSlice01B") as Node3D
	var player := _scene.get_node_or_null("Runner") as Node3D
	var scrapper := _scene.get_node_or_null("GearsScrapperToolRuntime")
	var survey := _scene.get_node_or_null("GearsSurveyedServiceCutRuntime")
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	if district == null or player == null or scrapper == null or touch_ui == null:
		await _fail("Retained P05 route/input fixture is incomplete")
		return
	if survey == null:
		await _fail("Production 06 GearsSurveyedServiceCutRuntime is absent")
		return
	if not survey.has_method("sample_player_position") or not survey.has_method("is_route_surveyed"):
		await _fail("Production 06 traversal seam is incomplete")
		return
	survey.set_physics_process(false)

	var store = survey.call("get_progress_store")
	if store == null or String(store.call("get_storage_path")) != AUTO_TEST_PATH:
		await _fail("Production scene did not use isolated deterministic P06 test storage")
		return
	if String(survey.call("get_route_id")) != ROUTE_ID or bool(survey.call("is_route_surveyed")):
		await _fail("Clean runtime did not begin with the stable route unknown")
		return

	var entry_socket := district.get_node_or_null("ServiceAlleyEntrySocket") as Node3D
	var connector := district.get_node_or_null("NorthConnector") as Node3D
	if entry_socket == null or connector == null:
		await _fail("Retained ServiceAlley/NorthConnector geometry is missing")
		return
	var entry := Vector3(entry_socket.global_position.x, player.global_position.y, entry_socket.global_position.z)
	var connector_end := Vector3(connector.global_position.x - 1.0, player.global_position.y, connector.global_position.z)

	# Observation/placement at the route cannot survey while physical access is jammed.
	survey.call("sample_player_position", entry)
	survey.call("sample_player_position", entry + Vector3(0.0, 0.0, -1.0))
	if bool(survey.call("is_route_surveyed")):
		await _fail("Observing/standing at the service cut surveyed it")
		return

	# P05 remains the only access owner. Forcing it open alone must not grant knowledge.
	if not bool(scrapper.call("_force_access_open")) or String(scrapper.call("get_access_state_name")) != "FORCED_OPEN":
		await _fail("Retained P05 service access could not be forced open")
		return
	await physics_frame
	if bool(survey.call("is_route_surveyed")):
		await _fail("Forcing JAMMED -> FORCED_OPEN alone surveyed the route")
		return

	# Direct relocation between endpoints is a rejected discontinuity, not discovery.
	survey.call("reset_transient_state")
	survey.call("sample_player_position", entry)
	survey.call("sample_player_position", connector_end)
	if bool(survey.call("is_route_surveyed")):
		await _fail("Discontinuous teleport/test placement surveyed the route")
		return

	# Continuous legitimate travel through the authored alley qualifies exactly once.
	survey.call("reset_transient_state")
	var continuous := [
		entry,
		Vector3(-10.0, player.global_position.y, -28.5),
		Vector3(-10.0, player.global_position.y, -31.0),
		Vector3(-10.0, player.global_position.y, -33.5),
		Vector3(-10.0, player.global_position.y, -36.0),
		Vector3(-10.0, player.global_position.y, -38.5),
		Vector3(-10.0, player.global_position.y, -41.0),
		Vector3(-10.0, player.global_position.y, -43.3),
		Vector3(-9.2, player.global_position.y, -44.5),
		connector_end,
	]
	_sample_path(survey, continuous)
	if not bool(survey.call("is_route_surveyed")):
		await _fail("Legitimate continuous traversal did not survey the route")
		return
	if int(survey.call("get_survey_record_count")) != 1 or int(store.call("get_write_count")) != 1:
		await _fail("First legitimate traversal was not recorded exactly once")
		return
	if not survey.has_method("is_discovery_feedback_visible") or not survey.has_method("get_discovery_feedback_text"):
		await _fail("First survey has no bounded player-facing discovery feedback seam")
		return
	if not bool(survey.call("is_discovery_feedback_visible")) or not String(survey.call("get_discovery_feedback_text")).contains("SERVICE CUT SURVEYED"):
		await _fail("First legitimate traversal did not present readable learned-route confirmation")
		return

	# Repeated traversal cannot duplicate progression.
	var reverse := continuous.duplicate()
	reverse.reverse()
	_sample_path(survey, reverse)
	_sample_path(survey, continuous)
	if int(survey.call("get_survey_record_count")) != 1 or int(store.call("get_write_count")) != 1:
		await _fail("Repeated crossings duplicated mapped progress")
		return

	# Full Replay restores P05 physical JAMMED access but preserves P06 Durable Mapped Knowledge.
	touch_ui.replay_pressed.emit()
	await process_frame
	await physics_frame
	await physics_frame
	if not bool(survey.call("is_route_surveyed")):
		await _fail("Replay erased surveyed mapped knowledge")
		return
	if String(scrapper.call("get_access_state_name")) != "JAMMED" or not bool(scrapper.call("is_service_access_blocking")):
		await _fail("Replay did not restore retained P05 physical JAMMED access")
		return
	if String(survey.call("get_transient_state_name")) != "IDLE":
		await _fail("Replay left stale P06 traversal qualification state")
		return

	# Knowledge is independent from physical access: reopening changes access only.
	var writes_before_reopen := int(store.call("get_write_count"))
	if not bool(scrapper.call("_force_access_open")):
		await _fail("Known route could not reuse retained P05 force-open behavior")
		return
	if not bool(survey.call("is_route_surveyed")) or int(store.call("get_write_count")) != writes_before_reopen:
		await _fail("Reopening known access rewrote or lost mapped knowledge")
		return

	print("[GEARS_SURVEYED_SERVICE_CUT] PASS")
	await _finish(0)
