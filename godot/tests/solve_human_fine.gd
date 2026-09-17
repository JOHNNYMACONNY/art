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

	var target_10 = Vector3(-0.5029, 0.8648, -0.3849)
	var target_2  = Vector3(-0.2171, 0.8648, -0.3849)

	var base_quats = {
		"L": [
			Quaternion(-0.736739, 0.294711, 0.268811, 0.545987),
			Quaternion(0.060543, 0.329341, -0.57399, 0.747265),
			Quaternion(0.238028, 0.899178, 0.31525, 0.188251)
		],
		"R": [
			Quaternion(-0.565503, 0.033688, -0.724337, 0.392948),
			Quaternion(-0.147241, -0.594758, 0.48347, 0.625172),
			Quaternion(0.374377, -0.799027, -0.185228, 0.432537)
		]
	}

	var final_quats = {}

	for side in ["L", "R"]:
		var is_left = (side == "L")
		var target_knuckle = target_10 if is_left else target_2
		var target_clock = 5.0 if is_left else 1.0

		var b_ua = skel.find_bone("UpperArm." + side)
		var b_la = skel.find_bone("LowerArm." + side)
		var b_h  = skel.find_bone("Hand." + side)
		var b_i2 = skel.find_bone("Index2." + side)

		var init_ua = base_quats[side][0]
		var init_la = base_quats[side][1]
		var init_h  = base_quats[side][2]

		var best_score = 99999.0
		var best_ua = init_ua
		var best_la = init_la
		var best_h  = init_h
		var best_info = {}

		# Fine search around base
		for duax in range(-12, 12, 3):
			for duay in range(-12, 12, 3):
				for duaz in range(-12, 12, 3):
					var q_ua = Quaternion.from_euler(Vector3(deg_to_rad(duax), deg_to_rad(duay), deg_to_rad(duaz))) * init_ua
					skel.set_bone_pose_rotation(b_ua, q_ua)

					var p_el = skel.to_global(skel.get_bone_global_pose(b_la).origin)

					for dlaz in range(-16, 16, 4):
						for dlay in range(-16, 16, 4):
							var q_la = Quaternion.from_euler(Vector3(0.0, deg_to_rad(dlay), deg_to_rad(dlaz))) * init_la
							skel.set_bone_pose_rotation(b_la, q_la)

							var p_wr = skel.to_global(skel.get_bone_global_pose(b_h).origin)

							for dhx in range(-16, 16, 4):
								for dhy in range(-16, 16, 4):
									for dhz in range(-16, 16, 4):
										var q_h = Quaternion.from_euler(Vector3(deg_to_rad(dhx), deg_to_rad(dhy), deg_to_rad(dhz))) * init_h
										skel.set_bone_pose_rotation(b_h, q_h)

										var p_k = skel.to_global(skel.get_bone_global_pose(b_i2).origin)

										var v_forearm = (p_wr - p_el).normalized()
										var v_hand    = (p_k - p_wr).normalized()
										var wrist_angle_deg = rad_to_deg(v_forearm.angle_to(v_hand))

										if wrist_angle_deg > 32.0: # Keep wrist very straight with forearm!
											continue

										var err_k = p_k.distance_to(target_knuckle) * 100.0
										var torus_res = check_torus.call(p_k)
										var surf_cm = abs(torus_res.dist_surface_cm)
										var clock_diff = abs(torus_res.clock_pos - target_clock)

										var flare = abs(p_el.x - wheel_center.x) - abs(skel.to_global(skel.get_bone_global_pose(b_ua).origin).x - wheel_center.x)

										var score = err_k * 30.0 + surf_cm * 20.0 + clock_diff * 20.0 + wrist_angle_deg * 2.0 + abs(flare) * 50.0
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

		print("\n--- FINE TUNED RESULT FOR " + side + " ---")
		print("  Knuckle pos:   ", best_info["p_k"])
		print("  Knuckle Error: %.2f cm | Surf Dist: %.2f cm | Clock: %.1fh" % [best_info["err_k"], best_info["surf_cm"], best_info["clock"]])
		print("  Elbow pos:     ", best_info["p_el"], " (Flare: %+.1f cm)" % best_info["flare_cm"])
		print("  Wrist pos:     ", best_info["p_wr"])
		print("  Wrist-Forearm Angle: %.1f deg" % best_info["wrist_angle_deg"])
		print("  UpperArm." + side + " Quat: ", best_ua)
		print("  LowerArm." + side + " Quat: ", best_la)
		print("  Hand." + side + " Quat:     ", best_h)

		final_quats["UpperArm." + side] = best_ua
		final_quats["LowerArm." + side] = best_la
		final_quats["Hand." + side]     = best_h

	quit(0)
