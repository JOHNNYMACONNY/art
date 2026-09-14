extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	runner.position = Vector3.ZERO
	runner.rotation = Vector3.ZERO

	# Light
	var env = WorldEnvironment.new()
	var env_res = Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.18, 0.20, 0.24)
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.environment = env_res
	root.add_child(env)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 45, 0)
	sun.light_energy = 1.5
	root.add_child(sun)

	var cam = Camera3D.new()
	root.add_child(cam)
	cam.current = true

	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	# Reset all bones to rest
	skel.reset_bone_poses()

	var b_hand = skel.find_bone("Hand.L")
	var p_hand = skel.to_global(skel.get_bone_global_pose(b_hand).origin)
	print("True rest Hand.L pos: ", p_hand)

	# 1. Back of hand (dorsal)
	cam.position = p_hand + Vector3(0.0, 0.0, 0.35)
	cam.look_at(p_hand, Vector3.UP)
	cam.fov = 30.0
	await process_frame
	await process_frame
	var img_dorsal = root.get_viewport().get_texture().get_image()
	img_dorsal.save_png("res://../docs/visual_direction/references/hand_mesh_rest_dorsal.png")

	# 2. Palm view
	cam.position = p_hand + Vector3(0.0, 0.0, -0.35)
	cam.look_at(p_hand, Vector3.UP)
	await process_frame
	await process_frame
	var img_palm = root.get_viewport().get_texture().get_image()
	img_palm.save_png("res://../docs/visual_direction/references/hand_mesh_rest_palm.png")

	# 3. 3/4 Perspective view
	cam.position = p_hand + Vector3(0.25, 0.15, 0.25)
	cam.look_at(p_hand, Vector3.UP)
	await process_frame
	await process_frame
	var img_iso = root.get_viewport().get_texture().get_image()
	img_iso.save_png("res://../docs/visual_direction/references/hand_mesh_rest_iso.png")

	print("Saved rest hand captures!")
	quit(0)
