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
	var b_hips := skel.find_bone("Hips")

	print("Before play: Hips pose origin: ", skel.get_bone_pose_position(b_hips))

	var anim := ap.get_animation("bike_ride").duplicate() as Animation
	print("Track 0 path: ", anim.track_get_path(0))
	for k in range(anim.track_get_key_count(0)):
		anim.track_set_key_value(0, k, Vector3(0.0, 0.445, -0.07))

	var lib := ap.get_animation_library("")
	lib.remove_animation("bike_ride")
	lib.add_animation("bike_ride", anim)

	ap.play("bike_ride")
	ap.advance(0.1)

	print("After play+advance: Hips pose origin: ", skel.get_bone_pose_position(b_hips))
	print("After play+advance: Hips world: ", skel.to_global(skel.get_bone_global_pose(b_hips).origin))

	quit(0)
