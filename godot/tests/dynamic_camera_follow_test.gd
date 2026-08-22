extends SceneTree

# Combined #29 + #30 regression: latest desktop controls must remain camera-relative
# while the camera follows on-foot movement and vehicle heading without snaps.
var _scene_under_test: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	_release_key(KEY_W)
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[DYNAMIC_CAMERA_AB] %s" % message)
	await _finish(1)

func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	return event

func _inject_key(key: Key, pressed: bool) -> void:
	Input.parse_input_event(_key_event(key, pressed))
	Input.flush_buffered_events()

func _release_key(key: Key) -> void:
	_inject_key(key, false)

func _yaw_error(actual: float, expected: float) -> float:
	return abs(wrapf(actual - expected, -PI, PI))

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame

	var camera := _scene_under_test.get_node_or_null("ChinatownCamera3D")
	var player := _scene_under_test.get_node_or_null("Runner")
	var courier_bike := _scene_under_test.get_node_or_null("CourierBike")
	var scrap_hauler := _scene_under_test.get_node_or_null("ScrapHauler")
	if camera == null or player == null or courier_bike == null or scrap_hauler == null:
		await _fail("Main scene is missing camera/player/Bike/Hauler integration nodes")
		return

	# RED on fixed-camera #29 baseline: combined candidate must explicitly expose dynamic yaw.
	if camera.get("dynamic_yaw_enabled") == null or camera.get("_current_yaw_rad") == null:
		await _fail("Dynamic heading-follow camera capability is absent")
		return
	camera.set("dynamic_yaw_enabled", true)

	# 1. CourierBike uses the strong vehicle-heading follow path.
	camera.call("reset_camera_instant", courier_bike)
	courier_bike.rotation.y = deg_to_rad(90.0)
	courier_bike.current_speed = 8.0
	courier_bike.velocity = Vector3(-8.0, 0.0, 0.0)
	for _i in range(90):
		camera.call("_process", 0.016)
	var bike_fwd: Vector3 = -courier_bike.global_transform.basis.z
	var bike_expected := wrapf(atan2(bike_fwd.x, bike_fwd.z) + PI, -PI, PI)
	if _yaw_error(float(camera.get("_current_yaw_rad")), bike_expected) >= 0.35:
		await _fail("CourierBike camera yaw did not converge to vehicle heading")
		return

	# 2. ScrapHauler must have exact vehicle-heading parity.
	camera.call("reset_camera_instant", scrap_hauler)
	scrap_hauler.rotation.y = deg_to_rad(-90.0)
	scrap_hauler.current_speed = 6.0
	scrap_hauler.velocity = Vector3(6.0, 0.0, 0.0)
	for _i in range(90):
		camera.call("_process", 0.016)
	var hauler_fwd: Vector3 = -scrap_hauler.global_transform.basis.z
	var hauler_expected := wrapf(atan2(hauler_fwd.x, hauler_fwd.z) + PI, -PI, PI)
	if _yaw_error(float(camera.get("_current_yaw_rad")), hauler_expected) >= 0.35:
		await _fail("ScrapHauler did not use the vehicle-heading follow path")
		return

	# 3. On-foot sustained movement rotates the camera toward movement direction.
	camera.call("reset_camera_instant", player)
	player.velocity = Vector3(0.0, 0.0, 3.5)
	for _i in range(90):
		camera.call("_process", 0.016)
	var foot_expected := wrapf(PI, -PI, PI)
	if _yaw_error(float(camera.get("_current_yaw_rad")), foot_expected) >= 0.40:
		await _fail("On-foot camera yaw did not follow sustained movement")
		return

	# 4. Desktop W remains screen-forward after the camera yaw is materially rotated.
	camera.set("dynamic_yaw_enabled", false)
	camera.set("_current_yaw_rad", PI / 2.0)
	camera.call("set_target", player)
	camera.call("_process", 0.016)
	player.set_joystick_input(Vector2.ZERO)
	player.velocity = Vector3.ZERO
	_inject_key(KEY_W, true)
	player._physics_process(0.1)
	_release_key(KEY_W)
	var cam_basis: Basis = camera.global_transform.basis
	var cam_fwd_xz := Vector3(-cam_basis.z.x, 0.0, -cam_basis.z.z).normalized()
	var player_dir := Vector3(player.velocity.x, 0.0, player.velocity.z).normalized()
	if player_dir.length_squared() < 0.5 or player_dir.dot(cam_fwd_xz) <= 0.95:
		await _fail("Physical W is not live-camera-relative after camera rotation")
		return
	camera.set("dynamic_yaw_enabled", true)

	# 5. Interaction mode freezes yaw; exit resumes within the configured slew cap.
	camera.call("reset_camera_instant", player)
	var before_interaction := float(camera.get("_current_yaw_rad"))
	camera.call("set_interaction_mode", true, player)
	player.velocity = Vector3(10.0, 0.0, 10.0)
	for _i in range(30):
		camera.call("_process", 0.016)
	if _yaw_error(float(camera.get("_current_yaw_rad")), before_interaction) > 0.001:
		await _fail("Camera yaw moved during interaction mode")
		return
	camera.call("set_interaction_mode", false)
	var before_resume := float(camera.get("_current_yaw_rad"))
	camera.call("_process", 0.016)
	var resume_step := _yaw_error(float(camera.get("_current_yaw_rad")), before_resume)
	var max_yaw_speed := float(camera.get("max_yaw_speed"))
	if resume_step > max_yaw_speed * 0.016 + 0.001:
		await _fail("Camera snapped when leaving interaction mode")
		return

	print("[DYNAMIC_CAMERA_AB] PASS")
	await _finish(0)
