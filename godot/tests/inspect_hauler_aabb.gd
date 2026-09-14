extends SceneTree
func _init():
	var res = load("res://scenes/vehicles/scrap_hauler.tscn")
	var node = res.instantiate()
	var mesh_inst = node.find_child("*Mesh*", true, false)
	if mesh_inst and mesh_inst.mesh:
		var aabb = mesh_inst.mesh.get_aabb()
		print("In scene: Mesh AABB: size=", aabb.size, " pos=", aabb.position)
		print("In scene: MeshInstance3D scale=", mesh_inst.scale)
	quit(0)
