extends SceneTree

const OUTPUT_DIR := "res://verification/production17"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const PROOF_FOV := 40.0

var _scene: Node = null
var _wanted: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P17_SIDEARM_RENDER] %s" % message)
	quit(1)

func _free_scene() -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_scene = null
	if _wanted != null and _wanted.has_method("reset_runtime"):
		_wanted.call("reset_runtime")

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
	await process_frame
	if _wanted != null and _wanted.has_method("bind_to_scene"):
		if not bool(_wanted.call("bind_to_scene", _scene)):
			return null
	return _scene

func _fixture(scene: Node) -> Dictionary:
	var runtime := scene.get_node_or_null("GearsSidearmRuntime")
	var player := scene.get_node_or_null("Runner") as CharacterBody3D
	var incident := scene.get_node_or_null("GearsWorkZoneIncident")
	var crawler := incident.get_node_or_null("GearsCrawler") as CharacterBody3D if incident != null else null
	var worker := incident.get_node_or_null("GearsWorker") as CharacterBody3D if incident != null else null
	var pickup := runtime.call("get_pickup") as Node3D if runtime != null else null
	var held := player.get_node_or_null("MeshPivot/HeldRetrofitSidearm") as Node3D if player != null else null
	var fire_button := scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/RightTouchArea/FireButton") as Button
	return {
		"runtime": runtime,
		"player": player,
		"incident": incident,
		"crawler": crawler,
		"worker": worker,
		"pickup": pickup,
		"held": held,
		"fire_button": fire_button,
	}

func _complete(f: Dictionary) -> bool:
	for key in ["runtime", "player", "incident", "crawler", "worker", "pickup", "held", "fire_button"]:
		if f.get(key) == null:
			return false
	return true

func _acquire(scene: Node, f: Dictionary) -> bool:
	var player: CharacterBody3D = f["player"]
	var pickup: Node3D = f["pickup"]
	# Render proof should exercise the authored Service Alley pickup placement
	# rather than teleporting the contraband to the spawn point. Move the proof
	# player to the street-facing side of the real pickup so the production camera
	# can show the acquired sidearm without relying on PR #44 occlusion work.
	player.global_position = Vector3(pickup.global_position.x + 0.75, player.global_position.y, pickup.global_position.z + 0.15)
	player.velocity = Vector3.ZERO
	pickup.call("update_player_distance", player.global_position)
	scene.set("_active_target", pickup)
	return bool(f["runtime"].call("handle_action_pressed"))

func _face_crawler(f: Dictionary) -> void:
	var player: CharacterBody3D = f["player"]
	var crawler: CharacterBody3D = f["crawler"]
	player.global_position = crawler.global_position + Vector3(0.0, 0.0, 4.0)
	player.velocity = Vector3.ZERO
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if pivot != null:
		pivot.rotation.y = 0.0

func _jam_report(scene: Node, player: CharacterBody3D) -> bool:
	var access := scene.get_node_or_null("CivicReportAccess")
	if access == null:
		return false
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	scene.set("_active_target", access)
	return bool(_wanted.call("handle_action_pressed"))

func _camera(scene: Node) -> Camera3D:
	return scene.get_node_or_null("ChinatownCamera3D") as Camera3D

func _frame_node(scene: Node, focus: Node3D) -> Camera3D:
	var camera := _camera(scene)
	if camera == null or focus == null:
		return null
	camera.set_process(true)
	camera.call("reset_camera_instant", focus)
	camera.call("set_interaction_mode", true, focus)
	camera.fov = PROOF_FOV
	await process_frame
	await process_frame
	await process_frame
	return camera

func _frame_pair(scene: Node, a: Node3D, b: Node3D, marker_name: String) -> Dictionary:
	if a == null or b == null:
		return {}
	var marker := Marker3D.new()
	marker.name = marker_name
	scene.add_child(marker)
	marker.global_position = (a.global_position + b.global_position) * 0.5
	var camera := _camera(scene)
	if camera == null:
		marker.queue_free()
		return {}
	camera.set_process(true)
	camera.call("reset_camera_instant", marker)
	camera.fov = PROOF_FOV
	camera.set_process(false)
	await process_frame
	await process_frame
	await process_frame
	return {"camera": camera, "marker": marker}

func _screen(camera: Camera3D, node: Node3D) -> Vector2:
	if camera == null or node == null or camera.is_position_behind(node.global_position):
		return Vector2(-1.0, -1.0)
	return camera.unproject_position(node.global_position)

func _in_view(camera: Camera3D, node: Node3D) -> bool:
	if camera == null or node == null or not camera.is_position_in_frustum(node.global_position):
		return false
	var p := _screen(camera, node)
	var size := root.get_visible_rect().size
	return p.x >= 0.0 and p.y >= 0.0 and p.x <= size.x and p.y <= size.y

func _capture(file_name: String, scene: Node, camera: Camera3D, outcome: String, tracked: Dictionary) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var save_error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]

	var runtime := scene.get_node_or_null("GearsSidearmRuntime")
	var incident := scene.get_node_or_null("GearsWorkZoneIncident")
	var crawler := incident.get_node_or_null("GearsCrawler") if incident != null else null
	var fire_button := scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/RightTouchArea/FireButton") as Button
	var wanted_label := scene.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label
	var alarm := scene.get_node_or_null("CivicServiceAlarm")
	var entry := {
		"file": file_name,
		"outcome": outcome,
		"heat": int(_wanted.call("get_heat_level")),
		"wanted_state": String(_wanted.call("get_wanted_state_name")),
		"wanted_visible": wanted_label.visible if wanted_label != null else false,
		"wanted_text": wanted_label.text if wanted_label != null else "",
		"has_sidearm": bool(runtime.call("has_sidearm")) if runtime != null else false,
		"shot_count": int(runtime.call("get_shot_count")) if runtime != null else -1,
		"ballistic_queries": int(runtime.call("get_ballistic_query_count")) if runtime != null else -1,
		"last_impact": String(runtime.call("get_last_impact_name")) if runtime != null else "",
		"incident_state": String(incident.call("get_incident_state_name")) if incident != null else "",
		"report_attempts": int(incident.call("get_report_attempt_count")) if incident != null else -1,
		"crawler_durability": int(crawler.get("current_durability")) if crawler != null else -1,
		"crawler_state": int(crawler.get("current_state")) if crawler != null else -1,
		"fire_visible": fire_button.visible if fire_button != null else false,
		"fire_disabled": fire_button.disabled if fire_button != null else true,
		"alarm_triggered": bool(alarm.get("is_triggered")) if alarm != null else false,
		"report_enabled": bool(alarm.get("report_enabled")) if alarm != null else false,
		"tracked": {},
	}
	for key in tracked:
		var node = tracked[key]
		if node is Node3D:
			entry["tracked"][key] = {
				"world": (node as Node3D).global_position,
				"screen": _screen(camera, node as Node3D),
				"in_view": _in_view(camera, node as Node3D),
				"visible": (node as Node3D).visible,
			}
	_captures.append(entry)
	return ""

func _run() -> void:
	var output_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(output_abs)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create output directory: %s" % dir_error)
		return

	_wanted = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted == null:
		_fail("BurnsideWantedRuntime autoload is missing")
		return

	# 1. Physical contraband pickup.
	var scene := await _fresh_scene()
	if scene == null:
		_fail("Could not load pickup proof scene")
		return
	var f := _fixture(scene)
	if not _complete(f):
		_fail("Pickup proof fixture is incomplete")
		return
	var pickup: Node3D = f["pickup"]
	var pickup_camera := await _frame_node(scene, pickup)
	if pickup_camera == null or not _in_view(pickup_camera, pickup):
		_fail("Sidearm pickup is not readable in framed production geometry")
		return
	var err := await _capture("01_sidearm_pickup_ready.png", scene, pickup_camera, "PHYSICAL_PICKUP_READY", {"pickup": pickup})
	if not err.is_empty():
		_fail(err)
		return

	# 2. Acquired sidearm is visibly held and FIRE is truthful.
	if not _acquire(scene, f):
		_fail("Could not acquire sidearm for held proof")
		return
	var player: CharacterBody3D = f["player"]
	var held: Node3D = f["held"]
	var fire_button: Button = f["fire_button"]
	# Move the proof subject into the authored open intersection so the retained
	# camera can show the held silhouette without foreground-wall occlusion.
	player.global_position = f["incident"].global_position + Vector3(0.0, 0.0, 5.0)
	var held_pivot := player.get_node_or_null("MeshPivot") as Node3D
	if held_pivot != null:
		held_pivot.rotation.y = 0.0
	if held == null or not held.visible or fire_button == null or not fire_button.visible or fire_button.disabled:
		_fail("Held-sidearm or FIRE presentation is not truthful after acquisition")
		return
	var held_camera := await _frame_node(scene, player)
	if held_camera != null:
		held_camera.fov = 30.0
		await process_frame
		await process_frame
	if held_camera == null or not _in_view(held_camera, player):
		_fail("Held-sidearm player framing is invalid")
		return
	err = await _capture("02_sidearm_held_fire_ready.png", scene, held_camera, "HELD_SIDEARM_FIRE_READY", {"player": player, "held_sidearm": held})
	if not err.is_empty():
		_fail(err)
		return

	# 3. First shot: trace/impact + crawler durability + local alarm + Heat Contact.
	_face_crawler(f)
	var pair := await _frame_pair(scene, player, f["crawler"], "P17LivePairFocus")
	if pair.is_empty():
		_fail("Could not frame first-hit player/crawler pair")
		return
	var live_camera: Camera3D = pair["camera"]
	if not bool(f["runtime"].call("handle_weapon_action_pressed")):
		_fail("First render-proof shot was rejected")
		return
	if int(f["crawler"].get("current_durability")) != 1 	or String(f["incident"].call("get_incident_state_name")) != "ALARMED" 	or int(_wanted.call("get_heat_level")) != 1:
		_fail("First render-proof shot did not reach damage + alarm + retained Heat 1")
		return
	err = await _capture("03_sidearm_first_hit_report_contact.png", scene, live_camera, "FIRST_HIT_LOCAL_ALARM_REPORT_CONTACT", {"player": player, "crawler": f["crawler"], "worker": f["worker"], "held_sidearm": held})
	if not err.is_empty():
		_fail(err)
		return

	# 4. Second shot uses the crawler's own DISABLED lifecycle.
	f["runtime"].call("process_weapon_state", 0.40)
	if not bool(f["runtime"].call("handle_weapon_action_pressed")):
		_fail("Second render-proof shot was rejected")
		return
	if int(f["crawler"].get("current_durability")) != 0 	or int(f["crawler"].get("current_state")) != int(UtilityCrawler.CrawlerState.DISABLED):
		_fail("Second render-proof shot did not disable retained crawler")
		return
	err = await _capture("04_sidearm_second_hit_crawler_disabled.png", scene, live_camera, "SECOND_HIT_CRAWLER_DISABLED", {"player": player, "crawler": f["crawler"], "held_sidearm": held})
	if not err.is_empty():
		_fail(err)
		return

	# 5. Jammed civic link: same physical/local gunfire reaction, city stays CLEAR.
	scene = await _fresh_scene()
	if scene == null:
		_fail("Could not load jammed-report proof scene")
		return
	f = _fixture(scene)
	if not _complete(f):
		_fail("Jammed-report render fixture is incomplete")
		return
	player = f["player"]
	if not _jam_report(scene, player):
		_fail("Could not jam retained civic Report link for render proof")
		return
	if not _acquire(scene, f):
		_fail("Could not acquire sidearm after jammed Report setup")
		return
	_face_crawler(f)
	pair = await _frame_pair(scene, player, f["crawler"], "P17JammedPairFocus")
	if pair.is_empty():
		_fail("Could not frame jammed gunfire player/crawler pair")
		return
	var quiet_camera: Camera3D = pair["camera"]
	if not bool(f["runtime"].call("handle_weapon_action_pressed")):
		_fail("Jammed-report render-proof shot was rejected")
		return
	if String(f["incident"].call("get_incident_state_name")) != "ALARMED" 	or int(_wanted.call("get_heat_level")) != 0 	or String(_wanted.call("get_wanted_state_name")) != "CLEAR" 	or int(f["incident"].call("get_report_attempt_count")) != 1:
		_fail("Jammed render proof did not preserve local ALARMED + CLEAR authority")
		return
	err = await _capture("05_sidearm_jammed_report_local_alarm_clear.png", scene, quiet_camera, "LOCAL_ALARM_REPORT_SUPPRESSED_CLEAR", {"player": player, "crawler": f["crawler"], "worker": f["worker"], "held_sidearm": f["held"]})
	if not err.is_empty():
		_fail(err)
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
		_fail("Could not write P17 render report")
		return
	report_file.store_string(JSON.stringify(report, "	"))
	report_file.close()

	print("[P17_SIDEARM_RENDER] PASS: %s" % OUTPUT_DIR)
	await _free_scene()
	quit(0)
