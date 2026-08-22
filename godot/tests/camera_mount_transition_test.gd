extends SceneTree

# Deterministic regression for the valid Ticket05 mount/dismount continuity
# contract. Target switches themselves must not combine focus translation and
# heading-follow arc motion into a >0.8m frame step.
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

func _assert_bounded_transition(camera: Node, new_target: Node3D, label: String) -> bool:
	camera.call("set_target", new_target)
	var last_pos: Vector3 = camera.global_position
	var max_step := 0.0
	for _i in range(15):
		camera.call("_process", 1.0 / 60.0)
		var current_pos: Vector3 = camera.global_position
		if not is_finite(current_pos.x) or not is_finite(current_pos.y) or not is_finite(current_pos.z):
			push_error("[CAMERA_MOUNT_CONTINUITY] %s produced non-finite camera position" % label)
			return false
		var step := current_pos.distance_to(last_pos)
		max_step = maxf(max_step, step)
		if step >= 0.8:
			push_error("[CAMERA_MOUNT_CONTINUITY] %s camera step %.4fm exceeded 0.8m continuity bound" % [label, step])
			return false
		last_pos = current_pos
	print("[CAMERA_MOUNT_CONTINUITY] %s max step %.4fm" % [label, max_step])
	return true

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
	await process_frame
	player.global_position = courier_bike.global_position + Vector3(0.0, 0.0, 1.5)
	camera.call("reset_camera_instant", player)

	if not _assert_bounded_transition(camera, courier_bike, "mount"):
		await _finish(1)
		return
	if not _assert_bounded_transition(camera, player, "dismount"):
		await _finish(1)
		return

	print("[CAMERA_MOUNT_CONTINUITY] PASS")
	await _finish(0)
