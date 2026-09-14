extends SceneTree

func _init() -> void:
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn")
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	for mi in coupe.find_children("*", "MeshInstance3D", true, false):
		print("MI:", mi.name)
		for s in range(mi.mesh.get_surface_count() if mi.mesh else 0):
			var mat = mi.get_surface_override_material(s)
			print("  surface_override ", s, ":", mat)
			var active_mat = mi.get_active_material(s)
			print("  active_material ", s, ":", active_mat)
			if active_mat:
				if active_mat is StandardMaterial3D:
					print("    std albedo_texture:", active_mat.albedo_texture)
				elif active_mat is ShaderMaterial:
					print("    shader albedo_texture:", active_mat.get_shader_parameter("albedo_texture"))
	quit(0)
