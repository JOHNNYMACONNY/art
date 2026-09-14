extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"
const ARTIFACT_DIR := "/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "CaptureBikeApexLeanSuite"
	root.add_child(root_node)

	# World Environment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.16, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.60, 0.62, 0.68, 1.0)
	env.ambient_light_energy = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.04
	env_node.environment = env
	root_node.add_child(env_node)

	# Main Key Light
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38.0, 42.0, 0.0)
	sun.light_color = Color(1.0, 0.96, 0.90, 1.0)
	sun.light_energy = 1.9
	sun.shadow_enabled = true
	root_node.add_child(sun)

	# Fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, -140.0, 0.0)
	fill.light_color = Color(0.65, 0.72, 0.88, 1.0)
	fill.light_energy = 1.0
	root_node.add_child(fill)

	# Rim / Hair light
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-60.0, 180.0, 0.0)
	rim.light_color = Color(0.9, 0.95, 1.0, 1.0)
	rim.light_energy = 1.2
	root_node.add_child(rim)

	# Ground plane (dark tarmac with subtle texture lines)
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(40.0, 40.0)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.09, 0.10, 0.11, 1.0)
	ground_mat.roughness = 0.9
	plane_mesh.material = ground_mat
	ground.mesh = plane_mesh
	root_node.add_child(ground)

	var outline_mat := StandardMaterial3D.new()
	outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_mat.albedo_color = Color(0.015, 0.015, 0.02, 1.0)
	outline_mat.grow = true
	outline_mat.grow_amount = 0.009

	# 1. Instantiate Bike
	var bike_scene := load("res://scenes/vehicles/courier_bike.tscn") as PackedScene
	var bike := bike_scene.instantiate() as CharacterBody3D
	bike.position = Vector3.ZERO
	bike.rotation = Vector3.ZERO
	bike.set_physics_process(false)
	bike.set_process(false)
	root_node.add_child(bike)
	_apply_outline(bike, outline_mat)

	# 2. Instantiate Runner
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root_node.add_child(runner)
	_apply_outline(runner, outline_mat)

	# Mount runner to bike
	runner.set_vehicle_driving_posture(true, "bike")
	runner.is_mounted = true
	bike.occupant = runner

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer

	# Camera
	var cam := Camera3D.new()
	cam.current = true
	root_node.add_child(cam)

	var vp := root.get_viewport()
	vp.size = Vector2i(1280, 720)

	var captured_images: Dictionary = {}

	# =========================================================================
	# CAPTURE SETTINGS: 3 Postures x 2 Camera Angles (OTS Rear & Front Head-on)
	# =========================================================================
	var postures := [
		{
			"id": "lean_left",
			"label": "Apex Lean Left (-14 deg bank + spine roll)",
			"anim": "bike_lean_left",
			"bike_roll_deg": 14.0 # Roll left
		},
		{
			"id": "upright",
			"label": "Straight Riding (0 deg bank - center)",
			"anim": "bike_ride",
			"bike_roll_deg": 0.0
		},
		{
			"id": "lean_right",
			"label": "Apex Lean Right (+14 deg bank + spine roll)",
			"anim": "bike_lean_right",
			"bike_roll_deg": -14.0 # Roll right
		}
	]

	for p in postures:
		var pid: String = p["id"]
		var anim_name: String = p["anim"]
		var roll_deg: float = p["bike_roll_deg"]

		# Set bike visual roll
		bike.visual_root.rotation.z = deg_to_rad(roll_deg)
		# Update rider tracking
		runner.global_position = bike.rider_socket.global_position
		runner.global_basis = bike.rider_socket.global_basis

		# Play animation
		ap.play(anim_name)
		ap.advance(0.1)

		for _i in range(10): await process_frame

		# Angle 1: Rear OTS / Chase view (looking forward over rider's shoulder)
		cam.fov = 34.0
		cam.position = Vector3(0.35, 1.55, 3.0)
		cam.look_at(Vector3(0.0, 0.90, -0.6), Vector3.UP)
		for _i in range(8): await process_frame
		var img_ots := vp.get_texture().get_image()
		var path_ots := OUT_DIR + "/bike_apex_" + pid + "_ots.png"
		img_ots.save_png(path_ots)
		img_ots.save_png(ARTIFACT_DIR + "/bike_apex_" + pid + "_ots.png")
		captured_images[pid + "_ots"] = img_ots
		print("Saved: ", path_ots)

		# Angle 2: Front Head-on Action view (camera framed to capture full rider and bike)
		cam.fov = 34.0
		cam.position = Vector3(0.0, 1.15, -3.4)
		cam.look_at(Vector3(0.0, 0.90, 0.0), Vector3.UP)
		for _i in range(8): await process_frame
		var img_front := vp.get_texture().get_image()
		var path_front := OUT_DIR + "/bike_apex_" + pid + "_front.png"
		img_front.save_png(path_front)
		img_front.save_png(ARTIFACT_DIR + "/bike_apex_" + pid + "_front.png")
		captured_images[pid + "_front"] = img_front
		print("Saved: ", path_front)

		# Angle 3: Dynamic 3/4 Low Front Action Iso
		cam.fov = 34.0
		var iso_x: float = -2.2 if roll_deg >= 0.0 else 2.2
		cam.position = Vector3(iso_x, 1.1, -3.0)
		cam.look_at(Vector3(0.0, 0.85, 0.0), Vector3.UP)
		for _i in range(8): await process_frame
		var img_iso := vp.get_texture().get_image()
		var path_iso := OUT_DIR + "/bike_apex_" + pid + "_iso.png"
		img_iso.save_png(path_iso)
		img_iso.save_png(ARTIFACT_DIR + "/bike_apex_" + pid + "_iso.png")
		captured_images[pid + "_iso"] = img_iso
		print("Saved: ", path_iso)

	# Build a Master 6-Panel Apex Comparison Board:
	# Row 1: Front Views [Left Lean | Upright | Right Lean]
	# Row 2: Rear OTS Views [Left Lean | Upright | Right Lean]
	var cell_w := 640
	var cell_h := 360
	var board_w := cell_w * 3
	var board_h := cell_h * 2

	var board := Image.create(board_w, board_h, false, Image.FORMAT_RGBA8)
	board.fill(Color(0.08, 0.09, 0.11, 1.0))

	var panels := [
		# Row 1: Front
		[captured_images["lean_left_front"], 0, 0],
		[captured_images["upright_front"], cell_w, 0],
		[captured_images["lean_right_front"], cell_w * 2, 0],
		# Row 2: Rear OTS
		[captured_images["lean_left_ots"], 0, cell_h],
		[captured_images["upright_ots"], cell_w, cell_h],
		[captured_images["lean_right_ots"], cell_w * 2, cell_h],
	]

	for p in panels:
		var src_img: Image = p[0]
		var px: int = p[1]
		var py: int = p[2]
		var scaled := src_img.duplicate()
		scaled.convert(Image.FORMAT_RGBA8)
		scaled.resize(cell_w, cell_h, Image.INTERPOLATE_LANCZOS)
		board.blit_rect(scaled, Rect2i(0, 0, cell_w, cell_h), Vector2i(px, py))

	var board_path := OUT_DIR + "/bike_apex_lean_master_board.png"
	board.save_png(board_path)
	board.save_png(ARTIFACT_DIR + "/bike_apex_lean_master_board.png")
	print("\nSaved Master 6-Panel Board: ", board_path)

	print("\n=== BIKE APEX LEAN CAPTURES COMPLETE ===")
	quit(0)

func _apply_outline(node: Node, mat: Material) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.visible:
			var orig_mat: Material = child.material_override
			if orig_mat is StandardMaterial3D:
				var m := orig_mat.duplicate() as StandardMaterial3D
				m.next_pass = mat
				child.material_override = m
			elif orig_mat is ShaderMaterial:
				var sm := orig_mat.duplicate() as ShaderMaterial
				sm.next_pass = mat
				child.material_override = sm
		_apply_outline(child, mat)
