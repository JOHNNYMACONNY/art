extends SceneTree

const OUTPUT_DIR := "res://verification/production14"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const TEST_BASENAME := "burnside_production14_scrap_bash_bar_render_capture"
const CASH_PATH := "user://tests/p12_production14_scrap_bash_bar_render_capture.json"
const CLAIM_PATH := "user://tests/p11_burnside_production14_scrap_bash_bar_render_capture.json"
const CONTACT_PATH := "user://tests/p10_burnside_production14_scrap_bash_bar_render_capture.json"
const STAGE_POSITION := Vector3(-2.0, 0.05, -22.0)

var _scene: Node3D = null
var _wanted_runtime: Node = null
var _camera: Camera3D = null
var _bike: Node3D = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _cleanup_storage() -> void:
	for base in [CASH_PATH, CLAIM_PATH, CONTACT_PATH]:
		for path in [base, base + ".tmp"]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _fail(message: String) -> void:
	push_error("[P14_BASH_BAR_RENDER] " + message)
	_cleanup_storage()
	quit(1)

func _stage_bike(position: Vector3) -> void:
	_bike.global_position = position
	_bike.set("velocity", Vector3.ZERO)
	_bike.set("current_speed", 0.0)
	_scene.set("active_vehicle", _bike)
	_camera.set_process(true)
	_camera.call("reset_camera_instant", _bike)
	_camera.set_process(false)
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
		"bash_bar_visible": bool(_bike.call("has_scrap_bash_bar")),
		"bike_position": [_bike.global_position.x, _bike.global_position.y, _bike.global_position.z],
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

	var district := _scene.get_node_or_null("GearsDistrictSlice01B") as Node3D
	var player = _scene.get("player")
	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_bike = _scene.get("courier_bike") as Node3D
	var claim_runtime := _scene.get_node_or_null("BurnGarageCourierBikeClaimRuntime")
	var contact_runtime := _scene.get_node_or_null("MayorBurnContactServiceRuntime")
	var cash_runtime := _scene.get_node_or_null("BurnsideCashEconomyRuntime")
	var mod_runtime := _scene.get_node_or_null("BurnGarageCourierBikeScrapperModRuntime")
	var socket := district.get_node_or_null("CourierBikeClaimSocket") as Marker3D if district != null else null
	if district == null or player == null or _camera == null or _bike == null or claim_runtime == null 	or contact_runtime == null or cash_runtime == null or mod_runtime == null or socket == null:
		_fail("Rendered proof is missing a production dependency")
		return

	_bike.set_physics_process(false)
	var cash_store = cash_runtime.call("get_progress_store")
	var claim_store = claim_runtime.call("get_progress_store")
	var contact_store = contact_runtime.call("get_progress_store")
	if cash_store == null or claim_store == null or contact_store == null:
		_fail("Rendered proof durable stores missing")
		return
	if String(cash_store.call("get_storage_path")) != CASH_PATH 	or String(claim_store.call("get_storage_path")) != CLAIM_PATH 	or String(contact_store.call("get_storage_path")) != CONTACT_PATH:
		_fail("Rendered proof did not use isolated deterministic storage")
		return

	if not bool(contact_store.call("mark_known")):
		_fail("Could not establish Burn KNOWN")
		return
	player.global_position = socket.global_position
	player.is_mounted = false
	_scene.set("active_vehicle", null)
	_bike.global_position = socket.global_position
	_bike.set("current_speed", 0.0)
	_bike.set("velocity", Vector3.ZERO)
	if not bool(claim_runtime.call("attempt_claim")):
		_fail("Could not establish claimed production Bike")
		return

	await _stage_bike(STAGE_POSITION)
	if bool(_bike.call("has_scrap_bash_bar")):
		_fail("Claimed stock Bike already exposes bash bar")
		return
	var capture_error := await _capture("01_claimed_stock_bike.png", "CLAIMED_STOCK")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# Use authored P13 payouts and the real P14 Garage purchase path.
	player.global_position = socket.global_position
	_scene.set("active_vehicle", null)
	_bike.global_position = socket.global_position
	_bike.set("current_speed", 0.0)
	_bike.set("velocity", Vector3.ZERO)
	if int(cash_runtime.call("award_mission_01", 320)) != 320 	or int(cash_runtime.call("award_mission_02", 450)) != 450 	or int(cash_runtime.call("get_balance")) != 770:
		_fail("Could not establish authored 770-Cash fixture")
		return
	if not bool(mod_runtime.call("attempt_purchase")):
		_fail("Real P14 Garage purchase path failed")
		return
	if int(cash_runtime.call("get_balance")) != 270 	or not bool(cash_store.call("has_courier_bike_bash_bar_receipt")) 	or not bool(_bike.call("has_scrap_bash_bar")):
		_fail("Purchase did not establish durable fitted state")
		return

	await _stage_bike(STAGE_POSITION)
	var bash_bar := _bike.get_node_or_null("VisualRoot/ScrapBashBar") as Node3D
	if bash_bar == null or not bash_bar.visible:
		_fail("Fitted visual is not visible")
		return
	capture_error = await _capture("02_scrap_bash_bar_fitted.png", "SCRAP_BASH_BAR_FITTED")
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
		"real_claim_path": true,
		"real_cash_payout_path": true,
		"real_garage_purchase_path": true,
		"cash_after_purchase": int(cash_runtime.call("get_balance")),
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write Production 14 rendered report")
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()

	print("[P14_BASH_BAR_RENDER] PASS: %s" % OUTPUT_DIR)
	_scene.queue_free()
	await process_frame
	_cleanup_storage()
	quit(0)
