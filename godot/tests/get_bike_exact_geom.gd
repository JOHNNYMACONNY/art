extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var bike_scene := load("res://models/courier_bike.glb") as PackedScene
	var bike := bike_scene.instantiate() as Node3D
	root.add_child(bike)

	var bars := bike.find_child("Handlebars", true, false) as MeshInstance3D
	var seat := bike.find_child("Seat", true, false) as MeshInstance3D

	print("=== BIKE EXACT MESH VERTICES ===")
	if bars:
		print("Bars node global transform: ", bars.global_transform)
		var arr := bars.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var min_v := Vector3(999, 999, 999)
		var max_v := Vector3(-999, -999, -999)
		for v in verts:
			var gv := bars.to_global(v)
			min_v = min_v.min(gv)
			max_v = max_v.max(gv)
		print("Bars global AABB: min=", min_v, " max=", max_v)
		# Find the grip tubes (outer 15cm on each side)
		var l_pts := []
		var r_pts := []
		for v in verts:
			var gv := bars.to_global(v)
			if gv.x < -0.30:
				l_pts.append(gv)
			elif gv.x > 0.30:
				r_pts.append(gv)
		var l_center := Vector3.ZERO
		for p in l_pts: l_center += p
		l_center /= max(len(l_pts), 1)

		var r_center := Vector3.ZERO
		for p in r_pts: r_center += p
		r_center /= max(len(r_pts), 1)

		print("Bars Left Grip Center: ", l_center)
		print("Bars Right Grip Center: ", r_center)

	if seat:
		print("Seat node global transform: ", seat.global_transform)
		var arr := seat.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var min_v := Vector3(999, 999, 999)
		var max_v := Vector3(-999, -999, -999)
		for v in verts:
			var gv := seat.to_global(v)
			min_v = min_v.min(gv)
			max_v = max_v.max(gv)
		print("Seat global AABB: min=", min_v, " max=", max_v)

	quit(0)
