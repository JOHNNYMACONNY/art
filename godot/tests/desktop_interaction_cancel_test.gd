extends SceneTree

# Real Viewport regression for #29 desktop tuner interaction.
# Proves physical mouse delivery, cancellation cleanup, visible feedback,
# real frequency movement, dwell-to-lock progression, and panel power-up.
# In GitHub Web export CI only, this final pre-export test also requires the
# exact-build rendered verification payload to be prepared for publication.
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

func _push_key(key: Key) -> void:
	root.push_input(_key_event(key, true), true)
	root.push_input(_key_event(key, false), true)

func _enter_tuner(touch_ui: Node, player: Node, tuner: SignalTuner) -> bool:
	player.global_position = tuner.global_position + Vector3(0.0, 0.0, 1.5)
	tuner.update_player_distance(player.global_position)
	_scene_under_test._process(0.016)
	if _scene_under_test._active_target != tuner:
		return false
	_push_key(KEY_E)
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

func _mouse_down_at(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.device = 0
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position
	root.push_input(event, true)

func _mouse_motion(position: Vector2, relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.device = 0
	event.position = position
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)

func _mouse_up_at(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.device = 0
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = position
	root.push_input(event, true)

func _prepare_ci_verification_payload() -> String:
	if OS.get_environment("GITHUB_ACTIONS").to_lower() != "true":
		return ""
	var source_sha := OS.get_environment("SOURCE_SHA")
	if source_sha.is_empty():
		return "CI verification payload requires SOURCE_SHA"

	var output: Array = []
	var args := PackedStringArray([
		"-a",
		"-s",
		"-screen 0 1280x720x24",
		OS.get_executable_path(),
		"--path",
		ProjectSettings.globalize_path("res://"),
		"--rendering-method",
		"gl_compatibility",
		"--",
		"--run-gears-verification-capture",
	])
	var exit_code := OS.execute("xvfb-run", args, output, true)
	for line in output:
		print(str(line))
	if exit_code != 0:
		return "Rendered verification child failed with exit code %d" % exit_code

	var report_path := "res://verification/current/verification_report.json"
	if not FileAccess.file_exists(report_path):
		return "Rendered verification report was not generated"
	var report = JSON.parse_string(FileAccess.get_file_as_string(report_path))
	if not report is Dictionary:
		return "Rendered verification report is invalid JSON"
	if str(report.get("source_sha", "")) != source_sha:
		return "Rendered verification report does not match SOURCE_SHA"

	var preset := ConfigFile.new()
	var preset_error := preset.load(ProjectSettings.globalize_path("res://export_presets.cfg"))
	if preset_error != OK:
		return "Could not reload Web export preset after verification capture"
	var head_include := str(preset.get_value("preset.0.options", "html/head_include", ""))
	if "GEARS_VERIFICATION_PAYLOAD_V2" not in head_include:
		return "Web export preset is missing rendered verification payload marker"
	if source_sha not in head_include:
		return "Web export verification payload is not stamped to SOURCE_SHA"
	if not FileAccess.file_exists("res://verification_contact_sheet.png"):
		return "Web export contact-sheet source asset is missing"
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

	if not _enter_tuner(touch_ui, player, tuner):
		await _fail("Could not select tuner through normal target authority")
		return
	await process_frame
	var open_error := _assert_tuner_open(touch_ui, player, tuner, camera)
	if not open_error.is_empty():
		await _fail(open_error)
		return

	var gesture_center: Vector2 = touch_ui.gesture_panel.get_global_rect().get_center()
	_mouse_down_at(gesture_center)
	await process_frame
	_mouse_motion(gesture_center + Vector2(10, 0), Vector2(10, 0))
	await process_frame
	var unrelated_up := InputEventMouseButton.new()
	unrelated_up.device = 0
	unrelated_up.button_index = MOUSE_BUTTON_RIGHT
	unrelated_up.pressed = false
	unrelated_up.position = gesture_center + Vector2(10, 0)
	root.push_input(unrelated_up, true)
	await process_frame
	open_error = _assert_tuner_open(touch_ui, player, tuner, camera)
	if not open_error.is_empty():
		await _fail("Unrelated mouse-button release cancelled left-mouse tuner drag: %s" % open_error)
		return
	_mouse_up_at(gesture_center + Vector2(10, 0))
	await process_frame
	var release_error := _assert_tuner_closed(touch_ui, player, tuner, camera)
	if not release_error.is_empty():
		await _fail("Mouse-release cancel trap: %s" % release_error)
		return

	for cycle in range(2):
		if not _enter_tuner(touch_ui, player, tuner):
			await _fail("Could not re-enter tuner on ESC cycle %d" % (cycle + 1))
			return
		await process_frame
		open_error = _assert_tuner_open(touch_ui, player, tuner, camera)
		if not open_error.is_empty():
			await _fail("ESC cycle %d open state: %s" % [cycle + 1, open_error])
			return
		_push_key(KEY_ESCAPE)
		await process_frame
		var escape_error := _assert_tuner_closed(touch_ui, player, tuner, camera)
		if not escape_error.is_empty():
			await _fail("ESC cycle %d: %s" % [cycle + 1, escape_error])
			return

	if not _enter_tuner(touch_ui, player, tuner):
		await _fail("Could not enter tuner for real drag progression proof")
		return
	await process_frame
	gesture_center = touch_ui.gesture_panel.get_global_rect().get_center()
	var start_frequency := tuner.current_frequency
	_mouse_down_at(gesture_center)
	await process_frame
	_mouse_motion(gesture_center + Vector2(180, 0), Vector2(300, 0))
	await process_frame
	await physics_frame

	if tuner.current_frequency <= start_frequency + 0.20:
		await _fail("Real Viewport mouse motion did not materially change tuner frequency")
		return
	if abs(tuner.current_frequency - tuner.target_frequency) > tuner.lock_tolerance:
		await _fail("Real mouse drag did not reach target lock zone (freq=%.3f target=%.3f)" % [tuner.current_frequency, tuner.target_frequency])
		return
	if touch_ui.tuner_readout_label == null or not touch_ui.tuner_readout_label.visible:
		await _fail("Tuner readout was not visible during real mouse tuning")
		return
	if not touch_ui.tuner_readout_label.text.contains("TUNE") or not touch_ui.tuner_readout_label.text.contains("SIGNAL"):
		await _fail("Tuner readout did not expose live TUNE/SIGNAL feedback")
		return
	if touch_ui.tuner_readout_label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		await _fail("Decorative tuner readout can intercept pointer delivery")
		return

	await create_timer(tuner.dwell_time_required + 0.15).timeout
	await process_frame
	if tuner.current_state != tuner.TunerState.LOCKED:
		await _fail("Production dwell did not transition tuner to LOCKED")
		return
	if not panel.is_powered:
		await _fail("Signal lock did not power the Corroded Panel")
		return
	if player.is_input_locked or camera._is_interaction_mode or touch_ui.gesture_panel.visible:
		await _fail("Successful tuner lock did not cleanly restore player/camera/UI authority")
		return

	_mouse_up_at(gesture_center + Vector2(180, 0))
	await process_frame
	if not panel.is_powered or tuner.current_state != tuner.TunerState.LOCKED:
		await _fail("Post-lock mouse release regressed successful tuner progression")
		return

	panel.is_powered = true
	panel.is_player_in_range = true
	panel.current_step = panel.Step.APPROACHED
	_scene_under_test._active_target = panel
	_push_key(KEY_E)
	await process_frame
	if panel.current_step != panel.Step.PEELING or not player.is_input_locked or not touch_ui.gesture_panel.visible:
		await _fail("Panel did not enter peel interaction before ESC cancel proof")
		return
	_push_key(KEY_ESCAPE)
	await process_frame
	if panel.current_step == panel.Step.PEELING or player.is_input_locked or camera._is_interaction_mode or touch_ui.gesture_panel.visible:
		await _fail("ESC did not deterministically cancel panel peel interaction")
		return

	var verification_error := _prepare_ci_verification_payload()
	if not verification_error.is_empty():
		await _fail("Verification publication: %s" % verification_error)
		return

	print("[DESKTOP_INTERACTION_CANCEL] PASS")
	await _finish(0)