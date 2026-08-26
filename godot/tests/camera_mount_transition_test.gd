extends SceneTree

# Issue #30 / Ticket05 regression. Reproduces the production mount/dismount
# lifecycle while making camera advancement single-owner. Automatic Camera3D
# processing is disabled before the test explicitly advances fixed 16ms steps,
# avoiding the previous timer + manual _process double-step artifact.
# This dedicated regression is also the reference oracle for the legacy Ticket05 repair.
# Keep this path in the focused workflow so legacy-oracle repairs are verified before publish.
# Open World Expansion 01C also invokes its focused production-scene destination contract here.
const BurnGarageContract = preload("res://tests/mayor_burn_garage_integration_contract.gd")

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

func _advance_bounded(camera: Node, label: String) -> bool:
	var last_pos: Vector3 = camera.global_position
	var max_step := 0.0
	for _i in range(15):
		await create_timer(0.02).timeout
		camera.call("_process", 0.016)
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
	print("[CAMERA_MOUNT_CONTINUITY] %s max deterministic step %.4fm" % [label, max_step])
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
	await process_frame

	var burn_garage_error: String = BurnGarageContract.verify(_scene_under_test)
	if burn_garage_error != "":
		await _fail("[GEARS_DISTRICT_01C] %s" % burn_garage_error)
		return

	var camera := _scene_under_test.get_node_or_null("ChinatownCamera3D")
	var player := _scene_under_test.get_node_or_null("Runner")
	var courier_bike := _scene_under_test.get_node_or_null("CourierBike")
	if camera == null or player == null or courier_bike == null:
		await _fail("Main scene is missing camera/player/CourierBike")
		return

	_scene_under_test.call("reset_slice")
	await create_timer(0.1).timeout

	# Match the legacy Ticket05 production mount path, but disable automatic
	# camera processing before deterministic manual camera advancement.
	camera.set_process(false)
	player.global_position = courier_bike.global_position + Vector3(0.0, 0.0, 1.5)
	await create_timer(0.2).timeout
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_scene_under_test.call("_evaluate_target_selection")
	_scene_under_test.call("_on_action_pressed")
	if courier_bike.current_state != CourierBike.BikeState.MOUNTING:
		await _fail("Bike did not enter MOUNTING through production action path")
		return
	camera.call("set_target", courier_bike)

	if not await _advance_bounded(camera, "mount"):
		await _finish(1)
		return

	await create_timer(0.15).timeout
	if courier_bike.current_state != CourierBike.BikeState.DRIVING:
		await _fail("Bike did not reach DRIVING after mount transition")
		return

	_scene_under_test.call("_on_dismount_pressed")
	camera.call("set_target", player)
	if not await _advance_bounded(camera, "dismount"):
		await _finish(1)
		return

	print("[CAMERA_MOUNT_CONTINUITY] PASS")
	await _finish(0)
