extends SceneTree

# Integration regression for #29's full authority path:
# keyboard -> TouchControlsUI normalized intent -> ScrapTestBlock -> existing vehicle physics seam.
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

func _mount_vehicle(vehicle: Node, player: Node) -> bool:
	player.global_position = vehicle.global_position + Vector3(0.5, 0.0, 0.5)
	if vehicle.mount_interactable:
		vehicle.mount_interactable.update_player_distance(player.global_position)
	return vehicle.request_mount(player)

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
	var bike := _scene_under_test.get_node_or_null("CourierBike")
	var hauler := _scene_under_test.get_node_or_null("ScrapHauler")
	if touch_ui == null or player == null or bike == null or hauler == null:
		await _fail("Main scene is missing TouchControlsUI, Runner, CourierBike, or ScrapHauler")
		return

	# Courier Bike: mount through the real vehicle contract.
	if not _mount_vehicle(bike, player):
		await _fail("CourierBike request_mount failed during desktop authority setup")
		return
	await create_timer(0.3).timeout
	await process_frame
	if bike.occupant != player:
		await _fail("CourierBike did not complete mount")
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
	if not _mount_vehicle(hauler, player):
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