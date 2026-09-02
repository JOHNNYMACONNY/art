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
	var pursuer := _scene.get_node_or_null("PursuerPrototype")
	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	var scrapper := _scene.get_node_or_null("GearsScrapperToolRuntime")
	var authority = _runtime.get("wanted_authority")
	if touch_ui == null or player == null or pursuer == null or alarm == null or authority == null:
		await _fail("Retained input/player/Wanted fixture is missing")
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

	# Full Replay restores the P05 pickup/possession/UI state through the retained signal.
	touch_ui.replay_pressed.emit()
	await process_frame
	if bool(scrapper.call("has_tool")) or tool_button.visible or bool(pickup.call("is_acquired")):
		await _fail("Replay did not restore Scrapper pickup/possession/UI state")
		return

	# Reacquire and establish real Wanted before testing P05-local reset independence.
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	if not bool(scrapper.call("acquire_active_pickup")):
		await _fail("Could not reacquire Scrapper for local reset contract")
		return
	alarm.set("report_enabled", true)
	alarm.call("reset_alarm")
	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	_scene.set("_active_target", alarm)
	if not bool(_runtime.call("handle_action_pressed")):
		await _fail("Could not establish Heat 1 for local reset contract")
		return
	if int(authority.call("get_heat_level")) != 1 or String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("Local reset fixture did not establish Heat 1 + Contact")
		return
	if not bool(pursuer.call("apply_scrapper_stagger", Vector3.FORWARD)):
		await _fail("Local reset fixture could not establish temporary Scrapper stagger")
		return
	if not bool(scrapper.call("_force_access_open")):
		await _fail("Local reset fixture could not force the authored service access")
		return

	var preserved_pursuer_state := int(pursuer.get("current_state"))
	var preserved_target: Node = pursuer.get("target_node")
	var preserved_reason := String(authority.call("get_last_reason"))
	var preserved_known_position := Vector3(authority.call("get_last_known_position"))
	scrapper.call("reset_runtime")
	await physics_frame
	if bool(scrapper.call("has_tool")) or bool(pickup.call("is_acquired")) or tool_button.visible:
		await _fail("P05-local reset left stale possession/pickup/UI state")
		return
	if String(scrapper.call("get_access_state_name")) != "JAMMED" or not bool(scrapper.call("is_service_access_blocking")):
		await _fail("P05-local reset did not restore the jammed service access")
		return
	if bool(scrapper.call("is_swing_active")) or int(scrapper.call("get_contact_evaluation_count")) != 0 or String(scrapper.call("get_last_contact_name")) != "NONE":
		await _fail("P05-local reset left stale swing/contact state")
		return
	if bool(pursuer.call("is_scrapper_staggered")):
		await _fail("P05-local reset left stale Scrapper pursuer stagger")
		return
	if int(pursuer.get("current_state")) != preserved_pursuer_state or pursuer.get("target_node") != preserved_target or not bool(pursuer.get("is_active")):
		await _fail("P05-local reset mutated retained pursuer authority/state")
		return
	if int(authority.call("get_heat_level")) != 1 or String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("P05-local reset cleared or changed Wanted authority")
		return
	if String(authority.call("get_last_reason")) != preserved_reason or Vector3(authority.call("get_last_known_position")).distance_to(preserved_known_position) > 0.001:
		await _fail("P05-local reset changed retained Contact knowledge")
		return

	print("[GEARS_SCRAPPER_TOOL_INPUT] PASS")
	await _finish(0)
