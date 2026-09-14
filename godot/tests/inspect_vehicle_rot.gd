extends SceneTree

func _init() -> void:
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn")
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	print("Coupe root rotation:", coupe.rotation_degrees)
	var mi = coupe.find_child("MuscleCoupe_Mesh", true, false)
	if mi:
		print("Coupe Mesh global transform:", mi.global_transform)
		var aabb = mi.get_aabb()
		print("Coupe AABB size:", aabb.size, "position:", aabb.position)
	quit(0)
