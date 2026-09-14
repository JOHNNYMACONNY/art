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
	
	print("\n=== WHEEL AND HAND MEASUREMENTS (COUPE) ===")
	print("Wheel mount position: ", wheel.global_position)
	# Rim targets: 10 o'clock: (-0.477, 0.896, -0.399), 2 o'clock: (-0.243, 0.896, -0.399)
	var target_10 = Vector3(-0.477, 0.896, -0.399)
	var target_2 = Vector3(-0.243, 0.896, -0.399)
	
	for side in ["L", "R"]:
		var b_h = skel.find_bone("Hand." + side)
		var b_i2 = skel.find_bone("Index2." + side)
		var b_i4 = skel.find_bone("Index4." + side)
		var b_i4_end = skel.find_bone("Index4." + side + "_end")
		var b_t3 = skel.find_bone("Thumb3." + side)
		
		var p_h = skel.to_global(skel.get_bone_global_pose(b_h).origin)
		var p_i2 = skel.to_global(skel.get_bone_global_pose(b_i2).origin)
		var p_i4 = skel.to_global(skel.get_bone_global_pose(b_i4).origin)
		var p_i4e = skel.to_global(skel.get_bone_global_pose(b_i4_end).origin)
		var p_t3 = skel.to_global(skel.get_bone_global_pose(b_t3).origin)
		
		var target = target_10 if side == "L" else target_2
		print("\nSide " + side + ":")
		print("  Hand (wrist):     ", p_h)
		print("  Index2 (knuckle): ", p_i2, " dist to rim target: ", p_i2.distance_to(target) * 100.0, " cm")
		print("  Index4 (distal):  ", p_i4)
		print("  Index4_end (tip): ", p_i4e, " tip Z vs rim Z (-0.399): ", p_i4e.z - target.z)
		print("  Thumb3:           ", p_t3)
		
	var b_hl = skel.find_bone("Hand.L")
	var b_hr = skel.find_bone("Hand.R")
	var hl = skel.to_global(skel.get_bone_global_pose(b_hl).origin)
	var hr = skel.to_global(skel.get_bone_global_pose(b_hr).origin)
	print("\nHand separation: ", hl.distance_to(hr) * 100.0, " cm")
	
	quit(0)
