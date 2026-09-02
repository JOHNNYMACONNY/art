extends SceneTree

var _scene: Node = null
var _runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _runtime != null:
		_runtime.call("reset_runtime")
	quit(code)

func _fail(message: String) -> void:
	push_error("[GEARS_SCRAPPER_TOOL_INPUT] %s" % message)
	await _finish(1)

func _run() -> void:
	_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _runtime == null:
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
	await process_frame
	if not bool(_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to production scene")
		return

	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := _scene.get_node_or_null("Runner") as Node3D
	var scrapper := _scene.get_node_or_null("GearsScrapperToolRuntime")
	if touch_ui == null or player == null:
		await _fail("Retained input/player fixture is missing")
		return
	if not touch_ui.has_signal("tool_action_pressed"):
		await _fail("Production 05 dedicated Tool Action is absent")
		return
	var tool_button := touch_ui.get_node_or_null("SafeAreaRoot/RightTouchArea/ToolActionButton") as Button
	if tool_button == null:
		await _fail("Tool Action touch button is absent")
		return
	if scrapper == null:
		await _fail("Production 05 Scrapper runtime is absent")
		return
	if bool(scrapper.call("has_tool")):
		await _fail("Scrapper Tool started already held")
		return

	var pickup := scrapper.call("get_pickup") as Node3D
	if pickup == null:
		await _fail("Scrapper Tool pickup was not mounted")
		return
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	if not bool(scrapper.call("acquire_active_pickup")) or not bool(scrapper.call("has_tool")):
		await _fail("Contextual Scrapper Tool pickup did not acquire")
		return
	if not tool_button.visible or tool_button.disabled:
		await _fail("Held Scrapper Tool did not expose available Tool Action")
		return

	var counts := {"action": 0, "tool": 0}
	touch_ui.action_button_pressed.connect(func(): counts.action += 1)
	touch_ui.tool_action_pressed.connect(func(): counts.tool += 1)
	touch_ui.call("trigger_tool_action")
	await process_frame
	if int(counts.tool) != 1 or int(counts.action) != 0:
		await _fail("Tool press double-fired or synthesized generic Action")
		return
	if bool(touch_ui.call("is_pointer_index_claimed", 17)):
		await _fail("Tool press leaked touch pointer ownership")
		return

	scrapper.call("reset_runtime")
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	touch_ui.call("trigger_action")
	await process_frame
	if not bool(scrapper.call("has_tool")):
		await _fail("Pickup did not use retained contextual Action")
		return
	if int(counts.action) != 1 or int(counts.tool) != 1:
		await _fail("Contextual pickup Action polluted Tool signal ownership")
		return

	touch_ui.call("set_mode", TouchControlsUI.UIMode.VEHICLE_DRIVING)
	if tool_button.visible:
		await _fail("Tool Action remained visible while mounted/driving")
		return
	touch_ui.call("trigger_tool_action")
	await process_frame
	if int(counts.tool) != 1:
		await _fail("Vehicle mode accepted Tool Action")
		return
	touch_ui.call("set_mode", TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	if not tool_button.visible:
		await _fail("Returning on foot did not restore held Tool Action availability")
		return

	touch_ui.replay_pressed.emit()
	await process_frame
	if bool(scrapper.call("has_tool")) or tool_button.visible or bool(pickup.call("is_acquired")):
		await _fail("Replay did not restore Scrapper pickup/possession/UI state")
		return

	print("[GEARS_SCRAPPER_TOOL_INPUT] PASS")
	await _finish(0)
