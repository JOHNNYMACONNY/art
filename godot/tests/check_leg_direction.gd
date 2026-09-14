extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	runner.rotation_degrees = Vector3(0, 180, 0)
	
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)
	await process_frame
	
	for leg in ["UpperLeg", "LowerLeg", "Foot"]:
		var idx_l = skel.find_bone(leg + ".L")
		var idx_r = skel.find_bone(leg + ".R")
		var pos_l = skel.to_global(skel.get_bone_global_pose(idx_l).origin)
		var pos_r = skel.to_global(skel.get_bone_global_pose(idx_r).origin)
		print("%-10s L: %s | R: %s" % [leg, pos_l, pos_r])
		
	quit(0)
