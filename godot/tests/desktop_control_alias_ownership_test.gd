extends SceneTree

# Regression for independent desktop driving-key aliases. Holding W+Up (or D+Right)
# must keep the normalized direction active until the final alias is released.
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
	push_error("[DESKTOP_ALIAS_OWNERSHIP] %s" % message)
	await _finish(1)

func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	return event

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame

	var touch_ui := _scene_under_test.get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null:
		await _fail("Main scene is missing TouchControlsUI")
		return

	touch_ui.set_mode(touch_ui.UIMode.VEHICLE_DRIVING)
	var throttle: Array[float] = [0.0]
	var steer: Array[float] = [0.0]
	touch_ui.driving_throttle_updated.connect(func(value: float): throttle[0] = value)
	touch_ui.driving_steer_updated.connect(func(value: float): steer[0] = value)

	# W and Up are aliases for forward. Releasing either one must not cancel the other.
	touch_ui._input(_key_event(KEY_W, true))
	touch_ui._input(_key_event(KEY_UP, true))
	if not is_equal_approx(throttle[0], 1.0):
		await _fail("W+Up did not hold +1 throttle")
		return
	touch_ui._input(_key_event(KEY_W, false))
	if not is_equal_approx(throttle[0], 1.0):
		await _fail("Releasing W cancelled still-held Up alias")
		return
	touch_ui._input(_key_event(KEY_UP, false))
	if not is_equal_approx(throttle[0], 0.0):
		await _fail("Forward throttle did not clear after final alias release")
		return

	# D and Right are aliases for right steering with the same ownership contract.
	touch_ui._input(_key_event(KEY_D, true))
	touch_ui._input(_key_event(KEY_RIGHT, true))
	if not is_equal_approx(steer[0], 1.0):
		await _fail("D+Right did not hold +1 steering")
		return
	touch_ui._input(_key_event(KEY_D, false))
	if not is_equal_approx(steer[0], 1.0):
		await _fail("Releasing D cancelled still-held Right alias")
		return
	touch_ui._input(_key_event(KEY_RIGHT, false))
	if not is_equal_approx(steer[0], 0.0):
		await _fail("Right steering did not clear after final alias release")
		return

	print("[DESKTOP_ALIAS_OWNERSHIP] PASS")
	await _finish(0)
