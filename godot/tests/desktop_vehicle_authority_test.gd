extends SceneTree

# Integration regression for #29's full authority path:
# keyboard -> TouchControlsUI normalized intent -> ScrapTestBlock -> existing vehicle physics seam.
const PursuerInterceptContract = preload("res://tests/pursuer_intercept_contract_test.gd")
const Wave1RetentionRecord = preload("res://tests/wave1_retention_record_test.gd")

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
	push_error("[DESKTOP_VEHICLE_AUTHORITY] %s" % message)
	await _finish(1)

func _key_event(key: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	event.echo = echo
	return event

func _press(touch_ui: Node, key: Key) -> void:
	touch_ui._input(_key_event(key, true))

func _release(touch_ui: Node, key: Key) -> void:
	touch_ui._input(_key_event(key, false))

func _mount_vehicle_direct(vehicle: Node, player: Node) -> bool:
	player.global_position = vehicle.global_position + Vector3(0.5, 0.0, 0.5)
	if vehicle.mount_interactable:
		vehicle.mount_interactable.update_player_distance(player.global_position)
	return vehicle.request_mount(player)

func _run_ci_wave1_integrated_harness() -> String:
	if OS.get_environment("CI").to_lower() != "true":
		print("[CTW_FEEL_07] Integrated E1-E7 nested harness SKIP outside CI")
		return ""
	var output: Array = []
	var project_path := ProjectSettings.globalize_path("res://")
	var verification_sha := OS.get_environment("GITHUB_SHA").strip_edges()
	if verification_sha.is_empty():
		verification_sha = "ci-exact-source"
	var args := PackedStringArray([
		"--headless",
		"--rendering-method", "gl_compatibility",
		"--path", project_path,
		"--script", "res://scripts/verification/ctw_feel_harness.gd",
		"--",
		"--run-ctw-feel-integrated",
		"--feel-build-commit=%s" % verification_sha,
	])
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	var combined := "\n".join(output)
	if exit_code != 0:
		return "integrated E1-E7 harness exited %d; output=%s" % [exit_code, combined.right(3000)]
	if not combined.contains("[CTW_FEEL] INTEGRATED PASS"):
		return "integrated E1-E7 harness exited 0 without PASS marker; output=%s" % combined.right(3000)
	print("[CTW_FEEL_07] Integrated E1-E7 comparison PASS")
	return ""

func _run() -> void:
	var retention_error: String = Wave1RetentionRecord.verify()
	if not retention_error.is_empty():
		await _fail("CTW Feel 07: %s" % retention_error)
		return

	var integrated_error := _run_ci_wave1_integrated_harness()
	if not integrated_error.is_empty():
		await _fail("CTW Feel 07: %s" % integrated_error)
		return

	# CTW Feel 06 owns a pure destination-selection A/B contract. Its synthetic
	# nodes attach under the SceneTree root so production global transforms are
	# valid, but it never touches the live prototype scene fixture.
	var intercept_error: String = PursuerInterceptContract.verify(root)
	if not intercept_error.is_empty():
		await _fail("CTW Feel 06: %s" % intercept_error)
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
	var bike := _scene_under_test.get_node_or_null("CourierBike")
	var hauler := _scene_under_test.get_node_or_null("ScrapHauler")
	if touch_ui == null or player == null or bike == null or hauler == null:
		await _fail("Main scene is missing TouchControlsUI, Runner, CourierBike, or ScrapHauler")
		return

	# CTW Feel 04 seam: normalized vehicle intent remains observable by feedback
	# systems without mutating the existing Courier Bike handling path.
	if not bike.has_method("get_vehicle_feedback_telemetry"):
		await _fail("Courier Bike vehicle-feedback telemetry seam is absent")
		return

	# Courier Bike: E must traverse target selection + action authority, not a test-only mount shortcut.
	player.global_position = bike.global_position + Vector3(0.5, 0.0, 0.5)
	bike.mount_interactable.update_player_distance(player.global_position)
	_scene_under_test._process(0.016)
	if _scene_under_test._active_target != bike.mount_interactable:
		await _fail("Bike mount interactable was not selected as the real E target")
		return
	var bike_mount_count: Array[int] = [0]
	bike.mounted.connect(func(_player_ref): bike_mount_count[0] += 1)
	touch_ui._input(_key_event(KEY_E, true))
	touch_ui._input(_key_event(KEY_E, true, true))
	touch_ui._input(_key_event(KEY_E, false))
	await create_timer(0.3).timeout
	await process_frame
	if bike.occupant != player or bike_mount_count[0] != 1:
		await _fail("E did not mount CourierBike exactly once through controller authority")
		return

	# R must change the actual radio lifecycle state exactly once despite key-repeat echo.
	var radio_before: bool = _scene_under_test.is_radio_enabled()
	touch_ui._input(_key_event(KEY_R, true))
	touch_ui._input(_key_event(KEY_R, true, true))
	touch_ui._input(_key_event(KEY_R, false))
	if _scene_under_test.is_radio_enabled() == radio_before:
		await _fail("R did not toggle actual vehicle radio state")
		return
	var radio_after_one_press: bool = _scene_under_test.is_radio_enabled()
	touch_ui._input(_key_event(KEY_R, true, true))
	if _scene_under_test.is_radio_enabled() != radio_after_one_press:
		await _fail("R key-repeat echo toggled actual radio state more than once")
		return
	# Restore initial state for the rest of the integration test.
	touch_ui._input(_key_event(KEY_R, true))
	touch_ui._input(_key_event(KEY_R, false))
	if _scene_under_test.is_radio_enabled() != radio_before:
		await _fail("Second deliberate R press did not restore radio state")
		return

	# W reaches set_drive_inputs and accelerates the actual bike.
	_press(touch_ui, KEY_W)
	_scene_under_test._process(0.1)
	_release(touch_ui, KEY_W)
	if bike.current_speed <= 0.0:
		await _fail("W normalized intent did not accelerate CourierBike")
		return

	# D/A reach the existing steering seam; opposite keys cancel.
	_press(touch_ui, KEY_D)
	_scene_under_test._process(0.05)
	if bike.steering_angle <= 0.0:
		await _fail("D normalized intent did not steer CourierBike right")
		return
	_press(touch_ui, KEY_A)
	_scene_under_test._process(0.05)
	if not is_zero_approx(bike.steering_angle):
		await _fail("A+D did not cancel at CourierBike authority")
		return
	_release(touch_ui, KEY_D)
	_scene_under_test._process(0.05)
	if bike.steering_angle >= 0.0:
		await _fail("A normalized intent did not steer CourierBike left")
		return
	_release(touch_ui, KEY_A)

	# Space uses the same handbrake boolean consumed by vehicle physics.
	_press(touch_ui, KEY_SPACE)
	_scene_under_test._process(0.016)
	if not bike.is_handbrake_active:
		await _fail("Space did not engage CourierBike handbrake authority")
		return
	_release(touch_ui, KEY_SPACE)
	_scene_under_test._process(0.016)
	if bike.is_handbrake_active:
		await _fail("Space release left CourierBike handbrake stuck")
		return

	# S must preserve the existing brake -> zero-cross -> gear-settle -> reverse contract.
	bike.current_speed = 6.0
	_press(touch_ui, KEY_S)
	var reverse_reached := false
	for _step in range(90):
		_scene_under_test._process(0.016)
		if bike.current_speed < -0.01:
			reverse_reached = true
			break
	_release(touch_ui, KEY_S)
	if not reverse_reached:
		await _fail("Holding S did not preserve CourierBike brake-to-reverse zero-cross behavior")
		return

	# E respects the existing speed-limit gate, then exits safely once stopped.
	bike.current_speed = 5.0
	_press(touch_ui, KEY_E)
	_release(touch_ui, KEY_E)
	await process_frame
	if bike.occupant != player:
		await _fail("E bypassed CourierBike high-speed dismount rejection")
		return
	bike.current_speed = 0.0
	_press(touch_ui, KEY_E)
	_release(touch_ui, KEY_E)
	await create_timer(0.25).timeout
	await process_frame
	if bike.occupant != null or player.is_mounted:
		await _fail("E did not complete legal CourierBike dismount")
		return

	# Scrap Hauler: same keyboard language must traverse the same controller seam.
	if not _mount_vehicle_direct(hauler, player):
		await _fail("ScrapHauler request_mount failed during parity setup")
		return
	await create_timer(0.3).timeout
	await process_frame
	if hauler.occupant != player:
		await _fail("ScrapHauler did not complete mount")
		return

	_press(touch_ui, KEY_W)
	_scene_under_test._process(0.1)
	_release(touch_ui, KEY_W)
	if hauler.current_speed <= 0.0:
		await _fail("W normalized intent did not accelerate ScrapHauler")
		return

	_press(touch_ui, KEY_A)
	_scene_under_test._process(0.05)
	if hauler.steering_angle >= 0.0:
		await _fail("A normalized intent did not steer ScrapHauler left")
		return
	_release(touch_ui, KEY_A)

	_press(touch_ui, KEY_SPACE)
	_scene_under_test._process(0.016)
	if not hauler.is_handbrake_active:
		await _fail("Space did not engage ScrapHauler handbrake authority")
		return
	_release(touch_ui, KEY_SPACE)
	_scene_under_test._process(0.016)
	if hauler.is_handbrake_active:
		await _fail("Space release left ScrapHauler handbrake stuck")
		return

	# Reset must clear adapter/controller authority so no stale desktop input survives replay.
	_scene_under_test.reset_slice()
	await process_frame
	if not is_zero_approx(_scene_under_test._throttle_input):
		await _fail("Replay reset left stale throttle intent")
		return
	if not is_zero_approx(_scene_under_test._steer_input):
		await _fail("Replay reset left stale steering intent")
		return
	if _scene_under_test._handbrake_input:
		await _fail("Replay reset left stale handbrake intent")
		return

	print("[DESKTOP_VEHICLE_AUTHORITY] PASS")
	await _finish(0)