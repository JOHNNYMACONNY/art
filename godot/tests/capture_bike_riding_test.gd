extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "CaptureRoot"
	root.add_child(root_node)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.15, 0.18, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.57, 0.62, 1.0)
	env.ambient_light_energy = 1.3
	env_node.environment = env
	root_node.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.88, 1.0)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	root_node.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.65, 0.72, 0.85, 1.0)
	fill.light_energy = 0.9
	root_node.add_child(fill)

	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(25.0, 25.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.10, 0.11, 0.12, 1.0)
	ground_mat.roughness = 0.92
	plane_mesh.material = ground_mat
	ground.mesh = plane_mesh
	root_node.add_child(ground)

	var outline_mat := StandardMaterial3D.new()
	outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_mat.albedo_color = Color(0.015, 0.015, 0.02, 1.0)
	outline_mat.grow = true
	outline_mat.grow_amount = 0.009

	var bike_scene := load("res://models/courier_bike.glb") as PackedScene
	var bike := bike_scene.instantiate() as Node3D
	bike.position = Vector3(0.0, 0.0, 0.0)
	root_node.add_child(bike)
	_apply_outline(bike, outline_mat)

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	runner.set_physics_process(false)
	runner.set_process(false)
	root_node.add_child(runner)
	_apply_outline(runner, outline_mat)

	runner.position = Vector3(0.0, 0.58, 0.15)
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.play("bike_ride")
	ap.advance(0.1)

	var cam := Camera3D.new()
	cam.fov = 34.0
	root_node.add_child(cam)

	var pitch_rad := deg_to_rad(25.0)
	var yaw_rad := deg_to_rad(140.0)
	var dist := 3.8
	var target := Vector3(0.0, 0.85, 0.0)
	cam.position = target + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target, Vector3.UP)
	cam.make_current()

	for i in range(15):
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/test_bike_ride_actual_iso.png")

	# Side view
	cam.position = Vector3(3.2, 1.1, 0.0)
	cam.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
	for i in range(15):
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/test_bike_ride_actual_side.png")

	quit(0)

func _apply_outline(node: Node, outline_mat: Material) -> void:
	if node is MeshInstance3D and node.mesh:
		for s in range(node.mesh.get_surface_count()):
			var active_mat = node.get_active_material(s)
			if active_mat is StandardMaterial3D:
				active_mat.next_pass = outline_mat
	for child in node.get_children():
		_apply_outline(child, outline_mat)
