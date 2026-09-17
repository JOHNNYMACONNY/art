extends SceneTree

const OUT_DIR := "res://../docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.16, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.68, 0.72, 1.0)
	env.ambient_light_energy = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_bloom = 0.25
	env.glow_hdr_threshold = 1.0
	env_node.environment = env
	root_node.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 38.0, 0.0)
	sun.light_color = Color(1.0, 0.98, 0.92, 1.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	root_node.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.60, 0.70, 0.85, 1.0)
	fill.light_energy = 0.65
	root_node.add_child(fill)

	# Direct light aiming through windshield and side window into cockpit
	var cabin_light := DirectionalLight3D.new()
	cabin_light.rotation_degrees = Vector3(-35.0, 160.0, 0.0)
	cabin_light.light_color = Color(1.0, 0.98, 0.92, 1.0)
	cabin_light.light_energy = 1.65
	root_node.add_child(cabin_light)

	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(40.0, 0.2, 40.0)
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, -0.1, 0.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.14, 0.15, 0.17, 1.0)
	ground_mat.roughness = 0.85
	ground.material_override = ground_mat
	root_node.add_child(ground)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 28.0
	root_node.add_child(cam)

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene

	# =========================================================================
	# 1. MUSCLE COUPE: MACRO, NEUTRAL, STEER LEFT, STEER RIGHT, ISO
	# =========================================================================
	var coupe_scene := load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root_node.add_child(coupe)
	coupe.set_physics_process(false)
	coupe.set_process(false)
	coupe.visible = true
	coupe.position = Vector3.ZERO
	coupe.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	var c_col = coupe.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if c_col: c_col.disabled = true

	var coupe_seat = coupe.find_child("Seat_Driver", true, false)
	var runner_c = runner_scene.instantiate()
	coupe.add_child(runner_c)
	runner_c.set_physics_process(false)
	runner_c.set_process(false)
	runner_c.visible = true
	var rc_col = runner_c.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if rc_col: rc_col.disabled = true
	runner_c.set_vehicle_driving_posture(true, "car")
	runner_c.position = coupe_seat.position + Vector3(0.0, -0.80, 0.08)
	runner_c.rotation = Vector3.ZERO

	var ap = runner_c.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner_c.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)
	await process_frame
	var b_hl = skel.find_bone("Hand.L")
	var b_hr = skel.find_bone("Hand.R")
	var b_head = skel.find_bone("Head")
	print("=== RUNNER IN COUPE POSITIONS ===")
	print("Seat global pos: ", coupe_seat.global_position)
	print("Runner global pos: ", runner_c.global_position)
	print("Hand.L global pos: ", skel.to_global(skel.get_bone_global_pose(b_hl).origin))
	print("Hand.R global pos: ", skel.to_global(skel.get_bone_global_pose(b_hr).origin))
	print("Head global pos: ", skel.to_global(skel.get_bone_global_pose(b_head).origin))

	# A1. Macro close-up on hands gripping the 36cm wheel through side window
	cam.fov = 17.0
	cam.position = Vector3(1.35, 1.32, 0.42)
	cam.look_at(Vector3(0.36, 0.85, 0.36), Vector3.UP)
	ap.play("car_drive")
	ap.advance(0.1)
	for _i in range(12): await process_frame
	var img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_grip_macro_hands.png")
	print("Saved char_grip_macro_hands.png")

	# B. Coupe Front 3/4 neutral driving
	cam.fov = 28.0
	cam.position = Vector3(0.85, 1.95, 2.5)
	cam.look_at(Vector3(0.36, 0.77, 0.25), Vector3.UP)
	for _i in range(10): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_seated_coupe_32deg.png")
	print("Saved char_seated_coupe_32deg.png")

	# C. Coupe Steer Left
	ap.play("car_steer_left")
	ap.advance(0.1)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_steer_coupe_left.png")
	print("Saved char_steer_coupe_left.png")

	# D. Coupe Steer Right
	ap.play("car_steer_right")
	ap.advance(0.1)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_steer_coupe_right.png")
	print("Saved char_steer_coupe_right.png")

	# E. Side profile cockpit view with grip
	ap.play("car_drive")
	ap.advance(0.1)
	cam.position = Vector3(1.65, 1.55, 0.35)
	cam.look_at(Vector3(0.36, 0.85, 0.15), Vector3.UP)
	for _i in range(10): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_seated_coupe_iso.png")
	print("Saved char_seated_coupe_iso.png")

	coupe.queue_free()
	await process_frame

	# =========================================================================
	# 2. SECURITY INTERCEPTOR: NEUTRAL, STEER LEFT, STEER RIGHT, ISO
	# =========================================================================
	var int_scene := load("res://scenes/vehicles/security_interceptor.tscn") as PackedScene
	var interceptor = int_scene.instantiate()
	root_node.add_child(interceptor)
	interceptor.set_physics_process(false)
	interceptor.set_process(false)
	interceptor.visible = true
	interceptor.position = Vector3.ZERO
	interceptor.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	var i_col = interceptor.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if i_col: i_col.disabled = true

	var int_seat = interceptor.find_child("Seat_Driver", true, false)
	var runner_i = runner_scene.instantiate()
	interceptor.add_child(runner_i)
	runner_i.set_physics_process(false)
	runner_i.set_process(false)
	runner_i.visible = true
	var ri_col = runner_i.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if ri_col: ri_col.disabled = true
	runner_i.set_vehicle_driving_posture(true, "car")
	runner_i.position = int_seat.position + Vector3(0.0, -0.80, 0.08)
	runner_i.rotation = Vector3.ZERO

	var ap_i = runner_i.find_child("AnimationPlayer", true, false) as AnimationPlayer

	# A. Neutral
	cam.position = Vector3(0.85, 1.95, 2.5)
	cam.look_at(Vector3(0.38, 0.79, 0.25), Vector3.UP)
	ap_i.play("car_drive")
	ap_i.advance(0.1)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_seated_interceptor_32deg.png")
	print("Saved char_seated_interceptor_32deg.png")

	# B. Interceptor Steer Left
	ap_i.play("car_steer_left")
	ap_i.advance(0.1)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_steer_interceptor_left.png")
	print("Saved char_steer_interceptor_left.png")

	# C. Interceptor Steer Right
	ap_i.play("car_steer_right")
	ap_i.advance(0.1)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_steer_interceptor_right.png")
	print("Saved char_steer_interceptor_right.png")

	# D. Interceptor Iso Side Profile
	ap_i.play("car_drive")
	ap_i.advance(0.1)
	cam.position = Vector3(1.65, 1.55, 0.35)
	cam.look_at(Vector3(0.38, 0.85, 0.15), Vector3.UP)
	for _i in range(10): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_seated_interceptor_iso.png")
	print("Saved char_seated_interceptor_iso.png")

	interceptor.queue_free()
	await process_frame

	# =========================================================================
	# 3. BURNSIDE SCRAP HAULER: NEUTRAL, STEER LEFT, STEER RIGHT, ISO
	# =========================================================================
	var hauler_scene := load("res://scenes/vehicles/scrap_hauler.tscn") as PackedScene
	var hauler = hauler_scene.instantiate()
	root_node.add_child(hauler)
	hauler.set_physics_process(false)
	hauler.set_process(false)
	hauler.visible = true
	hauler.position = Vector3.ZERO
	hauler.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	var h_col = hauler.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if h_col: h_col.disabled = true

	var hauler_seat = hauler.find_child("Seat_Driver", true, false)
	var runner_h = runner_scene.instantiate()
	hauler.add_child(runner_h)
	runner_h.set_physics_process(false)
	runner_h.set_process(false)
	runner_h.visible = true
	var rh_col = runner_h.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if rh_col: rh_col.disabled = true
	runner_h.set_vehicle_driving_posture(true, "car")
	runner_h.position = hauler_seat.position + Vector3(0.0, -0.80, 0.08)
	runner_h.rotation = Vector3.ZERO

	var ap_h = runner_h.find_child("AnimationPlayer", true, false) as AnimationPlayer

	# A. Elevated front 3/4 view into hauler cab
	ap_h.play("car_drive")
	ap_h.advance(0.1)
	cam.position = Vector3(1.10, 3.0, 4.2)
	cam.look_at(Vector3(0.60, 1.95, 2.0), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_seated_hauler_32deg.png")
	print("Saved char_seated_hauler_32deg.png")

	# B. Hauler Steer Left
	ap_h.play("car_steer_left")
	ap_h.advance(0.1)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_steer_hauler_left.png")
	print("Saved char_steer_hauler_left.png")

	# C. Hauler Steer Right
	ap_h.play("car_steer_right")
	ap_h.advance(0.1)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_steer_hauler_right.png")
	print("Saved char_steer_hauler_right.png")

	# D. Side cab profile showing generous ceiling headroom
	ap_h.play("car_drive")
	ap_h.advance(0.1)
	cam.position = Vector3(2.8, 2.4, 2.8)
	cam.look_at(Vector3(0.60, 2.0, 1.8), Vector3.UP)
	for _i in range(10): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/char_seated_hauler_iso.png")
	print("Saved char_seated_hauler_iso.png")

	quit(0)
