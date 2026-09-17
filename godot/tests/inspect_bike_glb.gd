extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Inspecting courier_bike.glb ---")
	var glb_scene := load("res://models/courier_bike.glb") as PackedScene
	if glb_scene:
		var bike_glb := glb_scene.instantiate()
		root.add_child(bike_glb)
		_print_children(bike_glb, 0)
	else:
		print("Could not load courier_bike.glb")
	quit(0)

func _print_children(node: Node, depth: int):
	var prefix := ""
	for i in range(depth): prefix += "  "
	var t_str := ""
	if node is Node3D:
		t_str = " pos=" + str(node.position) + " rot=" + str(node.rotation)
		if node is MeshInstance3D and node.mesh:
			t_str += " aabb=" + str(node.mesh.get_aabb())
	print(prefix, node.name, " (", node.get_class(), ")", t_str)
	for child in node.get_children():
		_print_children(child, depth + 1)
