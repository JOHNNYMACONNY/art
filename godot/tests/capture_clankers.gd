extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "ClankersCaptureRoot"
	root.add_child(root_node)

	# World Environment (High-contrast graphic comic lighting)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.15, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.40, 0.42, 0.46, 1.0)
	env.ambient_light_energy = 0.35
	env.glow_enabled = true
	env.glow_intensity = 0.40
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.25
	env_node.environment = env
	root_node.add_child(env_node)

	# Key light (sun) - carves hard two-tone cel shadow cuts
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	sun.light_color = Color(1.0, 0.96, 0.90, 1.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	root_node.add_child(sun)

	# Subtle cool fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.55, 0.65, 0.80, 1.0)
	fill.light_energy = 0.25
	root_node.add_child(fill)

	# Ground plane
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(30.0, 30.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.10, 0.11, 0.12, 1.0)
	ground_mat.roughness = 0.92
	plane_mesh.material = ground_mat
	ground.mesh = plane_mesh
	root_node.add_child(ground)

	# 1. Instantiate Runner Protagonist (Left, scale reference)
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	runner.position = Vector3(-1.25, 0.0, 0.0)
	runner.rotation_degrees = Vector3(0.0, 15.0, 0.0)
	root_node.add_child(runner)
	runner.set_physics_process(false)
	runner.set_process(false)

	# 2. Instantiate Scrap Worker Bot (Center, rotated 185 deg to face camera)
	var worker_scene := load("res://scenes/entities/scrap_worker.tscn") as PackedScene
	var worker := worker_scene.instantiate() as CharacterBody3D
	worker.position = Vector3(0.0, 0.0, 0.0)
	worker.rotation_degrees = Vector3(0.0, 5.0, 0.0)
	worker.move_speed = 0.0
	root_node.add_child(worker)
	worker.set_physics_process(false)
	worker.set_process(false)

	# 3. Instantiate Utility Crawler Bot (Right, rotated -15 deg to face camera)
	var crawler_scene := load("res://scenes/entities/utility_crawler.tscn") as PackedScene
	var crawler := crawler_scene.instantiate() as CharacterBody3D
	crawler.position = Vector3(1.25, 0.0, 0.0)
	crawler.rotation_degrees = Vector3(0.0, -15.0, 0.0)
	crawler.move_speed = 0.0
	root_node.add_child(crawler)
	crawler.set_physics_process(false)
	crawler.set_process(false)

	# Camera at 32-degree elevated Chinatown Wars angle
	var cam := Camera3D.new()
	cam.fov = 34.0
	root_node.add_child(cam)

	var pitch_rad := deg_to_rad(32.0)
	var dist := 5.2
	var target_center := Vector3(0.0, 0.7, 0.0)

	# Wait a few frames for scene setup and shaders
	for _i in range(5):
		await process_frame

	# Ensure perfect alignment
	runner.position = Vector3(-1.25, 0.0, 0.0)
	worker.position = Vector3(0.0, 0.0, 0.0)
	worker.rotation_degrees = Vector3(0.0, 5.0, 0.0)
	crawler.position = Vector3(1.25, 0.0, 0.0)
	crawler.rotation_degrees = Vector3(0.0, -15.0, 0.0)

	# Front 32° View (Yaw -20 deg)
	var yaw_rad := deg_to_rad(-20.0)
	cam.position = target_center + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target_center, Vector3.UP)
	cam.make_current()

	for _i in range(15):
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/clankers_render_32deg.png")
	print("Saved clankers front 32-deg: ", OUT_DIR + "/clankers_render_32deg.png")

	# Ensure perfect alignment for rear shot
	runner.position = Vector3(-1.25, 0.0, 0.0)
	worker.position = Vector3(0.0, 0.0, 0.0)
	worker.rotation_degrees = Vector3(0.0, 5.0, 0.0)
	crawler.position = Vector3(1.25, 0.0, 0.0)
	crawler.rotation_degrees = Vector3(0.0, -15.0, 0.0)

	# Rear 32° view (Yaw 180 deg - direct back elevation)
	yaw_rad = deg_to_rad(180.0)
	cam.position = target_center + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target_center, Vector3.UP)

	for _i in range(15):
		await process_frame

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/clankers_render_rear_32deg.png")
	print("Saved clankers rear 32-deg: ", OUT_DIR + "/clankers_render_rear_32deg.png")

	# Ensure perfect alignment for topdown shot
	runner.position = Vector3(-1.25, 0.0, 0.0)
	worker.position = Vector3(0.0, 0.0, 0.0)
	worker.rotation_degrees = Vector3(0.0, 5.0, 0.0)
	crawler.position = Vector3(1.25, 0.0, 0.0)
	crawler.rotation_degrees = Vector3(0.0, -15.0, 0.0)

	# Top-down view
	cam.position = Vector3(0.0, 5.5, 0.0)
	cam.look_at(Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0))

	for _i in range(15):
		await process_frame

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/clankers_render_topdown.png")
	print("Saved clankers topdown: ", OUT_DIR + "/clankers_render_topdown.png")

	print("Clankers visual captures complete!")
	quit()
