extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var v_scene = load("res://scenes/vehicles/scrap_hauler.tscn") as PackedScene
	var vehicle = v_scene.instantiate()
	root.add_child(vehicle)
	vehicle.position = Vector3.ZERO
	await process_frame
	
	var meshes = []
	_find_meshes(vehicle, meshes)
	var max_y = -999.0
	for m in meshes:
		var aabb = m.get_aabb()
		var top_y = m.to_global(aabb.position + Vector3(0, aabb.size.y, 0)).y
		if top_y > max_y: max_y = top_y
	print("Scrap Hauler max Y: ", max_y)
	vehicle.queue_free()
	quit(0)

func _find_meshes(node: Node, out: Array):
	if node is MeshInstance3D: out.append(node)
	for c in node.get_children(): _find_meshes(c, out)
