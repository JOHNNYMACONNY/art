extends SceneTree

const OUTPUT_DIR := "res://verification/production16"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")

var _scene: Node3D = null
var _wanted_runtime: Node = null
var _camera: Camera3D = null
var _player: Node3D = null
var _city: Node = null
var _civic: Node = null
var _release: Node3D = null
var _seal: Node3D = null
var _core: Node3D = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P16_MEMORY_DISCLOSURE_RENDER] " + message)
	quit(1)

func _drive_complete() -> bool:
	_civic.mission.phase = CivicMissionScript.Phase.COMPLETE
	var mission = _city.mission
	return mission.unlock_after_civic_repossession() \
	and mission.on_silent_core_activated() \
	and mission.on_echo_completed() \
	and mission.on_escape_complete()

func _stage_camera() -> void:
	var midpoint := (_release.global_position + _seal.global_position) * 0.5
	_player.global_position = midpoint + Vector3(0.0, 0.0, 2.2)
	_player.set_physics_process(false)
	_camera.set_process(true)
	_camera.call("reset_camera_instant", _player)
	_camera.set_process(false)
	await process_frame
	await process_frame
	await process_frame

func _choose(relay: Node) -> bool:
	_player.global_position = relay.global_position
	_release.call("update_player_distance", _player.global_position)
	_seal.call("update_player_distance", _player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != relay:
		return false
	_city.call("_on_action_pressed")
	await process_frame
	return true

func _capture(file_name: String, state: String) -> String:
	await _stage_camera()
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for " + file_name
	var error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if error != OK:
		return "Could not save %s: %s" % [file_name, error]
	var snapshot: Dictionary = _city.call("get_aftermath_snapshot")
	_captures.append({
		"file": file_name,
		"state": state,
		"aftermath": snapshot["state"],
		"release": snapshot["release_relay"],
		"seal": snapshot["seal_relay"],
		"report_attempts": snapshot["release_report_attempt_count"],
		"viewport": [image.get_width(), image.get_height()],
	})
	return ""

func _run() -> void:
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
	_wanted_runtime.call("bind_to_scene", _scene)
	_wanted_runtime.call("reset_runtime")
	_wanted_runtime.set_process(false)

	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_player = _scene.get_node_or_null("Runner") as Node3D
	_city = _scene.get_node_or_null("CityThatForgotRuntime")
	_civic = _scene.get_node_or_null("CivicRepossessionRuntime")
	_release = _scene.get_node_or_null("MemoryReleaseRelay") as Node3D
	_seal = _scene.get_node_or_null("MemorySealRelay") as Node3D
	_core = _scene.get_node_or_null("SilentCore") as Node3D
	if _camera == null or _player == null or _city == null or _civic == null \
	or _release == null or _seal == null or _core == null:
		_fail("Rendered proof is missing production P16 dependencies")
		return

	var err := await _capture("01_relays_dormant.png", "DORMANT")
	if not err.is_empty():
		_fail(err)
		return

	if not _drive_complete():
		_fail("Could not establish Mission 03 COMPLETE")
		return
	_city.call("_arm_aftermath_choice")
	err = await _capture("02_choice_ready.png", "CHOICE_READY")
	if not err.is_empty():
		_fail(err)
		return

	if not await _choose(_release):
		_fail("Could not select RELEASE through production target arbitration")
		return
	err = await _capture("03_archive_released.png", "RELEASED")
	if not err.is_empty():
		_fail(err)
		return

	_wanted_runtime.call("reset_runtime")
	_city.call("_reset_for_full_replay")
	if not _drive_complete():
		_fail("Could not re-establish Mission 03 COMPLETE for SEAL proof")
		return
	_city.call("_arm_aftermath_choice")
	if not await _choose(_seal):
		_fail("Could not select SEAL through production target arbitration")
		return
	err = await _capture("04_archive_sealed.png", "SEALED")
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
		"existing_silent_core_site": true,
		"retained_target_arbitration": true,
		"captures": _captures,
	}
	var file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if file == null:
		_fail("Could not write P16 render report")
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("[P16_MEMORY_DISCLOSURE_RENDER] PASS: %s" % OUTPUT_DIR)
	_scene.queue_free()
	await process_frame
	quit(0)
