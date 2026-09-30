extends SceneTree

const OUTPUT_DIR := "res://verification/production15"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CLAIM_PATH := "user://tests/p11_burnside_production15_checkpoint_recognition_render_capture.json"

var _scene: Node3D = null
var _wanted_runtime: Node = null
var _camera: Camera3D = null
var _bike: Node3D = null
var _checkpoint: Node3D = null
var _event: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _cleanup_storage() -> void:
	for path in [CLAIM_PATH, CLAIM_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _fail(message: String) -> void:
	push_error("[P15_CHECKPOINT_RENDER] " + message)
	_cleanup_storage()
	quit(1)

func _stage_bike(offset_z: float) -> void:
	_bike.global_position = _checkpoint.global_position + Vector3(0.0, 0.05, offset_z)
	_bike.set("velocity", Vector3.ZERO)
	_bike.set("current_speed", 0.0)
	_scene.set("active_vehicle", _bike)
	_camera.set_process(true)
	_camera.call("reset_camera_instant", _bike)
	_camera.set_process(false)
	await process_frame
	await process_frame
	await process_frame

func _capture(file_name: String, state: String) -> String:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for " + file_name
	var path := OUTPUT_DIR + "/" + file_name
	var error := image.save_png(path)
	if error != OK:
		return "Could not save %s: %s" % [file_name, error]
	_captures.append({
		"file": file_name,
		"state": state,
		"checkpoint_state": int(_event.get("current_state")),
		"watchlisted": bool(_event.call("is_courier_bike_watchlisted")),
		"label": String(_event.call("get_watchlist_label_text")),
		"viewport": [image.get_width(), image.get_height()],
	})
	return ""

func _run() -> void:
	_cleanup_storage()
	var output_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(output_abs)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create output directory")
		return

	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		_fail("BurnsideWantedRuntime autoload missing")
		return

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Production scene could not load")
		return
	_scene = packed.instantiate() as Node3D
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame
	await process_frame

	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		_fail("Wanted runtime did not bind")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")

	_event = _scene.get_node_or_null("SecurityCheckpointWorldEvent")
	_checkpoint = _scene.get_node_or_null("GearsDistrictSlice01B/StreetClutter/SecurityCheckpoint") as Node3D
	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_bike = _scene.get("courier_bike") as Node3D
	var player = _scene.get("player")
	var claim_runtime := _scene.get_node_or_null("BurnGarageCourierBikeClaimRuntime")
	if _event == null or _checkpoint == null or _camera == null or _bike == null or player == null or claim_runtime == null:
		_fail("Rendered proof is missing production dependencies")
		return

	_bike.set_physics_process(false)
	var claim_store = claim_runtime.call("get_progress_store")
	if claim_store == null or String(claim_store.call("get_storage_path")) != CLAIM_PATH:
		_fail("Rendered proof did not use isolated P11 claim storage")
		return
	if not bool(claim_store.call("mark_claimed")):
		_fail("Could not establish claimed Courier Bike fixture")
		return

	player.set("is_mounted", true)
	player.visible = false
	_bike.set("occupant", player)
	_scene.set("active_vehicle", _bike)

	# Baseline: same claimed Bike, no prior checkpoint breach -> ordinary toll standoff.
	_event.call("reset_world_event", true)
	await _stage_bike(4.0)
	_event.call("_process", 0.1)
	if int(_event.get("current_state")) != 1:
		_fail("Ordinary render fixture did not enter STANDOFF")
		return
	var capture_error := await _capture("01_claimed_bike_ordinary_standoff.png", "ORDINARY_STANDOFF")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# Establish the actual P15 local-memory path.
	if not bool(_event.call("ram_breach", 8.5)):
		_fail("Could not establish claimed-Bike checkpoint breach")
		return
	await process_frame
	_wanted_runtime.call("reset_runtime")
	await _stage_bike(14.0)
	_event.call("_process", 8.1)
	if int(_event.get("current_state")) != 0 or not bool(_event.call("is_courier_bike_watchlisted")):
		_fail("Ordinary rearm did not preserve P15 watchlist")
		return

	await _stage_bike(4.0)
	_event.call("_process", 0.1)
	if int(_event.get("current_state")) != 5:
		_fail("Return render fixture did not enter WATCHLISTED")
		return
	if String(_event.call("get_watchlist_label_text")) != "VEHICLE FLAGGED // HOLD":
		_fail("Return render fixture lacks HOLD feedback")
		return
	capture_error = await _capture("02_claimed_bike_flagged_return.png", "WATCHLISTED_RETURN")
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
		"real_checkpoint_event": true,
		"claimed_bike_fixture": true,
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write Production 15 rendered report")
		return
	report_file.store_string(JSON.stringify(report, "	"))
	report_file.close()

	print("[P15_CHECKPOINT_RENDER] PASS: %s" % OUTPUT_DIR)
	_scene.queue_free()
	await process_frame
	_cleanup_storage()
	quit(0)
