extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	
	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)
	print("Seat_Driver position: ", seat.position)
	print("SteeringWheel_Mount position: ", wheel.position)
	
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	
	ap.play("car_drive")
	ap.advance(0.1)
	await process_frame
	
	print("\nRUNNER BONE RESTS & POSES IN CAR_DRIVE:")
	for bname in ["Hips", "Spine", "Torso", "Chest", "Head", "UpperLeg.L", "LowerLeg.L", "Foot.L"]:
		var idx = skel.find_bone(bname)
		if idx >= 0:
			var gpos = skel.get_bone_global_pose(idx).origin
			var rot = skel.get_bone_pose_rotation(idx)
			print("%-12s gpos: %-28s rot: %s" % [bname, gpos, rot])
			
	quit(0)
