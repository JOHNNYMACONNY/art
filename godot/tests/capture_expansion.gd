extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "ExpansionCaptureRoot"
	root.add_child(root_node)

	# World Environment (Gritty Chinatown Wars Graphic Comic Tone)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.16, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.42, 1.0)
	env.ambient_light_energy = 0.55
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_bloom = 0.25
	env.glow_hdr_threshold = 1.0
	env_node.environment = env
	root_node.add_child(env_node)

	# Key light (sun) - hard two-tone cel shadow cuts
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 38.0, 0.0)
	sun.light_color = Color(1.0, 0.98, 0.92, 1.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	root_node.add_child(sun)

	# Cool rim/fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.55, 0.65, 0.78, 1.0)
	fill.light_energy = 0.45
	root_node.add_child(fill)

	# Ground plane (dark industrial asphalt)
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

	# Yellow Road Striping for urban authenticity
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(36.0, 0.02, 0.18)
	stripe.mesh = stripe_mesh
	stripe.position = Vector3(0.0, 0.01, 1.8)
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.92, 0.75, 0.12, 1.0)
	stripe_mat.roughness = 0.6
	stripe.material_override = stripe_mat
	root_node.add_child(stripe)

	# Instance Assets (Spaced generously for zero occlusion)
	# 1. Muscle Coupe
	var coupe_scene := load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	coupe.visible = true
	coupe.position = Vector3(-4.2, 0.0, 0.0)
	coupe.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	root_node.add_child(coupe)
	coupe.set_physics_process(false)
	coupe.set_process(false)
	coupe.velocity = Vector3.ZERO

	# 2. Upgraded Scrap Hauler
	var hauler_scene := load("res://scenes/vehicles/scrap_hauler.tscn") as PackedScene
	var hauler = hauler_scene.instantiate()
	hauler.set_physics_process(false)
	hauler.visible = true
	hauler.position = Vector3(0.0, 0.0, -0.6)
	hauler.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	root_node.add_child(hauler)

	# 3. Security Patrol Interceptor
	var interceptor_scene := load("res://scenes/vehicles/security_interceptor.tscn") as PackedScene
	var interceptor = interceptor_scene.instantiate()
	interceptor.set_physics_process(false)
	interceptor.visible = true
	interceptor.position = Vector3(4.2, 0.0, 0.0)
	interceptor.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	root_node.add_child(interceptor)

	# 4. Traffic Barriers
	var barrier_scene := load("res://scenes/props/prop_traffic_barrier.tscn") as PackedScene
	var barrier1 = barrier_scene.instantiate()
	barrier1.position = Vector3(-7.2, 0.0, 0.2)
	barrier1.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	root_node.add_child(barrier1)

	# 5. Street Vendor Stall
	var vendor_scene := load("res://scenes/props/prop_street_vendor.tscn") as PackedScene
	var vendor = vendor_scene.instantiate()
	vendor.position = Vector3(-9.8, 0.0, -0.5)
	vendor.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	root_node.add_child(vendor)

	# 6. Security Checkpoint (positioned to right flank with zero interceptor overlap)
	var checkpoint_scene := load("res://scenes/props/prop_security_checkpoint.tscn") as PackedScene
	var checkpoint = checkpoint_scene.instantiate()
	checkpoint.position = Vector3(9.8, 0.0, -1.8)
	checkpoint.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	root_node.add_child(checkpoint)

	# Camera
	var cam := Camera3D.new()
	root_node.add_child(cam)

	# =========================================================================
	# VIEW A: 32-Degree Chinatown Wars Gameplay Perspective
	# =========================================================================
	var target := Vector3(0.0, 0.8, 0.0)
	var elev_deg := 32.0
	var azim_deg := 20.0
	var dist := 16.0
	var elev_rad := deg_to_rad(elev_deg)
	var azim_rad := deg_to_rad(azim_deg)
	var cx := target.x + dist * cos(elev_rad) * sin(azim_rad)
	var cy := target.y + dist * sin(elev_rad)
	var cz := target.z + dist * cos(elev_rad) * cos(azim_rad)

	cam.fov = 36.0
	cam.position = Vector3(cx, cy, cz)
	cam.look_at(target, Vector3.UP)

	for _i in range(15):
		interceptor.visible = true
		coupe.position.y = 0.0
		coupe.velocity = Vector3.ZERO
		await process_frame
	interceptor.visible = true
	coupe.position.y = 0.0

	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/expansion_render_32deg.png")
	print("Saved expansion gameplay 32-deg: ", OUT_DIR + "/expansion_render_32deg.png")

	# =========================================================================
	# VIEW B: Front View (Fleet Alignment & Facia Read)
	# =========================================================================
	barrier1.visible = false
	vendor.visible = false
	checkpoint.visible = false

	# Face towards camera (+Z direction)
	coupe.visible = true
	coupe.position = Vector3(-3.2, 0.0, 0.0)
	coupe.rotation_degrees = Vector3(0.0, 180.0, 0.0)

	hauler.visible = true
	hauler.position = Vector3(0.0, 0.0, 0.0)
	hauler.rotation_degrees = Vector3(0.0, 180.0, 0.0)

	interceptor.visible = true
	interceptor.position = Vector3(3.2, 0.0, 0.0)
	interceptor.rotation_degrees = Vector3(0.0, 180.0, 0.0)

	# Front Key Light for crisp comic two-tone illumination on grilles and fascias
	var front_key := DirectionalLight3D.new()
	front_key.rotation_degrees = Vector3(-20.0, 172.0, 0.0)
	front_key.light_color = Color(1.0, 0.98, 0.94, 1.0)
	front_key.light_energy = 1.10
	root_node.add_child(front_key)

	cam.fov = 32.0
	cam.position = Vector3(0.0, 1.3, 11.2)
	cam.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)

	for _i in range(15):
		interceptor.visible = true
		coupe.position.y = 0.0
		coupe.velocity = Vector3.ZERO
		await process_frame
	interceptor.visible = true
	coupe.position.y = 0.0

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/expansion_render_front.png")
	print("Saved expansion front view: ", OUT_DIR + "/expansion_render_front.png")

	front_key.visible = false

	# =========================================================================
	# VIEW C: Side Elevation (Vehicle Fleet Profiles)
	# =========================================================================
	# Side profiles facing right: rotation Y = -90 (270 deg)
	coupe.visible = true
	coupe.position = Vector3(-10.0, 0.0, 0.0)
	coupe.rotation_degrees = Vector3(0.0, -90.0, 0.0)

	hauler.visible = true
	hauler.position = Vector3(0.0, 0.0, 0.0)
	hauler.rotation_degrees = Vector3(0.0, -90.0, 0.0)

	interceptor.visible = true
	interceptor.position = Vector3(9.8, 0.0, 0.0)
	interceptor.rotation_degrees = Vector3(0.0, -90.0, 0.0)

	# Side Key Light — balanced for clear livery reads without specular blowout
	var side_key := DirectionalLight3D.new()
	side_key.rotation_degrees = Vector3(-25.0, 10.0, 0.0)
	side_key.light_color = Color(1.0, 0.97, 0.90, 1.0)
	side_key.light_energy = 1.05
	root_node.add_child(side_key)
	# Secondary fill from opposite angle
	var side_fill := DirectionalLight3D.new()
	side_fill.rotation_degrees = Vector3(-20.0, -20.0, 0.0)
	side_fill.light_color = Color(0.80, 0.85, 1.0, 1.0)
	side_fill.light_energy = 0.6
	root_node.add_child(side_fill)

	cam.fov = 36.0
	cam.position = Vector3(0.0, 1.45, 22.0)
	cam.look_at(Vector3(0.0, 1.10, 0.0), Vector3.UP)

	for _i in range(15):
		interceptor.visible = true
		coupe.position.y = 0.0
		coupe.velocity = Vector3.ZERO
		await process_frame
	interceptor.visible = true
	coupe.position.y = 0.0

	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/expansion_render_side.png")
	print("Saved expansion side view: ", OUT_DIR + "/expansion_render_side.png")

	print("Expansion visual captures complete!")
	quit(0)
