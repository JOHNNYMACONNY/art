@tool
extends SceneTree

func _init():
    print("=== Inspecting courier_bike.glb ===")
    var bike_packed = load("res://models/courier_bike.glb")
    if bike_packed:
        var bike_inst = bike_packed.instantiate()
        _print_tree(bike_inst, 0)
        bike_inst.free()
    else:
        print("Failed to load courier_bike.glb")

    print("\n=== Inspecting runner.glb ===")
    var runner_packed = load("res://models/runner.glb")
    if runner_packed:
        var runner_inst = runner_packed.instantiate()
        _print_tree(runner_inst, 0)
        runner_inst.free()
    else:
        print("Failed to load runner.glb")
    quit()

func _print_tree(node: Node, depth: int):
    var indent = ""
    for i in range(depth):
        indent += "  "
    var type_str = node.get_class()
    if node is MeshInstance3D and node.mesh:
        type_str += " (Mesh: %s, Mats: %d)" % [node.mesh.get_class(), node.mesh.get_surface_count()]
    print("%s- %s [%s]" % [indent, node.name, type_str])
    for child in node.get_children():
        _print_tree(child, depth + 1)
