extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root_node.add_child(runner)
	runner.position = Vector3(0.0, 0.58, 0.15)

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var b_hips := skel.find_bone("Hips")

	# Load anim_bike_ride.res that was just saved!
	var anim_res := load("res://scenes/player/anim_bike_ride.res") as Animation
	print("Track 0 in saved res: path=", anim_res.track_get_path(0), " val[0]=", anim_res.track_get_key_value(0, 0))

	var lib := ap.get_animation_library("")
	if lib.has_animation("bike_ride"):
		lib.remove_animation("bike_ride")
	lib.add_animation("bike_ride", anim_res)

	ap.play("bike_ride")
	ap.advance(0.1)

	print("Hips pose pos: ", skel.get_bone_pose_position(b_hips))
	print("Hips world pos: ", skel.to_global(skel.get_bone_global_pose(b_hips).origin))

	for i in range(5):
		await process_frame

	print("After 5 frames Hips pose pos: ", skel.get_bone_pose_position(b_hips))
	print("After 5 frames Hips world pos: ", skel.to_global(skel.get_bone_global_pose(b_hips).origin))

	quit(0)
