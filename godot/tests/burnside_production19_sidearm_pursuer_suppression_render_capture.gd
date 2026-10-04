extends SceneTree

const OUTPUT_DIR := "res://verification/production19"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const PROOF_FOV := 48.0

var _scene: Node = null
var _wanted: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P19_SIDEARM_PURSUER_RENDER] %s" % message)
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
	if _wanted == null or not bool(_wanted.call("bind_to_scene", _scene)):
		return null
	return _scene

func _camera(scene: Node) -> Camera3D:
	return scene.get_node_or_null("ChinatownCamera3D") as Camera3D

func _frame_pair(scene: Node, a: Node3D, b: Node3D, marker_name: String, fov: float = PROOF_FOV) -> Dictionary:
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
	camera.call("set_interaction_mode", true, marker)
	camera.fov = fov
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
	var point := _screen(camera, node)
	var size := root.get_visible_rect().size
	return point.x >= 0.0 and point.y >= 0.0 and point.x <= size.x and point.y <= size.y

func _acquire_sidearm(scene: Node, runtime: Node, player: Node3D) -> bool:
	var pickup := runtime.call("get_pickup") as Node3D
	if pickup == null:
		return false
	pickup.global_position = player.global_position + Vector3(0.6, 0.3, 0.0)
	pickup.call("update_player_distance", player.global_position)
	scene.set("_active_target", pickup)
	return bool(runtime.call("handle_action_pressed"))

func _capture(file_name: String, scene: Node, camera: Camera3D, outcome: String, player: Node3D, pursuer: Node3D, runtime: Node) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var save_error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]

	var wanted_label := scene.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label
	var target_node = pursuer.get("target_node")
	var direct_observation := bool(_wanted.call("has_direct_observation", pursuer, player))
	var entry := {
		"file": file_name,
		"outcome": outcome,
		"heat": int(_wanted.call("get_heat_level")),
		"wanted_state": String(_wanted.call("get_wanted_state_name")),
		"wanted_visible": wanted_label.visible if wanted_label != null else false,
		"wanted_text": wanted_label.text if wanted_label != null else "",
		"direct_observation": direct_observation,
		"pursuer_active": bool(pursuer.get("is_active")),
		"pursuer_state": int(pursuer.get("current_state")),
		"pursuer_target": String(target_node.name) if target_node is Node else "NONE",
		"pursuer_current_speed": float(pursuer.get("current_speed")),
		"sidearm_suppressed": bool(pursuer.call("is_sidearm_suppressed")),
		"suppression_remaining": float(pursuer.call("get_sidearm_suppression_remaining")),
		"scrapper_staggered": bool(pursuer.call("is_scrapper_staggered")),
		"sidearm_shots": int(runtime.call("get_shot_count")),
		"ballistic_queries": int(runtime.call("get_ballistic_query_count")),
		"last_impact": String(runtime.call("get_last_impact_name")),
		"player_world": player.global_position,
		"pursuer_world": pursuer.global_position,
		"player_screen": _screen(camera, player),
		"pursuer_screen": _screen(camera, pursuer),
		"player_in_view": _in_view(camera, player),
		"pursuer_in_view": _in_view(camera, pursuer),
	}
	_captures.append(entry)
	return ""

func _run() -> void:
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create P19 proof directory")
		return

	_wanted = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted == null:
		_fail("BurnsideWantedRuntime autoload is missing")
		return

	var scene := await _fresh_scene()
	if scene == null:
		_fail("Could not instantiate production scene")
		return
	var player := scene.get_node_or_null("Runner") as CharacterBody3D
	var pursuer := scene.get_node_or_null("PursuerPrototype") as CharacterBody3D
	var sidearm := scene.get_node_or_null("GearsSidearmRuntime")
	if player == null or pursuer == null or sidearm == null:
		_fail("P19 render fixture is incomplete")
		return
	if not pursuer.has_method("apply_sidearm_suppression") or not pursuer.has_method("is_sidearm_suppressed"):
		_fail("P19 pursuer suppression seam is missing")
		return
	if not _acquire_sidearm(scene, sidearm, player):
		_fail("Could not acquire retained P17 sidearm")
		return

	# Establish retained Heat 1, then move into a physically observed CONTACT lane.
	player.global_position = Vector3(-4.5, 0.1, -29.0)
	player.velocity = Vector3.ZERO
	if not bool(_wanted.call("request_civic_report", player.global_position)):
		_fail("Could not establish retained Heat 1 for P19 proof")
		return
	pursuer.global_position = Vector3(-4.5, 0.5, -33.0)
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if pivot != null:
		pivot.rotation.y = 0.0
	_wanted.call("process_wanted", 0.1)
	if String(_wanted.call("get_wanted_state_name")) != "CONTACT":
		_fail("Retained Wanted did not establish CONTACT")
		return
	if not bool(_wanted.call("has_direct_observation", pursuer, player)):
		_fail("CONTACT proof lane is unexpectedly occluded")
		return

	var framed := await _frame_pair(scene, player, pursuer, "P19ContactPair", 42.0)
	if framed.is_empty():
		_fail("Could not frame CONTACT approach")
		return
	var camera: Camera3D = framed["camera"]
	if not _in_view(camera, player) or not _in_view(camera, pursuer):
		_fail("CONTACT proof pair is not visible")
		return
	var err := await _capture(
		"01_contact_pursuer_closing.png",
		scene,
		camera,
		"HEAT1_CONTACT_PURSUER_CLOSING",
		player,
		pursuer,
		sidearm
	)
	if not err.is_empty():
		_fail(err)
		return

	# One retained FIRE ray physically hits the pursuer. P19 only requests local
	# hesitation; Heat and CONTACT remain unchanged and P05 displacement is absent.
	pursuer.set("current_speed", float(pursuer.get("max_speed")))
	if not bool(sidearm.call("handle_weapon_action_pressed")):
		_fail("Valid P19 proof shot was rejected")
		return
	if String(sidearm.call("get_last_impact_name")) != "PursuerPrototype":
		_fail("P19 proof shot did not physically resolve the pursuer")
		return
	if not bool(pursuer.call("is_sidearm_suppressed")):
		_fail("P19 proof shot did not create visible suppression")
		return
	if bool(pursuer.call("is_scrapper_staggered")):
		_fail("P19 proof shot incorrectly created Scrapper stagger")
		return
	if int(_wanted.call("get_heat_level")) != 1 or String(_wanted.call("get_wanted_state_name")) != "CONTACT":
		_fail("P19 proof shot directly mutated Wanted authority")
		return
	err = await _capture(
		"02_sidearm_hit_hesitation.png",
		scene,
		camera,
		"SIDEARM_HIT_SUPPRESSED_CONTACT_UNCHANGED",
		player,
		pursuer,
		sidearm
	)
	if not err.is_empty():
		_fail(err)
		return

	# Let the local modifier expire, then use the retained Commercial Frontage
	# fixture to create a real physical LOS break. This first proof frame remains
	# CONTACT because the retained 0.8 s observation grace has not elapsed.
	pursuer.call("_physics_process", 0.20)
	pursuer.global_position = Vector3(-4.5, 0.5, -35.0)
	player.global_position = Vector3(-17.0, 0.1, -35.0)
	player.velocity = Vector3.ZERO
	if bool(_wanted.call("has_direct_observation", pursuer, player)):
		_fail("Commercial Frontage did not physically block P19 proof LOS")
		return
	_wanted.call("process_wanted", 0.4)
	if String(_wanted.call("get_wanted_state_name")) != "CONTACT":
		_fail("P19 cover proof skipped retained CONTACT-loss grace")
		return
	framed = await _frame_pair(scene, player, pursuer, "P19CoverPair", 58.0)
	if framed.is_empty():
		_fail("Could not frame physical cover break")
		return
	camera = framed["camera"]
	err = await _capture(
		"03_physical_cover_breaks_los.png",
		scene,
		camera,
		"PHYSICAL_COVER_LOS_BROKEN_CONTACT_GRACE",
		player,
		pursuer,
		sidearm
	)
	if not err.is_empty():
		_fail(err)
		return

	# Only retained Wanted observation authority may now turn the sustained
	# physical sight break into SEARCH.
	_wanted.call("process_wanted", 0.5)
	if String(_wanted.call("get_wanted_state_name")) != "SEARCH" or int(_wanted.call("get_heat_level")) != 1:
		_fail("Retained LOS authority did not produce Heat 1 + SEARCH")
		return
	err = await _capture(
		"04_retained_wanted_search.png",
		scene,
		camera,
		"RETAINED_WANTED_CONTACT_TO_SEARCH",
		player,
		pursuer,
		sidearm
	)
	if not err.is_empty():
		_fail(err)
		return

	# A legitimate physical reacquisition remains owned by retained Wanted logic.
	pursuer.global_position = Vector3(-4.5, 0.5, -33.0)
	player.global_position = Vector3(-4.5, 0.1, -29.0)
	_wanted.call("process_wanted", 0.1)
	if String(_wanted.call("get_wanted_state_name")) != "CONTACT" or pursuer.get("target_node") != player:
		_fail("Retained Wanted did not reacquire CONTACT")
		return
	framed = await _frame_pair(scene, player, pursuer, "P19ReacquirePair", 42.0)
	if framed.is_empty():
		_fail("Could not frame retained reacquisition")
		return
	camera = framed["camera"]
	err = await _capture(
		"05_physical_reacquisition_contact.png",
		scene,
		camera,
		"PHYSICAL_REACQUISITION_CONTACT",
		player,
		pursuer,
		sidearm
	)
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
		"capture_count": _captures.size(),
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write P19 render report")
		return
	report_file.store_string(JSON.stringify(report, "  ") + "\n")
	report_file.close()

	print("[P19_SIDEARM_PURSUER_RENDER] PASS")
	await _free_scene()
	quit(0)
