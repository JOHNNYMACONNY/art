extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var v_scene = load("res://scenes/vehicles/security_interceptor.tscn") as PackedScene
	var vehicle = v_scene.instantiate()
	root.add_child(vehicle)
	vehicle.position = Vector3.ZERO
	vehicle.rotation_degrees = Vector3(0, 180, 0)
	vehicle.set_physics_process(false)
	await process_frame
	
	var seat = vehicle.find_child("Seat_Driver", true, false)
	var wheel = vehicle.find_child("SteeringWheel_Mount", true, false)
	
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	runner.global_rotation = vehicle.global_rotation
	
	runner.global_position = seat.global_position + Vector3(0.0, -0.88, -0.16)
	await process_frame
	
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)
	await process_frame
	
	print("Seat position: ", seat.global_position)
	print("Wheel position: ", wheel.global_position)
	
	var check_bones = ["Hips", "Chest", "Head", "Hand.L", "Hand.R", "Foot.L", "Foot.R"]
	for bname in check_bones:
		var idx = skel.find_bone(bname)
		if idx >= 0:
			var bpos = skel.to_global(skel.get_bone_global_pose(idx).origin)
			print("Bone %-8s: %s (rel to seat: %s)" % [bname, bpos, bpos - seat.global_position])
			
	quit(0)
