extends SceneTree

const OUTPUT_DIR := "res://verification/production06"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const ROUTE_ID := "gears.service_alley_north_connector"
const TEST_STORAGE := "user://tests/p06_gears_surveyed_service_cut_render_capture.json"

var _scene: Node3D = null
var _wanted_runtime: Node = null
var _district: Node3D = null
var _player: Node3D = null
var _camera: Camera3D = null
var _scrapper: Node = null
var _survey: Node = null
var _touch_ui: Node = null
var _route_sheet: Control = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _remove_test_progress() -> void:
	if FileAccess.file_exists(TEST_STORAGE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORAGE))

func _fail(message: String) -> void:
	push_error("[GEARS_SURVEYED_SERVICE_CUT_RENDER] %s" % message)
	_remove_test_progress()
	quit(1)

func _open_map() -> bool:
	_touch_ui.call("trigger_map_action")
	await process_frame
	return bool(_survey.call("is_map_open"))

func _close_map() -> void:
	if bool(_survey.call("is_map_open")):
		_touch_ui.call("trigger_map_action")
		await process_frame

func _sample_legitimate_route(entry: Vector3, connector_end: Vector3) -> void:
	var y := _player.global_position.y
	var continuous := [
		entry,
		Vector3(-10.0, y, -28.5),
		Vector3(-10.0, y, -31.0),
		Vector3(-10.0, y, -33.5),
		Vector3(-10.0, y, -36.0),
		Vector3(-10.0, y, -38.5),
		Vector3(-10.0, y, -41.0),
		Vector3(-10.0, y, -43.3),
		Vector3(-9.2, y, -44.5),
		connector_end,
	]
	for position in continuous:
		_survey.call("sample_player_position", position)

func _run() -> void:
	_remove_test_progress()
	var output_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(output_abs)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create output directory: %s" % dir_error)
		return

	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		_fail("BurnsideWantedRuntime autoload is missing")
		return

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load real playable scene")
		return
	_scene = packed.instantiate() as Node3D
	if _scene == null:
		_fail("Could not instantiate real playable scene")
		return
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		_fail("Wanted runtime did not bind to real playable scene")
		return
	await process_frame

	_district = _scene.get_node_or_null("GearsDistrictSlice01B") as Node3D
	_player = _scene.get_node_or_null("Runner") as Node3D
	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_scrapper = _scene.get_node_or_null("GearsScrapperToolRuntime")
	_survey = _scene.get_node_or_null("GearsSurveyedServiceCutRuntime")
	_touch_ui = _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	if _district == null or _player == null or _camera == null or _scrapper == null or _survey == null or _touch_ui == null:
		_fail("Rendered proof is missing a production dependency")
		return
	_route_sheet = _survey.call("get_route_sheet") as Control
	if _route_sheet == null:
		_fail("Rendered proof could not resolve the P06 route sheet")
		return
	_survey.set_physics_process(false)

	var store = _survey.call("get_progress_store")
	if store == null or String(store.call("get_storage_path")) != TEST_STORAGE:
		_fail("Rendered proof did not use isolated deterministic storage")
		return
	if bool(_survey.call("is_route_surveyed")):
		_fail("Rendered proof did not begin clean")
		return

	var entry_socket := _district.get_node_or_null("ServiceAlleyEntrySocket") as Node3D
	var connector := _district.get_node_or_null("NorthConnector") as Node3D
	if entry_socket == null or connector == null:
		_fail("Retained ServiceAlley/NorthConnector geometry is missing")
		return
	var entry := Vector3(entry_socket.global_position.x, _player.global_position.y, entry_socket.global_position.z)
	var connector_end := Vector3(connector.global_position.x - 1.0, _player.global_position.y, connector.global_position.z)

	# 1. Before learning, the ordinary Gears street context can be mapped but the cut is absent.
	if not await _open_map():
		_fail("Could not open pre-survey route sheet")
		return
	if bool(_route_sheet.call("is_service_cut_visible")) or String(_route_sheet.call("get_access_status_text")) != "UNKNOWN ROUTE":
		_fail("Pre-survey route sheet exposed unearned geography")
		return
	var capture_error := await _capture("01_pre_survey_route_sheet.png", "PRE_SURVEY_UNKNOWN")
	if not capture_error.is_empty():
		_fail(capture_error)
		return
	await _close_map()

	# 2. P05 can physically open the cut without granting P06 knowledge.
	if not bool(_scrapper.call("_force_access_open")) or String(_scrapper.call("get_access_state_name")) != "FORCED_OPEN":
		_fail("Could not force retained P05 service access open")
		return
	if bool(_survey.call("is_route_surveyed")):
		_fail("Force-open alone incorrectly granted mapped knowledge")
		return
	_player.global_position = entry + Vector3(0.0, 0.0, 1.5)
	_camera.call("reset_camera_instant", _player)
	capture_error = await _capture("02_open_unsurveyed_service_cut.png", "OPEN_UNSURVEYED")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 3. Only a legitimate continuous crossing establishes the durable route fact.
	_survey.call("reset_transient_state")
	_sample_legitimate_route(entry, connector_end)
	_player.global_position = connector_end
	_camera.call("reset_camera_instant", _player)
	if not bool(_survey.call("is_route_surveyed")) or int(_survey.call("get_survey_record_count")) != 1:
		_fail("Legitimate crossing did not establish exactly one surveyed route")
		return
	if not bool(_survey.call("is_discovery_feedback_visible")) or not String(_survey.call("get_discovery_feedback_text")).contains("SERVICE CUT SURVEYED"):
		_fail("First discovery confirmation is not visible in the rendered state")
		return
	capture_error = await _capture("03_first_crossing_learned.png", "FIRST_CROSSING_LEARNED")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 4. The newly learned route appears accurately while current access is still open.
	if not await _open_map():
		_fail("Could not open post-survey route sheet")
		return
	if not bool(_route_sheet.call("is_service_cut_visible")) or String(_route_sheet.call("get_access_status_text")) != "KNOWN · ACCESS OPEN":
		_fail("Post-survey route sheet did not show learned/open service cut")
		return
	capture_error = await _capture("04_post_survey_route_sheet.png", "KNOWN_OPEN")
	if not capture_error.is_empty():
		_fail(capture_error)
		return
	await _close_map()

	# 5. Replay resets physical P05 access to JAMMED but must not erase mapped knowledge.
	_touch_ui.replay_pressed.emit()
	await process_frame
	await physics_frame
	await physics_frame
	if not bool(_survey.call("is_route_surveyed")) or String(_scrapper.call("get_access_state_name")) != "JAMMED":
		_fail("Replay did not preserve known geography while restoring JAMMED access")
		return
	if not await _open_map():
		_fail("Could not open learned + jammed route sheet after Replay")
		return
	if not bool(_route_sheet.call("is_service_cut_visible")) or String(_route_sheet.call("get_access_status_text")) != "KNOWN · ACCESS JAMMED":
		_fail("Replay route sheet is not truthful about known-but-blocked state")
		return
	capture_error = await _capture("05_replay_known_jammed.png", "KNOWN_JAMMED")
	if not capture_error.is_empty():
		_fail(capture_error)
		return
	await _close_map()

	# 6. Reopening the known route changes physical truth only; knowledge remains one durable fact.
	var writes_before_reopen := int(store.call("get_write_count"))
	if not bool(_scrapper.call("_force_access_open")):
		_fail("Could not reopen learned service cut")
		return
	_survey.call("refresh_map_presentation")
	if int(store.call("get_write_count")) != writes_before_reopen:
		_fail("Reopening learned access rewrote mapped knowledge")
		return
	if not await _open_map():
		_fail("Could not open reopened known route sheet")
		return
	if String(_route_sheet.call("get_access_status_text")) != "KNOWN · ACCESS OPEN":
		_fail("Reopened learned route did not report current usable access")
		return
	capture_error = await _capture("06_reopened_known_route.png", "KNOWN_REOPENED")
	if not capture_error.is_empty():
		_fail(capture_error)
		return
	await _close_map()

	var report := {
		"schema_version": 1,
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"real_playable_scene": true,
		"route_id": ROUTE_ID,
		"storage_path": String(store.call("get_storage_path")),
		"survey_record_count": int(_survey.call("get_survey_record_count")),
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write Production 06 rendered verification report")
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()

	print("[GEARS_SURVEYED_SERVICE_CUT_RENDER] PASS: %s" % OUTPUT_DIR)
	_scene.queue_free()
	await process_frame
	_remove_test_progress()
	quit(0)

func _capture(file_name: String, expected_state: String) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var path := OUTPUT_DIR + "/" + file_name
	var save_error: Error = image.save_png(path)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]
	_captures.append({
		"file": file_name,
		"state": expected_state,
		"surveyed": bool(_survey.call("is_route_surveyed")),
		"p05_access": String(_scrapper.call("get_access_state_name")),
		"map_open": bool(_survey.call("is_map_open")),
		"route_visible": bool(_route_sheet.call("is_service_cut_visible")),
		"route_status": String(_route_sheet.call("get_access_status_text")),
		"discovery_feedback_visible": bool(_survey.call("is_discovery_feedback_visible")),
		"discovery_feedback_text": String(_survey.call("get_discovery_feedback_text")),
		"player_position": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
	})
	return ""
