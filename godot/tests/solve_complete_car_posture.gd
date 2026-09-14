extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	coupe.rotation_degrees = Vector3(0, 180, 0)
	
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	coupe.add_child(runner)
	
	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)
	
	# Runner placed so Hips rest right at seat cushion top (Y=0.48) and backrest junction
	# Seat_Driver is (-0.36, 0.45, -0.05).
	# With runner at seat.position + Vector3(0.0, -0.80, 0.08):
	runner.position = seat.position + Vector3(0.0, -0.80, 0.08)
	runner.rotation = Vector3.ZERO
	
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	
	# 1. Torso: Recline back -15 degrees to match bucket seat backrest!
	var q_hips = Quaternion.from_euler(Vector3(deg_to_rad(-6.0), 0.0, 0.0))
	var q_abdo = Quaternion.from_euler(Vector3(deg_to_rad(-4.0), 0.0, 0.0))
	var q_torso = Quaternion.from_euler(Vector3(deg_to_rad(-3.0), 0.0, 0.0))
	var q_chest = Quaternion.from_euler(Vector3(deg_to_rad(-2.0), 0.0, 0.0))
	var q_neck = Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_head = Quaternion.from_euler(Vector3(deg_to_rad(7.0), 0.0, 0.0))
	
	skel.set_bone_pose_rotation(skel.find_bone("Hips"), q_hips)
	skel.set_bone_pose_rotation(skel.find_bone("Abdomen"), q_abdo)
	skel.set_bone_pose_rotation(skel.find_bone("Torso"), q_torso)
	skel.set_bone_pose_rotation(skel.find_bone("Chest"), q_chest)
	skel.set_bone_pose_rotation(skel.find_bone("Neck"), q_neck)
	skel.set_bone_pose_rotation(skel.find_bone("Head"), q_head)
	
	var b_hips = skel.find_bone("Hips")
	var b_chest = skel.find_bone("Chest")
	var b_head = skel.find_bone("Head")
	var b_uleg_l = skel.find_bone("UpperLeg.L")
	var b_lleg_l = skel.find_bone("LowerLeg.L")
	var b_foot_l = skel.find_bone("Foot.L")
	
	print("Hips global pos: ", skel.to_global(skel.get_bone_global_pose(b_hips).origin))
	print("Chest global pos: ", skel.to_global(skel.get_bone_global_pose(b_chest).origin))
	print("Head global pos: ", skel.to_global(skel.get_bone_global_pose(b_head).origin))
	var rest_uleg_l = skel.get_bone_rest(skel.find_bone("UpperLeg.L")).basis.get_rotation_quaternion()
	var rest_lleg_l = skel.get_bone_rest(skel.find_bone("LowerLeg.L")).basis.get_rotation_quaternion()
	var rest_foot_l = skel.get_bone_rest(skel.find_bone("Foot.L")).basis.get_rotation_quaternion()
	# Solve Left Leg and Right Leg
	var target_knee_l = Vector3(-0.41, 0.52, -0.34)
	var target_foot_l = Vector3(-0.42, 0.28, -0.55)
	var target_knee_r = Vector3(-0.31, 0.52, -0.34)
	var target_foot_r = Vector3(-0.32, 0.28, -0.55)
	
	var b_ul_l = skel.find_bone("UpperLeg.L")
	var b_ll_l = skel.find_bone("LowerLeg.L")
	var b_ft_l = skel.find_bone("Foot.L")
	
	var best_err_l = 999.0
	var best_q_ul_l = rest_uleg_l
	var best_q_ll_l = rest_lleg_l
	
	# Grid search UpperLeg.L and LowerLeg.L
	for ux in range(-90, -50, 4):
		for uy in range(-30, 30, 5):
			for uz in range(-30, 30, 5):
				var q_ul = Quaternion.from_euler(Vector3(deg_to_rad(ux), deg_to_rad(uy), deg_to_rad(uz))) * rest_uleg_l
				skel.set_bone_pose_rotation(b_ul_l, q_ul)
				var cur_knee = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ll_l).origin))
				var knee_err = (cur_knee - target_knee_l).length()
				if knee_err > 0.10:
					continue
				
				for lx in range(-90, 90, 10):
					for ly in range(-90, 90, 10):
						for lz in range(-90, 90, 10):
							var q_ll = Quaternion.from_euler(Vector3(deg_to_rad(lx), deg_to_rad(ly), deg_to_rad(lz))) * rest_lleg_l
							skel.set_bone_pose_rotation(b_ll_l, q_ll)
							var cur_foot = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ft_l).origin))
							var total_err = knee_err * 2.0 + (cur_foot - target_foot_l).length()
							if total_err < best_err_l:
								best_err_l = total_err
								best_q_ul_l = q_ul
								best_q_ll_l = q_ll
	
	# Fine gradient refinement for Left Leg
	var cur_ul_euler = best_q_ul_l.get_euler()
	var cur_ll_euler = best_q_ll_l.get_euler()
	
	for step in [2.0, 1.0, 0.5]:
		for _iter in range(40):
			var improved = false
			for p in ["ux", "uy", "uz", "lx", "ly", "lz"]:
				for sgn in [-1.0, 1.0]:
					var tu = cur_ul_euler
					var tl = cur_ll_euler
					var delta = deg_to_rad(step * sgn)
					if p == "ux": tu.x += delta
					elif p == "uy": tu.y += delta
					elif p == "uz": tu.z += delta
					elif p == "lx": tl.x += delta
					elif p == "ly": tl.y += delta
					elif p == "lz": tl.z += delta
					
					var q_u = Quaternion.from_euler(tu)
					var q_l = Quaternion.from_euler(tl)
					skel.set_bone_pose_rotation(b_ul_l, q_u)
					skel.set_bone_pose_rotation(b_ll_l, q_l)
					
					var k = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ll_l).origin))
					var f = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ft_l).origin))
					var err = (k - target_knee_l).length() * 2.0 + (f - target_foot_l).length()
					if err < best_err_l:
						best_err_l = err
						cur_ul_euler = tu
						cur_ll_euler = tl
						best_q_ul_l = q_u
						best_q_ll_l = q_l
						improved = true
			if not improved:
				break
	
	skel.set_bone_pose_rotation(b_ul_l, best_q_ul_l)
	skel.set_bone_pose_rotation(b_ll_l, best_q_ll_l)
	var final_knee_l = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ll_l).origin))
	var final_foot_l = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ft_l).origin))
	print("\n--- REFINED LEFT LEG ---")
	print("Final Knee.L: ", final_knee_l, " (target: ", target_knee_l, ")")
	print("Final Foot.L: ", final_foot_l, " (target: ", target_foot_l, ")")
	print("best_q_ul_l: ", best_q_ul_l)
	print("best_q_ll_l: ", best_q_ll_l)
	
	# Solve Foot.L angle so sole rests flat against angled pedal board
	var q_foot_l = Quaternion.from_euler(Vector3(deg_to_rad(-40.0), 0.0, deg_to_rad(6.0))) * rest_foot_l
	skel.set_bone_pose_rotation(b_ft_l, q_foot_l)
	
	# Now solve Right Leg
	var b_ul_r = skel.find_bone("UpperLeg.R")
	var b_ll_r = skel.find_bone("LowerLeg.R")
	var b_ft_r = skel.find_bone("Foot.R")
	var rest_uleg_r = skel.get_bone_rest(b_ul_r).basis.get_rotation_quaternion()
	var rest_lleg_r = skel.get_bone_rest(b_ll_r).basis.get_rotation_quaternion()
	var rest_foot_r = skel.get_bone_rest(b_ft_r).basis.get_rotation_quaternion()
	
	var best_err_r = 999.0
	var best_q_ul_r = rest_uleg_r
	var best_q_ll_r = rest_lleg_r
	
	for ux in range(-90, -50, 4):
		for uy in range(-30, 30, 5):
			for uz in range(-30, 30, 5):
				var q_ul = Quaternion.from_euler(Vector3(deg_to_rad(ux), deg_to_rad(uy), deg_to_rad(uz))) * rest_uleg_r
				skel.set_bone_pose_rotation(b_ul_r, q_ul)
				var cur_knee = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ll_r).origin))
				var knee_err = (cur_knee - target_knee_r).length()
				if knee_err > 0.10:
					continue
				
				for lx in range(-90, 90, 10):
					for ly in range(-90, 90, 10):
						for lz in range(-90, 90, 10):
							var q_ll = Quaternion.from_euler(Vector3(deg_to_rad(lx), deg_to_rad(ly), deg_to_rad(lz))) * rest_lleg_r
							skel.set_bone_pose_rotation(b_ll_r, q_ll)
							var cur_foot = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ft_r).origin))
							var total_err = knee_err * 2.0 + (cur_foot - target_foot_r).length()
							if total_err < best_err_r:
								best_err_r = total_err
								best_q_ul_r = q_ul
								best_q_ll_r = q_ll
	
	var cur_ul_r_euler = best_q_ul_r.get_euler()
	var cur_ll_r_euler = best_q_ll_r.get_euler()
	for step in [2.0, 1.0, 0.5]:
		for _iter in range(40):
			var improved = false
			for p in ["ux", "uy", "uz", "lx", "ly", "lz"]:
				for sgn in [-1.0, 1.0]:
					var tu = cur_ul_r_euler
					var tl = cur_ll_r_euler
					var delta = deg_to_rad(step * sgn)
					if p == "ux": tu.x += delta
					elif p == "uy": tu.y += delta
					elif p == "uz": tu.z += delta
					elif p == "lx": tl.x += delta
					elif p == "ly": tl.y += delta
					elif p == "lz": tl.z += delta
					
					var q_u = Quaternion.from_euler(tu)
					var q_l = Quaternion.from_euler(tl)
					skel.set_bone_pose_rotation(b_ul_r, q_u)
					skel.set_bone_pose_rotation(b_ll_r, q_l)
					
					var k = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ll_r).origin))
					var f = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ft_r).origin))
					var err = (k - target_knee_r).length() * 2.0 + (f - target_foot_r).length()
					if err < best_err_r:
						best_err_r = err
						cur_ul_r_euler = tu
						cur_ll_r_euler = tl
						best_q_ul_r = q_u
						best_q_ll_r = q_l
						improved = true
			if not improved:
				break
	
	skel.set_bone_pose_rotation(b_ul_r, best_q_ul_r)
	skel.set_bone_pose_rotation(b_ll_r, best_q_ll_r)
	var final_knee_r = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ll_r).origin))
	var final_foot_r = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_ft_r).origin))
	print("\n--- REFINED RIGHT LEG ---")
	print("Final Knee.R: ", final_knee_r, " (target: ", target_knee_r, ")")
	print("Final Foot.R: ", final_foot_r, " (target: ", target_foot_r, ")")
	print("best_q_ul_r: ", best_q_ul_r)
	var q_foot_r = Quaternion.from_euler(Vector3(deg_to_rad(-40.0), 0.0, deg_to_rad(-6.0))) * rest_foot_r
	skel.set_bone_pose_rotation(b_ft_r, q_foot_r)
	
	# 4. Solve Left Arm to 10 o'clock wheel rim
	var b_ua_l = skel.find_bone("UpperArm.L")
	var b_la_l = skel.find_bone("LowerArm.L")
	var b_h_l  = skel.find_bone("Hand.L")
	var b_i2_l = skel.find_bone("Index2.L")
	var b_m2_l = skel.find_bone("Middle2.L")
	
	var rest_ua_l = skel.get_bone_rest(b_ua_l).basis.get_rotation_quaternion()
	var rest_la_l = skel.get_bone_rest(b_la_l).basis.get_rotation_quaternion()
	var rest_h_l  = skel.get_bone_rest(b_h_l).basis.get_rotation_quaternion()
	
	# Tactical Glove finger curl:
	var q_knuckle = Quaternion.from_euler(Vector3(deg_to_rad(52.0), 0.0, 0.0))
	var q_mid_pip = Quaternion.from_euler(Vector3(deg_to_rad(68.0), 0.0, 0.0))
	var q_dist_dip = Quaternion.from_euler(Vector3(deg_to_rad(45.0), 0.0, 0.0))
	var q_thumb2_l = Quaternion.from_euler(Vector3(deg_to_rad(-20.0), deg_to_rad(40.0), deg_to_rad(-30.0)))
	var q_thumb3_l = Quaternion.from_euler(Vector3(deg_to_rad(-45.0), 0.0, 0.0))
	
	for f in ["Index", "Middle", "Ring", "Pinky"]:
		skel.set_bone_pose_rotation(skel.find_bone(f + "2.L"), q_knuckle)
		skel.set_bone_pose_rotation(skel.find_bone(f + "3.L"), q_mid_pip)
		skel.set_bone_pose_rotation(skel.find_bone(f + "4.L"), q_dist_dip)
	skel.set_bone_pose_rotation(skel.find_bone("Thumb2.L"), q_thumb2_l)
	skel.set_bone_pose_rotation(skel.find_bone("Thumb3.L"), q_thumb3_l)
	
	var wheel_center_coupe = wheel.position # (-0.36, 0.79, -0.35)
	var tilt_rad = deg_to_rad(-25.0)
	
	var check_torus = func(p_coupe: Vector3) -> Dictionary:
		var d = p_coupe - wheel_center_coupe
		var dy_unt = d.y * cos(-tilt_rad) - d.z * sin(-tilt_rad)
		var dz_unt = d.y * sin(-tilt_rad) + d.z * cos(-tilt_rad)
		var dx_unt = d.x
		var r_xy = sqrt(dx_unt * dx_unt + dy_unt * dy_unt)
		var dist_tube_center = sqrt(pow(r_xy - 0.165, 2) + pow(dz_unt, 2))
		var dist_tube_surf = dist_tube_center - 0.015
		var clock_deg = rad_to_deg(atan2(dx_unt, dy_unt))
		if clock_deg < 0.0: clock_deg += 360.0
		return {
			"dist_surf_cm": dist_tube_surf * 100.0,
			"clock_pos": clock_deg / 30.0,
			"dz_unt_cm": dz_unt * 100.0,
			"dx_unt": dx_unt,
			"dy_unt": dy_unt
		}
	
	var get_palm_l_coupe = func() -> Vector3:
		var p_i = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_i2_l).origin))
		var p_m = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_m2_l).origin))
		return (p_i + p_m) * 0.5
	
	# Target 10 o'clock: clock_pos = 10.0 (angle = 300 deg, dx < 0, dy > 0)
	var best_l_cost = 999.0
	var best_ua_l = rest_ua_l
	var best_la_l = rest_la_l
	var best_h_l  = rest_h_l
	
	for uax in range(-80, -35, 8):
		for uay in range(-10, 40, 10):
			for uaz in range(-10, 40, 10):
				var tua = Quaternion.from_euler(Vector3(deg_to_rad(uax), deg_to_rad(uay), deg_to_rad(uaz))) * rest_ua_l
				skel.set_bone_pose_rotation(b_ua_l, tua)
				
				for laz in range(-85, -25, 12):
					for lay in range(-30, 30, 12):
						var tla = Quaternion.from_euler(Vector3(0.0, deg_to_rad(lay), deg_to_rad(laz))) * rest_la_l
						skel.set_bone_pose_rotation(b_la_l, tla)
						
						for hx in range(-30, 40, 15):
							for hy in range(0, 70, 15):
								var th = Quaternion.from_euler(Vector3(deg_to_rad(hx), deg_to_rad(hy), deg_to_rad(10.0))) * rest_h_l
								skel.set_bone_pose_rotation(b_h_l, th)
								
								var palm = get_palm_l_coupe.call()
								var res = check_torus.call(palm)
								var clock_err = abs(res.clock_pos - 10.0)
								var cost = abs(res.dist_surf_cm) + clock_err * 3.0 + abs(res.dz_unt_cm) * 2.0
								if cost < best_l_cost:
									best_l_cost = cost
									best_ua_l = tua
									best_la_l = tla
									best_h_l = th
	
	print("\nCoarse Left Arm Search Best Cost: ", best_l_cost)
	skel.set_bone_pose_rotation(b_ua_l, best_ua_l)
	skel.set_bone_pose_rotation(b_la_l, best_la_l)
	skel.set_bone_pose_rotation(b_h_l, best_h_l)
	var palm_res = check_torus.call(get_palm_l_coupe.call())
	print("Coarse Left Palm: SurfDist=%+0.2f cm, Clock=%0.2fh, DZ=%+0.2f cm" % [
		palm_res.dist_surf_cm, palm_res.clock_pos, palm_res.dz_unt_cm
	])
	
	# Gradient descent refinement
	var cur_ua_euler = best_ua_l.get_euler()
	var cur_la_euler = best_la_l.get_euler()
	var cur_h_euler  = best_h_l.get_euler()
	
	for step in [2.0, 1.0, 0.4, 0.1]:
		for _iter in range(40):
			var improved = false
			for p in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua = cur_ua_euler
					var tla = cur_la_euler
					var th = cur_h_euler
					var delta = deg_to_rad(step * sgn)
					if p == "uax": tua.x += delta
					elif p == "uay": tua.y += delta
					elif p == "uaz": tua.z += delta
					elif p == "lay": tla.y += delta
					elif p == "laz": tla.z += delta
					elif p == "hx": th.x += delta
					elif p == "hy": th.y += delta
					elif p == "hz": th.z += delta
					
					skel.set_bone_pose_rotation(b_ua_l, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_l, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_l, Quaternion.from_euler(th))
					
					var palm = get_palm_l_coupe.call()
					var res = check_torus.call(palm)
					var clock_err = abs(res.clock_pos - 10.0)
					var cost = abs(res.dist_surf_cm) + clock_err * 3.0 + abs(res.dz_unt_cm) * 2.0
					if cost < best_l_cost:
						best_l_cost = cost
						cur_ua_euler = tua
						cur_la_euler = tla
						cur_h_euler = th
						improved = true
			if not improved:
				break
	
	best_ua_l = Quaternion.from_euler(cur_ua_euler)
	best_la_l = Quaternion.from_euler(cur_la_euler)
	best_h_l  = Quaternion.from_euler(cur_h_euler)
	
	skel.set_bone_pose_rotation(b_ua_l, best_ua_l)
	skel.set_bone_pose_rotation(b_la_l, best_la_l)
	skel.set_bone_pose_rotation(b_h_l, best_h_l)
	palm_res = check_torus.call(get_palm_l_coupe.call())
	print("\nRefined Left Palm: SurfDist=%+0.2f cm, Clock=%0.2fh, DZ=%+0.2f cm" % [
		palm_res.dist_surf_cm, palm_res.clock_pos, palm_res.dz_unt_cm
	])
	
	# Symmetrical Right Arm solver (target 2 o'clock = 2.0h)
	var b_ua_r = skel.find_bone("UpperArm.R")
	var b_la_r = skel.find_bone("LowerArm.R")
	var b_h_r  = skel.find_bone("Hand.R")
	var b_i2_r = skel.find_bone("Index2.R")
	var b_m2_r = skel.find_bone("Middle2.R")
	
	var q_thumb2_r = Quaternion.from_euler(Vector3(deg_to_rad(-20.0), deg_to_rad(-40.0), deg_to_rad(30.0)))
	var q_thumb3_r = Quaternion.from_euler(Vector3(deg_to_rad(-45.0), 0.0, 0.0))
	for f in ["Index", "Middle", "Ring", "Pinky"]:
		skel.set_bone_pose_rotation(skel.find_bone(f + "2.R"), q_knuckle)
		skel.set_bone_pose_rotation(skel.find_bone(f + "3.R"), q_mid_pip)
		skel.set_bone_pose_rotation(skel.find_bone(f + "4.R"), q_dist_dip)
	skel.set_bone_pose_rotation(skel.find_bone("Thumb2.R"), q_thumb2_r)
	skel.set_bone_pose_rotation(skel.find_bone("Thumb3.R"), q_thumb3_r)
	
	var get_palm_r_coupe = func() -> Vector3:
		var p_i = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_i2_r).origin))
		var p_m = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_m2_r).origin))
		return (p_i + p_m) * 0.5
	
	var cur_ua_r_euler = Vector3(cur_ua_euler.x, -cur_ua_euler.y, -cur_ua_euler.z)
	var cur_la_r_euler = Vector3(cur_la_euler.x, -cur_la_euler.y, -cur_la_euler.z)
	var cur_h_r_euler  = Vector3(cur_h_euler.x,  -cur_h_euler.y,  -cur_h_euler.z)
	
	skel.set_bone_pose_rotation(b_ua_r, Quaternion.from_euler(cur_ua_r_euler))
	skel.set_bone_pose_rotation(b_la_r, Quaternion.from_euler(cur_la_r_euler))
	skel.set_bone_pose_rotation(b_h_r, Quaternion.from_euler(cur_h_r_euler))
	
	var best_r_cost = 999.0
	for step in [2.0, 1.0, 0.4, 0.1]:
		for _iter in range(40):
			var improved = false
			for p in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua = cur_ua_r_euler
					var tla = cur_la_r_euler
					var th = cur_h_r_euler
					var delta = deg_to_rad(step * sgn)
					if p == "uax": tua.x += delta
					elif p == "uay": tua.y += delta
					elif p == "uaz": tua.z += delta
					elif p == "lay": tla.y += delta
					elif p == "laz": tla.z += delta
					elif p == "hx": th.x += delta
					elif p == "hy": th.y += delta
					elif p == "hz": th.z += delta
					
					skel.set_bone_pose_rotation(b_ua_r, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_r, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_r, Quaternion.from_euler(th))
					
					var palm = get_palm_r_coupe.call()
					var res = check_torus.call(palm)
					var clock_err = abs(res.clock_pos - 2.0)
					var cost = abs(res.dist_surf_cm) + clock_err * 3.0 + abs(res.dz_unt_cm) * 2.0
					if cost < best_r_cost:
						best_r_cost = cost
						cur_ua_r_euler = tua
						cur_la_r_euler = tla
						cur_h_r_euler = th
						improved = true
			if not improved:
				break
	
	var best_ua_r = Quaternion.from_euler(cur_ua_r_euler)
	var best_la_r = Quaternion.from_euler(cur_la_r_euler)
	var best_h_r  = Quaternion.from_euler(cur_h_r_euler)
	
	skel.set_bone_pose_rotation(b_ua_r, best_ua_r)
	skel.set_bone_pose_rotation(b_la_r, best_la_r)
	skel.set_bone_pose_rotation(b_h_r, best_h_r)
	var palm_r_res = check_torus.call(get_palm_r_coupe.call())
	print("\nRefined Right Palm: SurfDist=%+0.2f cm, Clock=%0.2fh, DZ=%+0.2f cm" % [
		palm_r_res.dist_surf_cm, palm_r_res.clock_pos, palm_r_res.dz_unt_cm
	])
	
	# Test exact thumb grip from bake_all_car_animations.gd
	var b_t2_l = skel.find_bone("Thumb2.L")
	var b_t3_l = skel.find_bone("Thumb3.L")
	var b_t2_r = skel.find_bone("Thumb2.R")
	var b_t3_r = skel.find_bone("Thumb3.R")
	var prev_t2_l = Quaternion(-0.15603, 0.840564, 0.065661, 0.514584)
	var prev_t3_l = Quaternion(-0.982698, 0.070987, -0.159204, 0.062611)
	var prev_t2_r = Quaternion(0.140618, -0.286222, -0.273665, 0.90742)
	var prev_t3_r = Quaternion(-0.85421, -0.11678, -0.50509, 0.039637)
	
	# Direct thumb search targeting underbelly of tube (DZ ~ 0, inside rim radius)
	var target_thumb_l = Vector3(-0.47, 0.84, -0.37)
	var b_t3_end_l = skel.find_bone("Thumb3.L_end")
	
	var best_t_err = 999.0
	var best_qt2_l = Quaternion.IDENTITY
	var best_qt3_l = Quaternion.IDENTITY
	
	for rx in range(-90, 90, 15):
		for ry in range(-90, 90, 15):
			for rz in range(-90, 90, 15):
				var q2 = Quaternion.from_euler(Vector3(deg_to_rad(rx), deg_to_rad(ry), deg_to_rad(rz)))
				skel.set_bone_pose_rotation(b_t2_l, q2)
				for tx in range(-90, 45, 15):
					var q3 = Quaternion.from_euler(Vector3(deg_to_rad(tx), 0.0, 0.0))
					skel.set_bone_pose_rotation(b_t3_l, q3)
					var pos = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_t3_end_l).origin))
					var res = check_torus.call(pos)
					var err = abs(res.dist_surf_cm) + abs(res.dz_unt_cm) * 2.0
					if err < best_t_err:
						best_t_err = err
						best_qt2_l = q2
						best_qt3_l = q3
	
	skel.set_bone_pose_rotation(b_t2_l, best_qt2_l)
	skel.set_bone_pose_rotation(b_t3_l, best_qt3_l)
	var p_end = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_t3_end_l).origin))
	var res_end = check_torus.call(p_end)
	print("\nSolved Thumb.L Tip: Surf Dist=%+.2f cm, Clock=%.2fh, DZ=%+.2f cm" % [
		res_end.dist_surf_cm, res_end.clock_pos, res_end.dz_unt_cm
	])
	
	# Symmetrical Right Thumb
	var b_t3_end_r = skel.find_bone("Thumb3.R_end")
	var q2_euler = best_qt2_l.get_euler()
	var best_qt2_r = Quaternion.from_euler(Vector3(q2_euler.x, -q2_euler.y, -q2_euler.z))
	var best_qt3_r = best_qt3_l
	skel.set_bone_pose_rotation(b_t2_r, best_qt2_r)
	skel.set_bone_pose_rotation(b_t3_r, best_qt3_r)
	var p_end_r = coupe.to_local(skel.to_global(skel.get_bone_global_pose(b_t3_end_r).origin))
	var res_end_r = check_torus.call(p_end_r)
	print("Solved Thumb.R Tip: Surf Dist=%+.2f cm, Clock=%.2fh, DZ=%+.2f cm" % [
		res_end_r.dist_surf_cm, res_end_r.clock_pos, res_end_r.dz_unt_cm
	])
	# 5. Solve Steer Left and Steer Right arms
	print("\n--- SOLVING STEER LEFT ARMS ---")
	# Steer Left: Left hand pulls down to 9.2h, Right hand sweeps up to 1.2h
	var best_steer_l_cost = 999.0
	var cur_sl_ua = cur_ua_euler
	var cur_sl_la = cur_la_euler
	var cur_sl_h  = cur_h_euler
	for step in [2.0, 1.0, 0.4, 0.1]:
		for _iter in range(40):
			var improved = false
			for p in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua = cur_sl_ua
					var tla = cur_sl_la
					var th = cur_sl_h
					var delta = deg_to_rad(step * sgn)
					if p == "uax": tua.x += delta
					elif p == "uay": tua.y += delta
					elif p == "uaz": tua.z += delta
					elif p == "lay": tla.y += delta
					elif p == "laz": tla.z += delta
					elif p == "hx": th.x += delta
					elif p == "hy": th.y += delta
					elif p == "hz": th.z += delta
					
					skel.set_bone_pose_rotation(b_ua_l, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_l, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_l, Quaternion.from_euler(th))
					
					var palm = get_palm_l_coupe.call()
					var res = check_torus.call(palm)
					var clock_err = abs(res.clock_pos - 9.1)
					var cost = abs(res.dist_surf_cm) + clock_err * 3.0 + abs(res.dz_unt_cm) * 2.0
					if cost < best_steer_l_cost:
						best_steer_l_cost = cost
						cur_sl_ua = tua
						cur_sl_la = tla
						cur_sl_h = th
						improved = true
			if not improved:
				break
	
	var sl_ua_l = Quaternion.from_euler(cur_sl_ua)
	var sl_la_l = Quaternion.from_euler(cur_sl_la)
	var sl_h_l  = Quaternion.from_euler(cur_sl_h)
	
	# Steer Left Right Arm (sweeps up to ~1.2h)
	var best_steer_r_cost = 999.0
	var cur_sl_ua_r = cur_ua_r_euler
	var cur_sl_la_r = cur_la_r_euler
	var cur_sl_h_r  = cur_h_r_euler
	for step in [2.0, 1.0, 0.4, 0.1]:
		for _iter in range(40):
			var improved = false
			for p in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua = cur_sl_ua_r
					var tla = cur_sl_la_r
					var th = cur_sl_h_r
					var delta = deg_to_rad(step * sgn)
					if p == "uax": tua.x += delta
					elif p == "uay": tua.y += delta
					elif p == "uaz": tua.z += delta
					elif p == "lay": tla.y += delta
					elif p == "laz": tla.z += delta
					elif p == "hx": th.x += delta
					elif p == "hy": th.y += delta
					elif p == "hz": th.z += delta
					
					skel.set_bone_pose_rotation(b_ua_r, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_r, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_r, Quaternion.from_euler(th))
					
					var palm = get_palm_r_coupe.call()
					var res = check_torus.call(palm)
					var clock_err = abs(res.clock_pos - 1.2)
					var cost = abs(res.dist_surf_cm) + clock_err * 3.0 + abs(res.dz_unt_cm) * 2.0
					if cost < best_steer_r_cost:
						best_steer_r_cost = cost
						cur_sl_ua_r = tua
						cur_sl_la_r = tla
						cur_sl_h_r = th
						improved = true
			if not improved:
				break
	
	var sl_ua_r = Quaternion.from_euler(cur_sl_ua_r)
	var sl_la_r = Quaternion.from_euler(cur_sl_la_r)
	var sl_h_r  = Quaternion.from_euler(cur_sl_h_r)
	
	# Steer Right: Left hand sweeps up to ~10.9h, Right hand pulls down to ~2.9h
	print("\n--- SOLVING STEER RIGHT ARMS ---")
	var best_sr_l_cost = 999.0
	var cur_sr_ua = cur_ua_euler
	var cur_sr_la = cur_la_euler
	var cur_sr_h  = cur_h_euler
	for step in [2.0, 1.0, 0.4, 0.1]:
		for _iter in range(40):
			var improved = false
			for p in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua = cur_sr_ua
					var tla = cur_sr_la
					var th = cur_sr_h
					var delta = deg_to_rad(step * sgn)
					if p == "uax": tua.x += delta
					elif p == "uay": tua.y += delta
					elif p == "uaz": tua.z += delta
					elif p == "lay": tla.y += delta
					elif p == "laz": tla.z += delta
					elif p == "hx": th.x += delta
					elif p == "hy": th.y += delta
					elif p == "hz": th.z += delta
					
					skel.set_bone_pose_rotation(b_ua_l, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_l, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_l, Quaternion.from_euler(th))
					
					var palm = get_palm_l_coupe.call()
					var res = check_torus.call(palm)
					var clock_err = abs(res.clock_pos - 10.9)
					var cost = abs(res.dist_surf_cm) + clock_err * 3.0 + abs(res.dz_unt_cm) * 2.0
					if cost < best_sr_l_cost:
						best_sr_l_cost = cost
						cur_sr_ua = tua
						cur_sr_la = tla
						cur_sr_h = th
						improved = true
			if not improved:
				break
	
	var sr_ua_l = Quaternion.from_euler(cur_sr_ua)
	var sr_la_l = Quaternion.from_euler(cur_sr_la)
	var sr_h_l  = Quaternion.from_euler(cur_sr_h)
	
	var best_sr_r_cost = 999.0
	var cur_sr_ua_r = cur_ua_r_euler
	var cur_sr_la_r = cur_la_r_euler
	var cur_sr_h_r  = cur_h_r_euler
	for step in [2.0, 1.0, 0.4, 0.1]:
		for _iter in range(40):
			var improved = false
			for p in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua = cur_sr_ua_r
					var tla = cur_sr_la_r
					var th = cur_sr_h_r
					var delta = deg_to_rad(step * sgn)
					if p == "uax": tua.x += delta
					elif p == "uay": tua.y += delta
					elif p == "uaz": tua.z += delta
					elif p == "lay": tla.y += delta
					elif p == "laz": tla.z += delta
					elif p == "hx": th.x += delta
					elif p == "hy": th.y += delta
					elif p == "hz": th.z += delta
					
					skel.set_bone_pose_rotation(b_ua_r, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_r, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_r, Quaternion.from_euler(th))
					
					var palm = get_palm_r_coupe.call()
					var res = check_torus.call(palm)
					var clock_err = abs(res.clock_pos - 2.9)
					var cost = abs(res.dist_surf_cm) + clock_err * 3.0 + abs(res.dz_unt_cm) * 2.0
					if cost < best_sr_r_cost:
						best_sr_r_cost = cost
						cur_sr_ua_r = tua
						cur_sr_la_r = tla
						cur_sr_h_r = th
						improved = true
			if not improved:
				break
	
	var sr_ua_r = Quaternion.from_euler(cur_sr_ua_r)
	var sr_la_r = Quaternion.from_euler(cur_sr_la_r)
	var sr_h_r  = Quaternion.from_euler(cur_sr_h_r)
	
	print("\n=== COMPLETE SOLVED QUATERNIONS ===")
	print("\"Hips\": ", q_hips, ",")
	print("\"Abdomen\": ", q_abdo, ",")
	print("\"Torso\": ", q_torso, ",")
	print("\"Chest\": ", q_chest, ",")
	print("\"Neck\": ", q_neck, ",")
	print("\"Head\": ", q_head, ",")
	print("\"UpperLeg.L\": ", best_q_ul_l, ",")
	print("\"LowerLeg.L\": ", best_q_ll_l, ",")
	print("\"Foot.L\": ", q_foot_l, ",")
	print("\"UpperLeg.R\": ", best_q_ul_r, ",")
	print("\"LowerLeg.R\": ", best_q_ll_r, ",")
	print("\"Foot.R\": ", q_foot_r, ",")
	print("\"Thumb2.L\": ", best_qt2_l, ",")
	print("\"Thumb3.L\": ", best_qt3_l, ",")
	print("\"Thumb2.R\": ", best_qt2_r, ",")
	print("\"Thumb3.R\": ", best_qt3_r, ",")
	print("\n# DRIVE:")
	print("\"UpperArm.L\": ", best_ua_l, ",")
	print("\"LowerArm.L\": ", best_la_l, ",")
	print("\"Hand.L\": ", best_h_l, ",")
	print("\"UpperArm.R\": ", best_ua_r, ",")
	print("\"LowerArm.R\": ", best_la_r, ",")
	print("\"Hand.R\": ", best_h_r, ",")
	print("\n# STEER LEFT:")
	print("\"UpperArm.L\": ", sl_ua_l, ",")
	print("\"LowerArm.L\": ", sl_la_l, ",")
	print("\"Hand.L\": ", sl_h_l, ",")
	print("\"UpperArm.R\": ", sl_ua_r, ",")
	print("\"LowerArm.R\": ", sl_la_r, ",")
	print("\"Hand.R\": ", sl_h_r, ",")
	print("\n# STEER RIGHT:")
	print("\"UpperArm.L\": ", sr_ua_l, ",")
	print("\"LowerArm.L\": ", sr_la_l, ",")
	print("\"Hand.L\": ", sr_h_l, ",")
	print("\"UpperArm.R\": ", sr_ua_r, ",")
	print("\"LowerArm.R\": ", sr_la_r, ",")
	print("\"Hand.R\": ", sr_h_r, ",")
	quit(0)

