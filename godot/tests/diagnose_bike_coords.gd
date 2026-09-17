extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var bike_scene := load("res://scenes/vehicles/courier_bike.tscn") as PackedScene
	var bike := bike_scene.instantiate() as CharacterBody3D
	root.add_child(bike)
	bike.global_position = Vector3(0, 0, 0)

	var socket := bike.find_child("RiderSocket", true, false) as Node3D
	print("Bike RiderSocket global_pos: ", socket.global_position)

	var saddle := bike.find_child("Saddle", true, false) as MeshInstance3D
	if saddle:
		print("Saddle global_transform: ", saddle.global_transform)
		var arrays := saddle.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var min_v := Vector3(999, 999, 999)
		var max_v := Vector3(-999, -999, -999)
		for v in verts:
			var gv := saddle.to_global(v)
			min_v = min_v.min(gv)
			max_v = max_v.max(gv)
		print("Saddle global bounds: min=", min_v, " max=", max_v, " center=", (min_v + max_v) * 0.5)

	var bars := bike.find_child("Handlebars", true, false) as MeshInstance3D
	if bars:
		print("Handlebars global_transform: ", bars.global_transform)
		var arrays := bars.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var min_v := Vector3(999, 999, 999)
		var max_v := Vector3(-999, -999, -999)
		var left_grip := Vector3.ZERO
		var right_grip := Vector3.ZERO
		var c_l := 0
		var c_r := 0
		for v in verts:
			var gv := bars.to_global(v)
			min_v = min_v.min(gv)
			max_v = max_v.max(gv)
			if v.x < -0.35:
				left_grip += gv
				c_l += 1
			elif v.x > 0.35:
				right_grip += gv
				c_r += 1
		print("Handlebars global bounds: min=", min_v, " max=", max_v)
		print("Handlebars Left Grip global: ", left_grip / c_l)
		print("Handlebars Right Grip global: ", right_grip / c_r)

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)
	runner.global_position = socket.global_position

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.play("bike_ride")
	# Force animation update
	ap.advance(0.0)

	print("\nRunner mounted with default 'bike_ride' animation:")
	for bname in ["Hips", "Chest", "Head", "Hand.L", "Hand.R", "Foot.L", "Foot.R"]:
		var b_idx := skel.find_bone(bname)
		if b_idx >= 0:
			var gpose := skel.global_transform * skel.get_bone_global_pose(b_idx)
			print("  ", bname, " global pos: ", gpose.origin)

	quit(0)
