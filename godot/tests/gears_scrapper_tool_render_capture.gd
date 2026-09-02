extends SceneTree

const OUTPUT_DIR := "res://verification/production05"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

var _runtime: Node = null
var _scene: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[GEARS_SCRAPPER_TOOL_RENDER] %s" % message)
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

func _camera(scene: Node) -> Camera3D:
	return scene.get_node_or_null("ChinatownCamera3D") as Camera3D

func _frame_node(scene: Node, focus: Node3D) -> Camera3D:
	var camera := _camera(scene)
	var player := scene.get_node_or_null("Runner") as Node3D
	if camera == null or player == null or focus == null:
		return null
	camera.call("reset_camera_instant", player)
	camera.call("set_interaction_mode", true, focus)
	await process_frame
	await process_frame
	await process_frame
	return camera

func _frame_midpoint(scene: Node, a: Node3D, b: Node3D, name: String) -> Dictionary:
	if a == null or b == null:
		return {}
	var marker := Marker3D.new()
	marker.name = name
	scene.add_child(marker)
	marker.global_position = (a.global_position + b.global_position) * 0.5
	var camera := await _frame_node(scene, marker)
	if camera == null:
		marker.queue_free()
		return {}
	return {"camera": camera, "marker": marker}

func _screen_point(camera: Camera3D, world_pos: Vector3) -> Vector2:
	if camera == null or camera.is_position_behind(world_pos):
		return Vector2(-1.0, -1.0)
	return camera.unproject_position(world_pos)

func _in_view(camera: Camera3D, node: Node3D) -> bool:
	if camera == null or node == null or not camera.is_position_in_frustum(node.global_position):
		return false
	var p := _screen_point(camera, node.global_position)
	var size := root.get_visible_rect().size
	return p.x >= 0.0 and p.y >= 0.0 and p.x <= size.x and p.y <= size.y

func _capture(file_name: String, scene: Node, camera: Camera3D, outcome: String, tracked: Dictionary = {}) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var save_error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]

	var wanted_label := scene.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label
	var alarm := scene.get_node_or_null("CivicServiceAlarm")
	var access := scene.get_node_or_null("CivicReportAccess")
	var alarm_label := alarm.get_node_or_null("StatusLabel") as Label3D if alarm != null else null
	var access_label := access.get_node_or_null("StatusLabel") as Label3D if access != null else null
	var entry := {
		"file": file_name,
		"outcome": outcome,
		"heat": int(_runtime.call("get_heat_level")),
		"wanted_state": String(_runtime.call("get_wanted_state_name")),
		"wanted_visible": wanted_label.visible if wanted_label != null else false,
		"wanted_text": wanted_label.text if wanted_label != null else "",
		"alarm_text": alarm_label.text if alarm_label != null else "",
		"access_text": access_label.text if access_label != null else "",
		"tracked": {},
	}
	for key in tracked:
		var node = tracked[key]
		if node is Node3D:
			entry["tracked"][key] = {
				"world": (node as Node3D).global_position,
				"screen": _screen_point(camera, (node as Node3D).global_position),
				"in_view": _in_view(camera, node as Node3D),
			}
	_captures.append(entry)
	return ""

func _acquire_scrapper(scene: Node) -> String:
	var player := scene.get_node_or_null("Runner") as Node3D
	var scrapper := scene.get_node_or_null("GearsScrapperToolRuntime")
	if player == null or scrapper == null:
		return "Scrapper acquisition fixture is incomplete"
	var pickup := scrapper.call("get_pickup") as Node3D
	if pickup == null:
		return "Scrapper pickup is missing"
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	scene.set("_active_target", pickup)
	if not bool(scrapper.call("acquire_active_pickup")):
		return "Could not acquire Scrapper"
	return ""

func _force_service_access(scene: Node) -> String:
	var player := scene.get_node_or_null("Runner") as Node3D
	var scrapper := scene.get_node_or_null("GearsScrapperToolRuntime")
	if player == null or scrapper == null:
		return "Forced-access fixture is incomplete"
	var barrier := scrapper.call("get_access_barrier") as Node3D
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if barrier == null or pivot == null:
		return "Forced-access barrier/facing fixture is missing"
	player.global_position = barrier.global_position + Vector3(0.0, -0.7, 1.15)
	pivot.rotation.y = 0.0
	if not bool(scrapper.call("handle_tool_action_pressed")):
		return "Forced-access Tool swing was not accepted"
	scrapper.call("process_tool_state", 0.15)
	await process_frame
	await physics_frame
	if String(scrapper.call("get_access_state_name")) != "FORCED_OPEN" or String(scrapper.call("get_last_contact_name")) != "SERVICE_ACCESS":
		return "Forced-access Tool swing did not open the authored barrier"
	return ""

func _jam_report_link(scene: Node) -> String:
	var player := scene.get_node_or_null("Runner") as Node3D
	var access := scene.get_node_or_null("CivicReportAccess")
	var alarm := scene.get_node_or_null("CivicServiceAlarm")
	if player == null or access == null or alarm == null:
		return "Civic report-jam fixture is incomplete"
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	scene.set("_active_target", access)
	if not bool(_runtime.call("handle_action_pressed")) or bool(alarm.get("report_enabled")):
		return "Could not jam the retained civic report link"
	return ""

func _establish_heat_one(scene: Node) -> String:
	var player := scene.get_node_or_null("Runner") as Node3D
	var alarm := scene.get_node_or_null("CivicServiceAlarm")
	if player == null or alarm == null:
		return "Heat-1 fixture is incomplete"
	alarm.set("report_enabled", true)
	alarm.call("reset_alarm")
	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	scene.set("_active_target", alarm)
	if not bool(_runtime.call("handle_action_pressed")):
		return "Could not trigger retained civic Report"
	if int(_runtime.call("get_heat_level")) != 1 or String(_runtime.call("get_wanted_state_name")) != "CONTACT":
		return "Retained civic Report did not establish Heat 1 + Contact"
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

	# 1. Physical pickup is present and readable before possession.
	var pickup_scene := await _fresh_scene()
	if pickup_scene == null:
		_fail("Could not load pickup-ready production scene")
		return
	var pickup_runtime := pickup_scene.get_node_or_null("GearsScrapperToolRuntime")
	var pickup := pickup_runtime.call("get_pickup") as Node3D if pickup_runtime != null else null
	if pickup == null or bool(pickup_runtime.call("has_tool")):
		_fail("Pickup-ready state is invalid")
		return
	var pickup_camera := await _frame_node(pickup_scene, pickup)
	if pickup_camera == null or not _in_view(pickup_camera, pickup):
		_fail("Scrapper pickup is not readable in pickup-ready framing")
		return
	var capture_error := await _capture("01_scrapper_pickup_ready.png", pickup_scene, pickup_camera, "PHYSICAL_PICKUP_READY", {"pickup": pickup})
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 2. Contextual Action possession produces a visible held tool and Tool control.
	var acquire_error := _acquire_scrapper(pickup_scene)
	if not acquire_error.is_empty():
		_fail(acquire_error)
		return
	var player := pickup_scene.get_node_or_null("Runner") as Node3D
	var held := player.get_node_or_null("HeldScrapperTool") as Node3D if player != null else null
	var tool_button := pickup_scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/RightTouchArea/ToolActionButton") as Control
	if held == null or not held.visible or tool_button == null or not tool_button.visible:
		_fail("Held Scrapper/Tool Action presentation is not active")
		return
	var held_camera := await _frame_node(pickup_scene, player)
	if held_camera == null or not _in_view(held_camera, player):
		_fail("Held Scrapper player framing is unreadable")
		return
	capture_error = await _capture("02_scrapper_held.png", pickup_scene, held_camera, "SCRAPPER_HELD_TOOL_ACTION_AVAILABLE", {"player": player, "held_tool": held})
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 3. Live Report composition: forced barrier + local ALARMED reaction + Heat 1 Contact.
	var live_scene := await _fresh_scene()
	if live_scene == null:
		_fail("Could not load live-report production scene")
		return
	acquire_error = _acquire_scrapper(live_scene)
	if not acquire_error.is_empty():
		_fail(acquire_error)
		return
	var force_error := await _force_service_access(live_scene)
	if not force_error.is_empty():
		_fail(force_error)
		return
	var live_scrapper := live_scene.get_node_or_null("GearsScrapperToolRuntime")
	var live_barrier := live_scrapper.call("get_access_barrier") as Node3D
	var live_incident := live_scene.get_node_or_null("GearsWorkZoneIncident")
	var live_worker := live_incident.get_node_or_null("GearsWorker") as Node3D if live_incident != null else null
	var live_crawler := live_incident.get_node_or_null("GearsCrawler") as Node3D if live_incident != null else null
	var live_alarm := live_scene.get_node_or_null("CivicServiceAlarm")
	if live_incident == null or live_worker == null or live_crawler == null or live_alarm == null:
		_fail("Live-report render fixture is incomplete")
		return
	if String(live_incident.call("get_incident_state_name")) != "ALARMED" or int(_runtime.call("get_heat_level")) != 1 or String(_runtime.call("get_wanted_state_name")) != "CONTACT":
		_fail("Forced-access live Report state did not reach local ALARMED + Heat 1 Contact")
		return
	var live_alarm_label := live_alarm.get_node_or_null("StatusLabel") as Label3D
	if live_alarm_label == null or not live_alarm_label.text.contains("REPORT SENT"):
		_fail("Live forced-access Report feedback is not REPORT SENT")
		return
	var live_frame := await _frame_midpoint(live_scene, live_barrier, live_worker, "P05LiveProofFocus")
	if live_frame.is_empty():
		_fail("Could not frame live forced-access proof")
		return
	var live_camera := live_frame["camera"] as Camera3D
	if not _in_view(live_camera, live_barrier) or not _in_view(live_camera, live_worker):
		_fail("Forced barrier/local reaction are not jointly readable in live proof")
		return
	capture_error = await _capture("03_service_access_forced_report_sent.png", live_scene, live_camera, "FORCED_ACCESS_LOCAL_ALARM_REPORT_SENT_CONTACT", {"barrier": live_barrier, "worker": live_worker, "crawler": live_crawler, "alarm": live_alarm})
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 4. Jammed Report composition: same physical/local consequence, city remains CLEAR.
	var quiet_scene := await _fresh_scene()
	if quiet_scene == null:
		_fail("Could not load suppressed-report production scene")
		return
	var jam_error := _jam_report_link(quiet_scene)
	if not jam_error.is_empty():
		_fail(jam_error)
		return
	acquire_error = _acquire_scrapper(quiet_scene)
	if not acquire_error.is_empty():
		_fail(acquire_error)
		return
	force_error = await _force_service_access(quiet_scene)
	if not force_error.is_empty():
		_fail(force_error)
		return
	var quiet_scrapper := quiet_scene.get_node_or_null("GearsScrapperToolRuntime")
	var quiet_barrier := quiet_scrapper.call("get_access_barrier") as Node3D
	var quiet_incident := quiet_scene.get_node_or_null("GearsWorkZoneIncident")
	var quiet_worker := quiet_incident.get_node_or_null("GearsWorker") as Node3D if quiet_incident != null else null
	var quiet_crawler := quiet_incident.get_node_or_null("GearsCrawler") as Node3D if quiet_incident != null else null
	var quiet_alarm := quiet_scene.get_node_or_null("CivicServiceAlarm")
	if quiet_incident == null or quiet_worker == null or quiet_crawler == null or quiet_alarm == null:
		_fail("Suppressed-report render fixture is incomplete")
		return
	var quiet_alarm_label := quiet_alarm.get_node_or_null("StatusLabel") as Label3D
	if String(quiet_incident.call("get_incident_state_name")) != "ALARMED" or int(_runtime.call("get_heat_level")) != 0 or String(_runtime.call("get_wanted_state_name")) != "CLEAR":
		_fail("Forced-access suppressed Report did not preserve local ALARMED + CLEAR authority")
		return
	if quiet_alarm_label == null or not quiet_alarm_label.text.contains("ALARM FAULT"):
		_fail("Suppressed forced-access feedback is not ALARM FAULT")
		return
	var quiet_frame := await _frame_midpoint(quiet_scene, quiet_barrier, quiet_worker, "P05QuietProofFocus")
	if quiet_frame.is_empty():
		_fail("Could not frame suppressed forced-access proof")
		return
	var quiet_camera := quiet_frame["camera"] as Camera3D
	if not _in_view(quiet_camera, quiet_barrier) or not _in_view(quiet_camera, quiet_worker):
		_fail("Forced barrier/local reaction are not jointly readable in suppressed proof")
		return
	capture_error = await _capture("04_service_access_forced_report_suppressed.png", quiet_scene, quiet_camera, "FORCED_ACCESS_LOCAL_ALARM_REPORT_SUPPRESSED_CLEAR", {"barrier": quiet_barrier, "worker": quiet_worker, "crawler": quiet_crawler, "alarm": quiet_alarm})
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# 5-6. Heat-1 pursuer impact creates brief space, then expires and chase resumes.
	var chase_scene := await _fresh_scene()
	if chase_scene == null:
		_fail("Could not load pursuer proof production scene")
		return
	acquire_error = _acquire_scrapper(chase_scene)
	if not acquire_error.is_empty():
		_fail(acquire_error)
		return
	var heat_error := _establish_heat_one(chase_scene)
	if not heat_error.is_empty():
		_fail(heat_error)
		return
	var chase_player := chase_scene.get_node_or_null("Runner") as Node3D
	var pursuer := chase_scene.get_node_or_null("PursuerPrototype") as Node3D
	var chase_scrapper := chase_scene.get_node_or_null("GearsScrapperToolRuntime")
	var chase_pivot := chase_player.get_node_or_null("MeshPivot") as Node3D if chase_player != null else null
	if chase_player == null or pursuer == null or chase_scrapper == null or chase_pivot == null or not bool(pursuer.get("is_active")):
		_fail("Pursuer proof fixture is incomplete")
		return
	chase_player.global_position = Vector3(18.0, 0.1, -18.0)
	pursuer.global_position = chase_player.global_position + Vector3(0.0, 0.5, -1.1)
	chase_pivot.rotation.y = 0.0
	if not bool(chase_scrapper.call("handle_tool_action_pressed")):
		_fail("Pursuer proof Tool swing was not accepted")
		return
	chase_scrapper.call("process_tool_state", 0.15)
	if String(chase_scrapper.call("get_last_contact_name")) != "PURSUER" or not bool(pursuer.call("is_scrapper_staggered")):
		_fail("Pursuer proof did not establish the bounded stagger")
		return
	var impact_distance := chase_player.global_position.distance_to(pursuer.global_position)
	var chase_frame := await _frame_midpoint(chase_scene, chase_player, pursuer, "P05PursuerProofFocus")
	if chase_frame.is_empty():
		_fail("Could not frame pursuer impact proof")
		return
	var chase_camera := chase_frame["camera"] as Camera3D
	capture_error = await _capture("05_pursuer_scrapper_impact.png", chase_scene, chase_camera, "HEAT1_PURSUER_SCRAPPER_STAGGER", {"player": chase_player, "pursuer": pursuer})
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	pursuer.call("_physics_process", 0.31)
	var spaced_distance := chase_player.global_position.distance_to(pursuer.global_position)
	if bool(pursuer.call("is_scrapper_staggered")) or spaced_distance <= impact_distance:
		_fail("Pursuer proof did not create temporary physical space before expiry")
		return
	pursuer.call("_physics_process", 0.20)
	var recovered_distance := chase_player.global_position.distance_to(pursuer.global_position)
	if float(pursuer.get("current_speed")) <= 0.0 or recovered_distance >= spaced_distance or not bool(pursuer.get("is_active")):
		_fail("Pursuer did not visibly resume chase after Scrapper recovery")
		return
	capture_error = await _capture("06_pursuer_recovered.png", chase_scene, chase_camera, "HEAT1_PURSUER_RECOVERED_CHASE", {"player": chase_player, "pursuer": pursuer})
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
		"tool_reach_m": 1.8,
		"swing_total_sec": 0.60,
		"pursuer_stagger_sec": 0.30,
		"pursuer_impact_distance": impact_distance,
		"pursuer_spaced_distance": spaced_distance,
		"pursuer_recovered_distance": recovered_distance,
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write Production 05 render report")
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()

	print("[GEARS_SCRAPPER_TOOL_RENDER] PASS: %s" % OUTPUT_DIR)
	await _free_scene()
	quit(0)
