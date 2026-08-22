extends SceneTree

# Desktop control regression at the public device-mapping seams:
# physical keyboard -> PlayerRunner / TouchControlsUI -> normalized gameplay intent.
var _scene_under_test: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	_release_key(KEY_W)
	_release_key(KEY_A)
	_release_key(KEY_S)
	_release_key(KEY_D)
	_release_key(KEY_UP)
	_release_key(KEY_DOWN)
	_release_key(KEY_LEFT)
	_release_key(KEY_RIGHT)
	_release_key(KEY_SPACE)
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[DESKTOP_CONTROLS] %s" % message)
	await _finish(1)

func _key_event(key: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	event.echo = echo
	return event

func _inject_physical_key(key: Key, pressed: bool) -> void:
	Input.parse_input_event(_key_event(key, pressed))
	Input.flush_buffered_events()

func _release_key(key: Key) -> void:
	_inject_physical_key(key, false)

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
	var player := _scene_under_test.get_node_or_null("Runner")
	if touch_ui == null or player == null:
		await _fail("Main scene is missing TouchControlsUI or Runner")
		return

	# 0. Desktop mouse must remain a mouse. If Godot synthesizes touch from it,
	# a normal click can enter the floating-joystick ScreenTouch path.
	if bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", true)):
		await _fail("Desktop mouse-to-touch emulation must be disabled to prevent joystick capture")
		return

	# 1. Physical WASD drives the on-foot runner without relying on touch emulation.
	touch_ui.set_mode(touch_ui.UIMode.FOOT_TRAVERSAL)
	player.set_joystick_input(Vector2.ZERO)
	player.velocity = Vector3.ZERO
	_inject_physical_key(KEY_W, true)
	player._physics_process(0.1)
	_release_key(KEY_W)
	if player.velocity.length() <= 0.01:
		await _fail("Physical W did not produce on-foot movement")
		return

	# 2. Diagonal physical keyboard input is normalized to the runner speed cap.
	player.velocity = Vector3.ZERO
	_inject_physical_key(KEY_W, true)
	_inject_physical_key(KEY_D, true)
	player._physics_process(0.25)
	_release_key(KEY_W)
	_release_key(KEY_D)
	if player.velocity.length() > player.move_speed + 0.01:
		await _fail("W+D exceeded the normalized on-foot movement speed cap")
		return

	# 3. E is a single-fire foot action; release and key-repeat echo must not duplicate it.
	var action_count: Array[int] = [0]
	touch_ui.action_button_pressed.connect(func(): action_count[0] += 1)
	touch_ui._input(_key_event(KEY_E, true))
	touch_ui._input(_key_event(KEY_E, true, true))
	touch_ui._input(_key_event(KEY_E, false))
	if action_count[0] != 1:
		await _fail("E must emit exactly one foot action; got %d" % action_count[0])
		return

	# 4. Physical mouse gestures operate interaction UI but never acquire the movement joystick.
	touch_ui.reset_all_input_states()
	touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	var tuning_value: Array[float] = [0.0]
	touch_ui.tuner_dragged.connect(func(px: float): tuning_value[0] = px)
	var mouse_down := InputEventMouseButton.new()
	mouse_down.device = 0
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(480, 270)
	touch_ui._gui_input(mouse_down)
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.device = 0
	mouse_motion.position = Vector2(530, 270)
	mouse_motion.relative = Vector2(50, 0)
	touch_ui._gui_input(mouse_motion)
	if tuning_value[0] <= 0.0:
		await _fail("Physical mouse drag did not drive the tuner gesture")
		return
	if touch_ui._joystick_active or player.joystick_vector.length() > 0.001:
		await _fail("Physical mouse interaction incorrectly acquired movement joystick ownership")
		return
	var mouse_up := InputEventMouseButton.new()
	mouse_up.device = 0
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	touch_ui._input(mouse_up)
	touch_ui.close_interaction_overlay()

	# 5. Vehicle keyboard mapping emits the same normalized intent signals as touch.
	touch_ui.set_mode(touch_ui.UIMode.VEHICLE_DRIVING)
	var throttle: Array[float] = [0.0]
	var steer: Array[float] = [0.0]
	var handbrake: Array[bool] = [false]
	var dismount_count: Array[int] = [0]
	var radio_count: Array[int] = [0]
	touch_ui.driving_throttle_updated.connect(func(value: float): throttle[0] = value)
	touch_ui.driving_steer_updated.connect(func(value: float): steer[0] = value)
	touch_ui.driving_handbrake_updated.connect(func(value: bool): handbrake[0] = value)
	touch_ui.dismount_pressed.connect(func(): dismount_count[0] += 1)
	touch_ui.radio_toggle_pressed.connect(func(): radio_count[0] += 1)

	# A focused touch Button must not receive the same Space key that driving
	# consumes as handbrake. Exercise the real Viewport propagation path.
	touch_ui.radio_button.grab_focus()
	await process_frame
	if not touch_ui.radio_button.has_focus():
		await _fail("Radio button could not acquire focus for Space propagation proof")
		return
	root.push_input(_key_event(KEY_SPACE, true), true)
	root.push_input(_key_event(KEY_SPACE, false), true)
	await process_frame
	if radio_count[0] != 0:
		await _fail("Vehicle Space leaked into focused RadioButton and toggled radio")
		return
	touch_ui.radio_button.release_focus()

	touch_ui._input(_key_event(KEY_W, true))
	if not is_equal_approx(throttle[0], 1.0):
		await _fail("Vehicle W did not emit normalized +1 throttle")
		return
	touch_ui._input(_key_event(KEY_S, true))
	if not is_equal_approx(throttle[0], 0.0):
		await _fail("Vehicle W+S did not cancel to zero throttle")
		return
	touch_ui._input(_key_event(KEY_W, false))
	if not is_equal_approx(throttle[0], -1.0):
		await _fail("Vehicle S did not emit normalized -1 brake/reverse intent")
		return
	touch_ui._input(_key_event(KEY_S, false))

	touch_ui._input(_key_event(KEY_D, true))
	if not is_equal_approx(steer[0], 1.0):
		await _fail("Vehicle D did not emit normalized +1 steering")
		return
	touch_ui._input(_key_event(KEY_A, true))
	if not is_equal_approx(steer[0], 0.0):
		await _fail("Vehicle A+D did not cancel to zero steering")
		return
	touch_ui._input(_key_event(KEY_D, false))
	if not is_equal_approx(steer[0], -1.0):
		await _fail("Vehicle A did not emit normalized -1 steering")
		return
	touch_ui._input(_key_event(KEY_A, false))

	touch_ui._input(_key_event(KEY_SPACE, true))
	if not handbrake[0]:
		await _fail("Vehicle Space did not engage handbrake intent")
		return
	touch_ui._input(_key_event(KEY_SPACE, false))
	if handbrake[0]:
		await _fail("Vehicle Space release left stale handbrake intent")
		return

	touch_ui._input(_key_event(KEY_E, true))
	touch_ui._input(_key_event(KEY_E, true, true))
	touch_ui._input(_key_event(KEY_E, false))
	if dismount_count[0] != 1:
		await _fail("Vehicle E must emit exactly one dismount/context action")
		return

	touch_ui._input(_key_event(KEY_R, true))
	touch_ui._input(_key_event(KEY_R, true, true))
	touch_ui._input(_key_event(KEY_R, false))
	if radio_count[0] != 1:
		await _fail("Vehicle R must emit exactly one radio toggle")
		return

	# 6. Touch ownership survives browser-synthesized companion mouse events.
	touch_ui.reset_all_input_states()
	touch_ui.set_mode(touch_ui.UIMode.VEHICLE_DRIVING)
	var gas_press := InputEventScreenTouch.new()
	gas_press.index = 9
	gas_press.pressed = true
	touch_ui.gas_button.gui_input.emit(gas_press)
	if not touch_ui._is_gas_pressed or touch_ui._gas_touch_index != 9:
		await _fail("Gas touch setup failed before emulated-mouse ownership test")
		return
	var emulated_up := InputEventMouseButton.new()
	emulated_up.device = InputEvent.DEVICE_ID_EMULATION
	emulated_up.button_index = MOUSE_BUTTON_LEFT
	emulated_up.pressed = false
	touch_ui._input(emulated_up)
	if not touch_ui._is_gas_pressed or touch_ui._gas_touch_index != 9:
		await _fail("Emulated mouse release cleared real touch ownership")
		return
	var gas_release := InputEventScreenTouch.new()
	gas_release.index = 9
	gas_release.pressed = false
	touch_ui.gas_button.gui_input.emit(gas_release)

	print("[DESKTOP_CONTROLS] PASS")
	await _finish(0)