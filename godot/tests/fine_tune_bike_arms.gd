extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root.add_child(runner)
	runner.set_vehicle_driving_posture(true, "bike")
	runner.position = Vector3(0.0, 0.58, 0.15)

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D

	var hips_track_pos := Vector3(0.0, 0.445, -0.07)
	var q_hips := Quaternion.from_euler(Vector3(deg_to_rad(20.0), 0.0, 0.0))
	var q_abdomen := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_torso := Quaternion.from_euler(Vector3(deg_to_rad(8.0), 0.0, 0.0))
	var q_chest := Quaternion.from_euler(Vector3(deg_to_rad(6.0), 0.0, 0.0))
	var q_neck := Quaternion.from_euler(Vector3(deg_to_rad(-16.0), 0.0, 0.0))
	var q_head := Quaternion.from_euler(Vector3(deg_to_rad(-20.0), 0.0, 0.0))

	skel.set_bone_pose_position(skel.find_bone("Hips"), hips_track_pos)
	skel.set_bone_pose_rotation(skel.find_bone("Hips"), q_hips)
	skel.set_bone_pose_rotation(skel.find_bone("Abdomen"), q_abdomen)
	skel.set_bone_pose_rotation(skel.find_bone("Torso"), q_torso)
	skel.set_bone_pose_rotation(skel.find_bone("Chest"), q_chest)
	skel.set_bone_pose_rotation(skel.find_bone("Neck"), q_neck)
	skel.set_bone_pose_rotation(skel.find_bone("Head"), q_head)

	var b_ua_l := skel.find_bone("UpperArm.L")
	var b_la_l := skel.find_bone("LowerArm.L")
	var b_h_l  := skel.find_bone("Hand.L")
	var b_i2_l := skel.find_bone("Index2.L")
	var b_m2_l := skel.find_bone("Middle2.L")

	var grip_l := Vector3(-0.422169, 1.182702, -0.455136)

	var cur_ua_euler := Quaternion(-0.504508, -0.546351, 0.203134, 0.636953).get_euler()
	var cur_la_euler := Quaternion(0.008926, -0.61281, -0.01941, 0.789942).get_euler()
	var cur_h_euler  := Quaternion(0.015628, 0.106287, 0.186213, 0.976618).get_euler()

	var get_palm_dist = func() -> float:
		var p_i2 := skel.to_global(skel.get_bone_global_pose(b_i2_l).origin)
		var p_m2 := skel.to_global(skel.get_bone_global_pose(b_m2_l).origin)
		var palm := (p_i2 + p_m2) * 0.5
		return (palm - grip_l).length()

	skel.set_bone_pose_rotation(b_ua_l, Quaternion.from_euler(cur_ua_euler))
	skel.set_bone_pose_rotation(b_la_l, Quaternion.from_euler(cur_la_euler))
	skel.set_bone_pose_rotation(b_h_l, Quaternion.from_euler(cur_h_euler))

	var best_dist = get_palm_dist.call()
	print("Initial palm dist: ", best_dist * 100.0, " cm")

	for step in [1.5, 0.8, 0.3, 0.1]:
		for _iter in range(50):
			var improved := false
			for param in ["uax", "uay", "uaz", "lay", "laz", "hx", "hy", "hz"]:
				for sgn in [-1.0, 1.0]:
					var tua := cur_ua_euler
					var tla := cur_la_euler
					var th := cur_h_euler
					var delta_rad := deg_to_rad(step * sgn)
					if param == "uax": tua.x += delta_rad
					elif param == "uay": tua.y += delta_rad
					elif param == "uaz": tua.z += delta_rad
					elif param == "lay": tla.y += delta_rad
					elif param == "laz": tla.z += delta_rad
					elif param == "hx": th.x += delta_rad
					elif param == "hy": th.y += delta_rad
					elif param == "hz": th.z += delta_rad

					skel.set_bone_pose_rotation(b_ua_l, Quaternion.from_euler(tua))
					skel.set_bone_pose_rotation(b_la_l, Quaternion.from_euler(tla))
					skel.set_bone_pose_rotation(b_h_l, Quaternion.from_euler(th))

					var d: float = get_palm_dist.call()
					if d < best_dist:
						best_dist = d
						cur_ua_euler = tua
						cur_la_euler = tla
						cur_h_euler = th
						improved = true
			if not improved:
				break

	print("Final palm dist to Left Grip: ", best_dist * 100.0, " cm")
	var q_ua_l := Quaternion.from_euler(cur_ua_euler)
	var q_la_l := Quaternion.from_euler(cur_la_euler)
	var q_h_l  := Quaternion.from_euler(cur_h_euler)

	print("Solved Left Arm:")
	print("  UpperArm.L: ", q_ua_l)
	print("  LowerArm.L: ", q_la_l)
	print("  Hand.L:     ", q_h_l)

	# Invert for Right Arm
	var uar_euler := Vector3(cur_ua_euler.x, -cur_ua_euler.y, -cur_ua_euler.z)
	var lar_euler := Vector3(cur_la_euler.x, -cur_la_euler.y, -cur_la_euler.z)
	var hr_euler  := Vector3(cur_h_euler.x,  -cur_h_euler.y,  -cur_h_euler.z)

	var q_ua_r := Quaternion.from_euler(uar_euler)
	var q_la_r := Quaternion.from_euler(lar_euler)
	var q_h_r  := Quaternion.from_euler(hr_euler)

	skel.set_bone_pose_rotation(skel.find_bone("UpperArm.R"), q_ua_r)
	skel.set_bone_pose_rotation(skel.find_bone("LowerArm.R"), q_la_r)
	skel.set_bone_pose_rotation(skel.find_bone("Hand.R"), q_h_r)

	var b_i2_r := skel.find_bone("Index2.R")
	var b_m2_r := skel.find_bone("Middle2.R")
	var p_i2_r := skel.to_global(skel.get_bone_global_pose(b_i2_r).origin)
	var p_m2_r := skel.to_global(skel.get_bone_global_pose(b_m2_r).origin)
	var palm_r := (p_i2_r + p_m2_r) * 0.5
	var grip_r := Vector3(0.422155, 1.182702, -0.455136)
	print("Final palm dist to Right Grip: ", (palm_r - grip_r).length() * 100.0, " cm")

	quit(0)
