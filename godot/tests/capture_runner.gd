extends SceneTree

const RUNNER_SCENE_PATH := "res://scenes/player/runner.tscn"
const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "CaptureRoot"
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

	# Directional Sun Light (Chinatown Wars late afternoon key)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.88, 1.0)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	root_node.add_child(sun)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.65, 0.72, 0.85, 1.0)
	fill.light_energy = 0.9
	root_node.add_child(fill)

	# Ground plane
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(20.0, 20.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.10, 0.11, 0.12, 1.0)
	ground_mat.roughness = 0.92
	plane_mesh.material = ground_mat
	ground.mesh = plane_mesh
	root_node.add_child(ground)

	# Instantiate Runner
	var runner_res := load(RUNNER_SCENE_PATH) as PackedScene
	var runner := runner_res.instantiate() as CharacterBody3D
	runner.position = Vector3(0.0, 0.0, 0.0)
	root_node.add_child(runner)

	# Camera at 32-degree elevated 3/4 Chinatown Wars angle
	var cam := Camera3D.new()
	cam.fov = 32.0
	root_node.add_child(cam)

	var pitch_rad := deg_to_rad(32.0)
	var yaw_rad := deg_to_rad(145.0) # Front-facing 3/4 angle
	var dist := 3.4
	var target_center := Vector3(0.0, 0.95, 0.0)

	var cam_x := dist * cos(pitch_rad) * sin(yaw_rad)
	var cam_y := target_center.y + dist * sin(pitch_rad)
	var cam_z := dist * cos(pitch_rad) * cos(yaw_rad)
	cam.position = Vector3(cam_x, cam_y, cam_z)
	cam.look_at(target_center)
	cam.make_current()

	# Settle physics and pipeline
	for _i in range(30):
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		var out_path := OUT_DIR + "/runner_render_iso.png"
		img.save_png(out_path)
		print("Saved 32-degree front-3/4 render: ", out_path)

	# Rear 3/4 render (showing satchel, back stripe, collar, spoiler)
	yaw_rad = deg_to_rad(-35.0)
	cam_x = dist * cos(pitch_rad) * sin(yaw_rad)
	cam_y = target_center.y + dist * sin(pitch_rad)
	cam_z = dist * cos(pitch_rad) * cos(yaw_rad)
	cam.position = Vector3(cam_x, cam_y, cam_z)
	cam.look_at(target_center)
	for _i in range(15):
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		var out_path := OUT_DIR + "/runner_render_rear_iso.png"
		img.save_png(out_path)
		print("Saved 32-degree rear-3/4 render: ", out_path)

	# Top-down render
	cam.position = Vector3(0.0, 4.2, 0.0)
	cam.look_at(target_center, Vector3(0.0, 0.0, -1.0))
	for _i in range(15):
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		var out_path := OUT_DIR + "/runner_render_topdown.png"
		img.save_png(out_path)
		print("Saved top-down render: ", out_path)

	# Mounted posture render
	runner.set_mounted_posture(true)
	yaw_rad = deg_to_rad(130.0)
	cam_x = dist * cos(pitch_rad) * sin(yaw_rad)
	cam_y = 0.65 + dist * sin(pitch_rad)
	cam_z = dist * cos(pitch_rad) * cos(yaw_rad)
	cam.position = Vector3(cam_x, cam_y, cam_z)
	cam.look_at(Vector3(0.0, 0.65, 0.0))
	for _i in range(15):
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		var out_path := OUT_DIR + "/runner_render_mounted.png"
		img.save_png(out_path)
		print("Saved mounted posture render: ", out_path)

	print("All runner visual renders captured successfully!")
	quit(0)
