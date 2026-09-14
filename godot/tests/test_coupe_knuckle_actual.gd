extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)
	print("Seat position:  ", seat.position)
	print("Wheel position: ", wheel.position)
	print("Wheel global_pos: ", wheel.global_position)
	
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	coupe.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	runner.position = seat.position + Vector3(0.0, -0.78, 0.18)
	print("Runner position:", runner.position)

	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	ap.play("car_drive")
	ap.advance(0.1)

	var b_i2_l = skel.find_bone("Index2.L")
	var b_i2_r = skel.find_bone("Index2.R")
	var pos_l = skel.to_global(skel.get_bone_global_pose(b_i2_l).origin)
	var pos_r = skel.to_global(skel.get_bone_global_pose(b_i2_r).origin)

	print("Left Knuckle (Index2.L) global pos:  ", pos_l)
	print("Right Knuckle (Index2.R) global pos: ", pos_r)

	# Wheel Torus Center: (-0.36, 0.79, -0.35)
	# 10 o'clock target:  (-0.5029, 0.8648, -0.3849)
	# 2 o'clock target:   (-0.2171, 0.8648, -0.3849)
	var target_10 = Vector3(-0.5029, 0.8648, -0.3849)
	var target_2  = Vector3(-0.2171, 0.8648, -0.3849)

	print("Left Knuckle Error:  ", (pos_l - target_10).length() * 100.0, " cm")
	print("Right Knuckle Error: ", (pos_r - target_2).length() * 100.0, " cm")
	print("Left Knuckle Delta needed:  ", target_10 - pos_l)
	print("Right Knuckle Delta needed: ", target_2 - pos_r)

	quit(0)
