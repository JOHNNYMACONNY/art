extends SceneTree
func _init():
	var res = load("res://models/scrap_hauler.glb")
	var node = res.instantiate()
	var mesh_inst: MeshInstance3D = node.find_child("*Mesh*", true, false)
	if mesh_inst and mesh_inst.mesh:
		var m = mesh_inst.mesh
		print("Surfaces: ", m.get_surface_count())
		for s in range(m.get_surface_count()):
			var mat = m.surface_get_material(s)
			var mat_name = mat.resource_name if mat else "null"
			var arrays = m.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var min_z = 999.0
			var max_z = -999.0
			for v in verts:
				if v.z < min_z: min_z = v.z
				if v.z > max_z: max_z = v.z
			print("  Surface %d (%s): z_min=%.2f, z_max=%.2f" % [s, mat_name, min_z, max_z])
	quit(0)
