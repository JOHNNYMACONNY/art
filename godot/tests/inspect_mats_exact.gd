extends SceneTree

func _init() -> void:
	var sf_scene = load("res://scenes/world/burnside_storefront.tscn")
	var sf = sf_scene.instantiate()
	root.add_child(sf)
	for mi in sf.find_children("*", "MeshInstance3D", true, false):
		print("MI:", mi.name)
		for s in range(mi.mesh.get_surface_count() if mi.mesh else 0):
			var mat = mi.get_surface_override_material(s)
			if not mat:
				mat = mi.mesh.surface_get_material(s)
			print("  surface ", s, ":", mat)
			if mat is ShaderMaterial:
				print("    base_color:", mat.get_shader_parameter("base_color"))
				print("    emission_energy:", mat.get_shader_parameter("emission_energy"))
				print("    albedo_texture:", mat.get_shader_parameter("albedo_texture"))
			elif mat is StandardMaterial3D:
				print("    std albedo_color:", mat.albedo_color)
				print("    std emission_enabled:", mat.emission_enabled)
				print("    std albedo_texture:", mat.albedo_texture)
	quit(0)
