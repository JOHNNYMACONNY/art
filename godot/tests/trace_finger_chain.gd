extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	
	var b_i2 = skel.find_bone("Index2.L")
	var b_i3 = skel.find_bone("Index3.L")
	
	var rest_i2 = skel.get_bone_rest(b_i2)
	var rest_i3 = skel.get_bone_rest(b_i3)
	
	print("Index2.L rest origin: ", rest_i2.origin)
	print("Index3.L rest origin: ", rest_i3.origin)
	
	# In rest pose of Index2.L, where does Index3.L sit?
	print("Vector from knuckle (Index2) to joint (Index3) in Index2 space: ", rest_i3.origin)
	
	# If we rotate around X, Y, Z:
	for axis in ["X", "Y", "Z"]:
		var rot = Vector3.ZERO
		if axis == "X": rot.x = deg_to_rad(45)
		elif axis == "Y": rot.y = deg_to_rad(45)
		elif axis == "Z": rot.z = deg_to_rad(45)
		
		var q = Quaternion.from_euler(rot)
		var v_rotated = q * rest_i3.origin
		print("Rotated +45 deg around " + axis + ": " + str(v_rotated))

	quit(0)
