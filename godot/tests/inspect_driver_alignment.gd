extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var vehicles = [
		{"name": "Muscle Coupe", "path": "res://scenes/vehicles/muscle_coupe.tscn"},
		{"name": "Security Interceptor", "path": "res://scenes/vehicles/security_interceptor.tscn"},
		{"name": "Scrap Hauler", "path": "res://scenes/vehicles/scrap_hauler.tscn"}
	]
	
	for v_info in vehicles:
		print("\n=======================================================")
		print("VEHICLE: ", v_info.name)
		var v_scene = load(v_info.path) as PackedScene
		var vehicle = v_scene.instantiate()
		root.add_child(vehicle)
		vehicle.position = Vector3.ZERO
		vehicle.rotation_degrees = Vector3(0, 180, 0)
		await process_frame
		await process_frame
		
		var seat = vehicle.find_child("Seat_Driver", true, false)
		var wheel = vehicle.find_child("SteeringWheel_Mount", true, false)
		if seat:
			print("Seat_Driver global pos: ", seat.global_position)
		if wheel:
			print("SteeringWheel_Mount global pos: ", wheel.global_position)
		if seat and wheel:
			print("Vector from Seat to Wheel: ", wheel.global_position - seat.global_position)
			
		vehicle.queue_free()
		await process_frame
		
	quit(0)
