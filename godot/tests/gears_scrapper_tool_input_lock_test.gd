extends SceneTree

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	quit(code)

func _fail(message: String) -> void:
	push_error("[GEARS_SCRAPPER_TOOL_INPUT_LOCK] %s" % message)
	await _finish(1)

func _run() -> void:
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to production scene")
		return

	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := _scene.get_node_or_null("Runner") as Node3D
	var scrapper := _scene.get_node_or_null("GearsScrapperToolRuntime")
	if touch_ui == null or player == null or scrapper == null:
		await _fail("Production input/player/Scrapper fixture is incomplete")
		return
	var tool_button := touch_ui.get_node_or_null("SafeAreaRoot/RightTouchArea/ToolActionButton") as Button
	var gesture_panel := touch_ui.get_node_or_null("SafeAreaRoot/GestureOverlayPanel") as Control
	if tool_button == null or gesture_panel == null:
		await _fail("Retained Tool/gesture UI fixture is incomplete")
		return

	var pickup := scrapper.call("get_pickup") as Node3D
	if pickup == null:
		await _fail("Scrapper pickup is missing")
		return
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	if not bool(scrapper.call("acquire_active_pickup")):
		await _fail("Could not acquire Scrapper for input-lock contract")
		return
	if not tool_button.visible or tool_button.disabled:
		await _fail("Held Scrapper did not expose Tool Action before retained input lock")
		return

	var counts := {"tool": 0, "action": 0}
	touch_ui.tool_action_pressed.connect(func(): counts.tool += 1)
	touch_ui.action_button_pressed.connect(func(): counts.action += 1)

	# A real retained gesture overlay owns interaction input. P05 must yield fully:
	# touch affordance hidden/disabled, touch and desktop signal routes suppressed,
	# and the runtime's direct seam fail-closed as defense in depth.
	touch_ui.call("show_gesture_overlay", "TUNE_SIGNAL")
	await process_frame
	if not gesture_panel.visible:
		await _fail("Retained TUNE_SIGNAL gesture overlay did not become active")
		return
	if tool_button.visible or not tool_button.disabled:
		await _fail("Tool Action stayed available while retained gesture/input lock owned interaction")
		return

	touch_ui.call("trigger_tool_action")
	await process_frame
	if int(counts.tool) != 0 or int(counts.action) != 0:
		await _fail("Touch Tool Action emitted while retained gesture/input lock owned interaction")
		return

	var key_f := InputEventKey.new()
	key_f.pressed = true
	key_f.keycode = KEY_F
	key_f.physical_keycode = KEY_F
	touch_ui.call("_input", key_f)
	await process_frame
	if int(counts.tool) != 0 or int(counts.action) != 0:
		await _fail("Desktop F Tool Action emitted while retained gesture/input lock owned interaction")
		return

	if bool(scrapper.call("handle_tool_action_pressed")):
		await _fail("Scrapper runtime accepted direct Tool Action while retained gesture/input lock owned interaction")
		return
	if bool(scrapper.call("is_swing_active")):
		await _fail("Input-locked Tool Action started a swing")
		return

	# Releasing the retained lock restores the held on-foot Tool affordance and
	# exactly one dedicated Tool signal without synthesizing generic Action.
	touch_ui.call("close_interaction_overlay")
	await process_frame
	if gesture_panel.visible:
		await _fail("Retained gesture overlay did not close")
		return
	if not tool_button.visible or tool_button.disabled:
		await _fail("Tool Action did not restore after retained gesture/input lock released")
		return
	touch_ui.call("trigger_tool_action")
	await process_frame
	if int(counts.tool) != 1 or int(counts.action) != 0:
		await _fail("Restored Tool Action did not emit exactly one dedicated Tool signal")
		return

	print("[GEARS_SCRAPPER_TOOL_INPUT_LOCK] PASS")
	await _finish(0)
