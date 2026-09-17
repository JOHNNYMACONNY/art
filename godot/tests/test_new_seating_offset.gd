extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)

	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	coupe.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")

	# Test seating offsets
	print("=== TESTING SEATING OFFSET ADJUSTMENT ===")
	var base_offset = Vector3(0.0, -0.78, 0.18)
	var delta_needed = Vector3(-0.0177, 0.0743, 0.1311)
	var new_offset = base_offset + delta_needed

	runner.position = seat.position + new_offset

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

	var bones_to_check = [
		"Index2.L", "Index3.L", "Index4.L", "Thumb2.L", "Thumb3.L",
		"Index2.R", "Index3.R", "Index4.R", "Thumb2.R", "Thumb3.R"
	]

	print("Tested offset: ", new_offset)
	for b in bones_to_check:
		var b_idx = skel.find_bone(b)
		var pos = skel.to_global(skel.get_bone_global_pose(b_idx).origin)
		var res = check_torus.call(pos)
		print("  %-12s: Pos=(%+.3f, %+.3f, %+.3f) | SurfDist=%+0.2f cm | Clock=%0.1fh" % [
			b, pos.x, pos.y, pos.z, res.dist_surface_cm, res.clock_pos
		])

	# Check head position and headroom
	var b_head = skel.find_bone("Head_end")
	var head_pos = skel.to_global(skel.get_bone_global_pose(b_head).origin)
	print("\nHead global pos: ", head_pos)
	print("Roof clearance in Coupe: Y=1.28m, Head Y=", head_pos.y, " (Clearance: %+0.2f cm)" % ((1.28 - head_pos.y)*100.0))

	quit(0)
