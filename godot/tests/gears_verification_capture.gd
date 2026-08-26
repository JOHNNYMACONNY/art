extends SceneTree

const OUTPUT_DIR := "res://verification/current"
const REPORT_PATH := OUTPUT_DIR + "/verification_report.json"
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

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failure := await _capture_and_measure()
	if failure != "":
		push_error("[GEARS_VERIFICATION_CAPTURE] %s" % failure)
		quit(1)
		return
	print("[GEARS_VERIFICATION_CAPTURE] PASS: %s" % REPORT_PATH)
	quit(0)

func _capture_and_measure() -> String:
	var output_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(output_abs)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return "Could not create verification output directory: %s" % dir_error
	for file_name in CAPTURE_NAMES:
		var stale := OUTPUT_DIR + "/" + file_name
		if FileAccess.file_exists(stale):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale))
	if FileAccess.file_exists(REPORT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(REPORT_PATH))

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		return "Could not load real playable scene"
	_scene = packed.instantiate() as Node3D
	if _scene == null:
		return "Could not instantiate real playable scene"
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await create_timer(0.20).timeout

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

	# Day is the neutral starting presentation for the first six captures.
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
	await create_timer(0.08).timeout
	error = await _save_capture(CAPTURE_NAMES[8], 0.02)
	if error != "": return error
	await create_timer(0.70).timeout

	# Same-host performance evidence: current district visible versus retained-yard control.
	_proof.call("set_lighting_mode", "day")
	_place_player(Vector3(-1.5, 0.20, -18.0))
	var full_current := await _measure_render_sample("full_current")
	_proof.visible = false
	_district.visible = false
	await process_frame
	await create_timer(0.10).timeout
	_camera.call("reset_camera_instant", _player)
	var retained_control := await _measure_render_sample("retained_yard_control")
	_proof.visible = true
	_district.visible = true

	var report := {
		"schema_version": 1,
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"generated_utc": Time.get_datetime_string_from_system(true),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"os": OS.get_name(),
		"display_server": DisplayServer.get_name(),
		"renderer_method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"viewport": {"width": root.size.x, "height": root.size.y},
		"camera_fov_deg": _camera.fov,
		"captures": _captures,
		"telemetry": {
			"sample_frames": 180,
			"full_current": full_current,
			"retained_yard_control": retained_control,
			"delta_full_minus_control": _telemetry_delta(full_current, retained_control),
			"historical_v7_desktop_baseline": V7_BASELINE,
			"historical_baseline_comparability": "context_only_hardware_renderer_mismatch",
		},
		"verification_scope": {
			"retained_camera_rendered": true,
			"same_host_incremental_cost_measured": true,
			"human_audio_listening": false,
			"black_box_browser_input": false,
		},
	}
	if str(report.source_sha).is_empty():
		report.source_sha = "local_or_unstamped"
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

func _save_capture(file_name: String, settle_seconds: float = 0.12) -> String:
	await process_frame
	if settle_seconds > 0.0:
		await create_timer(settle_seconds).timeout
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport image is empty for %s" % file_name
	var file_path := OUTPUT_DIR + "/" + file_name
	var save_error := image.save_png(file_path)
	if save_error != OK:
		return "PNG save failed for %s: %s" % [file_name, save_error]
	var absolute_path := ProjectSettings.globalize_path(file_path)
	var bytes := FileAccess.get_file_as_bytes(absolute_path).size()
	if bytes < 20000:
		return "Rendered PNG is unexpectedly small for %s: %s bytes" % [file_name, bytes]
	_captures.append({
		"file": file_name,
		"width": image.get_width(),
		"height": image.get_height(),
		"bytes": bytes,
	})
	return ""

func _measure_render_sample(label: String) -> Dictionary:
	if DisplayServer.get_name().to_lower() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for _i in range(30):
		await process_frame
	var frame_times: Array[float] = []
	for _i in range(180):
		var start_usec := Time.get_ticks_usec()
		await process_frame
		var end_usec := Time.get_ticks_usec()
		frame_times.append(float(end_usec - start_usec) / 1000.0)
	frame_times.sort()
	var average := 0.0
	for value in frame_times:
		average += value
	average /= float(frame_times.size())
	var p95_index := mini(frame_times.size() - 1, int(ceil(float(frame_times.size()) * 0.95)) - 1)
	return {
		"label": label,
		"avg_frame_ms": snappedf(average, 0.001),
		"p95_frame_ms": snappedf(frame_times[p95_index], 0.001),
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	}

func _telemetry_delta(full: Dictionary, control: Dictionary) -> Dictionary:
	return {
		"avg_frame_ms": snappedf(float(full.avg_frame_ms) - float(control.avg_frame_ms), 0.001),
		"p95_frame_ms": snappedf(float(full.p95_frame_ms) - float(control.p95_frame_ms), 0.001),
		"draw_calls": int(full.draw_calls) - int(control.draw_calls),
		"primitives": int(full.primitives) - int(control.primitives),
		"objects": int(full.objects) - int(control.objects),
	}
