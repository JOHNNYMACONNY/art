extends SceneTree

# Regression for the valid Ticket05 mount/dismount continuity contract. This
# intentionally mirrors the production mount timing that exposed the #30 snap:
# the scene processes naturally between 20ms samples and the camera is sampled
# after its explicit deterministic 16ms update.
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
	push_error("[CAMERA_MOUNT_CONTINUITY] %s" % message)
	await _finish(1)

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
	if camera == null or player == null or courier_bike == null:
		await _fail("Main scene is missing camera/player/CourierBike")
		return

	_scene_under_test.call("reset_slice")
	await create_timer(0.1).timeout

	# Exercise the same real mount selection/action route as the gameplay slice.
	player.global_position = courier_bike.global_position + Vector3(0.0, 0.0, 1.5)
	await create_timer(0.2).timeout
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_scene_under_test.call("_evaluate_target_selection")
	_scene_under_test.call("_on_action_pressed")
	camera.call("set_target", courier_bike)

	var last_pos: Vector3 = camera.global_position
	var max_mount_step := 0.0
	for _i in range(15):
		await create_timer(0.02).timeout
		camera.call("_process", 0.016)
		var current_pos: Vector3 = camera.global_position
		if not is_finite(current_pos.x) or not is_finite(current_pos.y) or not is_finite(current_pos.z):
			await _fail("Mount produced non-finite camera position")
			return
		var step := current_pos.distance_to(last_pos)
		max_mount_step = maxf(max_mount_step, step)
		if step >= 0.8:
			await _fail("Mount camera step %.4fm exceeded 0.8m continuity bound" % step)
			return
		last_pos = current_pos

	await create_timer(0.15).timeout

	# Exercise the production dismount request route, then preserve the legacy
	# deterministic sampling contract used by the canonical compatibility suite.
	_scene_under_test.call("_on_dismount_pressed")
	camera.call("set_target", player)
	var max_dismount_step := 0.0
	for _i in range(15):
		await create_timer(0.02).timeout
		camera.call("_process", 0.016)
		var current_pos: Vector3 = camera.global_position
		if not is_finite(current_pos.x) or not is_finite(current_pos.y) or not is_finite(current_pos.z):
			await _fail("Dismount produced non-finite camera position")
			return
		var step := current_pos.distance_to(last_pos)
		max_dismount_step = maxf(max_dismount_step, step)
		if step >= 0.8:
			await _fail("Dismount camera step %.4fm exceeded 0.8m continuity bound" % step)
			return
		last_pos = current_pos

	print("[CAMERA_MOUNT_CONTINUITY] mount max %.4fm · dismount max %.4fm" % [max_mount_step, max_dismount_step])
	print("[CAMERA_MOUNT_CONTINUITY] PASS")
	await _finish(0)
