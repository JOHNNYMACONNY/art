extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const AUTO_TEST_PATH := "user://tests/p06_gears_surveyed_service_cut_input_test.json"

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _remove_test_progress() -> void:
	if FileAccess.file_exists(AUTO_TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTO_TEST_PATH))

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	_remove_test_progress()
	quit(code)

func _fail(message: String) -> void:
	push_error("[GEARS_SURVEYED_SERVICE_CUT_INPUT] %s" % message)
	await _finish(1)

func _press_m(touch_ui: Node, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_M
	event.physical_keycode = KEY_M
	event.pressed = true
	event.echo = echo
	touch_ui.call("_input", event)

func _acquire_tool(scene: Node, player: Node3D, scrapper: Node) -> bool:
	var pickup := scrapper.call("get_pickup") as Node3D
	if pickup == null:
		return false
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	scene.set("_active_target", pickup)
	return bool(scrapper.call("acquire_active_pickup"))

func _rect_contains_rect(outer: Rect2, inner: Rect2) -> bool:
	return outer.has_point(inner.position) and outer.has_point(inner.position + inner.size)

func _run() -> void:
	_remove_test_progress()
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to production scene")
		return

	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := _scene.get_node_or_null("Runner") as Node3D
	var scrapper := _scene.get_node_or_null("GearsScrapperToolRuntime")
	var survey := _scene.get_node_or_null("GearsSurveyedServiceCutRuntime")
	if touch_ui == null or player == null or scrapper == null:
		await _fail("Retained input/player/P05 fixture is incomplete")
		return
	if survey == null:
		await _fail("Production 06 surveyed-route runtime is absent")
		return
	if not touch_ui.has_signal("map_action_pressed") or not touch_ui.has_method("trigger_map_action") or not touch_ui.has_method("set_map_modal_active"):
		await _fail("Production 06 dedicated Map input seam is absent")
		return

	var map_button := survey.call("get_map_button") as Button
	var route_sheet := survey.call("get_route_sheet") as Control
	var tool_button := touch_ui.get_node_or_null("SafeAreaRoot/RightTouchArea/ToolActionButton") as Button
	if map_button == null or map_button.get_parent() == null or String(map_button.get_parent().name) != "RightTouchArea":
		await _fail("Safe-area touch Map control is absent or mounted outside RightTouchArea")
		return
	if route_sheet == null or not route_sheet.has_method("is_service_cut_visible") or not route_sheet.has_method("get_access_status_text"):
		await _fail("Bounded Gears local route sheet is absent")
		return
	if tool_button == null or not _acquire_tool(_scene, player, scrapper):
		await _fail("Could not establish retained held-Tool fixture")
		return
	if not tool_button.visible:
		await _fail("Held Tool Action was not available before Map ownership test")
		return

	var counts := {"action": 0, "tool": 0, "map": 0}
	touch_ui.action_button_pressed.connect(func(): counts.action += 1)
	touch_ui.tool_action_pressed.connect(func(): counts.tool += 1)
	touch_ui.map_action_pressed.connect(func(): counts.map += 1)

	# Real touch control toggles one modal transition and reveals no unearned route geometry.
	map_button.pressed.emit()
	await process_frame
	if int(counts.map) != 1 or not bool(survey.call("is_map_open")):
		await _fail("Touch Map did not open exactly once")
		return
	if not bool(player.get("is_input_locked")) or not bool(touch_ui.call("is_map_modal_active")):
		await _fail("Map modal did not own locomotion/input")
		return
	if bool(route_sheet.call("is_service_cut_visible")) or String(route_sheet.call("get_access_status_text")) != "UNKNOWN ROUTE":
		await _fail("Pre-survey route sheet exposed unearned service-cut knowledge")
		return

	# Programmatic and UI-equivalent Action/Tool paths are suppressed while the modal owns input.
	touch_ui.call("trigger_action")
	touch_ui.call("trigger_tool_action")
	await process_frame
	if int(counts.action) != 0 or int(counts.tool) != 0:
		await _fail("Map modal leaked generic Action or Tool Action")
		return
	if tool_button.visible:
		await _fail("Tool Action remained interactable through the Map modal")
		return

	map_button.pressed.emit()
	await process_frame
	if int(counts.map) != 2 or bool(survey.call("is_map_open")) or bool(player.get("is_input_locked")) or bool(touch_ui.call("is_map_modal_active")):
		await _fail("Touch Map close did not restore prior input ownership exactly once")
		return
	if not tool_button.visible:
		await _fail("Closing Map did not restore the held Tool Action")
		return
	touch_ui.call("trigger_action")
	touch_ui.call("trigger_tool_action")
	await process_frame
	if int(counts.action) != 1 or int(counts.tool) != 1:
		await _fail("Dedicated actions did not restore cleanly after Map close")
		return

	# Retained gesture ownership suppresses Map before it can emit/open.
	var map_before_lock := int(counts.map)
	touch_ui.call("show_gesture_overlay", "PEEL_PANEL")
	touch_ui.call("trigger_map_action")
	await process_frame
	if bool(survey.call("is_map_open")) or int(counts.map) != map_before_lock:
		await _fail("Retained gesture/input lock accepted Map")
		return
	touch_ui.call("close_interaction_overlay")

	# A pre-existing player input lock cannot be stolen by Map.
	player.set("is_input_locked", true)
	touch_ui.call("trigger_map_action")
	await process_frame
	if bool(survey.call("is_map_open")):
		await _fail("Map opened while another runtime owned player input")
		return
	player.set("is_input_locked", false)

	# Vehicle mode suppresses both desktop/touch Map availability.
	touch_ui.call("set_mode", TouchControlsUI.UIMode.VEHICLE_DRIVING)
	var map_before_drive := int(counts.map)
	touch_ui.call("trigger_map_action")
	_press_m(touch_ui)
	await process_frame
	if bool(survey.call("is_map_open")) or int(counts.map) != map_before_drive or map_button.visible:
		await _fail("Driving mode accepted or exposed Map")
		return
	touch_ui.call("set_mode", TouchControlsUI.UIMode.FOOT_TRAVERSAL)

	# Desktop M toggles exactly once per non-echo press; echo cannot double-fire.
	var map_before_desktop := int(counts.map)
	_press_m(touch_ui)
	await process_frame
	if not bool(survey.call("is_map_open")) or int(counts.map) != map_before_desktop + 1:
		await _fail("Desktop M did not open Map exactly once")
		return
	_press_m(touch_ui, true)
	await process_frame
	if not bool(survey.call("is_map_open")) or int(counts.map) != map_before_desktop + 1:
		await _fail("Desktop key echo double-fired Map")
		return
	_press_m(touch_ui)
	await process_frame
	if bool(survey.call("is_map_open")) or int(counts.map) != map_before_desktop + 2:
		await _fail("Desktop M did not close Map exactly once")
		return

	# Learned geography and current P05 access are separate presentation truths.
	var store = survey.call("get_progress_store")
	if store == null or not bool(store.call("mark_surveyed", String(survey.call("get_route_id")))):
		await _fail("Could not establish known-route presentation fixture")
		return
	var writes_before_access_change := int(store.call("get_write_count"))
	touch_ui.call("trigger_map_action")
	await process_frame
	if not bool(route_sheet.call("is_service_cut_visible")) or String(route_sheet.call("get_access_status_text")) != "KNOWN · ACCESS JAMMED":
		await _fail("Surveyed + JAMMED did not present as known-but-blocked")
		return
	if not bool(scrapper.call("_force_access_open")):
		await _fail("Could not force known route open for access presentation")
		return
	survey.call("refresh_map_presentation")
	await process_frame
	if String(route_sheet.call("get_access_status_text")) != "KNOWN · ACCESS OPEN":
		await _fail("Known route did not reflect current FORCED_OPEN physical access")
		return
	if int(store.call("get_write_count")) != writes_before_access_change:
		await _fail("Physical access change rewrote mapped knowledge")
		return
	touch_ui.call("trigger_map_action")
	await process_frame

	# Safe-area layout keeps the small Map control inside the resolved canvas-safe rectangle.
	touch_ui.call("set_simulated_safe_area", Rect2i(100, 60, 1720, 900), Vector2i(1920, 1080))
	await process_frame
	await process_frame
	var safe_rect := touch_ui.call("get_resolved_safe_rect") as Rect2
	var button_rect := map_button.get_global_rect()
	if not _rect_contains_rect(safe_rect, button_rect):
		await _fail("Map control escaped the resolved mobile safe area")
		return

	print("[GEARS_SURVEYED_SERVICE_CUT_INPUT] PASS")
	await _finish(0)
