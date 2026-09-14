extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("\n=== 1. COURIER BIKE DIAGNOSTICS ===")
	var bike_scene := load("res://scenes/vehicles/courier_bike.tscn") as PackedScene
	var bike := bike_scene.instantiate() as CharacterBody3D
	root.add_child(bike)

	var socket := bike.find_child("RiderSocket", true, false) as Node3D
	if socket:
		print("RiderSocket local pos: ", socket.position, " rot: ", socket.rotation)

	var bars := bike.find_child("Handlebars", true, false) as MeshInstance3D
	if bars and bars.mesh:
		var aabb := bars.mesh.get_aabb()
		print("Handlebars AABB: ", aabb, " pos: ", bars.position)
		# Find handlebar grip extremes
		var arrays := bars.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var min_x := 999.0
		var max_x := -999.0
		var left_grip_verts := []
		var right_grip_verts := []
		for v in verts:
			min_x = minf(min_x, v.x)
			max_x = maxf(max_x, v.x)
		print("Handlebars X span: [", min_x, ", ", max_x, "]")
		# Collect left grip (negative x) and right grip (positive x) clusters
		var sum_l := Vector3.ZERO
		var count_l := 0
		var sum_r := Vector3.ZERO
		var count_r := 0
		for v in verts:
			if v.x < min_x + 0.12:
				sum_l += v
				count_l += 1
			elif v.x > max_x - 0.12:
				sum_r += v
				count_r += 1
		if count_l > 0:
			print("Estimated Left Grip Local Pos: ", sum_l / count_l)
		if count_r > 0:
			print("Estimated Right Grip Local Pos: ", sum_r / count_r)

	var saddle := bike.find_child("Saddle", true, false) as MeshInstance3D
	if saddle and saddle.mesh:
		print("Saddle AABB: ", saddle.mesh.get_aabb(), " pos: ", saddle.position)

	var frame := bike.find_child("MainChassis", true, false) as MeshInstance3D
	if frame and frame.mesh:
		print("Frame AABB: ", frame.mesh.get_aabb())

	print("\n=== 2. RUNNER SKELETON & ANIMATIONS ===")
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)

	var skel := runner.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel:
		print("Skeleton found with ", skel.get_bone_count(), " bones:")
		for i in range(skel.get_bone_count()):
			var bname := skel.get_bone_name(i)
			var parent_idx := skel.get_bone_parent(i)
			var parent_name := skel.get_bone_name(parent_idx) if parent_idx >= 0 else "ROOT"
			print("  [", i, "] ", bname, " (parent: ", parent_name, ") rest pos: ", skel.get_bone_rest(i).origin)

	var ap := runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		var anim_list := ap.get_animation_list()
		print("Animations in runner: ", anim_list)
		if ap.has_animation("bike_ride"):
			var anim := ap.get_animation("bike_ride")
			print("bike_ride length: ", anim.length, " track count: ", anim.get_track_count())
			for t in range(anim.get_track_count()):
				print("  track ", t, ": ", anim.track_get_path(t))

	quit(0)
