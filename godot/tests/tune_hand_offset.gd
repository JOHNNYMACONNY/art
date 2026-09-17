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
	
	# Target 10 o'clock and 2 o'clock on 36cm rim
	var target_10 = Vector3(-0.5029, 0.8648, -0.3849)
	var target_2  = Vector3(-0.2171, 0.8648, -0.3849)
	
	var b_hl = skel.find_bone("Hand.L")
	var b_i2l = skel.find_bone("Index2.L")
	var b_i4el = skel.find_bone("Index4.L_end")
	var b_t3l = skel.find_bone("Thumb3.L")
	
	var cur_rot_hl = skel.get_bone_pose_rotation(b_hl)
	print("Current Hand.L pose rotation: ", cur_rot_hl)
	var cur_euler = cur_rot_hl.get_euler()
	print("Current Hand.L euler (deg): ", Vector3(rad_to_deg(cur_euler.x), rad_to_deg(cur_euler.y), rad_to_deg(cur_euler.z)))
	
	var p_i2 = skel.to_global(skel.get_bone_global_pose(b_i2l).origin)
	print("Current Index2.L: ", p_i2, " dist to rim target: ", p_i2.distance_to(target_10) * 100.0, " cm")
	
	var b_ua = skel.find_bone("UpperArm.L")
	var b_la = skel.find_bone("LowerArm.L")
	var cur_rot_ua = skel.get_bone_pose_rotation(b_ua)
	var cur_rot_la = skel.get_bone_pose_rotation(b_la)
	
	print("Current UpperArm.L pose rotation: ", cur_rot_ua)
	print("Current LowerArm.L pose rotation: ", cur_rot_la)
	
	# Target for Index2.L knuckle: directly on top/front of 10 o'clock rim tube
	# Target 10 o'clock rim tube center is (-0.5029, 0.8648, -0.3849)
	var target_knuckle = Vector3(-0.5029, 0.8648, -0.3849)
	
	var best_err = 999.0
	var best_ua = Vector3.ZERO
	var best_la = Vector3.ZERO
	var best_h = Vector3.ZERO
	var best_p_h = Vector3.ZERO
	var best_p_i2 = Vector3.ZERO
	var best_p_i4e = Vector3.ZERO
	
	# Fine grid search around best deltas:
	# Delta UpperArm.L: (-10.0, 0.0, -10.0)
	# Delta LowerArm.L: (0.0, -5.0, -25.0)
	# Delta Hand.L:     (-30.0, 30.0, 30.0)
	best_err = 999.0
	
	for d_ua_x in range(-14, -6, 2):
		for d_ua_z in range(-14, -6, 2):
			for d_la_z in range(-30, -20, 2):
				for d_la_y in range(-9, -1, 2):
					var q_ua = Quaternion.from_euler(Vector3(deg_to_rad(d_ua_x), 0, deg_to_rad(d_ua_z))) * cur_rot_ua
					var q_la = Quaternion.from_euler(Vector3(0, deg_to_rad(d_la_y), deg_to_rad(d_la_z))) * cur_rot_la
					skel.set_bone_pose_rotation(b_ua, q_ua)
					skel.set_bone_pose_rotation(b_la, q_la)
					
					var p_wrist = skel.to_global(skel.get_bone_global_pose(b_hl).origin)
					for d_hx in range(-36, -24, 3):
						for d_hy in range(24, 36, 3):
							for d_hz in range(24, 36, 3):
								var q_h = Quaternion.from_euler(Vector3(deg_to_rad(d_hx), deg_to_rad(d_hy), deg_to_rad(d_hz))) * cur_rot_hl
								skel.set_bone_pose_rotation(b_hl, q_h)
								
								var pos_i2 = skel.to_global(skel.get_bone_global_pose(b_i2l).origin)
								var err = pos_i2.distance_to(target_knuckle)
								if err < best_err:
									best_err = err
									best_ua = Vector3(d_ua_x, 0, d_ua_z)
									best_la = Vector3(0, d_la_y, d_la_z)
									best_h  = Vector3(d_hx, d_hy, d_hz)
									best_p_h = p_wrist
									best_p_i2 = pos_i2
									best_p_i4e = skel.to_global(skel.get_bone_global_pose(b_i4el).origin)

	print("\n=== FINE TUNING RESULTS ===")
	print("Best Index2.L knuckle error to rim: ", best_err * 100.0, " cm")
	print("Delta UpperArm.L: ", best_ua)
	print("Delta LowerArm.L: ", best_la)
	print("Delta Hand.L:     ", best_h)
	print("Resulting Wrist pos:   ", best_p_h)
	print("Resulting Knuckle pos: ", best_p_i2, " vs Target: ", target_knuckle)
	print("Resulting Tip pos:     ", best_p_i4e)
	
	# Now calculate exact global rotation Euler angles to apply in Blender
	var final_q_ua = Quaternion.from_euler(Vector3(deg_to_rad(best_ua.x), 0, deg_to_rad(best_ua.z))) * cur_rot_ua
	var final_q_la = Quaternion.from_euler(Vector3(0, deg_to_rad(best_la.y), deg_to_rad(best_la.z))) * cur_rot_la
	var final_q_h  = Quaternion.from_euler(Vector3(deg_to_rad(best_h.x), deg_to_rad(best_h.y), deg_to_rad(best_h.z))) * cur_rot_hl
	
	skel.set_bone_pose_rotation(b_ua, final_q_ua)
	skel.set_bone_pose_rotation(b_la, final_q_la)
	skel.set_bone_pose_rotation(b_hl, final_q_h)

	# Mirror for Right Arm:
	var b_uar = skel.find_bone("UpperArm.R")
	var b_lar = skel.find_bone("LowerArm.R")
	var b_hr  = skel.find_bone("Hand.R")
	var cur_rot_uar = skel.get_bone_pose_rotation(b_uar)
	var cur_rot_lar = skel.get_bone_pose_rotation(b_lar)
	var cur_rot_hr  = skel.get_bone_pose_rotation(b_hr)
	
	var final_q_uar = Quaternion.from_euler(Vector3(deg_to_rad(best_ua.x), 0, deg_to_rad(-best_ua.z))) * cur_rot_uar
	var final_q_lar = Quaternion.from_euler(Vector3(0, deg_to_rad(-best_la.y), deg_to_rad(-best_la.z))) * cur_rot_lar
	var final_q_hr  = Quaternion.from_euler(Vector3(deg_to_rad(best_h.x), deg_to_rad(-best_h.y), deg_to_rad(-best_h.z))) * cur_rot_hr
	
	skel.set_bone_pose_rotation(b_uar, final_q_uar)
	skel.set_bone_pose_rotation(b_lar, final_q_lar)
	skel.set_bone_pose_rotation(b_hr,  final_q_hr)
	
	print("\nFinal Quats (L):")
	print("UpperArm.L: ", final_q_ua)
	print("LowerArm.L: ", final_q_la)
	print("Hand.L:     ", final_q_h)

	# Setup Camera focused directly on left hand and rim tube
	var cam = Camera3D.new()
	root.add_child(cam)
	cam.current = true
	cam.fov = 36.0
	# Focus directly on left hand knuckle and tube
	cam.position = Vector3(-0.35, 1.02, -0.22)
	cam.look_at(Vector3(-0.50, 0.86, -0.38), Vector3.UP)

	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.16, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.82, 1.0)
	env_node.environment = env
	root.add_child(env_node)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 38.0, 0.0)
	sun.light_energy = 1.4
	root.add_child(sun)

	for _i in range(12): await process_frame
	var img = root.get_viewport().get_texture().get_image()
	img.save_png("res://../docs/visual_direction/references/proof_grip_left_macro.png")
	print("Saved proof_grip_left_macro.png")
	
	quit(0)
