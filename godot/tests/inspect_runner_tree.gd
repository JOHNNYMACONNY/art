extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner := runner_scene.instantiate()
	root.add_child(runner)
	_print_tree(runner, 0)
	quit(0)

func _print_tree(node: Node, depth: int):
	var p := ""
	for i in range(depth): p += "  "
	var extra := ""
	if node is MeshInstance3D:
		extra = " [MeshInstance3D: " + str(node.mesh.resource_path if node.mesh else "no mesh") + " visible=" + str(node.visible) + "]"
	print(p, node.name, " (", node.get_class(), ")", extra)
	for c in node.get_children():
		_print_tree(c, depth + 1)
