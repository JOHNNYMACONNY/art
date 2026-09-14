extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D

	print("--- REST POSE GLOBAL POSITIONS ---")
	for bname in ["Hips", "Chest", "UpperArm.L", "LowerArm.L", "Hand.L", "UpperLeg.L", "LowerLeg.L", "Foot.L"]:
		var b_idx := skel.find_bone(bname)
		var rest_g := skel.get_bone_global_rest(b_idx)
		print(bname, " REST global pos: ", rest_g.origin)

	ap.play("bike_ride")
	ap.advance(0.0)

	print("\n--- BIKE_RIDE ANIMATION GLOBAL POSITIONS ---")
	for bname in ["Hips", "Chest", "UpperArm.L", "LowerArm.L", "Hand.L", "UpperLeg.L", "LowerLeg.L", "Foot.L"]:
		var b_idx := skel.find_bone(bname)
		var gpose := skel.get_bone_global_pose(b_idx)
		var lpose := skel.get_bone_pose(b_idx)
		print(bname, " BIKE global pos: ", gpose.origin, " rot euler deg: ", lpose.basis.get_euler() * 180.0 / PI)

	quit(0)
