extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
	await process_frame
	await process_frame
	quit(code)

func _fail(message: String) -> void:
	push_error("[P08_VEHICLE_DOCKING] %s" % message)
	await _finish(1)

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Failed to load production scene %s" % SCENE_PATH)
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame

	# 1. Require root BurnsideCompanionPresenceRuntime
	var runtime := _scene.get_node_or_null("BurnsideCompanionPresenceRuntime")
	if runtime == null:
		await _fail("BurnsideCompanionPresenceRuntime node missing from scene")
		return

	# 2. Require root/mobile FB13CompanionBody
	var fb13 := _scene.get_node_or_null("FB13CompanionBody")
	if fb13 == null:
		await _fail("FB13CompanionBody node missing from scene")
		return

	# 3. Require Runner HS7CarrySocket with one HS-7 visual child
	var runner := _scene.get_node_or_null("Runner") as Node3D
	if runner == null:
		await _fail("Runner node missing from scene")
		return
	var hs7_socket := runner.get_node_or_null("MeshPivot/Torso/HS7CarrySocket") as Node3D
	if hs7_socket == null:
		await _fail("Runner MeshPivot/Torso/HS7CarrySocket missing")
		return
	if hs7_socket.get_child_count() == 0:
		await _fail("HS7CarrySocket has no child visual instance")
		return

	# 4. Require CourierBike FB13DockSocket
	var bike := _scene.get_node_or_null("CourierBike")
	if bike == null:
		await _fail("CourierBike node missing from scene")
		return
	var bike_dock := bike.find_child("FB13DockSocket", true, false) as Node3D
	if bike_dock == null:
		await _fail("CourierBike FB13DockSocket missing")
		return

	# 5. Require ScrapHauler FB13DockSocket
	var hauler := _scene.get_node_or_null("ScrapHauler")
	if hauler == null:
		await _fail("ScrapHauler node missing from scene")
		return
	var hauler_dock := hauler.find_child("FB13DockSocket", true, false) as Node3D
	if hauler_dock == null:
		await _fail("ScrapHauler FB13DockSocket missing")
		return

	# 6. Test CourierBike mount / dock lifecycle
	runner.global_position = bike.global_position + Vector3(0.5, 0.0, 0.5)
	var bike_mounted: bool = bike.call("request_mount", runner)
	if not bike_mounted:
		await _fail("CourierBike request_mount failed")
		return

	# Immediately upon MOUNTING, FB-13 should start docking or be in docking state (state 2: DOCKING_BIKE or 3: DOCKED_BIKE)
	var mount_state: int = int(fb13.call("get_presence_state"))
	if mount_state != 2 and mount_state != 3:
		await _fail("FB-13 did not transition to DOCKING_BIKE upon mount start (got %d)" % mount_state)
		return

	# Wait for 0.25s mount completion
	await create_timer(0.35).timeout
	var docked_state: int = int(fb13.call("get_presence_state"))
	if docked_state != 3: # DOCKED_BIKE
		await _fail("FB-13 not DOCKED_BIKE after mount finished (state=%d)" % docked_state)
		return
	if hs7_socket.get_parent() == null:
		await _fail("HS-7 detached from runner during bike mount")
		return

	# Speed-based rejected dismount: FB-13 remains DOCKED_BIKE
	bike.set("current_speed", 10.0) # > dismount_speed_limit
	var dismount_res: bool = bike.call("request_dismount")
	if dismount_res:
		await _fail("Bike dismount should have been rejected at 10 m/s")
		return
	if int(fb13.call("get_presence_state")) != 3:
		await _fail("FB-13 state changed on rejected dismount")
		return

	# Legal dismount
	bike.set("current_speed", 0.0)
	var legal_dismount: bool = bike.call("request_dismount")
	if not legal_dismount:
		await _fail("Legal bike dismount failed")
		return

	# Wait for 0.2s dismount completion
	await create_timer(0.3).timeout
	var post_dismount_state: int = int(fb13.call("get_presence_state"))
	if post_dismount_state != 0 and post_dismount_state != 1: # FOLLOWING (0) or REJOINING (1)
		await _fail("FB-13 did not return to FOLLOWING/REJOINING after dismount (state=%d)" % post_dismount_state)
		return

	# 7. Test ScrapHauler mount / dock lifecycle with REJOINING override
	fb13.set("current_state", 1) # Force REJOINING
	runner.global_position = hauler.global_position + Vector3(0.5, 0.0, 0.5)
	var hauler_mounted: bool = hauler.call("request_mount", runner)
	if not hauler_mounted:
		await _fail("ScrapHauler request_mount failed")
		return

	# MOUNTING must cleanly override REJOINING into DOCKING_HAULER (4) or DOCKED_HAULER (5)
	var hauler_mount_state: int = int(fb13.call("get_presence_state"))
	if hauler_mount_state != 4 and hauler_mount_state != 5:
		await _fail("Mounting hauler did not override REJOINING into DOCKING_HAULER (got %d)" % hauler_mount_state)
		return

	await create_timer(0.35).timeout
	if int(fb13.call("get_presence_state")) != 5: # DOCKED_HAULER
		await _fail("FB-13 not DOCKED_HAULER after mount finished (state=%d)" % int(fb13.call("get_presence_state")))
		return

	hauler.set("current_speed", 0.0)
	var hauler_dismount: bool = hauler.call("request_dismount")
	if not hauler_dismount:
		await _fail("Legal hauler dismount failed")
		return

	await create_timer(0.3).timeout
	var hauler_post_state: int = int(fb13.call("get_presence_state"))
	if hauler_post_state != 0 and hauler_post_state != 1:
		await _fail("FB-13 did not return to FOLLOWING/REJOINING after hauler dismount (state=%d)" % hauler_post_state)
		return

	print("[P08_VEHICLE_DOCKING] PASS")
	await _finish(0)
