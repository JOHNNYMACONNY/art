extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	
	var mesh_inst = coupe.find_child("MuscleCoupe_Mesh", true, false) as MeshInstance3D
	if mesh_inst:
		var m = mesh_inst.mesh
		print("Surfaces: ", m.get_surface_count())
		var mdt = MeshDataTool.new()
		mdt.create_from_surface(m, 6)
		print("Vertex count: ", mdt.get_vertex_count())
		for i in range(mini(20, mdt.get_vertex_count())):
			var v = mdt.get_vertex(i)
			print("  v[", i, "] = ", v)
	quit(0)
