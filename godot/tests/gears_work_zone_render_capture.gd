extends SceneTree

const OUTPUT_DIR := "res://verification/production04"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

var _runtime: Node = null
var _scene: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[GEARS_WORK_ZONE_RENDER] %s" % message)
	quit(1)

func _free_scene() -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_scene = null
	if _runtime != null and _runtime.has_method("reset_runtime"):
		_runtime.call("reset_runtime")

func _fresh_scene() -> Node:
	await _free_scene()
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		return null
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	if not bool(_runtime.call("bind_to_scene", _scene)):
		return null
	await process_frame
	return _scene

func _place_viewer(scene: Node, incident: Node3D) -> Camera3D:
	var player := scene.get_node_or_null("Runner") as CharacterBody3D
	var camera := scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	if player == null or camera == null:
		return null
	player.global_position = incident.global_position + Vector3(0.0, 0.0, 4.2)
	player.velocity = Vector3.ZERO
	camera.call("reset_camera_instant", player)
	return camera

func _screen_point(camera: Camera3D, world_pos: Vector3) -> Vector2:
	if camera == null or camera.is_position_behind(world_pos):
		return Vector2(-1.0, -1.0)
	return camera.unproject_position(world_pos)

func _actors_are_readable(camera: Camera3D, worker: Node3D, crawler: Node3D) -> bool:
	if camera == null or worker == null or crawler == null:
		return false
	if not camera.is_position_in_frustum(worker.global_position) or not camera.is_position_in_frustum(crawler.global_position):
		return false
	var viewport_size := root.get_visible_rect().size
	var worker_screen := _screen_point(camera, worker.global_position)
	var crawler_screen := _screen_point(camera, crawler.global_position)
	for point in [worker_screen, crawler_screen]:
		if point.x < 0.0 or point.y < 0.0 or point.x > viewport_size.x or point.y > viewport_size.y:
			return false
	return worker_screen.distance_to(crawler_screen) >= 12.0

func _capture(file_name: String, scene: Node, incident: Node, camera: Camera3D, expected_outcome: String) -> String:
	await process_frame
	await process_frame
	var worker := incident.get_node_or_null("GearsWorker") as Node3D
	var crawler := incident.get_node_or_null("GearsCrawler") as Node3D
	if not _actors_are_readable(camera, worker, crawler):
		return "Work-zone actor pair is not simultaneously readable in %s" % file_name
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var save_error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]
	var wanted_label := scene.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label
	_captures.append({
		"file": file_name,
		"outcome": expected_outcome,
		"incident_state": String(incident.call("get_incident_state_name")),
		"worker_state": int(worker.get("current_state")),
		"crawler_state": int(crawler.get("current_state")),
		"heat": int(_runtime.call("get_heat_level")),
		"wanted_state": String(_runtime.call("get_wanted_state_name")),
		"wanted_visible": wanted_label.visible if wanted_label != null else false,
		"wanted_text": wanted_label.text if wanted_label != null else "",
		"worker_screen": _screen_point(camera, worker.global_position),
		"crawler_screen": _screen_point(camera, crawler.global_position),
		"actor_pair_in_frustum": true,
	})
	return ""

func _trigger_close_call(scene: Node, incident: Node) -> String:
	var worker := incident.get_node_or_null("GearsWorker") as CharacterBody3D
	var bike := scene.get("courier_bike") as CharacterBody3D
	if worker == null or bike == null:
		return "Work-zone close-call fixture is incomplete"
	bike.global_position = worker.global_position + Vector3(0.0, 0.0, 0.6)
	bike.velocity = Vector3(0.0, 0.0, -9.0)
	if "current_speed" in bike:
		bike.set("current_speed", 9.0)
	incident.call("process_player_sample", bike, true, 0.016)
	await process_frame
	return ""

func _jam_report_link(scene: Node) -> String:
	var player := scene.get_node_or_null("Runner") as Node3D
	var access := scene.get_node_or_null("CivicReportAccess")
	if player == null or access == null:
		return "Civic report access fixture is missing"
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	scene.set("_active_target", access)
	if not bool(_runtime.call("handle_action_pressed")):
		return "Could not jam civic report link"
	return ""

func _run() -> void:
	var output_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(output_abs)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create output directory: %s" % dir_error)
		return

	_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _runtime == null:
		_fail("BurnsideWantedRuntime autoload is missing")
		return

	# 1. Routine street life: both actors are genuinely present in the Gears view.
	var routine_scene := await _fresh_scene()
	if routine_scene == null:
		_fail("Could not load routine production scene")
		return
	var routine_incident := routine_scene.get_node_or_null("GearsWorkZoneIncident") as Node3D
	if routine_incident == null:
		_fail("Routine work-zone incident did not mount")
		return
	var routine_camera := _place_viewer(routine_scene, routine_incident)
	if routine_camera == null:
		_fail("Routine work-zone camera fixture is missing")
		return
	if String(routine_incident.call("get_incident_state_name")) != "ROUTINE":
		_fail("Routine capture did not start in ROUTINE")
		return
	var capture_error := await _capture("01_gears_work_zone_routine.png", routine_scene, routine_incident, routine_camera, "ROUTINE_LOCAL_LIFE")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 2. Live report: local alarm remains visible and ordinary city authority reaches Heat 1.
	var live_scene := await _fresh_scene()
	if live_scene == null:
		_fail("Could not load live-report production scene")
		return
	var live_incident := live_scene.get_node_or_null("GearsWorkZoneIncident") as Node3D
	var live_camera := _place_viewer(live_scene, live_incident)
	if live_incident == null or live_camera == null:
		_fail("Live work-zone render fixture is incomplete")
		return
	var trigger_error := await _trigger_close_call(live_scene, live_incident)
	if not trigger_error.is_empty():
		_fail(trigger_error)
		return
	if String(live_incident.call("get_incident_state_name")) != "ALARMED" \
	or int(_runtime.call("get_heat_level")) != 1 \
	or String(_runtime.call("get_wanted_state_name")) != "CONTACT":
		_fail("Live close-call render state did not reach local ALARMED + Heat 1 Contact")
		return
	capture_error = await _capture("02_gears_work_zone_report_sent.png", live_scene, live_incident, live_camera, "LOCAL_ALARM_REPORT_SENT_CONTACT")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 3. Jammed report: same local alarm is visible but authority remains quiet.
	var quiet_scene := await _fresh_scene()
	if quiet_scene == null:
		_fail("Could not load jammed-report production scene")
		return
	var quiet_incident := quiet_scene.get_node_or_null("GearsWorkZoneIncident") as Node3D
	if quiet_incident == null:
		_fail("Jammed work-zone incident did not mount")
		return
	var jam_error := _jam_report_link(quiet_scene)
	if not jam_error.is_empty():
		_fail(jam_error)
		return
	var quiet_camera := _place_viewer(quiet_scene, quiet_incident)
	if quiet_camera == null:
		_fail("Jammed work-zone camera fixture is missing")
		return
	trigger_error = await _trigger_close_call(quiet_scene, quiet_incident)
	if not trigger_error.is_empty():
		_fail(trigger_error)
		return
	if String(quiet_incident.call("get_incident_state_name")) != "ALARMED" \
	or int(_runtime.call("get_heat_level")) != 0 \
	or String(_runtime.call("get_wanted_state_name")) != "CLEAR":
		_fail("Jammed close-call render state did not preserve local ALARMED + CLEAR authority")
		return
	capture_error = await _capture("03_gears_work_zone_report_suppressed.png", quiet_scene, quiet_incident, quiet_camera, "LOCAL_ALARM_REPORT_SUPPRESSED_CLEAR")
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
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write Production 04 render report")
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()

	print("[GEARS_WORK_ZONE_RENDER] PASS: %s" % OUTPUT_DIR)
	await _free_scene()
	quit(0)
