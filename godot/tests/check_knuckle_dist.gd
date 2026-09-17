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

	var q_ua_l := Quaternion(-0.504508, -0.546351, 0.203134, 0.636953)
	var q_la_l := Quaternion(0.008926, -0.61281, -0.01941, 0.789942)
	var q_h_l  := Quaternion(0.015628, 0.106287, 0.186213, 0.976618)

	skel.set_bone_pose_rotation(skel.find_bone("UpperArm.L"), q_ua_l)
	skel.set_bone_pose_rotation(skel.find_bone("LowerArm.L"), q_la_l)
	skel.set_bone_pose_rotation(skel.find_bone("Hand.L"), q_h_l)

	var grip_l := Vector3(-0.422169, 1.182702, -0.455136)
	var p_h := skel.to_global(skel.get_bone_global_pose(skel.find_bone("Hand.L")).origin)
	var p_i2 := skel.to_global(skel.get_bone_global_pose(skel.find_bone("Index2.L")).origin)
	var p_m2 := skel.to_global(skel.get_bone_global_pose(skel.find_bone("Middle2.L")).origin)

	print("Grip L target: ", grip_l)
	print("Wrist (Hand.L): ", p_h, " dist: ", (p_h - grip_l).length() * 100.0, " cm")
	print("Index2.L:      ", p_i2, " dist: ", (p_i2 - grip_l).length() * 100.0, " cm")
	print("Middle2.L:     ", p_m2, " dist: ", (p_m2 - grip_l).length() * 100.0, " cm")

	quit(0)
