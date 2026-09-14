extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root.add_child(runner)
	runner.position = Vector3(0.0, 0.58, 0.15)

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D

	var anim := ap.get_animation("bike_ride")
	print("Track 0 path: ", anim.track_get_path(0), " type: ", anim.track_get_type(0), " keys: ", anim.track_get_key_count(0))
	print("Track 0 key 0 before: ", anim.track_get_key_value(0, 0))

	# Set Hips pos to (0, 0.1, 0)
	for k in range(anim.track_get_key_count(0)):
		anim.track_set_key_value(0, k, Vector3(0, 0.1, 0))

	print("Track 0 key 0 after: ", anim.track_get_key_value(0, 0))

	ap.play("bike_ride")
	ap.advance(0.0)

	var b_hips := skel.find_bone("Hips")
	var gpose := skel.get_bone_global_pose(b_hips)
	print("Hips bone global pose origin: ", gpose.origin)
	print("Hips bone in world: ", skel.to_global(gpose.origin))

	quit(0)
