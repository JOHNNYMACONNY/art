extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D

	print("AnimationPlayer root_node: ", ap.root_node)
	print("Animation list: ", ap.get_animation_list())

	ap.play("bike_ride")
	ap.advance(0.1)

	print("\n--- Testing bone global poses under bike_ride ---")
	for bname in ["Hips", "Chest", "UpperArm.L", "LowerArm.L", "Hand.L", "UpperLeg.L", "LowerLeg.L", "Foot.L"]:
		var b_idx := skel.find_bone(bname)
		var pose := skel.get_bone_pose(b_idx)
		var gpose := skel.get_bone_global_pose(b_idx)
		print(bname, " idx=", b_idx, " pose rot=", pose.basis.get_rotation_quaternion(), " origin=", pose.origin)

	quit(0)
