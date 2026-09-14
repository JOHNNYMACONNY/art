extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var vehicles = [
		{"name": "Muscle Coupe", "path": "res://scenes/vehicles/muscle_coupe.tscn"},
		{"name": "Security Interceptor", "path": "res://scenes/vehicles/security_interceptor.tscn"},
		{"name": "Scrap Hauler", "path": "res://scenes/vehicles/scrap_hauler.tscn"}
	]
	
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	
	for v_info in vehicles:
		var v_scene = load(v_info.path) as PackedScene
		var vehicle = v_scene.instantiate()
		root.add_child(vehicle)
		vehicle.position = Vector3.ZERO
		vehicle.rotation_degrees = Vector3(0, 180, 0)
		vehicle.set_physics_process(false)
		await process_frame
		
		var seat = vehicle.find_child("Seat_Driver", true, false)
		var wheel = vehicle.find_child("SteeringWheel_Mount", true, false)
		
		var runner = runner_scene.instantiate()
		vehicle.add_child(runner)
		runner.set_vehicle_driving_posture(true, "car")
		runner.position = seat.position + Vector3(0.0, -0.80, 0.08)
		runner.rotation = Vector3.ZERO
		
		var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
		ap.play("car_drive")
		ap.advance(0.1)
		await process_frame
		await process_frame
		
		var b_hl = skel.find_bone("Hand.L")
		var b_hr = skel.find_bone("Hand.R")
		var b_head = skel.find_bone("Head_end")
		if b_head < 0: b_head = skel.find_bone("Head")
		
		var hl_pos = skel.to_global(skel.get_bone_global_pose(b_hl).origin)
		var hr_pos = skel.to_global(skel.get_bone_global_pose(b_hr).origin)
		var head_pos = skel.to_global(skel.get_bone_global_pose(b_head).origin)
		
		var l_wheel_local = wheel.to_local(hl_pos)
		var r_wheel_local = wheel.to_local(hr_pos)
		
		print("\n=== ", v_info.name, " ===")
		print("Seat local pos:        ", seat.position)
		print("Wheel local pos:       ", wheel.position)
		print("Hand separation:       ", hl_pos.distance_to(hr_pos), " m")
		print("Hand.L rel to wheel:   ", l_wheel_local)
		print("Hand.R rel to wheel:   ", r_wheel_local)
		print("Head global Y:         ", head_pos.y)
		
		vehicle.queue_free()
		await process_frame
		
	quit(0)
