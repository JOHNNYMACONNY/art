extends SceneTree

const OUT_DIR := "/Users/bobbyinthelobby/{art/docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root_node.name = "SolveRoot"
	root.add_child(root_node)

	# Environment
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

	# 1. Bike
	var bike_scene := load("res://models/courier_bike.glb") as PackedScene
	var bike := bike_scene.instantiate() as Node3D
	bike.position = Vector3.ZERO
	root_node.add_child(bike)
	_apply_outline(bike, outline_mat)

	# 2. Runner
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	runner.set_physics_process(false)
	runner.set_process(false)
	root_node.add_child(runner)
	_apply_outline(runner, outline_mat)

	# Runner mount origin: on bike saddle forward zone
	runner.position = Vector3(0.0, 0.58, 0.15)
	runner.rotation = Vector3.ZERO

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer

	# We construct the animation dynamically and apply it
	var anim := ap.get_animation("bike_ride").duplicate() as Animation

	# Biomechanical Angles in Degrees:
	# Torso forward pitch: Hips ~ 22 deg, Abdomen ~ 6 deg, Torso ~ 8 deg, Chest ~ 6 deg. Total spine pitch ~ 42 deg forward crouch.
	# Head upright: Neck -16 deg, Head -18 deg.
	# Legs: Thigh forward-down 68 deg, Knee bend 86 deg, Foot horizontal.
	# Arms: Scrambler attack flaring out and extending to grips.

	# Targets:
	var grip_l := Vector3(-0.422, 1.183, -0.455)
	var grip_r := Vector3(0.422, 1.183, -0.455)
	var saddle_pos := Vector3(0.0, 0.985, 0.22)

	# Bone Rotations (Local space relative to parent rest)
	# Hips local position: lowering pelvis onto saddle cushion
	# In skel space (Model has 180 Y rot, so X_skel = -X_world, Z_skel = -Z_world)
	var hips_local_pos := Vector3(0.0, 0.445, -0.07) # Places hips in world at Y ~ 0.99, Z ~ 0.22

	# Hips rotation: pitch forward ~20 deg
	var q_hips := Quaternion.from_euler(Vector3(deg_to_rad(20.0), 0.0, 0.0))
	var q_abdomen := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_torso := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_chest := Quaternion.from_euler(Vector3(deg_to_rad(6.0), 0.0, 0.0))
	var q_neck := Quaternion.from_euler(Vector3(deg_to_rad(-16.0), 0.0, 0.0))
	var q_head := Quaternion.from_euler(Vector3(deg_to_rad(-20.0), 0.0, 0.0))

	# Legs:
	# In rest pose, UpperLeg has rotation. We apply delta or absolute.
	# UpperLeg.L: hip flexion forward, slight inward adduction
	var q_uleg_l := Quaternion.from_euler(Vector3(deg_to_rad(-62.0), deg_to_rad(8.0), deg_to_rad(-14.0))) * skel.get_bone_rest(skel.find_bone("UpperLeg.L")).basis.get_rotation_quaternion()
	var q_lleg_l := Quaternion.from_euler(Vector3(deg_to_rad(84.0), 0.0, 0.0)) * skel.get_bone_rest(skel.find_bone("LowerLeg.L")).basis.get_rotation_quaternion()
	var q_foot_l := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), 0.0, deg_to_rad(6.0))) * skel.get_bone_rest(skel.find_bone("Foot.L")).basis.get_rotation_quaternion()

	var q_uleg_r := Quaternion.from_euler(Vector3(deg_to_rad(-62.0), deg_to_rad(-8.0), deg_to_rad(14.0))) * skel.get_bone_rest(skel.find_bone("UpperLeg.R")).basis.get_rotation_quaternion()
	var q_lleg_r := Quaternion.from_euler(Vector3(deg_to_rad(84.0), 0.0, 0.0)) * skel.get_bone_rest(skel.find_bone("LowerLeg.R")).basis.get_rotation_quaternion()
	var q_foot_r := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), 0.0, deg_to_rad(-6.0))) * skel.get_bone_rest(skel.find_bone("Foot.R")).basis.get_rotation_quaternion()

	# Arms:
	# Scrambler attack posture: upper arms pitched forward from shoulder, elbows flared outward
	var rest_ua_l := skel.get_bone_rest(skel.find_bone("UpperArm.L")).basis.get_rotation_quaternion()
	var rest_la_l := skel.get_bone_rest(skel.find_bone("LowerArm.L")).basis.get_rotation_quaternion()
	var rest_h_l  := skel.get_bone_rest(skel.find_bone("Hand.L")).basis.get_rotation_quaternion()

	var rest_ua_r := skel.get_bone_rest(skel.find_bone("UpperArm.R")).basis.get_rotation_quaternion()
	var rest_la_r := skel.get_bone_rest(skel.find_bone("LowerArm.R")).basis.get_rotation_quaternion()
	var rest_h_r  := skel.get_bone_rest(skel.find_bone("Hand.R")).basis.get_rotation_quaternion()

	# Arm rotations reaching for the handlebar grips at (-0.42, 1.18, -0.46)
	var q_uarm_l := Quaternion.from_euler(Vector3(deg_to_rad(-52.0), deg_to_rad(28.0), deg_to_rad(32.0))) * rest_ua_l
	var q_larm_l := Quaternion.from_euler(Vector3(deg_to_rad(-18.0), deg_to_rad(24.0), deg_to_rad(-48.0))) * rest_la_l
	var q_hand_l := Quaternion.from_euler(Vector3(deg_to_rad(22.0), deg_to_rad(36.0), deg_to_rad(18.0))) * rest_h_l

	var q_uarm_r := Quaternion.from_euler(Vector3(deg_to_rad(-52.0), deg_to_rad(-28.0), deg_to_rad(-32.0))) * rest_ua_r
	var q_larm_r := Quaternion.from_euler(Vector3(deg_to_rad(-18.0), deg_to_rad(-24.0), deg_to_rad(48.0))) * rest_la_r
	var q_hand_r := Quaternion.from_euler(Vector3(deg_to_rad(22.0), deg_to_rad(-36.0), deg_to_rad(-18.0))) * rest_h_r

	# Tactical Glove finger curl around 2.2cm diameter handlebar tube:
	# Knuckles (MCP 45 deg), Interphalangeal (PIP 65 deg, DIP 40 deg)
	var q_knuckle := Quaternion.from_euler(Vector3(deg_to_rad(48.0), 0.0, 0.0))
	var q_mid_pip := Quaternion.from_euler(Vector3(deg_to_rad(65.0), 0.0, 0.0))
	var q_dist_dip := Quaternion.from_euler(Vector3(deg_to_rad(42.0), 0.0, 0.0))
	# Thumb wrapped underneath in safety lock
	var q_thumb2 := Quaternion.from_euler(Vector3(deg_to_rad(-22.0), deg_to_rad(45.0), deg_to_rad(-35.0)))
	var q_thumb3 := Quaternion.from_euler(Vector3(deg_to_rad(-45.0), 0.0, 0.0))

	var bone_rot_map := {
		"Hips": q_hips,
		"Abdomen": q_abdomen,
		"Torso": q_torso,
		"Chest": q_chest,
		"Neck": q_neck,
		"Head": q_head,

		"UpperLeg.L": q_uleg_l,
		"LowerLeg.L": q_lleg_l,
		"Foot.L": q_foot_l,
		"UpperLeg.R": q_uleg_r,
		"LowerLeg.R": q_lleg_r,
		"Foot.R": q_foot_r,

		"UpperArm.L": q_uarm_l,
		"LowerArm.L": q_larm_l,
		"Hand.L": q_hand_l,
		"UpperArm.R": q_uarm_r,
		"LowerArm.R": q_larm_r,
		"Hand.R": q_hand_r,

		# Fingers L
		"Index2.L": q_knuckle,
		"Index3.L": q_mid_pip,
		"Index4.L": q_dist_dip,
		"Middle2.L": q_knuckle,
		"Middle3.L": q_mid_pip,
		"Middle4.L": q_dist_dip,
		"Ring2.L": q_knuckle,
		"Ring3.L": q_mid_pip,
		"Ring4.L": q_dist_dip,
		"Pinky2.L": q_knuckle,
		"Pinky3.L": q_mid_pip,
		"Pinky4.L": q_dist_dip,
		"Thumb2.L": q_thumb2,
		"Thumb3.L": q_thumb3,

		# Fingers R
		"Index2.R": q_knuckle,
		"Index3.R": q_mid_pip,
		"Index4.R": q_dist_dip,
		"Middle2.R": q_knuckle,
		"Middle3.R": q_mid_pip,
		"Middle4.R": q_dist_dip,
		"Ring2.R": q_knuckle,
		"Ring3.R": q_mid_pip,
		"Ring4.R": q_dist_dip,
		"Pinky2.R": q_knuckle,
		"Pinky3.R": q_mid_pip,
		"Pinky4.R": q_dist_dip,
		"Thumb2.R": Quaternion.from_euler(Vector3(deg_to_rad(-22.0), deg_to_rad(-45.0), deg_to_rad(35.0))),
		"Thumb3.R": q_thumb3,
	}

	# Update animation tracks
	for i in range(anim.get_track_count()):
		var path_str := str(anim.track_get_path(i))
		var track_type := anim.track_get_type(i)

		# Hips position
		if track_type == Animation.TYPE_POSITION_3D and path_str.ends_with(":Hips"):
			for k in range(anim.track_get_key_count(i)):
				anim.track_set_key_value(i, k, hips_local_pos)

		# Bone rotations
		if track_type == Animation.TYPE_ROTATION_3D:
			for bname in bone_rot_map:
				if path_str.ends_with(":" + bname):
					var q: Quaternion = bone_rot_map[bname]
					for k in range(anim.track_get_key_count(i)):
						anim.track_set_key_value(i, k, q)

	# Save as res://scenes/player/anim_bike_ride.res
	var err := ResourceSaver.save(anim, "res://scenes/player/anim_bike_ride.res")
	print("Saved anim_bike_ride.res code: ", err)

	# Bind to anim_player and play
	var lib := ap.get_animation_library("")
	if lib.has_animation("bike_ride"):
		lib.remove_animation("bike_ride")
	lib.add_animation("bike_ride", anim)
	ap.play("bike_ride")
	ap.advance(0.1)

	# Measure contacts
	for _i in range(5):
		await process_frame

	var b_hips := skel.find_bone("Hips")
	var b_head := skel.find_bone("Head")
	var b_hand_l := skel.find_bone("Hand.L")
	var b_hand_r := skel.find_bone("Hand.R")
	var b_foot_l := skel.find_bone("Foot.L")
	var b_foot_r := skel.find_bone("Foot.R")

	var pos_hips := skel.to_global(skel.get_bone_global_pose(b_hips).origin)
	var pos_head := skel.to_global(skel.get_bone_global_pose(b_head).origin)
	var pos_hand_l := skel.to_global(skel.get_bone_global_pose(b_hand_l).origin)
	var pos_hand_r := skel.to_global(skel.get_bone_global_pose(b_hand_r).origin)
	var pos_foot_l := skel.to_global(skel.get_bone_global_pose(b_foot_l).origin)
	var pos_foot_r := skel.to_global(skel.get_bone_global_pose(b_foot_r).origin)

	print("\n=== MEASURED WORLD CONTACT POSITIONS ===")
	print("Hips pos: ", pos_hips, " (target saddle: ", saddle_pos, " dist: %0.2f cm)" % [(pos_hips - saddle_pos).length() * 100.0])
	print("Head pos: ", pos_head)
	print("Hand.L pos: ", pos_hand_l, " (target grip L: ", grip_l, " dist: %0.2f cm)" % [(pos_hand_l - grip_l).length() * 100.0])
	print("Hand.R pos: ", pos_hand_r, " (target grip R: ", grip_r, " dist: %0.2f cm)" % [(pos_hand_r - grip_r).length() * 100.0])
	print("Foot.L pos: ", pos_foot_l, " (target footpeg: Vector3(-0.22, 0.36, 0.12) dist: %0.2f cm)" % [(pos_foot_l - Vector3(-0.22, 0.36, 0.12)).length() * 100.0])
	print("Foot.R pos: ", pos_foot_r, " (target footpeg: Vector3(0.22, 0.36, 0.12) dist: %0.2f cm)" % [(pos_foot_r - Vector3(0.22, 0.36, 0.12)).length() * 100.0])

	# Setup Camera for visual rendering
	var cam := Camera3D.new()
	cam.fov = 34.0
	root_node.add_child(cam)

	# 1. Side Profile
	cam.position = Vector3(3.2, 1.1, 0.0)
	cam.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
	cam.make_current()
	for _i in range(15): await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_scrambler_side.png")
	print("Saved proof_scrambler_side.png")

	# 2. 32-degree elevated front 3/4 isometric
	var pitch_rad := deg_to_rad(28.0)
	var yaw_rad := deg_to_rad(140.0)
	var dist := 3.6
	var target := Vector3(0.0, 0.85, 0.0)
	cam.position = target + Vector3(sin(yaw_rad) * cos(pitch_rad) * dist, sin(pitch_rad) * dist, cos(yaw_rad) * cos(pitch_rad) * dist)
	cam.look_at(target, Vector3.UP)
	for _i in range(15): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_scrambler_iso.png")
	print("Saved proof_scrambler_iso.png")

	# 3. First-Person Rider POV (looking down over tank and handlebars)
	cam.fov = 68.0
	cam.position = pos_head + Vector3(0.0, 0.08, -0.04)
	cam.look_at(Vector3(0.0, 1.10, -0.60), Vector3.UP)
	for _i in range(15): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_scrambler_pov.png")
	print("Saved proof_scrambler_pov.png")

	# 4. Front Windshield / Head-on view
	cam.fov = 40.0
	cam.position = Vector3(0.0, 1.25, -2.4)
	cam.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
	for _i in range(15): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_scrambler_front.png")
	print("Saved proof_scrambler_front.png")

	# 5. Macro on Tactical Hands wrapping handlebars
	cam.fov = 22.0
	cam.position = Vector3(-0.72, 1.45, -0.22)
	cam.look_at(pos_hand_l, Vector3.UP)
	for _i in range(15): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/proof_scrambler_macro_hands.png")
	print("Saved proof_scrambler_macro_hands.png")

	quit(0)

func _apply_outline(node: Node, outline_mat: Material) -> void:
	if node is MeshInstance3D and node.mesh:
		for s in range(node.mesh.get_surface_count()):
			var active_mat = node.get_active_material(s)
			if active_mat is StandardMaterial3D:
				active_mat.next_pass = outline_mat
	for child in node.get_children():
		_apply_outline(child, outline_mat)
