extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var c = load("res://scenes/vehicles/muscle_coupe.tscn").instantiate()
	root.add_child(c)
	for m in c.find_children("*", "MeshInstance3D", true, false):
		print(m.name, " mesh=", m.mesh)
	quit(0)
