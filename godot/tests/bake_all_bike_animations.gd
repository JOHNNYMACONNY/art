extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("\n=== BAKING ALL BIKE RIDING ANIMATIONS ===")
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root.add_child(runner)
	runner.set_vehicle_driving_posture(true, "bike")
	runner.position = Vector3(0.0, 0.58, 0.15)

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer

	var grip_l := Vector3(-0.422169, 1.182702, -0.455136)
	var grip_r := Vector3(0.422155, 1.182702, -0.455136)

	var hips_track_pos := Vector3(0.0, 0.445, -0.07) # Places hips in world at Y ~ 0.99, Z ~ 0.22

	# 1. Torso Spine Arc (Attack Posture)
	var q_hips := Quaternion.from_euler(Vector3(deg_to_rad(20.0), 0.0, 0.0))
	var q_abdomen := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_torso := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_chest := Quaternion.from_euler(Vector3(deg_to_rad(6.0), 0.0, 0.0))
	var q_neck := Quaternion.from_euler(Vector3(deg_to_rad(-16.0), 0.0, 0.0))
	var q_head := Quaternion.from_euler(Vector3(deg_to_rad(-20.0), 0.0, 0.0))

	# 2. Legs: Hugging Tank, Feet Planted on Footpegs (Sub-millimeter Peg Alignment)
	# Left Leg:
	var q_uleg_l := Quaternion(0.67985, -0.220422, -0.381862, 0.586003)
	var q_lleg_l := Quaternion(0.648445, 0.341839, -0.322349, 0.598962)
	var q_foot_l := Quaternion(-0.856173, 0.013619, 0.022316, 0.516027)

	# Right Leg:
	var q_uleg_r := Quaternion(0.688747, 0.26361, 0.371411, 0.564085)
	var q_lleg_r := Quaternion(-0.648998, 0.342054, -0.322112, -0.598368)
	var q_foot_r := Quaternion(0.856447, -0.003047, -0.005335, -0.516198)

	# 3. 5-Digit Tactical Gloves Curl:
	# Knuckles (MCP 50 deg), PIP (70 deg), DIP (45 deg)
	var q_knuckle := Quaternion.from_euler(Vector3(deg_to_rad(50.0), 0.0, 0.0))
	var q_mid_pip := Quaternion.from_euler(Vector3(deg_to_rad(70.0), 0.0, 0.0))
	var q_dist_dip := Quaternion.from_euler(Vector3(deg_to_rad(45.0), 0.0, 0.0))
	# Thumb wrapped underneath in safety lock
	var q_thumb2_l := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), deg_to_rad(45.0), deg_to_rad(-35.0)))
	var q_thumb3_l := Quaternion.from_euler(Vector3(deg_to_rad(-50.0), 0.0, 0.0))
	var q_thumb2_r := Quaternion.from_euler(Vector3(deg_to_rad(-24.0), deg_to_rad(-45.0), deg_to_rad(35.0)))
	var q_thumb3_r := Quaternion.from_euler(Vector3(deg_to_rad(-50.0), 0.0, 0.0))

	# 4. Solved Arms for Neutral Ride:
	# Left Arm:
	var q_ua_l := Quaternion(-0.380372, -0.633049, 0.344397, 0.579618)
	var q_la_l := Quaternion(0.021392, -0.728621, -0.026731, 0.68406)
	var q_h_l  := Quaternion(-0.107709, 0.418956, 0.496483, 0.752582)

	# Optimize Right Arm independently for sub-millimeter precision:
	skel.set_bone_pose_position(skel.find_bone("Hips"), hips_track_pos)
	skel.set_bone_pose_rotation(skel.find_bone("Hips"), q_hips)
	skel.set_bone_pose_rotation(skel.find_bone("Abdomen"), q_abdomen)
	skel.set_bone_pose_rotation(skel.find_bone("Torso"), q_torso)
	skel.set_bone_pose_rotation(skel.find_bone("Chest"), q_chest)
	skel.set_bone_pose_rotation(skel.find_bone("Neck"), q_neck)
	skel.set_bone_pose_rotation(skel.find_bone("Head"), q_head)

	var b_ua_r := skel.find_bone("UpperArm.R")
	var b_la_r := skel.find_bone("LowerArm.R")
	var b_h_r  := skel.find_bone("Hand.R")
	var b_i2_r := skel.find_bone("Index2.R")
	var b_m2_r := skel.find_bone("Middle2.R")

	var ua_l_euler := q_ua_l.get_euler()
	var la_l_euler := q_la_l.get_euler()
	var h_l_euler  := q_h_l.get_euler()

	var cur_ua_r := Vector3(ua_l_euler.x, -ua_l_euler.y, -ua_l_euler.z)
	var cur_la_r := Vector3(la_l_euler.x, -la_l_euler.y, -la_l_euler.z)
	var cur_h_r  := Vector3(h_l_euler.x,  -h_l_euler.y,  -h_l_euler.z)

	var get_palm_r_dist = func() -> float:
		var p_i2 := skel.to_global(skel.get_bone_global_pose(b_i2_r).origin)
		var p_m2 := skel.to_global(skel.get_bone_global_pose(b_m2_r).origin)
		var palm := (p_i2 + p_m2) * 0.5
		return (palm - grip_r).length()

	skel.set_bone_pose_rotation(b_ua_r, Quaternion.from_euler(cur_ua_r))
	skel.set_bone_pose_rotation(b_la_r, Quaternion.from_euler(cur_la_r))
	skel.set_bone_pose_rotation(b_h_r, Quaternion.from_euler(cur_h_r))

	var best_r_dist: float = get_palm_r_dist.call()
	for step in [1.5, 0.8, 0.3, 0.1]:
		for _iter in range(50):
			var improved := false
			for param in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua := cur_ua_r
					var tla := cur_la_r
					var th := cur_h_r
					var delta_rad := deg_to_rad(step * sgn)
					if param == "uax": tua.x += delta_rad
					elif param == "uay": tua.y += delta_rad
					elif param == "uaz": tua.z += delta_rad
					elif param == "lay": tla.y += delta_rad
					elif param == "laz": tla.z += delta_rad
					elif param == "hx": th.x += delta_rad
					elif param == "hy": th.y += delta_rad
					elif param == "hz": th.z += delta_rad

					skel.set_bone_pose_rotation(b_ua_r, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_r, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_r, Quaternion.from_euler(th))

					var d: float = get_palm_r_dist.call()
					if d < best_r_dist:
						best_r_dist = d
						cur_ua_r = tua
						cur_la_r = tla
						cur_h_r = th
						improved = true
			if not improved:
				break

	var q_ua_r := Quaternion.from_euler(cur_ua_r)
	var q_la_r := Quaternion.from_euler(cur_la_r)
	var q_h_r  := Quaternion.from_euler(cur_h_r)

	print("Solved Right Arm palm dist to Right Grip: %0.2f cm" % [best_r_dist * 100.0])

	var base_bike_ride_map := {
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

		"UpperArm.L": q_ua_l,
		"LowerArm.L": q_la_l,
		"Hand.L": q_h_l,
		"UpperArm.R": q_ua_r,
		"LowerArm.R": q_la_r,
		"Hand.R": q_h_r,

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
		"Thumb2.L": q_thumb2_l,
		"Thumb3.L": q_thumb3_l,

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
		"Thumb2.R": q_thumb2_r,
		"Thumb3.R": q_thumb3_r,
	}

	# 5. Build Left Lean Posture (Roll -14 deg, inner knee hugs, outer braces, countersteer push/pull)
	var lean_left_map := base_bike_ride_map.duplicate()
	lean_left_map["Hips"] = Quaternion.from_euler(Vector3(0.0, 0.0, deg_to_rad(6.0))) * q_hips
	lean_left_map["Abdomen"] = Quaternion.from_euler(Vector3(0.0, deg_to_rad(4.0), deg_to_rad(8.0))) * q_abdomen
	lean_left_map["Torso"] = Quaternion.from_euler(Vector3(0.0, deg_to_rad(4.0), deg_to_rad(8.0))) * q_torso
	lean_left_map["Chest"] = Quaternion.from_euler(Vector3(0.0, deg_to_rad(2.0), deg_to_rad(6.0))) * q_chest
	# Vestibular horizon lock on head:
	lean_left_map["Head"] = Quaternion.from_euler(Vector3(0.0, 0.0, deg_to_rad(-16.0))) * q_head
	# Arms countersteer: Right arm extends, Left arm tucks:
	lean_left_map["UpperArm.L"] = Quaternion.from_euler(Vector3(deg_to_rad(4.0), deg_to_rad(6.0), deg_to_rad(-6.0))) * q_ua_l
	lean_left_map["UpperArm.R"] = Quaternion.from_euler(Vector3(deg_to_rad(-6.0), deg_to_rad(-4.0), deg_to_rad(8.0))) * q_ua_r

	# 6. Build Right Lean Posture (Symmetric opposite)
	var lean_right_map := base_bike_ride_map.duplicate()
	lean_right_map["Hips"] = Quaternion.from_euler(Vector3(0.0, 0.0, deg_to_rad(-6.0))) * q_hips
	lean_right_map["Abdomen"] = Quaternion.from_euler(Vector3(0.0, deg_to_rad(-4.0), deg_to_rad(-8.0))) * q_abdomen
	lean_right_map["Torso"] = Quaternion.from_euler(Vector3(0.0, deg_to_rad(-4.0), deg_to_rad(-8.0))) * q_torso
	lean_right_map["Chest"] = Quaternion.from_euler(Vector3(0.0, deg_to_rad(-2.0), deg_to_rad(-6.0))) * q_chest
	lean_right_map["Head"] = Quaternion.from_euler(Vector3(0.0, 0.0, deg_to_rad(16.0))) * q_head
	lean_right_map["UpperArm.L"] = Quaternion.from_euler(Vector3(deg_to_rad(-6.0), deg_to_rad(4.0), deg_to_rad(-8.0))) * q_ua_l
	lean_right_map["UpperArm.R"] = Quaternion.from_euler(Vector3(deg_to_rad(4.0), deg_to_rad(-6.0), deg_to_rad(6.0))) * q_ua_r

	var configs := [
		["bike_ride", base_bike_ride_map, "res://scenes/player/anim_bike_ride.res"],
		["bike_lean_left", lean_left_map, "res://scenes/player/anim_bike_lean_left.res"],
		["bike_lean_right", lean_right_map, "res://scenes/player/anim_bike_lean_right.res"]
	]

	var base_anim := ap.get_animation("bike_ride")

	for cfg in configs:
		var anim_name: String = cfg[0]
		var quat_map: Dictionary = cfg[1]
		var save_path: String = cfg[2]

		var anim := base_anim.duplicate() as Animation

		for i in range(anim.get_track_count()):
			var path_str := str(anim.track_get_path(i))
			var track_type := anim.track_get_type(i)

			if track_type == Animation.TYPE_POSITION_3D and path_str.ends_with(":Hips"):
				for k in range(anim.track_get_key_count(i)):
					anim.track_set_key_value(i, k, hips_track_pos)

			if track_type == Animation.TYPE_ROTATION_3D:
				for bname in quat_map:
					if path_str.ends_with(":" + bname):
						var q: Quaternion = quat_map[bname]
						for k in range(anim.track_get_key_count(i)):
							anim.track_set_key_value(i, k, q)

		var err := ResourceSaver.save(anim, save_path)
		print("Saved ", save_path, " code: ", err)

	print("\n=== ALL BIKE ANIMATIONS BAKED SUCCESSFULLY ===")
	quit(0)
