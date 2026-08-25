extends SceneTree

# Exercises actual Viewport -> Control GUI routing, not direct method calls.
const TouchSteeringConditioningContract = preload("res://tests/touch_steering_conditioning_contract_test.gd")
const MissionScrapJobContract = preload("res://tests/mission_scrap_job_contract_test.gd")

var _last_joystick_vector := Vector2.ZERO
var _scene_under_test: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[MOBILE_TOUCH_ROUTING] %s" % message)
	await _finish(1)

func _run() -> void:
	var steering_error: String = TouchSteeringConditioningContract.verify()
	if not steering_error.is_empty():
		await _fail("CTW Feel 02: %s" % steering_error)
		return

	var mission_error: String = MissionScrapJobContract.verify()
	if not mission_error.is_empty():
		await _fail("Mission/Narrative 01: %s" % mission_error)
		return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	await process_frame

	var touch_ui := _scene_under_test.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := _scene_under_test.get_node_or_null("Runner")
	if touch_ui == null or player == null:
		await _fail("Main scene is missing TouchControlsUI or Runner")
		return

	# Mission/Narrative 01 is deliberately attached to the production scene and
	# must share the established safe-area root instead of creating a parallel UI.
	var runtime := _scene_under_test.get_node_or_null("MissionScrapJobRuntime")
	if runtime == null or not bool(runtime.get("_bound")):
		await _fail("Mission/Narrative 01 runtime did not bind to retained gameplay systems")
		return
	var safe_root := touch_ui.get_node_or_null("SafeAreaRoot")
	var mission_hud := safe_root.get_node_or_null("MissionHUD") if safe_root != null else null
	if mission_hud == null:
		await _fail("Mission/Narrative 01 HUD is not rooted inside the established safe area")
		return
	var margin := mission_hud.find_child("MissionMargin", true, false) as Control
	var stack := mission_hud.find_child("MissionStack", true, false) as Control
	var title := mission_hud.find_child("MissionTitle", true, false) as Label
	var objective := mission_hud.find_child("ObjectiveLabel", true, false) as Label
	var contact := mission_hud.find_child("ContactLabel", true, false) as Label
	if margin == null or stack == null or title == null or objective == null or contact == null:
		await _fail("Mission/Narrative 01 HUD is missing required authored controls")
		return
	for hud_control in [mission_hud, margin, stack, title, objective, contact]:
		if hud_control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			await _fail("Mission/Narrative 01 HUD contains a control that can steal gameplay touch input")
			return
	if "COURIER BIKE" not in objective.text or not contact.text.begins_with("LIRA //"):
		await _fail("Mission/Narrative 01 cold-start briefing is not visible in the production scene")
		return
	var bike = _scene_under_test.get("courier_bike")
	if bike == null or not bike.mounted.is_connected(Callable(runtime, "_on_courier_bike_mounted")):
		await _fail("Retained Courier Bike mounted signal is not connected to the authored mission runtime")
		return

	touch_ui.joystick_vector_updated.connect(func(vec: Vector2): _last_joystick_vector = vec)
	var start_position: Vector3 = player.global_position

	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 7
	touch_down.pressed = true
	touch_down.position = Vector2(140, 390)
	root.push_input(touch_down, true)
	await process_frame

	# Keep the drag inside the now-visible 120px joystick base. This verifies
	# that the passive joystick artwork cannot steal the active touch stream.
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 7
	touch_drag.position = Vector2(180, 390)
	touch_drag.relative = Vector2(40, 0)
	root.push_input(touch_drag, true)
	await process_frame
	for _frame in range(4):
		await physics_frame

	if _last_joystick_vector.length() <= 0.05:
		await _fail("A left-half touch drag did not reach the floating joystick through the real Viewport GUI route")
		return
	if player.joystick_vector.length() <= 0.05:
		await _fail("Joystick signal did not reach PlayerRunner")
		return

	var horizontal_displacement := Vector2(
		player.global_position.x - start_position.x,
		player.global_position.z - start_position.z
	).length()
	if horizontal_displacement <= 0.01:
		await _fail("Touch joystick reached PlayerRunner but did not move the character in world space")
		return

	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 7
	touch_up.pressed = false
	touch_up.position = Vector2(180, 390)
	root.push_input(touch_up, true)
	await process_frame

	if player.joystick_vector.length() > 0.001:
		await _fail("Joystick release did not clear PlayerRunner input")
		return

	print("[MISSION_NARRATIVE_01] CONTRACT + RUNTIME WIRING PASS")
	print("[MOBILE_TOUCH_ROUTING] PASS")
	await _finish(0)
