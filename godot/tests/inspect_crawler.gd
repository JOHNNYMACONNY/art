extends SceneTree
func _init():
	var s = load("res://scenes/entities/utility_crawler.tscn").instantiate()
	root.add_child(s)
	_run(s)

func _run(s):
	for _i in range(3):
		await process_frame
	var crawler_mesh := s.find_child("UtilityCrawler_Mesh", true, false) as MeshInstance3D
	var m0 = crawler_mesh.get_surface_override_material(0) as ShaderMaterial
	var m1 = crawler_mesh.get_surface_override_material(1) as ShaderMaterial
	print("Mat 0 emission_energy:", m0.get_shader_parameter("emission_energy"), "color:", m0.get_shader_parameter("emission_color"))
	print("Mat 1 emission_energy:", m1.get_shader_parameter("emission_energy"), "color:", m1.get_shader_parameter("emission_color"))
	print("Mat 0 texture:", m0.get_shader_parameter("albedo_texture"))
	print("Mat 1 texture:", m1.get_shader_parameter("albedo_texture"))
	quit()
