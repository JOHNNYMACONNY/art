extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var v_scene = load("res://scenes/vehicles/security_interceptor.tscn") as PackedScene
	var vehicle = v_scene.instantiate()
	root.add_child(vehicle)
	vehicle.position = Vector3.ZERO
	vehicle.rotation = Vector3.ZERO
	vehicle.set_physics_process(false)
	await process_frame
	
	var seat = vehicle.find_child("Seat_Driver", true, false)
	var wheel = vehicle.find_child("SteeringWheel_Mount", true, false)
	
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	vehicle.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	
	# Test range of Y and Z offsets
	for dy in [-0.74, -0.76, -0.78, -0.80]:
		for dz in [0.15, 0.17, 0.18, 0.19]:
			runner.position = seat.position + Vector3(0.0, dy, dz)
			await process_frame
			var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
			var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
			ap.play("car_drive")
			ap.advance(0.1)
			await process_frame
			
			var b_hl = skel.find_bone("Hand.L")
			var b_hr = skel.find_bone("Hand.R")
			var hl_pos = skel.to_global(skel.get_bone_global_pose(b_hl).origin)
			var hr_pos = skel.to_global(skel.get_bone_global_pose(b_hr).origin)
			var l_loc = wheel.to_local(hl_pos)
			var r_loc = wheel.to_local(hr_pos)
			# Rim 10-and-2 position has: Y approx +0.09m, Z approx +0.04m (tilted back)
			print("dy: %.2f dz: %.2f | Hand.L rel: (x: %+.3f, y: %+.3f, z: %+.3f) | dist to rim 10-pos: %.3f" % [
				dy, dz, l_loc.x, l_loc.y, l_loc.z,
				l_loc.distance_to(Vector3(-0.13, 0.09, 0.04))
			])
	
	vehicle.queue_free()
	quit(0)
