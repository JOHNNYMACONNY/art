extends SceneTree

# Regression for the #29 owner-playtest trap:
# entering tuner from E, then releasing/cancelling without lock must always restore control.
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
	push_error("[DESKTOP_INTERACTION_CANCEL] %s" % message)
	await _finish(1)

func _key_event(key: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	event.echo = echo
	return event

func _enter_tuner(touch_ui: Node, player: Node, tuner: SignalTuner) -> bool:
	player.global_position = tuner.global_position + Vector3(0.0, 0.0, 1.5)
	tuner.update_player_distance(player.global_position)
	_scene_under_test._process(0.016)
	if _scene_under_test._active_target != tuner:
		return false
	touch_ui._input(_key_event(KEY_E, true))
	touch_ui._input(_key_event(KEY_E, false))
	return true

func _assert_tuner_open(touch_ui: Node, player: Node, tuner: SignalTuner, camera: ChinatownCamera3D) -> String:
	if tuner.current_state != tuner.TunerState.TUNING:
		return "Tuner did not enter TUNING"
	if not player.is_input_locked:
		return "Player was not locked during tuner interaction"
	if not camera._is_interaction_mode:
		return "Camera did not enter interaction mode"
	if not touch_ui.gesture_panel.visible:
		return "Tuner gesture overlay is not visible"
	return ""

func _assert_tuner_closed(touch_ui: Node, player: Node, tuner: SignalTuner, camera: ChinatownCamera3D) -> String:
	if tuner.current_state == tuner.TunerState.TUNING:
		return "Tuner remained in TUNING after cancel"
	if player.is_input_locked:
		return "Player remained input-locked after cancel"
	if camera._is_interaction_mode:
		return "Camera remained in interaction mode after cancel"
	if touch_ui.gesture_panel.visible:
		return "Gesture overlay remained visible after cancel"
	return ""

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame

	var touch_ui: TouchControlsUI = _scene_under_test.get_node_or_null("CanvasLayer/TouchControlsUI") as TouchControlsUI
	var player: PlayerRunner = _scene_under_test.get_node_or_null("Runner") as PlayerRunner
	var tuner: SignalTuner = _scene_under_test.signal_tuner as SignalTuner
	var camera: ChinatownCamera3D = _scene_under_test.camera as ChinatownCamera3D
	var panel: CorrodedPanel = _scene_under_test.corroded_panel as CorrodedPanel
	if touch_ui == null or player == null or tuner == null or camera == null or panel == null:
		await _fail("Main scene is missing tuner interaction dependencies")
		return

	# 1. Reproduce the owner trap: a physical mouse drag that does not lock signal,
	# then mouse release, must close the interaction and return movement/camera control.
	if not _enter_tuner(touch_ui, player, tuner):
		await _fail("Could not select tuner through normal target authority")
		return
	await process_frame
	var open_error := _assert_tuner_open(touch_ui, player, tuner, camera)
	if not open_error.is_empty():
		await _fail(open_error)
		return

	var mouse_down := InputEventMouseButton.new()
	mouse_down.device = 0
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(480, 270)
	touch_ui._gui_input(mouse_down)
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.device = 0
	mouse_motion.position = Vector2(490, 270)
	mouse_motion.relative = Vector2(10, 0)
	touch_ui._gui_input(mouse_motion)
	var mouse_up := InputEventMouseButton.new()
	mouse_up.device = 0
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	mouse_up.position = Vector2(490, 270)
	# Real Control events may traverse both GUI and global input callbacks.
	touch_ui._gui_input(mouse_up)
	touch_ui._input(mouse_up)
	await process_frame
	var release_error := _assert_tuner_closed(touch_ui, player, tuner, camera)
	if not release_error.is_empty():
		await _fail("Mouse-release cancel trap: %s" % release_error)
		return

	# 2. ESC is an explicit deterministic desktop cancel path. Repeat it to prove
	# no stale lock/camera/overlay state accumulates across enter/cancel cycles.
	for cycle in range(2):
		if not _enter_tuner(touch_ui, player, tuner):
			await _fail("Could not re-enter tuner on ESC cycle %d" % (cycle + 1))
			return
		await process_frame
		open_error = _assert_tuner_open(touch_ui, player, tuner, camera)
		if not open_error.is_empty():
			await _fail("ESC cycle %d open state: %s" % [cycle + 1, open_error])
			return
		touch_ui._input(_key_event(KEY_ESCAPE, true))
		touch_ui._input(_key_event(KEY_ESCAPE, false))
		await process_frame
		var escape_error := _assert_tuner_closed(touch_ui, player, tuner, camera)
		if not escape_error.is_empty():
			await _fail("ESC cycle %d: %s" % [cycle + 1, escape_error])
			return

	# 3. Panel peel gets the same explicit ESC cancel language without changing
	# extraction rules. Set up the already-proven powered/approached seam directly.
	panel.is_powered = true
	panel.is_player_in_range = true
	panel.current_step = panel.Step.APPROACHED
	_scene_under_test._active_target = panel
	touch_ui._input(_key_event(KEY_E, true))
	touch_ui._input(_key_event(KEY_E, false))
	await process_frame
	if panel.current_step != panel.Step.PEELING or not player.is_input_locked or not touch_ui.gesture_panel.visible:
		await _fail("Panel did not enter peel interaction before ESC cancel proof")
		return
	touch_ui._input(_key_event(KEY_ESCAPE, true))
	touch_ui._input(_key_event(KEY_ESCAPE, false))
	await process_frame
	if panel.current_step == panel.Step.PEELING or player.is_input_locked or camera._is_interaction_mode or touch_ui.gesture_panel.visible:
		await _fail("ESC did not deterministically cancel panel peel interaction")
		return

	print("[DESKTOP_INTERACTION_CANCEL] PASS")
	await _finish(0)