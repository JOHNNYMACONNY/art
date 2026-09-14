extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "CaptureScramblerSuite"
	root.add_child(root_node)

	# World Environment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.14, 0.17, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.60, 0.65, 1.0)
	env.ambient_light_energy = 1.35
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.2
	env_node.environment = env
	root_node.add_child(env_node)

	# Sun (Warm late afternoon key)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 36.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.88, 1.0)
	sun.light_energy = 1.85
	sun.shadow_enabled = true
	root_node.add_child(sun)

	# Fill light (Cool sky bounce)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.65, 0.72, 0.85, 1.0)
	fill.light_energy = 0.95
	root_node.add_child(fill)

	# Cockpit / Handlebar accent light
	var bar_light := DirectionalLight3D.new()
	bar_light.rotation_degrees = Vector3(-55.0, 175.0, 0.0)
	bar_light.light_color = Color(1.0, 0.96, 0.90, 1.0)
	bar_light.light_energy = 1.4
	root_node.add_child(bar_light)

	# Ground plane (Dark asphalt)
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(30.0, 30.0)
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

	# 1. Courier Bike (using updated courier_bike.tscn)
	var bike_scene := load("res://scenes/vehicles/courier_bike.tscn") as PackedScene
	var bike := bike_scene.instantiate() as CharacterBody3D
	bike.position = Vector3.ZERO
	bike.rotation = Vector3.ZERO
	bike.set_physics_process(false)
	bike.set_process(false)
	root_node.add_child(bike)
	_apply_outline(bike, outline_mat)

	# 2. Runner Character
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root_node.add_child(runner)
	_apply_outline(runner, outline_mat)

	# Mount runner to bike
	runner.set_vehicle_driving_posture(true, "bike")
	runner.position = Vector3(0.0, 0.58, 0.15)
	runner.rotation = Vector3.ZERO

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D

	# Camera
	var cam := Camera3D.new()
	cam.current = true
	root_node.add_child(cam)

	# -------------------------------------------------------------------------
	# 1. Side Profile: Rider Triangle (Saddle, Peghold, Handlebars)
	# -------------------------------------------------------------------------
	ap.play("bike_ride")
	ap.advance(0.1)
	cam.fov = 32.0
	cam.position = Vector3(3.4, 1.05, 0.0)
	cam.look_at(Vector3(0.0, 0.95, -0.05), Vector3.UP)
	for _i in range(15): await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_ride_side.png")
	print("Saved proof_bike_ride_side.png")

	# -------------------------------------------------------------------------
	# 2. Elevated 32-degree Chinatown Wars 3/4 Front Isometric
	# -------------------------------------------------------------------------
	var pitch_rad := deg_to_rad(28.0)
	var yaw_rad := deg_to_rad(140.0)
	var dist := 3.8
	var target := Vector3(0.0, 0.85, 0.0)
	cam.fov = 34.0
	cam.position = target + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target, Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_ride_iso.png")
	print("Saved proof_bike_ride_iso.png")

	# -------------------------------------------------------------------------
	# 3. First-Person Rider Cockpit POV (Looking down at handlebars and front wheel)
	# -------------------------------------------------------------------------
	var b_head := skel.find_bone("Head")
	var head_pos := skel.to_global(skel.get_bone_global_pose(b_head).origin)
	cam.fov = 72.0
	cam.position = head_pos + Vector3(0.0, 0.04, -0.24)
	cam.look_at(Vector3(0.0, 1.05, -0.75), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_ride_pov.png")
	print("Saved proof_bike_ride_pov.png")

	# 3B. Over-The-Shoulder (OTS) Cinematic Riding View
	cam.fov = 48.0
	cam.position = head_pos + Vector3(0.38, 0.22, 0.45)
	cam.look_at(Vector3(0.0, 1.08, -0.55), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_ride_ots.png")
	print("Saved proof_bike_ride_ots.png")

	# -------------------------------------------------------------------------
	# 4. Front Windshield / Head-on Stance (Wide Scrambler Elbows & Visor)
	# -------------------------------------------------------------------------
	cam.fov = 38.0
	cam.position = Vector3(0.0, 1.22, -2.6)
	cam.look_at(Vector3(0.0, 1.05, -0.1), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_ride_front.png")
	print("Saved proof_bike_ride_front.png")

	# -------------------------------------------------------------------------
	# 5. Macro on Tactical Glove Gripping Handlebar & Brake Lever
	# -------------------------------------------------------------------------
	var b_hand_l := skel.find_bone("Hand.L")
	var hand_l_pos := skel.to_global(skel.get_bone_global_pose(b_hand_l).origin)
	cam.fov = 18.0
	cam.position = hand_l_pos + Vector3(-0.45, 0.32, 0.42)
	cam.look_at(hand_l_pos + Vector3(0.0, -0.04, -0.08), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_macro_hands.png")
	print("Saved proof_bike_macro_hands.png")

	# -------------------------------------------------------------------------
	# 6. Hard Left Lean & Countersteer
	# -------------------------------------------------------------------------
	ap.play("bike_lean_left")
	ap.advance(0.1)
	if bike.visual_root:
		bike.visual_root.rotation.z = deg_to_rad(12.0)
	cam.fov = 34.0
	cam.position = target + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target, Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_lean_left.png")
	print("Saved proof_bike_lean_left.png")

	# -------------------------------------------------------------------------
	# 7. Hard Right Lean & Countersteer
	# -------------------------------------------------------------------------
	ap.play("bike_lean_right")
	ap.advance(0.1)
	if bike.visual_root:
		bike.visual_root.rotation.z = deg_to_rad(-12.0)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_bike_lean_right.png")
	print("Saved proof_bike_lean_right.png")

	print("\n=== FULL SCRAMBLER SUITE CAPTURES COMPLETE ===")
	quit(0)

func _apply_outline(node: Node, outline_mat: Material) -> void:
	if node is MeshInstance3D and node.mesh:
		for s in range(node.mesh.get_surface_count()):
			var active_mat = node.get_active_material(s)
			if active_mat is StandardMaterial3D:
				active_mat.next_pass = outline_mat
	for child in node.get_children():
		_apply_outline(child, outline_mat)
