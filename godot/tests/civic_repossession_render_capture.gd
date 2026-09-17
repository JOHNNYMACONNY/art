extends SceneTree

const OUTPUT_DIR := "res://verification/production03"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")

var _runtime: Node = null
var _scene: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[CIVIC_REPOSSESSION_RENDER] %s" % message)
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

func _complete_mission_one(scene: Node) -> String:
	var mission_one_runtime := scene.get_node_or_null("MissionScrapJobRuntime")
	var civic_runtime := scene.get_node_or_null("CivicRepossessionRuntime")
	var tuner = scene.get("signal_tuner")
	var panel = scene.get("corroded_panel")
	if mission_one_runtime == null or civic_runtime == null or tuner == null or panel == null:
		return "Mission fixture dependencies are missing"
	tuner.set("current_state", SignalTuner.TunerState.LOCKED)
	panel.set("current_step", CorrodedPanel.Step.EXTRACTED)
	var mission = mission_one_runtime.mission
	if mission.phase == ScrapJobMissionScript.Phase.BRIEFING:
		mission.start()
	if mission.phase == ScrapJobMissionScript.Phase.GET_BIKE:
		mission.on_courier_bike_mounted()
	if mission.phase == ScrapJobMissionScript.Phase.TRAVERSE_TO_TUNER:
		mission.on_tuner_arrived()
	if mission.phase == ScrapJobMissionScript.Phase.SPOOF_SIGNAL:
		mission.on_signal_locked()
	if mission.phase == ScrapJobMissionScript.Phase.EXTRACT_CORE:
		mission.on_core_extracted()
	if mission.phase == ScrapJobMissionScript.Phase.PURSUIT_COMPLICATION:
		mission.on_pursuit_active()
	if mission.phase == ScrapJobMissionScript.Phase.ROUTE_DECISION:
		mission.on_escape_complete()
	if mission.phase != ScrapJobMissionScript.Phase.COMPLETE:
		return "Mission 01 fixture could not complete"
	mission_one_runtime.call("_refresh_hud")
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.GET_HAULER:
		return "Mission 02 did not unlock"
	return ""

func _mission_ui(scene: Node) -> Dictionary:
	var hud := scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/MissionHUD")
	if hud == null:
		return {}
	return {
		"title": hud.find_child("MissionTitle", true, false) as Label,
		"objective": hud.find_child("ObjectiveLabel", true, false) as Label,
		"contact": hud.find_child("ContactLabel", true, false) as Label,
		"wanted": scene.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label,
	}

func _capture(file_name: String, scene: Node, labels: Dictionary, access: Node, alarm: Node, expected_outcome: String) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var save_error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]
	var access_label := access.get_node_or_null("StatusLabel") as Label3D
	var alarm_label := alarm.get_node_or_null("StatusLabel") as Label3D
	var wanted_label := labels["wanted"] as Label
	var title := labels["title"] as Label
	var objective := labels["objective"] as Label
	var contact := labels["contact"] as Label
	_captures.append({
		"file": file_name,
		"outcome": expected_outcome,
		"legacy_pursuit_state": int(scene.get("current_pursuit_state")),
		"heat": int(_runtime.call("get_heat_level")),
		"wanted_state": String(_runtime.call("get_wanted_state_name")),
		"wanted_visible": wanted_label.visible,
		"wanted_text": wanted_label.text,
		"mission_title": title.text,
		"objective": objective.text,
		"contact": contact.text,
		"access_text": access_label.text if access_label != null else "",
		"alarm_text": alarm_label.text if alarm_label != null else "",
		"report_enabled": bool(alarm.get("report_enabled")),
	})
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

	# LIVE REPORT: Mission 02 shares the ordinary Heat-1 authority while the
	# historical mission pursuit stays CALM.
	var live_scene := await _fresh_scene()
	if live_scene == null:
		_fail("Could not load/bind live-report production scene")
		return
	var setup_error := await _complete_mission_one(live_scene)
	if not setup_error.is_empty():
		_fail(setup_error)
		return
	var live_civic := live_scene.get_node_or_null("CivicRepossessionRuntime")
	var live_hauler = live_scene.get("scrap_hauler")
	var live_player := live_scene.get_node_or_null("Runner") as Node3D
	var live_alarm := live_scene.get_node_or_null("CivicServiceAlarm")
	var live_access := live_scene.get_node_or_null("CivicReportAccess")
	var live_camera := live_scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	var live_labels := _mission_ui(live_scene)
	if live_civic == null or live_hauler == null or live_player == null or live_alarm == null or live_access == null or live_camera == null or live_labels.is_empty():
		_fail("Live-report render fixture is incomplete")
		return
	live_hauler.global_position = live_alarm.global_position + Vector3(2.0, 0.0, 0.0)
	live_player.global_position = live_alarm.global_position + Vector3(0.8, 0.0, 0.0)
	live_hauler.mounted.emit(live_player)
	await process_frame
	if live_civic.mission.phase != CivicMissionScript.Phase.ESCAPE \
	or int(_runtime.call("get_heat_level")) != 1 \
	or String(_runtime.call("get_wanted_state_name")) != "CONTACT" \
	or int(live_scene.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.CALM):
		_fail("Live-report Mission 02 render state is incorrect")
		return
	var live_wanted := live_labels["wanted"] as Label
	var live_objective := live_labels["objective"] as Label
	if not live_wanted.visible or not live_wanted.text.contains("HEAT 1") or not live_objective.text.contains("LOSE THE PURSUER"):
		_fail("Live-report Mission/Wanted HUD is not readable")
		return
	live_camera.call("reset_camera_instant", live_player)
	var capture_error := await _capture("01_mission02_report_sent_contact.png", live_scene, live_labels, live_access, live_alarm, "REPORT_SENT_CONTACT")
	if not capture_error.is_empty():
		_fail(capture_error)
		return

	# JAMMED REPORT: physically use the local service access, then take the same
	# Hauler. The local alarm faults, Wanted stays quiet, and Mission 02 exposes the
	# clean-delivery objective immediately.
	var quiet_scene := await _fresh_scene()
	if quiet_scene == null:
		_fail("Could not load/bind clean-take production scene")
		return
	setup_error = await _complete_mission_one(quiet_scene)
	if not setup_error.is_empty():
		_fail(setup_error)
		return
	var quiet_civic := quiet_scene.get_node_or_null("CivicRepossessionRuntime")
	var quiet_hauler = quiet_scene.get("scrap_hauler")
	var quiet_player := quiet_scene.get_node_or_null("Runner") as Node3D
	var quiet_alarm := quiet_scene.get_node_or_null("CivicServiceAlarm")
	var quiet_access := quiet_scene.get_node_or_null("CivicReportAccess")
	var quiet_camera := quiet_scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	var quiet_labels := _mission_ui(quiet_scene)
	if quiet_civic == null or quiet_hauler == null or quiet_player == null or quiet_alarm == null or quiet_access == null or quiet_camera == null or quiet_labels.is_empty():
		_fail("Clean-take render fixture is incomplete")
		return
	quiet_player.global_position = quiet_access.global_position + Vector3(0.8, 0.0, 0.0)
	quiet_access.call("update_player_distance", quiet_player.global_position)
	quiet_scene.set("_active_target", quiet_access)
	if not bool(_runtime.call("handle_action_pressed")) or bool(quiet_alarm.get("report_enabled")):
		_fail("Clean-take render fixture could not jam the local Report link")
		return
	quiet_hauler.global_position = quiet_alarm.global_position + Vector3(2.0, 0.0, 0.0)
	quiet_hauler.mounted.emit(quiet_player)
	await process_frame
	if quiet_civic.mission.phase != CivicMissionScript.Phase.DELIVERY \
	or int(_runtime.call("get_heat_level")) != 0 \
	or String(_runtime.call("get_wanted_state_name")) != "CLEAR" \
	or int(quiet_scene.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.CALM):
		_fail("Clean-take Mission 02 render state is incorrect")
		return
	var quiet_wanted := quiet_labels["wanted"] as Label
	var quiet_objective := quiet_labels["objective"] as Label
	var quiet_access_label := quiet_access.get_node_or_null("StatusLabel") as Label3D
	var quiet_alarm_label := quiet_alarm.get_node_or_null("StatusLabel") as Label3D
	if quiet_wanted.visible \
	or not quiet_objective.text.contains("CLEAN TAKE") \
	or quiet_access_label == null or not quiet_access_label.text.contains("REPORT LINK JAMMED") \
	or quiet_alarm_label == null or not quiet_alarm_label.text.contains("ALARM FAULT"):
		_fail("Clean-take Mission/civic feedback is not readable")
		return
	quiet_player.global_position = (quiet_alarm.global_position + quiet_access.global_position) * 0.5 + Vector3(0.8, 0.0, 0.0)
	quiet_camera.call("reset_camera_instant", quiet_player)
	capture_error = await _capture("02_mission02_report_suppressed_clean_take.png", quiet_scene, quiet_labels, quiet_access, quiet_alarm, "REPORT_SUPPRESSED_CLEAN_TAKE")
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
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write Production 03 render report")
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()

	print("[CIVIC_REPOSSESSION_RENDER] PASS: %s" % OUTPUT_DIR)
	await _free_scene()
	quit(0)