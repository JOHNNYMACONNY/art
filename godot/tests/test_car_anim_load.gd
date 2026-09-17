extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var r = load("res://scenes/player/runner.tscn").instantiate()
	root.add_child(r)
	for ch in r.find_child("MeshPivot").get_children():
		print("MeshPivot child: ", ch.name, " class=", ch.get_class(), " children=", ch.get_child_count())
	quit(0)
