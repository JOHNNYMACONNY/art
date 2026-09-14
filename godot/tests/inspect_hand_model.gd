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
	env_res.background_color = Color(0.2, 0.22, 0.25)
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment = env_res
	root.add_child(env)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.5
	root.add_child(sun)

	var cam = Camera3D.new()
	root.add_child(cam)
	cam.current = true

	var skel = runner.find_child("Skeleton3D", true, false) as Skeleton3D
	var b_hand = skel.find_bone("Hand.L")

	await process_frame
	await process_frame

	# 1. Rest pose hand close-up
	var hand_pos = skel.to_global(skel.get_bone_global_pose(b_hand).origin)
	print("Rest Hand pos: ", hand_pos)

	cam.position = hand_pos + Vector3(0.0, 0.05, 0.35)
	cam.look_at(hand_pos, Vector3.UP)
	cam.fov = 35.0
	await process_frame
	await process_frame
	var img_rest = root.get_viewport().get_texture().get_image()
	img_rest.save_png("res://../docs/visual_direction/references/inspect_hand_rest.png")

	# 2. Side / edge view of rest hand
	cam.position = hand_pos + Vector3(0.35, 0.0, 0.0)
	cam.look_at(hand_pos, Vector3.UP)
	await process_frame
	await process_frame
	var img_side = root.get_viewport().get_texture().get_image()
	img_side.save_png("res://../docs/visual_direction/references/inspect_hand_side.png")

	# 3. Driving pose hand close-up (with car_drive animation)
	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	runner.set_vehicle_driving_posture(true, "car")
	ap.play("car_drive")
	ap.advance(0.1)
	await process_frame
	await process_frame

	var hand_drive_pos = skel.to_global(skel.get_bone_global_pose(b_hand).origin)
	print("Drive Hand pos: ", hand_drive_pos)

	# Looking directly at the curled fist from the front
	cam.position = hand_drive_pos + Vector3(0.0, 0.08, -0.32)
	cam.look_at(hand_drive_pos, Vector3.UP)
	cam.fov = 35.0
	await process_frame
	await process_frame
	var img_drive_front = root.get_viewport().get_texture().get_image()
	img_drive_front.save_png("res://../docs/visual_direction/references/inspect_hand_drive_front.png")

	# Looking from the thumb side
	cam.position = hand_drive_pos + Vector3(0.28, 0.05, 0.0)
	cam.look_at(hand_drive_pos, Vector3.UP)
	await process_frame
	await process_frame
	var img_drive_thumb = root.get_viewport().get_texture().get_image()
	img_drive_thumb.save_png("res://../docs/visual_direction/references/inspect_hand_drive_thumb.png")

	print("Saved all hand model inspection views!")
	quit(0)
