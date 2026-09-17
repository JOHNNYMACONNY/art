extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var anim = ap.get_animation("car_drive").duplicate() as Animation

	# Solved Godot Quaternions from solve_complete_grip.gd
	var solved = {
		"UpperArm.L": Quaternion(-0.878858, 0.184938, 0.395316, 0.192695),
		"LowerArm.L": Quaternion(0.185586, 0.173235, -0.679113, 0.688733),
		"Hand.L":     Quaternion(0.106174, 0.795335, 0.504207, 0.319288),
		"Thumb2.L":   Quaternion(-0.155173, 0.816714, -0.157512, 0.533),
		"Thumb3.L":   Quaternion(-0.907092, 0.019019, 0.205391, 0.366928),

		"UpperArm.R": Quaternion(-0.823639, -0.032717, -0.542098, 0.163336),
		"LowerArm.R": Quaternion(0.083789, -0.302703, 0.590931, 0.743069),
		"Hand.R":     Quaternion(0.227172, -0.748228, -0.451913, 0.429328),
		"Thumb2.R":   Quaternion(0.109252, -0.460994, -0.299019, 0.828333),
		"Thumb3.R":   Quaternion(-0.89022, -0.027971, -0.204364, 0.406155),
	}

	for i in range(anim.get_track_count()):
		var path_str = str(anim.track_get_path(i))
		for bname in solved:
			if path_str.ends_with(":" + bname):
				var q = solved[bname]
				# Update all keyframes in this track
				for k in range(anim.track_get_key_count(i)):
					anim.track_set_key_value(i, k, q)
				print("Updated track ", i, " for ", bname, " to ", q)

	# Save duplicate as custom resource
	var err = ResourceSaver.save(anim, "res://scenes/player/anim_car_drive.res")
	print("Saved anim_car_drive.res with code: ", err)

	# Test playing the modified anim
	var lib = ap.get_animation_library("")
	lib.add_animation("car_drive", anim)
	ap.play("car_drive")
	ap.advance(0.1)

	# Check contact in Coupe
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	coupe.add_child(runner)
	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)
	runner.position = seat.position + Vector3(0.0, -0.78, 0.18)

	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var b_i2_l = skel.find_bone("Index2.L")
	var b_i2_r = skel.find_bone("Index2.R")
	var pos_l = skel.to_global(skel.get_bone_global_pose(b_i2_l).origin)
	var pos_r = skel.to_global(skel.get_bone_global_pose(b_i2_r).origin)

	var target_10 = Vector3(-0.5029, 0.8648, -0.3849)
	var target_2  = Vector3(-0.2171, 0.8648, -0.3849)

	print("\n=== VERIFYING CONTACT WITH DIRECT GODOT BONE TRACKS ===")
	print("Index2.L pos: ", pos_l, " vs target: ", target_10, " (Dist: %+0.2f cm)" % [(pos_l - target_10).length() * 100.0])
	print("Index2.R pos: ", pos_r, " vs target: ", target_2,  " (Dist: %+0.2f cm)" % [(pos_r - target_2).length() * 100.0])

	quit(0)
