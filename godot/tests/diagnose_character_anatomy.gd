extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	root.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	runner.position = Vector3.ZERO
	runner.rotation = Vector3.ZERO

	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.play("car_drive")
	ap.advance(0.1)

	# Studio lighting
	var env = WorldEnvironment.new()
	var sky = Sky.new()
	var env_res = Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.2, 0.22, 0.25)
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment = env_res
	root.add_child(env)

	var key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, 45, 0)
	key_light.light_energy = 1.5
	root.add_child(key_light)

	var cam = Camera3D.new()
	root.add_child(cam)
	cam.current = true

	await process_frame
	await process_frame

	# 1. Front view of full body
	cam.position = Vector3(0.0, 1.0, -1.8)
	cam.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)
	cam.fov = 45.0
	await process_frame
	await process_frame
	var img_front = root.get_viewport().get_texture().get_image()
	img_front.save_png("/Users/bobbyinthelobby/{art/docs/visual_direction/references/diag_char_front.png")
	img_front.save_png("/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/diag_char_front.png")

	# 2. Side 3/4 view showing arm attachment to shoulder
	cam.position = Vector3(1.4, 1.2, -1.2)
	cam.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)
	cam.fov = 45.0
	await process_frame
	await process_frame
	var img_side = root.get_viewport().get_texture().get_image()
	img_side.save_png("/Users/bobbyinthelobby/{art/docs/visual_direction/references/diag_char_side.png")
	img_side.save_png("/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/diag_char_side.png")

	# 3. Top-down view showing shoulder-to-hand alignment
	cam.position = Vector3(0.0, 2.2, -0.6)
	cam.look_at(Vector3(0.0, 0.7, -0.3), Vector3.UP)
	cam.fov = 45.0
	await process_frame
	await process_frame
	var img_top = root.get_viewport().get_texture().get_image()
	img_top.save_png("/Users/bobbyinthelobby/{art/docs/visual_direction/references/diag_char_top.png")
	img_top.save_png("/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/diag_char_top.png")

	print("Saved full body anatomy diagnostics!")
	quit(0)
