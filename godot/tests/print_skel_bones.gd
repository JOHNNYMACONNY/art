extends SceneTree

func _init():
	var scene = load("res://scenes/player/runner.tscn") as PackedScene
	var r = scene.instantiate()
	root.add_child(r)
	var skel = r.find_child("Skeleton3D", true, false) as Skeleton3D
	for i in range(skel.get_bone_count()):
		var n = skel.get_bone_name(i)
		var p = skel.get_bone_parent(i)
		var pname = skel.get_bone_name(p) if p >= 0 else "ROOT"
		print(i, ": ", n, " -> parent: ", pname)
	quit(0)
