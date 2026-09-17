extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "SkinsCaptureRoot"
	root.add_child(root_node)

	# World Environment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.15, 0.18, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.54, 0.58, 1.0)
	env.ambient_light_energy = 1.3
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env_node.environment = env
	root_node.add_child(env_node)

	# Sun
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.88, 1.0)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	root_node.add_child(sun)

	# Fill
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.65, 0.72, 0.85, 1.0)
	fill.light_energy = 0.9
	root_node.add_child(fill)

	# Ground
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(30.0, 30.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.10, 0.11, 0.12, 1.0)
	ground_mat.roughness = 0.92
	plane_mesh.material = ground_mat
	ground.mesh = plane_mesh
	root_node.add_child(ground)

	# Outline material
	var outline_mat := StandardMaterial3D.new()
	outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_mat.albedo_color = Color(0.015, 0.015, 0.02, 1.0)
	outline_mat.grow = true
	outline_mat.grow_amount = 0.010

	# 1. Courier Bike (Center)
	var bike_scene := load("res://models/courier_bike.glb") as PackedScene
	var bike := bike_scene.instantiate() as Node3D
	bike.position = Vector3(0.0, 0.0, 0.0)
	bike.rotation_degrees = Vector3(0.0, -10.0, 0.0)
	root_node.add_child(bike)
	_apply_outline(bike, outline_mat)

	# 2. Base Skin Runner (Left)
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner_default := runner_scene.instantiate() as CharacterBody3D
	runner_default.position = Vector3(-1.15, 0.0, 0.15)
	runner_default.rotation_degrees = Vector3(0.0, 20.0, 0.0)
	root_node.add_child(runner_default)

	# 3. Silent Core Skin Runner (Right)
	var runner_silent := runner_scene.instantiate() as CharacterBody3D
	runner_silent.position = Vector3(1.15, 0.0, 0.15)
	runner_silent.rotation_degrees = Vector3(0.0, -20.0, 0.0)
	root_node.add_child(runner_silent)
	runner_silent.set_skin("SILENT_CORE")

	# Camera at 32-degree elevated Chinatown Wars angle
	var cam := Camera3D.new()
	cam.fov = 32.0
	root_node.add_child(cam)

	var pitch_rad := deg_to_rad(32.0)
	var yaw_rad := deg_to_rad(145.0)
	var dist := 5.2
	var target_center := Vector3(0.0, 0.85, 0.0)

	cam.position = target_center + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target_center, Vector3.UP)
	cam.make_current()

	for _i in range(25):
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/skins_comparison_front_32deg.png")
	print("Saved skins front 32-deg: ", OUT_DIR + "/skins_comparison_front_32deg.png")

	# Rear 3/4 view
	yaw_rad = deg_to_rad(-35.0)
	cam.position = target_center + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target_center, Vector3.UP)

	for _i in range(20):
		await process_frame

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/skins_comparison_rear_32deg.png")
	print("Saved skins rear 32-deg: ", OUT_DIR + "/skins_comparison_rear_32deg.png")

	# Top-down view
	cam.position = Vector3(0.0, 5.2, 0.0)
	cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)

	for _i in range(20):
		await process_frame

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/skins_comparison_topdown.png")
	print("Saved skins topdown: ", OUT_DIR + "/skins_comparison_topdown.png")

	print("Skins comparison visual captures complete!")
	quit()

func _apply_outline(node: Node, outline_mat: Material) -> void:
	if node is MeshInstance3D and node.mesh:
		for s in range(node.mesh.get_surface_count()):
			var active_mat = node.get_active_material(s)
			if active_mat is StandardMaterial3D:
				active_mat.next_pass = outline_mat
	for child in node.get_children():
		_apply_outline(child, outline_mat)
