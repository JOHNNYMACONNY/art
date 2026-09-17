extends SceneTree

func _init() -> void:
	var sf_scene = load("res://scenes/world/burnside_storefront.tscn")
	var sf = sf_scene.instantiate()
	root.add_child(sf)
	print("sf children count:", sf.get_child_count())
	for c in sf.get_children():
		print("child:", c.name, "type:", c.get_class())
		for gc in c.get_children():
			print("  grandchild:", gc.name, "type:", gc.get_class())
			if gc is MeshInstance3D:
				var m = gc as MeshInstance3D
				print("    mesh surface count:", m.mesh.get_surface_count() if m.mesh else 0)
				for s in range(m.mesh.get_surface_count() if m.mesh else 0):
					var mat = m.get_active_material(s)
					print("    surf ", s, " mat:", mat)
					if mat is ShaderMaterial:
						print("      shader:", mat.shader.resource_path)
						print("      albedo_tex:", mat.get_shader_parameter("albedo_texture"))
						print("      emission_energy:", mat.get_shader_parameter("emission_energy"))
					elif mat is StandardMaterial3D:
						print("      std albedo_tex:", mat.albedo_texture)
						print("      std emission_energy:", mat.emission_energy)
	quit(0)
