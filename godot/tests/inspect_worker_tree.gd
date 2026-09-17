extends SceneTree
func _init():
	var s = load("res://scenes/entities/scrap_worker.tscn").instantiate()
	root.add_child(s)
	print("ScrapWorker hierarchy:")
	_print_tree(s, "  ")
	quit()

func _print_tree(n: Node, indent: String):
	var mi = n as MeshInstance3D
	if mi:
		print(indent, "MeshInstance3D: ", n.name, " mesh: ", mi.mesh, " visible: ", mi.visible)
	else:
		print(indent, n.name, " (", n.get_class(), ") visible: ", n.visible if "visible" in n else true)
	for c in n.get_children():
		_print_tree(c, indent + "  ")
