extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)
	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D

	print("=== SKELETON BONE REST TRANSFORMS ===")
	for i in range(skel.get_bone_count()):
		var bname := skel.get_bone_name(i)
		var rest := skel.get_bone_rest(i)
		var parent_idx := skel.get_bone_parent(i)
		var parent_name := skel.get_bone_name(parent_idx) if parent_idx >= 0 else "ROOT"
		print(i, ": ", bname, " <- ", parent_name, " origin=", rest.origin, " rot_quat=", rest.basis.get_rotation_quaternion(), " rot_euler=", rest.basis.get_euler() * 180.0 / PI)

	quit(0)
