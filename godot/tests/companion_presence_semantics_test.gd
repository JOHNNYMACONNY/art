extends SceneTree

const RUNNER_SCENE_PATH := "res://scenes/player/runner.tscn"
const FB13_SCRIPT_PATH := "res://scripts/entities/fb13_companion_body.gd"
const FB13_SCENE_PATH := "res://scenes/entities/fb13_companion_body.tscn"

var _nodes: Array[Node] = []

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	await process_frame
	await process_frame
	quit(code)

func _fail(message: String) -> void:
	push_error("[P08_PRESENCE_SEMANTICS] %s" % message)
	await _finish(1)

func _create_obstacle(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	root.add_child(body)
	_nodes.append(body)
	body.global_position = pos
	return body

func _run() -> void:
	if not ResourceLoader.exists(FB13_SCRIPT_PATH) or not ResourceLoader.exists(FB13_SCENE_PATH):
		await _fail("FB13CompanionBody script or scene is missing (script=%s, scene=%s)" % [
			ResourceLoader.exists(FB13_SCRIPT_PATH),
			ResourceLoader.exists(FB13_SCENE_PATH)
		])
		return

	var fb13_script = load(FB13_SCRIPT_PATH)
	if fb13_script == null:
		await _fail("Failed to load FB13CompanionBody script")
		return

	var required_methods := [
		"configure",
		"tick_presence",
		"begin_dock",
		"release_from_dock",
		"reset_to_follow_position",
		"on_thrum_triggered",
		"get_presence_state",
		"get_follow_distance",
		"get_hard_rejoin_count",
		"get_last_hard_rejoin_snapshot",
		"get_thrum_reaction_count",
	]
	for method_name in required_methods:
		var found := false
		for m in fb13_script.get_script_method_list():
			if m.name == method_name:
				found = true
				break
		if not found:
			await _fail("FB13CompanionBody missing required method: %s" % method_name)
			return

	var runner_packed := load(RUNNER_SCENE_PATH) as PackedScene
	if runner_packed == null:
		await _fail("Failed to load runner scene")
		return
	var runner := runner_packed.instantiate() as Node3D
	root.add_child(runner)
	_nodes.append(runner)
	runner.global_position = Vector3(0, 0, 0)

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.1
	camera.far = 100.0
	root.add_child(camera)
	_nodes.append(camera)
	camera.position = Vector3(0, 10, 10)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)

	var fb13_packed := load(FB13_SCENE_PATH) as PackedScene
	if fb13_packed == null:
		await _fail("Failed to load FB13CompanionBody scene")
		return
	var fb13 = fb13_packed.instantiate() as Node3D
	fb13.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(fb13)
	_nodes.append(fb13)

	await process_frame
	await physics_frame

	fb13.call("configure", runner, camera)

	# Initial FOLLOWING state (enum index 0)
	var state = fb13.call("get_presence_state")
	if int(state) != 0:
		await _fail("Initial presence state is not FOLLOWING (got: %s)" % str(state))
		return

	var follow_dist: float = float(fb13.call("get_follow_distance"))
	if follow_dist >= 8.0:
		await _fail("Initial follow distance %.2f >= 8.0m" % follow_dist)
		return

	if not fb13.find_children("*", "CollisionShape3D", true, false).is_empty():
		await _fail("FB-13 has CollisionShape3D children (must have no collision authority)")
		return

	if not fb13.find_children("*", "Area3D", true, false).is_empty():
		await _fail("FB-13 has Area3D children (must have no collision authority)")
		return

	if not fb13.find_children("*", "NavigationAgent3D", true, false).is_empty():
		await _fail("FB-13 has NavigationAgent3D child (navigation agents prohibited)")
		return

	# Test local follow movement
	runner.global_position += Vector3(4.0, 0.0, 0.0)
	for _i in range(30):
		fb13.call("tick_presence", 1.0 / 60.0)
	var cur_dist: float = fb13.global_position.distance_to(runner.global_position)
	if cur_dist >= 8.0:
		await _fail("FB-13 did not follow runner; distance %.2f >= 8.0m" % cur_dist)
		return

	# Test clearance with blocking fixture
	var obstacle_pos := runner.global_position + Vector3(0.0, 0.5, 2.0)
	var obs := _create_obstacle(obstacle_pos, Vector3(2.0, 2.0, 2.0))
	for _i in range(60):
		fb13.call("tick_presence", 1.0 / 60.0)
	# Must not penetrate obstacle
	var dist_to_obs: float = fb13.global_position.distance_to(obs.global_position)
	if dist_to_obs < 0.6:
		await _fail("FB-13 penetrated obstacle (dist=%.2f)" % dist_to_obs)
		return

	# Separation and rejoin checks
	# 1. 17.9m for > 0.75s -> NO hard rejoin
	fb13.global_position = Vector3(17.9, 0, 0)
	runner.global_position = Vector3(0, 0, 0)
	camera.global_position = Vector3(0, 5, 5)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	var initial_rejoin_count: int = int(fb13.call("get_hard_rejoin_count"))
	for _i in range(50): # ~0.83s
		fb13.call("tick_presence", 1.0 / 60.0)
	if int(fb13.call("get_hard_rejoin_count")) != initial_rejoin_count:
		await _fail("Hard rejoin triggered at 17.9m (< 18.0m threshold)")
		return

	# 2. 18.1m for 0.74s -> NO hard rejoin
	fb13.call("reset_to_follow_position")
	fb13.global_position = Vector3(25.0, 0, 0) # off screen
	runner.global_position = Vector3(0, 0, 0)
	for _i in range(44): # 44 * (1/60) = 0.733s < 0.75s
		fb13.call("tick_presence", 1.0 / 60.0)
	if int(fb13.call("get_hard_rejoin_count")) != initial_rejoin_count:
		await _fail("Hard rejoin triggered before 0.75s duration elapsed")
		return

	# 3. Source visible in frustum -> NO hard rejoin
	fb13.call("reset_to_follow_position")
	camera.global_position = Vector3(0, 10, 25)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	fb13.global_position = Vector3(0, 0, 18.5) # in front of camera, visible
	runner.global_position = Vector3(0, 0, 0)
	for _i in range(60): # 1.0s
		fb13.call("tick_presence", 1.0 / 60.0)
	if int(fb13.call("get_hard_rejoin_count")) != initial_rejoin_count:
		await _fail("Hard rejoin triggered while FB-13 source position was visible in frustum")
		return

	# 4. Source off-screen and valid off-screen staging candidate -> exactly one hard rejoin
	fb13.call("reset_to_follow_position")
	camera.global_position = Vector3(0, 2, 5)
	camera.look_at(Vector3(0, 0, -10), Vector3.UP) # looking north
	fb13.global_position = Vector3(0, 0, 25) # far behind camera (off-screen)
	runner.global_position = Vector3(0, 0, 0)

	for _i in range(60): # 1.0s > 0.75s
		fb13.call("tick_presence", 1.0 / 60.0)

	var new_rejoin_count: int = int(fb13.call("get_hard_rejoin_count"))
	if new_rejoin_count != initial_rejoin_count + 1:
		await _fail("Expected exactly 1 hard rejoin, got %d" % (new_rejoin_count - initial_rejoin_count))
		return

	var snap: Dictionary = fb13.call("get_last_hard_rejoin_snapshot")
	if not snap.get("source_off_screen", false) or not snap.get("staging_off_screen", false):
		await _fail("Hard rejoin snapshot must verify both source and staging were off-screen: %s" % str(snap))
		return

	# State must be REJOINING (enum index 1)
	if int(fb13.call("get_presence_state")) != 1:
		await _fail("Presence state after hard rejoin snap is not REJOINING (got: %s)" % str(fb13.call("get_presence_state")))
		return

	# Physical ticks return FB-13 within 5.0m and transition to FOLLOWING
	for _i in range(300):
		fb13.call("tick_presence", 1.0 / 60.0)
		if int(fb13.call("get_presence_state")) == 0:
			break

	if int(fb13.call("get_presence_state")) != 0:
		await _fail("FB-13 did not return to FOLLOWING state within timeout (current: %s, dist: %.2f)" % [
			str(fb13.call("get_presence_state")),
			fb13.global_position.distance_to(runner.global_position)
		])
		return

	print("[P08_PRESENCE_SEMANTICS] PASS")
	await _finish(0)
