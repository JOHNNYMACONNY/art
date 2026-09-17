extends SceneTree
func _init():
	var root_node := Node3D.new()
	root.add_child(root_node)

	var runner := (load("res://scenes/player/runner.tscn") as PackedScene).instantiate() as CharacterBody3D
	runner.position = Vector3(-1.25, 0.0, 0.0)
	root_node.add_child(runner)
	runner.set_physics_process(false)
	runner.set_process(false)

	var worker := (load("res://scenes/entities/scrap_worker.tscn") as PackedScene).instantiate() as CharacterBody3D
	worker.position = Vector3(0.0, 0.0, 0.0)
	worker.move_speed = 0.0
	root_node.add_child(worker)
	worker.set_physics_process(false)
	worker.set_process(false)

	var crawler := (load("res://scenes/entities/utility_crawler.tscn") as PackedScene).instantiate() as CharacterBody3D
	crawler.position = Vector3(1.25, 0.0, 0.0)
	crawler.move_speed = 0.0
	root_node.add_child(crawler)
	crawler.set_physics_process(false)
	crawler.set_process(false)

	_run(runner, worker, crawler)

func _run(runner, worker, crawler):
	for _i in range(5):
		await process_frame
	# Re-lock positions and rotations
	runner.position = Vector3(-1.25, 0.0, 0.0)
	worker.position = Vector3(0.0, 0.0, 0.0)
	crawler.position = Vector3(1.25, 0.0, 0.0)
	worker.set_physics_process(false)
	crawler.set_physics_process(false)

	print("Shot 1:")
	print("  runner:", runner.global_position)
	print("  worker:", worker.global_position)
	print("  crawler:", crawler.global_position)

	for _i in range(25):
		await process_frame
	print("Shot 2:")
	print("  runner:", runner.global_position)
	print("  worker:", worker.global_position)
	print("  crawler:", crawler.global_position)

	for _i in range(25):
		await process_frame
	print("Shot 3:")
	print("  runner:", runner.global_position)
	print("  worker:", worker.global_position)
	print("  crawler:", crawler.global_position)
	quit()
