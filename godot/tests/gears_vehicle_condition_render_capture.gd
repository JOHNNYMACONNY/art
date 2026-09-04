extends SceneTree

const OUTPUT_DIR := "res://verification/production07"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const TEST_STORAGE := "user://tests/p06_gears_vehicle_condition_render_capture.json"

var _scene: Node3D = null
var _wanted_runtime: Node = null
var _district: Node3D = null
var _player: Node3D = null
var _camera: Camera3D = null
var _bike: Node3D = null
var _hauler: Node3D = null
var _garage: Node = null
var _scrapper: Node = null
var _survey: Node = null
var _touch_ui: Node = null
var _socket: Marker3D = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _remove_test_progress() -> void:
	if FileAccess.file_exists(TEST_STORAGE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STORAGE))

func _fail(message: String) -> void:
	push_error("[P07_VEHICLE_CONDITION_RENDER] %s" % message)
	_remove_test_progress()
	quit(1)

func _damage(vehicle: Node, impacts: int) -> bool:
	if vehicle == null or not vehicle.has_method("apply_collision_condition"):
		return false
	vehicle.call("reset_condition")
	for _impact in range(impacts):
		vehicle.set("_condition_contact_cooldown", 0.0)
		if not bool(vehicle.call("apply_collision_condition", 1.0, 10.0)):
			return false
	return true

func _stage_vehicle(vehicle: Node3D, position: Vector3) -> void:
	vehicle.global_position = position
	vehicle.set("velocity", Vector3.ZERO)
	vehicle.set("current_speed", 0.0)
	_scene.set("active_vehicle", vehicle)
	_camera.set_process(true)
	_camera.call("reset_camera_instant", vehicle)
	_camera.set_process(false)
	await process_frame
	await process_frame

func _sample_legitimate_route() -> bool:
	var entry_socket := _district.get_node_or_null("ServiceAlleyEntrySocket") as Node3D
	var connector := _district.get_node_or_null("NorthConnector") as Node3D
	if entry_socket == null or connector == null:
		return false
	if not bool(_scrapper.call("_force_access_open")):
		return false
	_survey.call("reset_transient_state")
	var y := _player.global_position.y
	var entry := Vector3(entry_socket.global_position.x, y, entry_socket.global_position.z)
	var connector_end := Vector3(connector.global_position.x - 1.0, y, connector.global_position.z)
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
	return bool(_survey.call("is_route_surveyed"))

func _open_map() -> bool:
	_touch_ui.call("trigger_map_action")
	await process_frame
	return bool(_survey.call("is_map_open"))

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
	await process_frame
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		_fail("Wanted runtime did not bind to real playable scene")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")

	_district = _scene.get_node_or_null("GearsDistrictSlice01B") as Node3D
	_player = _scene.get_node_or_null("Runner") as Node3D
	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_bike = _scene.get("courier_bike") as Node3D
	_hauler = _scene.get("scrap_hauler") as Node3D
	_garage = _scene.get_node_or_null("BurnGarageRepairRuntime")
	_scrapper = _scene.get_node_or_null("GearsScrapperToolRuntime")
	_survey = _scene.get_node_or_null("GearsSurveyedServiceCutRuntime")
	_touch_ui = _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	_socket = _district.get_node_or_null("MissionDestinationSocket") as Marker3D if _district != null else null
	if _district == null or _player == null or _camera == null or _bike == null or _hauler == null or _garage == null or _scrapper == null or _survey == null or _touch_ui == null or _socket == null:
		_fail("Rendered proof is missing a production dependency")
		return

	_bike.set_physics_process(false)
	_hauler.set_physics_process(false)
	_survey.set_physics_process(false)
	var store = _survey.call("get_progress_store")
	if store == null or String(store.call("get_storage_path")) != TEST_STORAGE:
		_fail("Rendered proof did not use isolated mapped-knowledge storage")
		return

	_bike.call("reset_condition")
	await _stage_vehicle(_bike, Vector3(-2.0, 0.05, -22.0))
	if String(_bike.call("get_condition_name")) != "ROADWORTHY":
		_fail("Bike did not begin ROADWORTHY")
		return
	var capture_error := await _capture("01_roadworthy_bike.png", "ROADWORTHY_BIKE")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# Visual condition stages use the production semantic API. Real move_and_slide
	# collision -> condition is independently proven by the focused runtime tracer.
	if not _damage(_bike, 1) or String(_bike.call("get_condition_name")) != "BATTERED":
		_fail("Could not stage BATTERED Bike through production condition API")
		return
	capture_error = await _capture("02_battered_after_impact.png", "BATTERED_AFTER_IMPACT")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	if not _damage(_bike, 2) or String(_bike.call("get_condition_name")) != "CRITICAL":
		_fail("Could not stage CRITICAL Bike through production condition API")
		return
	capture_error = await _capture("03_critical_limp_bike.png", "CRITICAL_LIMP_BIKE")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	if not await _sample_legitimate_route():
		_fail("Could not establish retained P06 surveyed service cut")
		return
	var service_entry := _district.get_node_or_null("ServiceAlleyEntrySocket") as Node3D
	if service_entry == null:
		_fail("Service Alley entry socket is missing")
		return
	await _stage_vehicle(_bike, service_entry.global_position + Vector3(0.0, 0.0, 1.2))
	capture_error = await _capture("04_critical_bike_known_service_cut.png", "CRITICAL_KNOWN_SERVICE_CUT")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	if not _damage(_hauler, 1) or String(_hauler.call("get_condition_name")) != "BATTERED":
		_fail("Could not stage independent BATTERED Hauler")
		return
	await _stage_vehicle(_hauler, Vector3(4.0, 0.05, -31.0))
	capture_error = await _capture("05_battered_scrap_hauler.png", "BATTERED_HAULER")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	if not _damage(_bike, 2):
		_fail("Could not restore CRITICAL Bike fixture")
		return
	await _stage_vehicle(_bike, _socket.global_position)
	var authority = _wanted_runtime.get("wanted_authority")
	if authority == null or not bool(authority.call("submit_report", "p07_render", _bike.global_position, Vector3.FORWARD, "p07_render_observer")):
		_fail("Could not establish authoritative CONTACT fixture")
		return
	_garage.call("_process", 0.0)
	if String(_wanted_runtime.call("get_wanted_state_name")) != "CONTACT" or String(_garage.call("get_affordance_text")) != "WANTED // SERVICE LOCKED":
		_fail("Garage did not visibly reject repair during CONTACT")
		return
	capture_error = await _capture("06_garage_wanted_rejected.png", "GARAGE_WANTED_REJECTED")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	authority.call("reset")
	_garage.call("_process", 0.0)
	_scene.call("_evaluate_target_selection")
	if String(_wanted_runtime.call("get_wanted_state_name")) != "CLEAR" or String(_garage.call("get_affordance_text")) != "REPAIR // ACTION":
		_fail("Eligible Garage repair affordance is not readable")
		return
	if _scene.get("_active_target") != _garage.call("get_repair_interactable"):
		_fail("Retained interaction selector did not own the Garage repair Action")
		return
	capture_error = await _capture("07_garage_clear_repair_action.png", "GARAGE_CLEAR_REPAIR_ACTION")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	_touch_ui.action_button_pressed.emit()
	await process_frame
	if String(_bike.call("get_condition_name")) != "ROADWORTHY":
		_fail("Retained Action routing did not repair the Bike")
		return
	await _stage_vehicle(_bike, _socket.global_position + Vector3(0.0, 0.0, 4.0))
	capture_error = await _capture("08_repaired_roadworthy_leaving.png", "REPAIRED_ROADWORTHY_LEAVING")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	if not _damage(_bike, 2) or not _damage(_hauler, 1):
		_fail("Could not establish damaged pre-Replay fixtures")
		return
	_touch_ui.replay_pressed.emit()
	await process_frame
	await physics_frame
	await physics_frame
	if String(_bike.call("get_condition_name")) != "ROADWORTHY" or String(_hauler.call("get_condition_name")) != "ROADWORTHY":
		_fail("Replay did not restore both production vehicles to ROADWORTHY")
		return
	if not bool(_survey.call("is_route_surveyed")):
		_fail("Replay erased retained P06 mapped knowledge")
		return
	if not await _open_map():
		_fail("Could not open retained P06 route sheet after Replay")
		return
	var route_sheet: Control = _survey.call("get_route_sheet") as Control
	if route_sheet == null or not bool(route_sheet.call("is_service_cut_visible")):
		_fail("Retained mapped service cut is not visible after Replay")
		return
	capture_error = await _capture("09_replay_roadworthy_route_known.png", "REPLAY_CONDITION_RESET_ROUTE_KNOWN")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	var report := {
		"schema_version": 1,
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"real_playable_scene": true,
		"condition_visuals_staged_via_production_api": true,
		"real_collision_path_proven_by": "res://tests/vehicle_condition_runtime_collision_test.gd",
		"mapped_knowledge_storage": String(store.call("get_storage_path")),
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write Production 07 rendered verification report")
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()

	print("[P07_VEHICLE_CONDITION_RENDER] PASS: %s" % OUTPUT_DIR)
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
		"bike_condition": String(_bike.call("get_condition_name")),
		"hauler_condition": String(_hauler.call("get_condition_name")),
		"wanted_heat": int(_wanted_runtime.call("get_heat_level")),
		"wanted_state": String(_wanted_runtime.call("get_wanted_state_name")),
		"garage_affordance": String(_garage.call("get_affordance_text")),
		"route_surveyed": bool(_survey.call("is_route_surveyed")),
		"map_open": bool(_survey.call("is_map_open")),
		"bike_position": [_bike.global_position.x, _bike.global_position.y, _bike.global_position.z],
		"hauler_position": [_hauler.global_position.x, _hauler.global_position.y, _hauler.global_position.z],
	})
	return ""