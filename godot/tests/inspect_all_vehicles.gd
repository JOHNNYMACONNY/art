extends SceneTree

func _init():
	for name in ["muscle_coupe", "scrap_hauler", "security_interceptor"]:
		print("--- VEHICLE: ", name, " ---")
		var glb = load("res://models/" + name + ".glb")
		var inst = glb.instantiate()
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			print(" Mesh: ", mi.name, " (surfaces: ", mi.mesh.get_surface_count(), ")")
			for s in range(mi.mesh.get_surface_count()):
				var mat = mi.get_active_material(s)
				var tex = mat.albedo_texture if (mat is StandardMaterial3D) else null
				print("   [", s, "] ", mat.resource_name, " | tex: ", (tex.resource_path if tex else "none"))
	quit(0)
