extends SceneTree

const OUTPUT_DIR := "res://verification/wanted"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

var _scene: Node3D = null
var _runtime: Node = null
var _player: Node3D = null
var _pursuer: Node3D = null
var _camera: Camera3D = null
var _alarm: Node = null
var _report_access: Node = null
var _touch_ui: Node = null
var _label: Label = null
var _access_label: Label3D = null
var _alarm_label: Label3D = null
var _authority = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[WANTED_HEAT1_RENDER] %s" % message)
	quit(1)

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

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Could not load real playable scene")
		return
	_scene = packed.instantiate() as Node3D
	if _scene == null:
		_fail("Could not instantiate real playable scene")
		return
	root.add_child(_scene)
	await process_frame
	await physics_frame
	_runtime.call("bind_to_scene", _scene)
	await process_frame

	_player = _scene.get_node_or_null("Runner") as Node3D
	_pursuer = _scene.get_node_or_null("PursuerPrototype") as Node3D
	_camera = _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	_alarm = _scene.get_node_or_null("CivicServiceAlarm")
	_report_access = _scene.get_node_or_null("CivicReportAccess")
	_touch_ui = _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	_label = _scene.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label
	_access_label = _report_access.get_node_or_null("StatusLabel") as Label3D if _report_access != null else null
	_alarm_label = _alarm.get_node_or_null("StatusLabel") as Label3D if _alarm != null else null
	_authority = _runtime.get("wanted_authority")
	if _player == null or _pursuer == null or _camera == null or _alarm == null or _report_access == null or _touch_ui == null or _label == null or _access_label == null or _alarm_label == null or _authority == null:
		_fail("Rendered proof is missing a production dependency")
		return

	# CONTACT: trigger the actual interaction through retained target selection + action signal.
	_player.global_position = _alarm.global_position + Vector3(0.8, 0.0, 0.0)
	_alarm.call("update_player_distance", _player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != _alarm:
		_fail("Civic alarm is not selectable through retained interaction arbitration")
		return
	_touch_ui.action_button_pressed.emit()
	if int(_authority.call("get_heat_level")) != 1 or String(_authority.call("get_wanted_state_name")) != "CONTACT":
		_fail("Rendered Contact setup did not produce Heat 1 + Contact")
		return
	_camera.call("reset_camera_instant", _player)
	var capture_error := await _capture("01_report_contact.png", "CONTACT")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# SEARCH: use real commercial frontage to break direct observation.
	_pursuer.global_position = Vector3(-4.5, 0.6, -35.0)
	_player.global_position = Vector3(-17.0, 0.1, -35.0)
	for _i in range(3):
		_runtime.call("process_wanted", 0.4)
	if String(_authority.call("get_wanted_state_name")) != "SEARCH":
		_fail("Rendered Search setup did not enter SEARCH")
		return
	_camera.call("reset_camera_instant", _player)
	capture_error = await _capture("02_search_last_known.png", "SEARCH")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# EVADED: prove the same scene returns to quiet free roam.
	_runtime.call("process_wanted", 7.0)
	if int(_authority.call("get_heat_level")) != 0 or String(_authority.call("get_wanted_state_name")) != "CLEAR" or _label.visible:
		_fail("Rendered Evasion setup did not return to quiet CLEAR state")
		return
	_camera.call("reset_camera_instant", _player)
	capture_error = await _capture("03_evaded_clear.png", "CLEAR")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# FIELD HACKING: physically reach the local service tap through retained arbitration.
	_runtime.call("reset_runtime")
	_player.global_position = _report_access.global_position + Vector3(0.8, 0.0, 0.0)
	_report_access.call("update_player_distance", _player.global_position)
	_alarm.call("update_player_distance", _player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != _report_access:
		_fail("Physical civic service tap is not selectable through retained interaction arbitration")
		return
	_touch_ui.action_button_pressed.emit()
	if bool(_alarm.get("report_enabled")) or not _access_label.text.contains("REPORT LINK JAMMED"):
		_fail("Rendered Field Hacking setup did not compromise the local Report link")
		return

	# Trigger the same incident while compromised. The alarm faults locally and Wanted stays quiet.
	_player.global_position = _alarm.global_position + Vector3(0.8, 0.0, 0.0)
	_alarm.call("update_player_distance", _player.global_position)
	_report_access.call("update_player_distance", _player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != _alarm:
		_fail("Compromised civic alarm is not selectable through retained interaction arbitration")
		return
	_touch_ui.action_button_pressed.emit()
	if int(_authority.call("get_heat_level")) != 0 or String(_authority.call("get_wanted_state_name")) != "CLEAR" or _label.visible:
		_fail("Compromised civic Report incorrectly created Wanted state")
		return
	if not _alarm_label.text.contains("ALARM FAULT"):
		_fail("Compromised civic incident lacks readable local fault feedback")
		return
	_player.global_position = (_alarm.global_position + _report_access.global_position) * 0.5 + Vector3(0.8, 0.0, 0.0)
	_camera.call("reset_camera_instant", _player)
	capture_error = await _capture("04_field_hack_report_suppressed.png", "REPORT_SUPPRESSED")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# RECOVERY: replay restores service and the same incident creates ordinary Heat 1 again.
	_runtime.call("reset_runtime")
	if not bool(_alarm.get("report_enabled")) or not _access_label.text.contains("SERVICE TAP"):
		_fail("Rendered recovery did not restore civic reporting service")
		return
	_player.global_position = _alarm.global_position + Vector3(0.8, 0.0, 0.0)
	_alarm.call("update_player_distance", _player.global_position)
	_report_access.call("update_player_distance", _player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != _alarm:
		_fail("Restored civic alarm is not selectable through retained interaction arbitration")
		return
	_touch_ui.action_button_pressed.emit()
	if int(_authority.call("get_heat_level")) != 1 or String(_authority.call("get_wanted_state_name")) != "CONTACT":
		_fail("Restored civic Report path did not create Heat 1 + Contact")
		return
	_camera.call("reset_camera_instant", _player)
	capture_error = await _capture("05_restored_report_contact.png", "CONTACT_RESTORED")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	_runtime.call("reset_runtime")
	if int(_authority.call("get_heat_level")) != 0 or String(_authority.call("get_wanted_state_name")) != "CLEAR" or _label.visible:
		_fail("Rendered proof cleanup did not restore quiet CLEAR state")
		return

	var report := {
		"schema_version": 2,
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"real_playable_scene": true,
		"field_hacking_access_path": "CivicReportAccess",
		"captures": _captures,
		"final_heat": int(_authority.call("get_heat_level")),
		"final_state": String(_authority.call("get_wanted_state_name")),
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write rendered verification report")
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()

	print("[WANTED_HEAT1_RENDER] PASS: %s" % OUTPUT_DIR)
	_scene.queue_free()
	await process_frame
	quit(0)

func _capture(file_name: String, expected_state: String) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var path := OUTPUT_DIR + "/" + file_name
	var save_error: Error = image.save_png(path)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]
	_captures.append({
		"file": file_name,
		"state": expected_state,
		"heat": int(_authority.call("get_heat_level")),
		"hud_visible": _label.visible,
		"hud_text": _label.text,
		"access_text": _access_label.text,
		"alarm_text": _alarm_label.text,
		"report_enabled": bool(_alarm.get("report_enabled")),
		"player_position": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
		"pursuer_position": [_pursuer.global_position.x, _pursuer.global_position.y, _pursuer.global_position.z],
	})
	return ""
