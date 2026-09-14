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

	# Wheel Torus geometry:
	# Center: (-0.36, 0.79, -0.35)
	# Tilt: -25 deg around X
	# Major radius R = 0.165m (outer diameter 0.36m, tube radius r = 0.015m)
	var wheel_center = wheel.global_position
	var tilt_rad = deg_to_rad(-25.0)

	print("\n=======================================================")
	print("DEEP AUTOMOTIVE BIOMECHANICS & MESH CONTACT AUDIT")
	print("=======================================================")
	print("Wheel Center: ", wheel_center)

	# Function to calculate distance from a point to the 3D torus surface
	# 1. Transform point into wheel local space (undo tilt)
	# 2. Compute distance to major circle
	# 3. Subtract tube radius r = 0.015m

	var check_torus_dist = func(p: Vector3) -> Dictionary:
		var d = p - wheel_center
		# Un-tilt around X by -tilt_rad = +25 deg
		var dy_untilted = d.y * cos(-tilt_rad) - d.z * sin(-tilt_rad)
		var dz_untilted = d.y * sin(-tilt_rad) + d.z * cos(-tilt_rad)
		var dx_untilted = d.x

		# In un-tilted wheel space, rim is in XY plane at z=0, radius R = 0.165
		var r_xy = sqrt(dx_untilted * dx_untilted + dy_untilted * dy_untilted)
		var dist_to_tube_centerline = sqrt(pow(r_xy - 0.165, 2) + pow(dz_untilted, 2))
		var dist_to_tube_surface = dist_to_tube_centerline - 0.015
		
		# Angle around rim (12 o clock = +90 deg, 10 o clock = 150 deg, 2 o clock = 30 deg)
		var rim_angle_deg = rad_to_deg(atan2(dy_untilted, dx_untilted))
		if rim_angle_deg < 0: rim_angle_deg += 360.0

		return {
			"dist_centerline_cm": dist_to_tube_centerline * 100.0,
			"dist_surface_cm": dist_to_tube_surface * 100.0,
			"penetration_cm": -dist_to_tube_surface * 100.0 if dist_to_tube_surface < 0 else 0.0,
			"rim_angle_deg": rim_angle_deg,
			"clock_pos": rim_angle_deg / 30.0 # 30 deg per clock hour
		}

	# 1. ARM ERGONOMICS (Shoulder, Elbow, Wrist)
	for side in ["L", "R"]:
		print("\n--- ARM POSTURE & ELBOW FLARE (" + side + ") ---")
		var b_sh = skel.find_bone("Shoulder." + side)
		var b_ua = skel.find_bone("UpperArm." + side)
		var b_la = skel.find_bone("LowerArm." + side)
		var b_h  = skel.find_bone("Hand." + side)

		var p_sh = skel.to_global(skel.get_bone_global_pose(b_sh).origin)
		var p_ua = skel.to_global(skel.get_bone_global_pose(b_ua).origin) # Shoulder joint
		var p_la = skel.to_global(skel.get_bone_global_pose(b_la).origin) # Elbow joint
		var p_h  = skel.to_global(skel.get_bone_global_pose(b_h).origin)  # Wrist joint

		print("Shoulder joint pos: ", p_ua)
		print("Elbow joint pos:    ", p_la)
		print("Wrist joint pos:    ", p_h)

		var elbow_height_vs_wheel = p_la.y - wheel_center.y
		var wrist_height_vs_wheel = p_h.y - wheel_center.y
		print("Elbow height vs wheel center: %+0.2f cm" % (elbow_height_vs_wheel * 100.0))
		print("Wrist height vs wheel center: %+0.2f cm" % (wrist_height_vs_wheel * 100.0))

		# Lateral flare (X distance of elbow vs shoulder)
		var lateral_flare = abs(p_la.x - wheel_center.x) - abs(p_ua.x - wheel_center.x)
		print("Elbow lateral flare outward:  %+0.2f cm" % (lateral_flare * 100.0))

	# 2. DETAILED FINGER CONTACT AUDIT
	print("\n--- DETAILED FINGER DISTANCES TO RIM SURFACE ---")
	var finger_bones = [
		"Index2", "Index3", "Index4", "Index4_end",
		"Thumb2", "Thumb3", "Thumb3_end"
	]

	for side in ["L", "R"]:
		print("\n[" + side + " HAND BONES]")
		for fb in finger_bones:
			var b_idx = skel.find_bone(fb + "." + side)
			if b_idx == -1: continue
			var pos = skel.to_global(skel.get_bone_global_pose(b_idx).origin)
			var res = check_torus_dist.call(pos)
			var state = "SURFACE CONTACT" if abs(res.dist_surface_cm) < 1.0 else ("PENETRATING MESH" if res.dist_surface_cm < -1.0 else "AIR GAP")
			print("  %-14s: Pos=(%+.3f, %+.3f, %+.3f) | SurfDist=%+0.2f cm | Clock=%0.1fh | %s" % [
				fb + "." + side, pos.x, pos.y, pos.z, res.dist_surface_cm, res.clock_pos, state
			])

	quit(0)
