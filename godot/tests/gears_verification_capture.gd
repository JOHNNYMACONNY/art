extends Node

# CI-only verification driver. It is present in the real playable scene so
# rendered capture follows the same normal-main-scene path as the repository's
# proven visual exporters. Outside the explicit verification command it frees
# itself immediately and owns no gameplay behavior.

const OUTPUT_DIR := "res://verification/current"
const REPORT_PATH := OUTPUT_DIR + "/verification_report.json"
const CONTACT_SHEET_PATH := "res://verification_contact_sheet.png"
const CAPTURE_FLAG := "--run-gears-verification-capture"
const CAPTURE_ENV := "GEARS_VERIFICATION_CAPTURE"
const CAPTURE_NAMES := [
	"01_quiet_traversal.png",
	"02_courier_bike.png",
	"03_pursuit.png",
	"04_shortcut_intersection.png",
	"05_burn_garage.png",
	"06_silent_core.png",
	"07_day.png",
	"08_dusk.png",
	"09_fb13_thrum.png",
]

const V7_BASELINE := {
	"sha": "47456504711a85a35d94f4f95e56315fbe395f70",
	"hardware": "Apple M4",
	"renderer": "Forward+ (Metal)",
	"draw_calls": 68,
	"primitives": 59410,
	"objects": 75,
	"avg_frame_ms": 16.46,
	"p95_frame_ms": 17.20,
}

const CONTACT_COLUMNS := 3
const CONTACT_ROWS := 3
const CONTACT_CELL_WIDTH := 480
const CONTACT_CELL_HEIGHT := 270
const CONTACT_WIDTH := CONTACT_COLUMNS * CONTACT_CELL_WIDTH
const CONTACT_HEIGHT := CONTACT_ROWS * CONTACT_CELL_HEIGHT
const MAX_CONTACT_BYTES := 2000000

var _scene: Node3D = null
var _player: CharacterBody3D = null
var _camera: Camera3D = null
var _bike: CharacterBody3D = null
var _pursuer: CharacterBody3D = null
var _proof: Node3D = null
var _district: Node3D = null
var _fb13_event: Node = null
var _audio: Node = null
var _captures: Array[Dictionary] = []
var _capture_images: Array[Image] = []

func _ready() -> void:
	var env_active := OS.get_environment(CAPTURE_ENV) == "1"
	var arg_active := OS.get_cmdline_user_args().has(CAPTURE_FLAG)
	if not env_active and not arg_active:
		queue_free()
		return
	call_deferred("_run")

func _gha_escape(message: String) -> String:
	return message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")

func _append_ci_summary(title: String, message: String) -> void:
	if OS.get_environment("GITHUB_ACTIONS").to_lower() != "true":
		return
	var summary_path := OS.get_environment("GITHUB_STEP_SUMMARY")
	if summary_path.is_empty():
		return
	var existing := FileAccess.get_file_as_string(summary_path) if FileAccess.file_exists(summary_path) else ""
	var file := FileAccess.open(summary_path, FileAccess.WRITE)
	if file != null:
		file.store_string(existing + "\n## %s\n\n%s\n" % [title, message])
		file.close()

func _run() -> void:
	var failure := await _capture_and_measure()
	if failure != "":
		_append_ci_summary("Gears verification capture failure", "`%s`" % failure)
		if OS.get_environment("GITHUB_ACTIONS").to_lower() == "true":
			print("::error title=GEARS_VERIFICATION_CAPTURE::%s" % _gha_escape(failure))
		push_error("[GEARS_VERIFICATION_CAPTURE] %s" % failure)
		get_tree().quit(1)
		return
	_append_ci_summary(
		"Gears verification capture child",
		"Rendered nine retained-camera states plus full-current and retained-control structural render snapshots for `%s`." % OS.get_environment("SOURCE_SHA")
	)
	print("[GEARS_VERIFICATION_CAPTURE] PASS: %s" % REPORT_PATH)
	get_tree().quit(0)

func _capture_and_measure() -> String:
	var output_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(output_abs)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return "Could not create verification output directory: %s" % dir_error
	for file_name in CAPTURE_NAMES:
		var stale := OUTPUT_DIR + "/" + file_name
		if FileAccess.file_exists(stale):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale))
	for stale_path in [REPORT_PATH, CONTACT_SHEET_PATH]:
		if FileAccess.file_exists(stale_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_path))

	_scene = get_parent() as Node3D
	if _scene == null or _scene.name != "ScrapTestBlock":
		return "Verification driver is not attached to the real playable scene"

	await get_tree().process_frame
	await get_tree().physics_frame

	_player = _scene.get_node_or_null("Runner") as CharacterBody3D
	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_bike = _scene.get_node_or_null("CourierBike") as CharacterBody3D
	_pursuer = _scene.get_node_or_null("PursuerPrototype") as CharacterBody3D
	_proof = _scene.get_node_or_null("GearsStyleProof") as Node3D
	_district = _scene.get_node_or_null("GearsDistrictSlice01B") as Node3D
	_fb13_event = _scene.get_node_or_null("FB13ThrumWorldEvent")
	_audio = _scene.get_node_or_null("AudioManager")
	if _player == null or _camera == null or _bike == null or _pursuer == null or _proof == null or _district == null or _fb13_event == null or _audio == null:
		return "Playable scene is missing a required verification dependency"
	if absf(_camera.fov - 32.0) > 0.01:
		return "Retained gameplay camera FOV is no longer 32 degrees"

	_proof.call("set_lighting_mode", "day")

	_place_player(Vector3(-4.5, 0.20, -30.0))
	var error := await _save_capture(CAPTURE_NAMES[0])
	if error != "": return error

	_bike.global_position = Vector3(-3.4, 0.15, -33.8)
	_bike.velocity = Vector3.ZERO
	_place_player(Vector3(-4.7, 0.20, -32.4))
	error = await _save_capture(CAPTURE_NAMES[1])
	if error != "": return error

	_bike.global_position = Vector3(-3.9, 0.15, -34.5)
	_bike.velocity = Vector3.ZERO
	_pursuer.global_position = Vector3(-0.8, 0.65, -33.0)
	_pursuer.velocity = Vector3.ZERO
	_pursuer.call("activate_pursuit", _bike)
	_scene.set("current_pursuit_state", 2)
	_place_player(Vector3(-4.8, 0.20, -34.1))
	error = await _save_capture(CAPTURE_NAMES[2])
	if error != "": return error
	_pursuer.call("deactivate_pursuit")
	_scene.set("current_pursuit_state", 0)

	_place_player(Vector3(-7.2, 0.20, -24.8))
	error = await _save_capture(CAPTURE_NAMES[3])
	if error != "": return error

	_place_player(Vector3(-10.0, 0.20, -39.1))
	error = await _save_capture(CAPTURE_NAMES[4])
	if error != "": return error

	_place_player(Vector3(6.2, 0.20, -26.0))
	error = await _save_capture(CAPTURE_NAMES[5])
	if error != "": return error

	_proof.call("set_lighting_mode", "day")
	_place_player(Vector3(-3.0, 0.20, -23.0))
	error = await _save_capture(CAPTURE_NAMES[6])
	if error != "": return error

	_proof.call("set_lighting_mode", "dusk")
	_place_player(Vector3(-3.0, 0.20, -23.0))
	error = await _save_capture(CAPTURE_NAMES[7])
	if error != "": return error

	_proof.call("set_lighting_mode", "day")
	var utility_plate := _scene.get_node_or_null("GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate") as MeshInstance3D
	if utility_plate == null:
		return "FB-13 resonance anchor is missing"
	_fb13_event.set_process(false)
	_audio.current_mix_state = AudioManager.MixState.CALM
	_place_player(Vector3(utility_plate.global_position.x, 0.20, utility_plate.global_position.z + 1.4))
	_fb13_event.call("_process", 0.10)
	error = await _save_capture(CAPTURE_NAMES[8])
	if error != "": return error

	_proof.call("set_lighting_mode", "day")
	_place_player(Vector3(-1.5, 0.20, -18.0))
	var full_current := await _measure_render_snapshot("full_current")
	_proof.visible = false
	_district.visible = false
	_camera.call("reset_camera_instant", _player)
	var retained_control := await _measure_render_snapshot("retained_yard_control")
	_proof.visible = true
	_district.visible = true

	var viewport := get_viewport()
	var report := {
		"schema_version": 9,
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"generated_utc": Time.get_datetime_string_from_system(true),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"os": OS.get_name(),
		"display_server": DisplayServer.get_name(),
		"renderer_method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"viewport": {"width": viewport.size.x, "height": viewport.size.y},
		"camera_fov_deg": _camera.fov,
		"captures": _captures,
		"telemetry": {
			"mode": "single_frame_same_host_structural_snapshot",
			"frame_time_scope": "advisory_smoke_only",
			"native_avg_p95_status": "deferred_requires_native_runtime",
			"full_current": full_current,
			"retained_yard_control": retained_control,
			"delta_full_minus_control": _telemetry_delta(full_current, retained_control),
			"historical_v7_desktop_baseline": V7_BASELINE,
			"historical_baseline_comparability": "context_only_hardware_renderer_mismatch",
		},
		"verification_scope": {
			"retained_camera_rendered": true,
			"normal_main_scene_runtime": true,
			"same_host_structural_cost_measured": true,
			"native_avg_p95_measured": false,
			"human_audio_listening": false,
			"black_box_browser_input": false,
		},
	}
	if str(report.source_sha).is_empty():
		report.source_sha = "local_or_unstamped"

	var publication_error := _publish_web_verification_payload(report)
	if publication_error != "":
		return publication_error

	var report_file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if report_file == null:
		return "Could not open verification report for writing"
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()
	if not FileAccess.file_exists(REPORT_PATH):
		return "Verification report was not written"
	return ""

func _place_player(position: Vector3) -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = position
	_camera.call("reset_camera_instant", _player)

func _save_capture(file_name: String) -> String:
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport image is empty for %s" % file_name
	var file_path := OUTPUT_DIR + "/" + file_name
	var save_error := image.save_png(file_path)
	if save_error != OK:
		return "PNG save failed for %s: %s" % [file_name, save_error]
	var bytes := FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(file_path)).size()
	if bytes < 20000:
		return "Rendered PNG is unexpectedly small for %s: %s bytes" % [file_name, bytes]
	_captures.append({
		"file": file_name,
		"width": image.get_width(),
		"height": image.get_height(),
		"bytes": bytes,
	})
	_capture_images.append(image.duplicate())
	return ""

func _publish_web_verification_payload(report: Dictionary) -> String:
	if OS.get_environment("GITHUB_ACTIONS").to_lower() != "true":
		return ""
	if _capture_images.size() != CAPTURE_NAMES.size():
		return "Contact sheet cannot be built because rendered capture count is incomplete"

	var sheet := Image.create_empty(CONTACT_WIDTH, CONTACT_HEIGHT, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.025, 0.03, 0.035, 1.0))
	for index in range(_capture_images.size()):
		var preview := _capture_images[index].duplicate()
		if preview.get_format() != Image.FORMAT_RGBA8:
			preview.convert(Image.FORMAT_RGBA8)
		preview.resize(CONTACT_CELL_WIDTH, CONTACT_CELL_HEIGHT, Image.INTERPOLATE_LANCZOS)
		var column := index % CONTACT_COLUMNS
		var row := int(index / CONTACT_COLUMNS)
		sheet.blit_rect(
			preview,
			Rect2i(Vector2i.ZERO, Vector2i(CONTACT_CELL_WIDTH, CONTACT_CELL_HEIGHT)),
			Vector2i(column * CONTACT_CELL_WIDTH, row * CONTACT_CELL_HEIGHT)
		)

	var contact_error := sheet.save_png(CONTACT_SHEET_PATH)
	if contact_error != OK:
		return "Verification contact sheet PNG write failed: %s" % contact_error
	var contact_bytes := FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(CONTACT_SHEET_PATH)).size()
	if contact_bytes < 20000:
		return "Verification contact sheet is unexpectedly small"
	if contact_bytes > MAX_CONTACT_BYTES:
		return "Verification contact sheet exceeds bounded Web asset budget: %d bytes" % contact_bytes

	report["publication"] = {
		"transport": "web_boot_splash_plus_head_include",
		"payload_marker": "GEARS_VERIFICATION_PAYLOAD_V2",
		"public_contact_sheet_path": "index.png",
		"contact_sheet": {
			"file": "verification_contact_sheet.png",
			"width": CONTACT_WIDTH,
			"height": CONTACT_HEIGHT,
			"columns": CONTACT_COLUMNS,
			"rows": CONTACT_ROWS,
			"cell_width": CONTACT_CELL_WIDTH,
			"cell_height": CONTACT_CELL_HEIGHT,
			"bytes": contact_bytes,
			"capture_order": CAPTURE_NAMES,
		},
	}

	ProjectSettings.set_setting("application/boot_splash/image", CONTACT_SHEET_PATH)
	ProjectSettings.set_setting("application/boot_splash/show_image", true)
	ProjectSettings.set_setting("application/boot_splash/fullsize", true)
	ProjectSettings.set_setting("application/boot_splash/use_filter", true)
	var project_save_error := ProjectSettings.save()
	if project_save_error != OK:
		return "Could not persist isolated Web boot-splash verification asset: %s" % project_save_error

	var full: Dictionary = report.telemetry.full_current
	var control: Dictionary = report.telemetry.retained_yard_control
	var delta: Dictionary = report.telemetry.delta_full_minus_control
	var source_sha := str(report.source_sha)
	var report_json := JSON.stringify(report)
	var head_include := "".join([
		"<!-- GEARS_VERIFICATION_PAYLOAD_V2 source_sha=", source_sha,
		" full_frame_smoke_ms=", str(full.frame_time_ms),
		" control_frame_smoke_ms=", str(control.frame_time_ms),
		" delta_draw_calls=", str(delta.draw_calls),
		" delta_primitives=", str(delta.primitives),
		" delta_objects=", str(delta.objects), " -->\n",
		"<script id=\"gears-verification-report\" type=\"application/json\" data-source-sha=\"", source_sha, "\">",
		report_json,
		"</script>\n",
	])

	var preset := ConfigFile.new()
	var preset_path := ProjectSettings.globalize_path("res://export_presets.cfg")
	var load_error := preset.load(preset_path)
	if load_error != OK:
		return "Could not load Web export preset for verification payload: %s" % load_error
	preset.set_value("preset.0.options", "html/head_include", head_include)
	var preset_save_error := preset.save(preset_path)
	if preset_save_error != OK:
		return "Could not persist Web verification telemetry payload: %s" % preset_save_error

	var verify := ConfigFile.new()
	if verify.load(preset_path) != OK:
		return "Could not reload Web export preset after payload write"
	var saved_include := str(verify.get_value("preset.0.options", "html/head_include", ""))
	if "GEARS_VERIFICATION_PAYLOAD_V2" not in saved_include or source_sha not in saved_include:
		return "Web verification payload did not persist to export preset"
	return ""

func _measure_render_snapshot(label: String) -> Dictionary:
	var start_usec := Time.get_ticks_usec()
	await get_tree().process_frame
	var end_usec := Time.get_ticks_usec()
	return {
		"label": label,
		"frame_time_ms": snappedf(float(end_usec - start_usec) / 1000.0, 0.001),
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	}

func _telemetry_delta(full: Dictionary, control: Dictionary) -> Dictionary:
	return {
		"frame_time_ms": snappedf(float(full.frame_time_ms) - float(control.frame_time_ms), 0.001),
		"draw_calls": int(full.draw_calls) - int(control.draw_calls),
		"primitives": int(full.primitives) - int(control.primitives),
		"objects": int(full.objects) - int(control.objects),
	}
