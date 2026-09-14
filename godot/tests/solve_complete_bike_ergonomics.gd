extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root_node.add_child(runner)
	runner.set_vehicle_driving_posture(true, "bike")
	runner.position = Vector3(0.0, 0.58, 0.15)

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer

	# Target contact points on Courier Bike (world space):
	var grip_l := Vector3(-0.422169, 1.182702, -0.455136)
	var grip_r := Vector3(0.422155, 1.182702, -0.455136)
	var saddle_contact := Vector3(0.0, 0.985, 0.22)
	var peg_l := Vector3(-0.22, 0.36, 0.12)
	var peg_r := Vector3(0.22, 0.36, 0.12)

	# 1. Base Posture Setup:
	# Lower hips down onto saddle cushion
	var hips_track_pos := Vector3(0.0, 0.445, -0.07) # Places hips in world at Y ~ 0.99, Z ~ 0.22

	# Torso forward crouch over tank:
	# Pelvis forward pitch +20 deg
	var q_hips := Quaternion.from_euler(Vector3(deg_to_rad(20.0), 0.0, 0.0))
	var q_abdomen := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_torso := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_chest := Quaternion.from_euler(Vector3(deg_to_rad(6.0), 0.0, 0.0))
	# Head tilted up to maintain horizontal eye-line through helmet visor:
	var q_neck := Quaternion.from_euler(Vector3(deg_to_rad(-16.0), 0.0, 0.0))
	var q_head := Quaternion.from_euler(Vector3(deg_to_rad(-20.0), 0.0, 0.0))

	# Legs:
	var rest_uleg_l := skel.get_bone_rest(skel.find_bone("UpperLeg.L")).basis.get_rotation_quaternion()
	var rest_lleg_l := skel.get_bone_rest(skel.find_bone("LowerLeg.L")).basis.get_rotation_quaternion()
	var rest_foot_l := skel.get_bone_rest(skel.find_bone("Foot.L")).basis.get_rotation_quaternion()

	var rest_uleg_r := skel.get_bone_rest(skel.find_bone("UpperLeg.R")).basis.get_rotation_quaternion()
	var rest_lleg_r := skel.get_bone_rest(skel.find_bone("LowerLeg.R")).basis.get_rotation_quaternion()
	var rest_foot_r := skel.get_bone_rest(skel.find_bone("Foot.R")).basis.get_rotation_quaternion()

	# Thighs pitched forward-down ~64 deg, slight inward adduction ~12 deg to grip tank console
	# Knees bent back ~86 deg, feet resting horizontally on footpegs
	var q_uleg_l := Quaternion.from_euler(Vector3(deg_to_rad(-64.0), deg_to_rad(10.0), deg_to_rad(-14.0))) * rest_uleg_l
	var q_lleg_l := Quaternion.from_euler(Vector3(deg_to_rad(86.0), 0.0, 0.0)) * rest_lleg_l
	var q_foot_l := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), 0.0, deg_to_rad(6.0))) * rest_foot_l

	var q_uleg_r := Quaternion.from_euler(Vector3(deg_to_rad(-64.0), deg_to_rad(-10.0), deg_to_rad(14.0))) * rest_uleg_r
	var q_lleg_r := Quaternion.from_euler(Vector3(deg_to_rad(86.0), 0.0, 0.0)) * rest_lleg_r
	var q_foot_r := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), 0.0, deg_to_rad(-6.0))) * rest_foot_r

	# Tactical Glove finger curl:
	var q_knuckle := Quaternion.from_euler(Vector3(deg_to_rad(50.0), 0.0, 0.0))
	var q_mid_pip := Quaternion.from_euler(Vector3(deg_to_rad(70.0), 0.0, 0.0))
	var q_dist_dip := Quaternion.from_euler(Vector3(deg_to_rad(45.0), 0.0, 0.0))
	# Opposable thumbs locked under grip tube
	var q_thumb2_l := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), deg_to_rad(45.0), deg_to_rad(-35.0)))
	var q_thumb3_l := Quaternion.from_euler(Vector3(deg_to_rad(-50.0), 0.0, 0.0))
	var q_thumb2_r := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), deg_to_rad(-45.0), deg_to_rad(35.0)))
	var q_thumb3_r := Quaternion.from_euler(Vector3(deg_to_rad(-50.0), 0.0, 0.0))

	# 2. Arm Optimization (Inverse Kinematics Search):
	# UpperArm, LowerArm, Hand
	var b_ua_l := skel.find_bone("UpperArm.L")
	var b_la_l := skel.find_bone("LowerArm.L")
	var b_h_l  := skel.find_bone("Hand.L")
	var b_i2_l := skel.find_bone("Index2.L")

	var rest_ua_l := skel.get_bone_rest(b_ua_l).basis.get_rotation_quaternion()
	var rest_la_l := skel.get_bone_rest(b_la_l).basis.get_rotation_quaternion()
	var rest_h_l  := skel.get_bone_rest(b_h_l).basis.get_rotation_quaternion()

	var rest_ua_r := skel.get_bone_rest(skel.find_bone("UpperArm.R")).basis.get_rotation_quaternion()
	var rest_la_r := skel.get_bone_rest(skel.find_bone("LowerArm.R")).basis.get_rotation_quaternion()
	var rest_h_r  := skel.get_bone_rest(skel.find_bone("Hand.R")).basis.get_rotation_quaternion()

	print("--- Optimizing Left Arm Reach to Grip (-0.422, 1.183, -0.455) ---")

	# Apply spine and hips first to skeleton
	skel.set_bone_pose_position(skel.find_bone("Hips"), hips_track_pos)
	skel.set_bone_pose_rotation(skel.find_bone("Hips"), q_hips)
	skel.set_bone_pose_rotation(skel.find_bone("Abdomen"), q_abdomen)
	skel.set_bone_pose_rotation(skel.find_bone("Torso"), q_torso)
	skel.set_bone_pose_rotation(skel.find_bone("Chest"), q_chest)
	skel.set_bone_pose_rotation(skel.find_bone("Neck"), q_neck)
	skel.set_bone_pose_rotation(skel.find_bone("Head"), q_head)

	skel.set_bone_pose_rotation(skel.find_bone("UpperLeg.L"), q_uleg_l)
	skel.set_bone_pose_rotation(skel.find_bone("LowerLeg.L"), q_lleg_l)
	skel.set_bone_pose_rotation(skel.find_bone("Foot.L"), q_foot_l)
	skel.set_bone_pose_rotation(skel.find_bone("UpperLeg.R"), q_uleg_r)
	skel.set_bone_pose_rotation(skel.find_bone("LowerLeg.R"), q_lleg_r)
	skel.set_bone_pose_rotation(skel.find_bone("Foot.R"), q_foot_r)

	# Search best arm angles for scrambler attack posture
	# Upper arm pitches forward (-X), abducts outward (+Z), internally rotates (+Y)
	# Lower arm flexes elbow (-Z)
	# Hand pronates (+Y) and tilts to match 12-deg handlebar sweep
	var best_dist := 999.0
	var best_uarm_l := rest_ua_l
	var best_larm_l := rest_la_l
	var best_hand_l := rest_h_l

	# Coarse grid search
	for uax in range(-75, -35, 5):
		for uay in range(10, 50, 5):
			for uaz in range(15, 55, 5):
				var test_ua := Quaternion.from_euler(Vector3(deg_to_rad(uax), deg_to_rad(uay), deg_to_rad(uaz))) * rest_ua_l
				skel.set_bone_pose_rotation(b_ua_l, test_ua)

				for laz in range(-80, -30, 8):
					for lay in range(0, 40, 8):
						var test_la := Quaternion.from_euler(Vector3(0.0, deg_to_rad(lay), deg_to_rad(laz))) * rest_la_l
						skel.set_bone_pose_rotation(b_la_l, test_la)

						for hy in range(10, 60, 10):
							for hx in range(0, 40, 10):
								var test_h := Quaternion.from_euler(Vector3(deg_to_rad(hx), deg_to_rad(hy), deg_to_rad(15.0))) * rest_h_l
								skel.set_bone_pose_rotation(b_h_l, test_h)

								var cur_hand_pos := skel.to_global(skel.get_bone_global_pose(b_h_l).origin)
								var d := (cur_hand_pos - grip_l).length()
								if d < best_dist:
									best_dist = d
									best_uarm_l = test_ua
									best_larm_l = test_la
									best_hand_l = test_h

	print("Coarse search best Hand.L distance: ", best_dist * 100.0, " cm")

	# Fine gradient refinement
	var cur_ua_euler := best_uarm_l.get_euler()
	var cur_la_euler := best_larm_l.get_euler()
	var cur_h_euler := best_hand_l.get_euler()

	for step in [2.0, 1.0, 0.5]:
		for _iter in range(30):
			var improved := false
			for param in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua := cur_ua_euler
					var tla := cur_la_euler
					var th := cur_h_euler
					var delta_rad := deg_to_rad(step * sgn)
					if param == "uax": tua.x += delta_rad
					elif param == "uay": tua.y += delta_rad
					elif param == "uaz": tua.z += delta_rad
					elif param == "lay": tla.y += delta_rad
					elif param == "laz": tla.z += delta_rad
					elif param == "hx": th.x += delta_rad
					elif param == "hy": th.y += delta_rad
					elif param == "hz": th.z += delta_rad

					skel.set_bone_pose_rotation(b_ua_l, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_l, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_l, Quaternion.from_euler(th))

					var cur_pos := skel.to_global(skel.get_bone_global_pose(b_h_l).origin)
					var d := (cur_pos - grip_l).length()
					if d < best_dist:
						best_dist = d
						cur_ua_euler = tua
						cur_la_euler = tla
						cur_h_euler = th
						improved = true
			if not improved:
				break

	best_uarm_l = Quaternion.from_euler(cur_ua_euler)
	best_larm_l = Quaternion.from_euler(cur_la_euler)
	best_hand_l = Quaternion.from_euler(cur_h_euler)
	print("Refined best Hand.L distance: ", best_dist * 100.0, " cm")

	# Right arm by lateral symmetry:
	# Invert Y and Z euler angles
	var uar_euler := Vector3(cur_ua_euler.x, -cur_ua_euler.y, -cur_ua_euler.z)
	var lar_euler := Vector3(cur_la_euler.x, -cur_la_euler.y, -cur_la_euler.z)
	var hr_euler  := Vector3(cur_h_euler.x,  -cur_h_euler.y,  -cur_h_euler.z)

	var best_uarm_r := Quaternion.from_euler(uar_euler)
	var best_larm_r := Quaternion.from_euler(lar_euler)
	var best_hand_r := Quaternion.from_euler(hr_euler)

	skel.set_bone_pose_rotation(skel.find_bone("UpperArm.R"), best_uarm_r)
	skel.set_bone_pose_rotation(skel.find_bone("LowerArm.R"), best_larm_r)
	skel.set_bone_pose_rotation(skel.find_bone("Hand.R"), best_hand_r)

	var r_hand_pos := skel.to_global(skel.get_bone_global_pose(skel.find_bone("Hand.R")).origin)
	var dist_r := (r_hand_pos - grip_r).length()
	print("Symmetric Hand.R distance: ", dist_r * 100.0, " cm")

	print("\n=== SOLVED QUATERNIONS ===")
	print("Hips Pos: ", hips_track_pos)
	print("UpperArm.L: ", best_uarm_l)
	print("LowerArm.L: ", best_larm_l)
	print("Hand.L:     ", best_hand_l)
	print("UpperArm.R: ", best_uarm_r)
	print("LowerArm.R: ", best_larm_r)
	print("Hand.R:     ", best_hand_r)

	quit(0)
