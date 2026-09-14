extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate() as CharacterBody3D
	root.add_child(runner)
	runner.position = Vector3(0.0, 0.58, 0.15)

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	print("skel global transform: ", skel.global_transform)

	var b_hips := skel.find_bone("Hips")
	var hips_rest := skel.get_bone_rest(b_hips)
	print("Hips rest origin: ", hips_rest.origin)
	var hips_world := skel.to_global(skel.get_bone_global_pose(b_hips).origin)
	print("Hips rest in world: ", hips_world)

	quit(0)
