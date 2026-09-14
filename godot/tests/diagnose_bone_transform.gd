extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)

	var b_i2 = skel.find_bone("Index2.L")
	var b_ua = skel.find_bone("UpperArm.L")
	var b_la = skel.find_bone("LowerArm.L")
	var b_h  = skel.find_bone("Hand.L")

	print("Skeleton global transform: ", skel.global_transform)
	print("UpperArm.L rest pose:   ", skel.get_bone_rest(b_ua))
	print("UpperArm.L global pose: ", skel.get_bone_global_pose(b_ua))
	print("LowerArm.L global pose: ", skel.get_bone_global_pose(b_la))
	print("Hand.L global pose:     ", skel.get_bone_global_pose(b_h))
	print("Index2.L global pose:   ", skel.get_bone_global_pose(b_i2))
	quit(0)
