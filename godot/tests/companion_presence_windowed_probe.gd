extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const OUTPUT_DIR := "res://verification/production08"

var _scene: Node = null
var _runner: Node3D = null
var _camera: Camera3D = null
var _fb13: Node3D = null
var _runtime: Node = null
var _bike: Node = null
var _hauler: Node = null
var _thrum_event: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P08_WINDOWED_PROBE] %s" % message)
	if is_instance_valid(_scene):
		_scene.queue_free()
	await process_frame
	await process_frame
	quit(1)

func _capture(file_name: String, description: String) -> String:
	for _i in range(3):
		await process_frame
		await physics_frame

	var texture := root.get_texture()
	if texture == null:
		return "Viewport texture null for %s" % file_name
	var image := texture.get_image()
	if image == null or image.is_empty():
		return "Viewport image empty for %s" % file_name

	var path := OUTPUT_DIR + "/" + file_name
	var abs_path := ProjectSettings.globalize_path(path)
	var dir_err := DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		return "Could not create directory for %s" % path

	var save_err := image.save_png(abs_path)
	if save_err != OK:
		return "Could not save %s (error %d)" % [path, save_err]

	var follow_dist: float = 0.0
	var state_val: int = -1
	if _fb13 and _fb13.has_method("get_follow_distance"):
		follow_dist = float(_fb13.call("get_follow_distance"))
	if _fb13 and _fb13.has_method("get_presence_state"):
		state_val = int(_fb13.call("get_presence_state"))

	_captures.append({
		"file": file_name,
		"description": description,
		"fb13_state": state_val,
		"follow_distance": follow_dist,
		"fb13_parent": String(_fb13.get_parent().name) if _fb13 and _fb13.get_parent() else "",
		"runner_position": [_runner.global_position.x, _runner.global_position.y, _runner.global_position.z] if _runner else [],
		"fb13_position": [_fb13.global_position.x, _fb13.global_position.y, _fb13.global_position.z] if _fb13 else [],
		"viewport_size": [image.get_width(), image.get_height()],
	})
	print("[P08_WINDOWED_PROBE] Captured %s: %s" % [file_name, description])
	return ""

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Failed to load production scene %s" % SCENE_PATH)
		return

	_scene = packed.instantiate()
	root.add_child(_scene)

	for _i in range(5):
		await process_frame
		await physics_frame

	_runner = _scene.get_node_or_null("Runner") as Node3D
	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_fb13 = _scene.get_node_or_null("FB13CompanionBody") as Node3D
	_runtime = _scene.get_node_or_null("BurnsideCompanionPresenceRuntime")
	_bike = _scene.get_node_or_null("CourierBike")
	_hauler = _scene.get_node_or_null("ScrapHauler")
	_thrum_event = _scene.get_node_or_null("FB13ThrumWorldEvent")

	if not _runner or not _camera or not _fb13 or not _runtime or not _bike or not _hauler or not _thrum_event:
		await _fail("Missing required production node dependencies")
		return

	var hs7_socket := _runner.get_node_or_null("MeshPivot/Torso/HS7CarrySocket") as Node3D
	if hs7_socket == null or hs7_socket.get_child_count() == 0:
		await _fail("Runner HS7CarrySocket or module visual child missing")
		return

	# --- 1. Ordinary On-Foot Follow Proof ---
	_runner.global_position = Vector3(0.0, 0.0, 5.0)
	if _camera.has_method("reset_camera_instant"):
		_camera.call("reset_camera_instant", _runner)
	for _i in range(30):
		await process_frame
		await physics_frame

	var cap_err := await _capture("01_on_foot_follow.png", "FB-13 following Runner on foot with HS-7 carried")
	if not cap_err.is_empty():
		await _fail(cap_err)
		return

	# --- 2. CourierBike Docked Proof ---
	_runner.global_position = _bike.global_position + Vector3(0.5, 0.0, 0.5)
	if _bike.get("mount_interactable"):
		_bike.mount_interactable.call("update_player_distance", _runner.global_position)
	if not bool(_bike.call("request_mount", _runner)):
		await _fail("Failed to mount CourierBike")
		return

	for _i in range(30): # 0.5s > 0.25s mount time
		await process_frame
		await physics_frame

	cap_err = await _capture("02_courier_bike_docked.png", "FB-13 docked on CourierBike rear rack")
	if not cap_err.is_empty():
		await _fail(cap_err)
		return

	# --- 3. Bike Dismount / Release Proof ---
	_bike.set("current_speed", 0.0)
	if not bool(_bike.call("request_dismount")):
		await _fail("Failed to dismount CourierBike")
		return

	for _i in range(25): # 0.4s > 0.2s dismount
		await process_frame
		await physics_frame

	cap_err = await _capture("03_bike_dismount_release.png", "FB-13 released physically following bike dismount")
	if not cap_err.is_empty():
		await _fail(cap_err)
		return

	# --- 4. ScrapHauler Docked Proof ---
	_runner.global_position = _hauler.global_position + Vector3(0.5, 0.0, 0.5)
	if _hauler.get("mount_interactable"):
		_hauler.mount_interactable.call("update_player_distance", _runner.global_position)
	if not bool(_hauler.call("request_mount", _runner)):
		await _fail("Failed to mount ScrapHauler")
		return

	for _i in range(30): # 0.5s > 0.25s mount
		await process_frame
		await physics_frame

	cap_err = await _capture("04_scrap_hauler_docked.png", "FB-13 docked on ScrapHauler cargo bed")
	if not cap_err.is_empty():
		await _fail(cap_err)
		return

	_hauler.set("current_speed", 0.0)
	_hauler.call("request_dismount")
	for _i in range(20):
		await process_frame
		await physics_frame

	# --- 5. Hard Recovery / Off-Camera Staging Proof ---
	_camera.set_process(false)
	_camera.set_physics_process(false)
	_runner.global_position = Vector3(0, 0, -10.0)
	_camera.global_position = Vector3(0, 3, -15.0)
	_camera.look_at(Vector3(0, 0, -30.0), Vector3.UP)
	_fb13.call("reset_to_follow_position")
	_fb13.global_position = Vector3(0, 1.15, 10.0) # 20m from runner, off-screen behind camera

	for _i in range(60): # 1.0s > 0.75s threshold
		await process_frame
		await physics_frame

	cap_err = await _capture("05_hard_rejoin_physical_return.png", "FB-13 physical rejoining return after off-screen recovery snap")
	if not cap_err.is_empty():
		await _fail(cap_err)
		return

	# --- 6. FB-13 Thrum Body Reaction Proof ---
	_camera.set_process(true)
	_camera.set_physics_process(true)
	var primary := _scene.get_node_or_null("GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate") as Node3D
	if primary:
		_runner.global_position = primary.global_position + Vector3(0.0, 0.0, 1.5)
		_fb13.call("reset_to_follow_position")
		if _camera.has_method("reset_camera_instant"):
			_camera.call("reset_camera_instant", _runner)
		for _i in range(20):
			await process_frame
			await physics_frame

		# Step on resonance plate
		_runner.global_position = primary.global_position
		for _i in range(15):
			await process_frame
			await physics_frame

		cap_err = await _capture("06_thrum_body_reaction.png", "FB-13 body tilt/emission reaction to retained Thrum event")
		if not cap_err.is_empty():
			await _fail(cap_err)
			return

	# Write summary report
	var report := {
		"schema_version": 1,
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"hard_rejoin_count": int(_fb13.call("get_hard_rejoin_count")),
		"last_hard_rejoin_snapshot": _fb13.call("get_last_hard_rejoin_snapshot"),
		"thrum_reaction_count": int(_fb13.call("get_thrum_reaction_count")),
		"runtime_snapshot": _runtime.call("get_runtime_snapshot"),
		"captures": _captures,
	}

	var report_path := ProjectSettings.globalize_path(OUTPUT_DIR + "/companion_presence_report.json")
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()

	print("[P08_WINDOWED_PROBE] PASS: Report and screenshots written to %s" % OUTPUT_DIR)
	_scene.queue_free()
	await process_frame
	await process_frame
	quit(0)
