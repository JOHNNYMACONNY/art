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

	var wheel_center = wheel.global_position
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

	for side in ["L", "R"]:
		var b_t2 = skel.find_bone("Thumb2." + side)
		var b_t3 = skel.find_bone("Thumb3." + side)
		var cur_q2 = skel.get_bone_pose_rotation(b_t2)
		var cur_q3 = skel.get_bone_pose_rotation(b_t3)

		var best_err = 999.0
		var best_q2 = cur_q2
		var best_q3 = cur_q3
		var best_info = {}

		for dx2 in range(-40, 40, 5):
			for dy2 in range(-40, 40, 5):
				for dz2 in range(-40, 40, 5):
					var q2 = Quaternion.from_euler(Vector3(deg_to_rad(dx2), deg_to_rad(dy2), deg_to_rad(dz2))) * cur_q2
					skel.set_bone_pose_rotation(b_t2, q2)

					for dx3 in range(-40, 40, 5):
						for dy3 in range(-40, 40, 5):
							var q3 = Quaternion.from_euler(Vector3(deg_to_rad(dx3), deg_to_rad(dy3), 0.0)) * cur_q3
							skel.set_bone_pose_rotation(b_t3, q3)

							var p_t3 = skel.to_global(skel.get_bone_global_pose(b_t3).origin)
							var res = check_torus.call(p_t3)
							var err = abs(res.dist_surface_cm)
							# Want thumb inside rim (r_xy <= 16.5cm) and surface contact
							if res.r_xy_cm <= 16.5 and err < best_err:
								best_err = err
								best_q2 = q2
								best_q3 = q3
								best_info = res

		print("Best for Thumb." + side + ":")
		print("  Thumb2." + side + " Quat: ", best_q2)
		print("  Thumb3." + side + " Quat: ", best_q3)
		print("  Surf Dist: %+.2f cm | Radius: %.2f cm" % [best_info["dist_surface_cm"], best_info["r_xy_cm"]])

	quit(0)
