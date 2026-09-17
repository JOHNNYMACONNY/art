extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== SOLVING SCRAMBLER MOTORCYCLE RIDING BIOMECHANICS ===")
	var bike_scene := load("res://models/courier_bike.glb") as PackedScene
	var bike := bike_scene.instantiate() as Node3D
	root.add_child(bike)
	bike.position = Vector3.ZERO

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root.add_child(runner)
	runner.set_physics_process(false)
	runner.set_process(false)

	# Runner positioned at RiderSocket location: (0.0, 0.58, 0.15)
	runner.position = Vector3(0.0, 0.58, 0.15)

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer

	# Target contact points on Courier Bike (world space):
	# Saddle contact: (0.0, 0.96, 0.25)
	# Left Handlebar Grip: (-0.42, 1.15, -0.46)
	# Right Handlebar Grip: (0.42, 1.15, -0.46)
	# Left Footpeg: (-0.22, 0.36, 0.12)
	# Right Footpeg: (0.22, 0.36, 0.12)
	var target_saddle := Vector3(0.0, 0.96, 0.25)
	var target_grip_l := Vector3(-0.42, 1.15, -0.46)
	var target_grip_r := Vector3(0.42, 1.15, -0.46)
	var target_foot_l := Vector3(-0.22, 0.36, 0.12)
	var target_foot_r := Vector3(0.22, 0.36, 0.12)

	print("Target Saddle: ", target_saddle)
	print("Target Left Grip: ", target_grip_l)
	print("Target Right Grip: ", target_grip_r)
	print("Target Left Footpeg: ", target_foot_l)
	print("Target Right Footpeg: ", target_foot_r)

	quit(0)
