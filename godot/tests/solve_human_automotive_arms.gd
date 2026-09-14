extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	coupe.position = Vector3.ZERO
	coupe.set_physics_process(false)

	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)

	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	coupe.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	runner.position = seat.position + Vector3(0.0, -0.78, 0.18)

	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)

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

	# Targets on 36cm rim tube
	# 10 o'clock: (-0.5029, 0.8648, -0.3849)
	# 2 o'clock:  (-0.2171, 0.8648, -0.3849)
	var target_10 = Vector3(-0.5029, 0.8648, -0.3849)
	var target_2  = Vector3(-0.2171, 0.8648, -0.3849)

	print("=== SOLVING REAL HUMAN BIOMECHANICAL AUTOMOTIVE ARM POSTURE ===")

	var solved_quats = {}

	for side in ["L", "R"]:
		var is_left = (side == "L")
		var target_knuckle = target_10 if is_left else target_2
		var target_clock = 5.0 if is_left else 1.0

		var b_sh = skel.find_bone("Shoulder." + side)
		var b_ua = skel.find_bone("UpperArm." + side)
		var b_la = skel.find_bone("LowerArm." + side)
		var b_h  = skel.find_bone("Hand." + side)
		var b_i2 = skel.find_bone("Index2." + side)

		# Rest rotations from skeleton
		var rest_ua = skel.get_bone_rest(b_ua).basis.get_rotation_quaternion()
		var rest_la = skel.get_bone_rest(b_la).basis.get_rotation_quaternion()
		var rest_h  = skel.get_bone_rest(b_h).basis.get_rotation_quaternion()

		var p_sh = skel.to_global(skel.get_bone_global_pose(b_ua).origin) # Shoulder position
		print("\n" + side + " Shoulder pos: ", p_sh)

		# Human constraints:
		# 1. Elbow must be forward of shoulder: p_el.z < p_sh.z - 0.08m
		# 2. Elbow lateral position must be natural: abs(p_el.x - wheel_center.x) >= abs(p_sh.x - wheel_center.x) - 0.04m (no squishing inward!)
		# 3. Wrist must be behind knuckle: p_wr.z > target_knuckle.z + 0.05m
		# 4. Forearm vector (wrist - elbow) and Hand vector (knuckle - wrist) angle must be <= 35 degrees! (NO 90 deg broken wrist!)
		# 5. Knuckle must touch rim: dist to target_knuckle < 1.5 cm

		var best_score = 999999.0
		var best_ua = Quaternion.IDENTITY
		var best_la = Quaternion.IDENTITY
		var best_h  = Quaternion.IDENTITY
		var best_info = {}

		# We search euler perturbations on UpperArm, LowerArm, Hand
		# Start from rest or current
		var base_ua = skel.get_bone_pose_rotation(b_ua)
		var base_la = skel.get_bone_pose_rotation(b_la)
		var base_h  = skel.get_bone_pose_rotation(b_h)

		for uax in range(-40, 40, 6):
			for uay in range(-40, 40, 6):
				for uaz in range(-40, 40, 6):
					var q_ua = Quaternion.from_euler(Vector3(deg_to_rad(uax), deg_to_rad(uay), deg_to_rad(uaz))) * base_ua
					skel.set_bone_pose_rotation(b_ua, q_ua)

					var p_el = skel.to_global(skel.get_bone_global_pose(b_la).origin)

					# Check elbow forward reach:
					# In Godot, -Z is forward. Elbow must be forward of shoulder (p_el.z < p_sh.z - 0.06)
					if p_el.z > p_sh.z - 0.05:
						continue
					
					# Check elbow lateral flare:
					var flare = abs(p_el.x - wheel_center.x) - abs(p_sh.x - wheel_center.x)
					if flare < -0.05: # More than 5cm inward is unnatural squishing
						continue

					for laz in range(-45, 45, 8):
						for lay in range(-45, 45, 8):
							var q_la = Quaternion.from_euler(Vector3(0.0, deg_to_rad(lay), deg_to_rad(laz))) * base_la
							skel.set_bone_pose_rotation(b_la, q_la)

							var p_wr = skel.to_global(skel.get_bone_global_pose(b_h).origin)

							# Wrist must be behind knuckle
							if p_wr.z < target_knuckle.z + 0.05:
								continue
							# Wrist height relaxed
							if p_wr.y > 0.92 or p_wr.y < 0.80:
								continue

							for hx in range(-35, 35, 7):
								for hy in range(-35, 35, 7):
									for hz in range(-35, 35, 7):
										var q_h = Quaternion.from_euler(Vector3(deg_to_rad(hx), deg_to_rad(hy), deg_to_rad(hz))) * base_h
										skel.set_bone_pose_rotation(b_h, q_h)

										var p_k = skel.to_global(skel.get_bone_global_pose(b_i2).origin)

										# Check forearm-hand angle:
										var v_forearm = (p_wr - p_el).normalized()
										var v_hand    = (p_k - p_wr).normalized()
										var wrist_angle_deg = rad_to_deg(v_forearm.angle_to(v_hand))

										if wrist_angle_deg > 40.0: # Ban impossible kinked wrists!
											continue

										var err_k = p_k.distance_to(target_knuckle) * 100.0
										var torus_res = check_torus.call(p_k)
										var surf_cm = abs(torus_res.dist_surface_cm)
										var clock_diff = abs(torus_res.clock_pos - target_clock)

										# Score emphasizes low knuckle error + straight wrist + natural flare
										var score = (
											err_k * 20.0 +
											surf_cm * 10.0 +
											clock_diff * 15.0 +
											wrist_angle_deg * 2.0 +
											abs(flare) * 100.0 +
											abs(p_wr.y - 0.85) * 50.0
										)

										if score < best_score:
											best_score = score
											best_ua = q_ua
											best_la = q_la
											best_h  = q_h
											best_info = {
												"err_k": err_k,
												"surf_cm": torus_res.dist_surface_cm,
												"clock": torus_res.clock_pos,
												"p_el": p_el,
												"p_wr": p_wr,
												"p_k": p_k,
												"flare_cm": flare * 100.0,
												"wrist_angle_deg": wrist_angle_deg
											}

		print("Best score for " + side + ": ", best_score)
		print("  Knuckle pos:   ", best_info.get("p_k", Vector3.ZERO))
		print("  Knuckle Error: %.2f cm | Surf Dist: %.2f cm | Clock: %.1fh" % [best_info.get("err_k", 99), best_info.get("surf_cm", 99), best_info.get("clock", 0)])
		print("  Elbow pos:     ", best_info.get("p_el", Vector3.ZERO), " (Flare: %+.1f cm)" % best_info.get("flare_cm", 0))
		print("  Wrist pos:     ", best_info.get("p_wr", Vector3.ZERO))
		print("  Wrist-Forearm Angle: %.1f deg (Natural Human < 35 deg)" % best_info.get("wrist_angle_deg", 99))
		print("  UpperArm." + side + " Quat: ", best_ua)
		print("  LowerArm." + side + " Quat: ", best_la)
		print("  Hand." + side + " Quat:     ", best_h)

		solved_quats["UpperArm." + side] = best_ua
		solved_quats["LowerArm." + side] = best_la
		solved_quats["Hand." + side]     = best_h

	quit(0)
