extends SceneTree

# Exercises actual Viewport -> Control GUI routing, not direct method calls.
const TouchSteeringConditioningContract = preload("res://tests/touch_steering_conditioning_contract_test.gd")

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

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame

	var touch_ui := _scene_under_test.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := _scene_under_test.get_node_or_null("Runner")
	if touch_ui == null or player == null:
		await _fail("Main scene is missing TouchControlsUI or Runner")
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

	print("[MOBILE_TOUCH_ROUTING] PASS")
	await _finish(0)
