extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	coupe.position = Vector3.ZERO
	coupe.rotation = Vector3.ZERO
	coupe.set_physics_process(false)
	await process_frame
	
	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)
	
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	coupe.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	runner.position = seat.position + Vector3(0.0, -0.78, 0.18)
	runner.rotation = Vector3.ZERO
	
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)
	await process_frame

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
			"dz_untilted_cm": dz_untilted * 100.0, # distance normal to wheel plane
			"r_xy_cm": r_xy * 100.0 # radius in wheel plane
		}

	# Targets on 36cm rim tube (10 o'clock and 2 o'clock)
	var target_10 = Vector3(-0.5029, 0.8648, -0.3849)
	var target_2  = Vector3(-0.2171, 0.8648, -0.3849)

	print("\n=== SOLVING COMPREHENSIVE AUTOMOTIVE GRIP ===")

	for side in ["L", "R"]:
		var is_left = (side == "L")
		var target_knuckle = target_10 if is_left else target_2
		var b_ua = skel.find_bone("UpperArm." + side)
		var b_la = skel.find_bone("LowerArm." + side)
		var b_h  = skel.find_bone("Hand." + side)
		var b_i2 = skel.find_bone("Index2." + side)
		var b_i3 = skel.find_bone("Index3." + side)
		var b_i4 = skel.find_bone("Index4." + side)
		var b_i4e = skel.find_bone("Index4." + side + "_end")
		var b_t2 = skel.find_bone("Thumb2." + side)
		var b_t3 = skel.find_bone("Thumb3." + side)

		var cur_rot_ua = skel.get_bone_pose_rotation(b_ua)
		var cur_rot_la = skel.get_bone_pose_rotation(b_la)
		var cur_rot_h  = skel.get_bone_pose_rotation(b_h)

		var best_score = 99999.0
		var best_ua_rot = cur_rot_ua
		var best_la_rot = cur_rot_la
		var best_h_rot  = cur_rot_h
		var best_pos_i2 = Vector3.ZERO
		var best_pos_wrist = Vector3.ZERO

		# Optimization grid:
		# We want:
		# 1. Knuckle (Index2) within 1.5cm of rim tube center line (contacting tube surface)
		# 2. Wrist Y between 0.83 and 0.89 (relaxed horizontal/slight rise approach, NO piano arch above 0.90)
		# 3. Wrist setback behind rim (dz < 0 in wheel plane)

		for d_uax in range(-25, 25, 4):
			for d_uaz in range(-25, 25, 4):
				var q_ua = Quaternion.from_euler(Vector3(deg_to_rad(d_uax), 0, deg_to_rad(d_uaz))) * cur_rot_ua
				skel.set_bone_pose_rotation(b_ua, q_ua)

				for d_laz in range(-45, 10, 4):
					for d_lay in range(-20, 20, 4):
						var q_la = Quaternion.from_euler(Vector3(0, deg_to_rad(d_lay), deg_to_rad(d_laz))) * cur_rot_la
						skel.set_bone_pose_rotation(b_la, q_la)

						var p_wrist = skel.to_global(skel.get_bone_global_pose(b_h).origin)
						# Wrist height constraint: relaxed automotive posture (0.82m - 0.89m)
						if p_wrist.y > 0.90 or p_wrist.y < 0.80:
							continue
						
						# Wrist should be 8-15cm away from knuckle target
						var d_wk = p_wrist.distance_to(target_knuckle)
						if d_wk < 0.08 or d_wk > 0.16:
							continue

						for d_hx in range(-50, 50, 5):
							for d_hy in range(-50, 50, 5):
								for d_hz in range(-50, 50, 5):
									var q_h = Quaternion.from_euler(Vector3(deg_to_rad(d_hx), deg_to_rad(d_hy), deg_to_rad(d_hz))) * cur_rot_h
									skel.set_bone_pose_rotation(b_h, q_h)

									var p_i2 = skel.to_global(skel.get_bone_global_pose(b_i2).origin)
									var err_knuckle = p_i2.distance_to(target_knuckle)

									# Score penalizes knuckle error + high wrists
									var score = err_knuckle * 100.0 + abs(p_wrist.y - 0.85) * 50.0
									if score < best_score:
										best_score = score
										best_ua_rot = q_ua
										best_la_rot = q_la
										best_h_rot  = q_h
										best_pos_i2 = p_i2
										best_pos_wrist = p_wrist

		# Apply best arm rotations
		skel.set_bone_pose_rotation(b_ua, best_ua_rot)
		skel.set_bone_pose_rotation(b_la, best_la_rot)
		skel.set_bone_pose_rotation(b_h,  best_h_rot)

		# Now optimize Thumb curl so Thumb3 hooks inner rim
		var cur_rot_t2 = skel.get_bone_pose_rotation(b_t2)
		var cur_rot_t3 = skel.get_bone_pose_rotation(b_t3)
		var best_thumb_err = 999.0
		var best_t2_rot = cur_rot_t2
		var best_t3_rot = cur_rot_t3

		for dt2_x in range(-50, 50, 10):
			for dt2_y in range(-50, 50, 10):
				for dt2_z in range(-40, 40, 10):
					var q_t2 = Quaternion.from_euler(Vector3(deg_to_rad(dt2_x), deg_to_rad(dt2_y), deg_to_rad(dt2_z))) * cur_rot_t2
					skel.set_bone_pose_rotation(b_t2, q_t2)

					for dt3_x in range(-50, 50, 10):
						var q_t3 = Quaternion.from_euler(Vector3(deg_to_rad(dt3_x), 0, 0)) * cur_rot_t3
						skel.set_bone_pose_rotation(b_t3, q_t3)

						var p_t3 = skel.to_global(skel.get_bone_global_pose(b_t3).origin)
						var res_t = check_torus.call(p_t3)
						# We want thumb near tube surface (dist_surface ~ 0) and inside rim (r_xy < 16.5)
						var t_err = abs(res_t.dist_surface_cm)
						if res_t.r_xy_cm < 17.5 and t_err < best_thumb_err:
							best_thumb_err = t_err
							best_t2_rot = q_t2
							best_t3_rot = q_t3

		skel.set_bone_pose_rotation(b_t2, best_t2_rot)
		skel.set_bone_pose_rotation(b_t3, best_t3_rot)

		print("\n--- RESULTS FOR SIDE " + side + " ---")
		print("UpperArm." + side + " Quat: ", best_ua_rot)
		print("LowerArm." + side + " Quat: ", best_la_rot)
		print("Hand." + side + " Quat:     ", best_h_rot)
		print("Thumb2." + side + " Quat:   ", best_t2_rot)
		print("Thumb3." + side + " Quat:   ", best_t3_rot)
		print("Wrist Pos:   ", best_pos_wrist, " (Height vs center: %+0.2f cm)" % ((best_pos_wrist.y - 0.79) * 100.0))
		print("Knuckle Pos: ", best_pos_i2, " vs Target: ", target_knuckle)
		var res_k = check_torus.call(best_pos_i2)
		print("Knuckle surface dist: %+0.2f cm (Clock: %0.1fh)" % [res_k.dist_surface_cm, res_k.clock_pos])
		var p_t3_final = skel.to_global(skel.get_bone_global_pose(b_t3).origin)
		var res_tf = check_torus.call(p_t3_final)
		print("Thumb3 surface dist:  %+0.2f cm (Clock: %0.1fh)" % [res_tf.dist_surface_cm, res_tf.clock_pos])

	quit(0)
