extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var v_scene = load("res://scenes/vehicles/scrap_hauler.tscn") as PackedScene
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
	runner.position = seat.position + Vector3(0.0, -0.76, 0.19)
	runner.rotation = Vector3.ZERO
	
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)
	await process_frame
	await process_frame
	
	var b_head = skel.find_bone("Head_end")
	if b_head < 0: b_head = skel.find_bone("Head")
	var head_pos = skel.to_global(skel.get_bone_global_pose(b_head).origin)
	
	print("Hauler Seat position: ", seat.position)
	print("Hauler Wheel position: ", wheel.position)
	print("Hauler Head global Y: ", head_pos.y)
	print("Hauler Cab Roof inner Y (approx 2.46):")
	print("Headroom clearance: ", 2.46 - head_pos.y)
	
	vehicle.queue_free()
	quit(0)
