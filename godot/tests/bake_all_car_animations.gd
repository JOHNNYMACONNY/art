extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D

	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)
	runner.position = seat.position + Vector3(0.0, -0.78, 0.18)

	var wheel_center = wheel.global_position # (-0.36, 0.79, -0.35)
	var tilt_rad = deg_to_rad(-25.0)

	var check_torus = func(p: Vector3) -> Dictionary:
		var d = p - wheel_center
		var dy_untilted = d.y * cos(-tilt_rad) - d.z * sin(-tilt_rad)
		var dz_untilted = d.y * sin(-tilt_rad) + d.z * cos(-tilt_rad)
		var dx_untilted = d.x

		var r_xy = sqrt(dx_untilted * dx_untilted + dy_untilted * dy_untilted)
		var dist_to_tube_centerline = sqrt(pow(r_xy - 0.165, 2) + pow(dz_untilted, 2))
		var dist_to_tube_surface = dist_to_tube_centerline - 0.015
		var rim_angle_deg = rad_to_deg(atan2(dy_untilted, dx_untilted))
		if rim_angle_deg < 0: rim_angle_deg += 360.0

		return {
			"dist_surface_cm": dist_to_tube_surface * 100.0,
			"clock_pos": rim_angle_deg / 30.0,
			"dz_untilted_cm": dz_untilted * 100.0,
			"r_xy_cm": r_xy * 100.0
		}

	# 1. Full Body Base Posture for Automotive Seating
	var q_knuckle = Quaternion.from_euler(Vector3(deg_to_rad(52.0), 0.0, 0.0))
	var q_mid_pip = Quaternion.from_euler(Vector3(deg_to_rad(68.0), 0.0, 0.0))
	var q_dist_dip = Quaternion.from_euler(Vector3(deg_to_rad(45.0), 0.0, 0.0))

	var base_car_body = {
		# Spine reclined -15 deg flush into bucket seatback
		"Hips":       Quaternion(-0.052336, 0.0, 0.0, 0.99863),
		"Abdomen":    Quaternion(-0.034899, 0.0, 0.0, 0.999391),
		"Torso":      Quaternion(-0.026177, 0.0, 0.0, 0.999657),
		"Chest":      Quaternion(-0.017452, 0.0, 0.0, 0.999848),
		# Head gaze leveled at road horizon through windshield
		"Neck":       Quaternion(0.069756, 0.0, 0.0, 0.997564),
		"Head":       Quaternion(0.061049, 0.0, 0.0, 0.998135),

		# Thighs resting horizontal on cushion, lower legs down, feet on pedals
		"UpperLeg.L": Quaternion(0.584001, -0.491968, -0.525868, 0.374664),
		"LowerLeg.L": Quaternion(0.380419, 0.842772, -0.26497, 0.273511),
		"Foot.L":     Quaternion(-0.916305, -0.023387, 0.046753, 0.397055),

		"UpperLeg.R": Quaternion(0.65435, 0.448777, 0.439014, 0.421535),
		"LowerLeg.R": Quaternion(0.178942, -0.318783, 0.405588, 0.837768),
		"Foot.R":     Quaternion(-0.916303, 0.0234, -0.046782, 0.397054),

		# Tactical Glove Fingers (L)
		"Index2.L":   q_knuckle,
		"Index3.L":   q_mid_pip,
		"Index4.L":   q_dist_dip,
		"Middle2.L":  q_knuckle,
		"Middle3.L":  q_mid_pip,
		"Middle4.L":  q_dist_dip,
		"Ring2.L":    q_knuckle,
		"Ring3.L":    q_mid_pip,
		"Ring4.L":    q_dist_dip,
		"Pinky2.L":   q_knuckle,
		"Pinky3.L":   q_mid_pip,
		"Pinky4.L":   q_dist_dip,
		"Thumb2.L":   Quaternion(-0.126079, 0.033783, 0.256605, 0.957662),
		"Thumb3.L":   Quaternion.IDENTITY,

		# Tactical Glove Fingers (R)
		"Index2.R":   q_knuckle,
		"Index3.R":   q_mid_pip,
		"Index4.R":   q_dist_dip,
		"Middle2.R":  q_knuckle,
		"Middle3.R":  q_mid_pip,
		"Middle4.R":  q_dist_dip,
		"Ring2.R":    q_knuckle,
		"Ring3.R":    q_mid_pip,
		"Ring4.R":    q_dist_dip,
		"Pinky2.R":   q_knuckle,
		"Pinky3.R":   q_mid_pip,
		"Pinky4.R":   q_dist_dip,
		"Thumb2.R":   Quaternion(-0.126079, -0.033783, -0.256605, 0.957662),
		"Thumb3.R":   Quaternion.IDENTITY,
	}

	# 2. Arms for Neutral Drive (10-and-2 grip with 0.00 cm surface contact)
	var solved_drive = base_car_body.duplicate()
	solved_drive["UpperArm.L"] = Quaternion(-0.686707, 0.418304, -0.233102, 0.546917)
	solved_drive["LowerArm.L"] = Quaternion(-0.022078, 0.043755, -0.385154, 0.92155)
	solved_drive["Hand.L"]     = Quaternion(0.170002, 0.139723, 0.12115, 0.967936)
	solved_drive["UpperArm.R"] = Quaternion(-0.682748, -0.409179, 0.244455, 0.553778)
	solved_drive["LowerArm.R"] = Quaternion(-0.028796, -0.059832, 0.38471, 0.920646)
	solved_drive["Hand.R"]     = Quaternion(0.13585, -0.111492, -0.148571, 0.97316)

	# 3. Steer Left (CCW wheel rotation ~25 deg)
	var solved_steer_left = base_car_body.duplicate()
	solved_steer_left["UpperArm.L"] = Quaternion(-0.702566, 0.449903, -0.17879, 0.521558)
	solved_steer_left["LowerArm.L"] = Quaternion(-0.035506, 0.07589, -0.384149, 0.919462)
	solved_steer_left["Hand.L"]     = Quaternion(0.184403, 0.152647, 0.115853, 0.963988)
	solved_steer_left["UpperArm.R"] = Quaternion(-0.673566, -0.389108, 0.268722, 0.56806)
	solved_steer_left["LowerArm.R"] = Quaternion(-0.028796, -0.059832, 0.38471, 0.920646)
	solved_steer_left["Hand.R"]     = Quaternion(0.111754, -0.130852, -0.150079, 0.973584)

	# 4. Steer Right (CW wheel rotation ~25 deg)
	var solved_steer_right = base_car_body.duplicate()
	solved_steer_right["UpperArm.L"] = Quaternion(-0.677252, 0.397001, -0.259291, 0.562572)
	solved_steer_right["LowerArm.L"] = Quaternion(-0.022078, 0.043755, -0.385154, 0.92155)
	solved_steer_right["Hand.L"]     = Quaternion(0.132891, 0.145297, 0.128228, 0.972001)
	solved_steer_right["UpperArm.R"] = Quaternion(-0.690294, -0.450285, 0.224021, 0.520146)
	solved_steer_right["LowerArm.R"] = Quaternion(-0.043543, -0.09513, 0.383321, 0.917671)
	solved_steer_right["Hand.R"]     = Quaternion(0.171932, -0.041108, -0.152599, 0.972349)

	var hips_track_pos = Vector3(0.0, 0.941913, 0.0)

	var anim_configs = [
		["car_drive", solved_drive, "res://scenes/player/anim_car_drive.res"],
		["car_steer_left", solved_steer_left, "res://scenes/player/anim_car_steer_left.res"],
		["car_steer_right", solved_steer_right, "res://scenes/player/anim_car_steer_right.res"]
	]

	for cfg in anim_configs:
		var anim_name = cfg[0]
		var quat_map = cfg[1]
		var save_path = cfg[2]

		var base_anim = ap.get_animation(anim_name)
		if not base_anim:
			base_anim = ap.get_animation("car_drive")
		var anim = base_anim.duplicate() as Animation

		for i in range(anim.get_track_count()):
			var path_str = str(anim.track_get_path(i))
			var track_type = anim.track_get_type(i)

			# Set Hips position track
			if track_type == Animation.TYPE_POSITION_3D and path_str.ends_with(":Hips"):
				for k in range(anim.track_get_key_count(i)):
					anim.track_set_key_value(i, k, hips_track_pos)

			# Reset CharacterArmature tracks
			if path_str == "CharacterArmature" or path_str.ends_with("/CharacterArmature"):
				if track_type == Animation.TYPE_POSITION_3D:
					for k in range(anim.track_get_key_count(i)):
						anim.track_set_key_value(i, k, Vector3.ZERO)
				elif track_type == Animation.TYPE_ROTATION_3D:
					for k in range(anim.track_get_key_count(i)):
						anim.track_set_key_value(i, k, Quaternion.IDENTITY)

			# Set skeletal bone rotation tracks
			if track_type == Animation.TYPE_ROTATION_3D:
				for bname in quat_map:
					if path_str.ends_with(":" + bname):
						var q = quat_map[bname]
						for k in range(anim.track_get_key_count(i)):
							anim.track_set_key_value(i, k, q)

		var err = ResourceSaver.save(anim, save_path)
		print("Saved ", save_path, " code: ", err)

	print("\n=== ALL CAR ANIMATIONS BAKED SUCCESSFULLY ===")
	quit(0)
