extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var vehicles = [
		["Coupe", "res://scenes/vehicles/muscle_coupe.tscn"],
		["Interceptor", "res://scenes/vehicles/security_interceptor.tscn"],
		["Hauler", "res://scenes/vehicles/scrap_hauler.tscn"]
	]

	for entry in vehicles:
		var vname = entry[0]
		var vpath = entry[1]
		var scene = load(vpath) as PackedScene
		var v = scene.instantiate()
		root.add_child(v)
		var seat = v.find_child("Seat_Driver", true, false)
		var wheel = v.find_child("SteeringWheel_Mount", true, false)
		print("\n=== ", vname, " ===")
		print("Seat pos:  ", seat.position)
		print("Wheel pos: ", wheel.position)
		print("Vector from Seat to Wheel: ", wheel.position - seat.position)
		v.queue_free()

	quit(0)
