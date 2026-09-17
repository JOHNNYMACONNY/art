extends SceneTree

func _init():
	call_deferred("_run")

func _run():
	var coupe_scene = load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root.add_child(coupe)
	coupe.position = Vector3.ZERO
	coupe.rotation = Vector3.ZERO
	coupe.set_physics_process(false)

	var seat = coupe.find_child("Seat_Driver", true, false)
	var wheel = coupe.find_child("SteeringWheel_Mount", true, false)

	var runner_scene = load("res://scenes/player/runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	coupe.add_child(runner)
	runner.set_vehicle_driving_posture(true, "car")
	runner.position = seat.position + Vector3(0.0, -0.78, 0.18)
	runner.rotation = Vector3.ZERO

	var ap = runner.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.play("car_drive")
	ap.advance(0.1)

	# Setup lighting
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 2.2
	root.add_child(light)

	var fill_light = OmniLight3D.new()
	fill_light.position = Vector3(-0.36, 1.1, -0.25)
	fill_light.light_energy = 2.0
	fill_light.omni_range = 3.0
	root.add_child(fill_light)

	var cam = Camera3D.new()
	root.add_child(cam)
	cam.current = true

	await process_frame
	await process_frame

	# 1. Cockpit Passenger 3/4 View (Looking down at steering wheel & both hands)
	cam.position = Vector3(-0.02, 1.02, -0.12)
	cam.look_at(Vector3(-0.36, 0.84, -0.36), Vector3.UP)
	cam.fov = 52.0
	await process_frame
	await process_frame
	var img_cockpit = root.get_viewport().get_texture().get_image()
	img_cockpit.save_png("/Users/bobbyinthelobby/{art/docs/visual_direction/references/proof_grip_cockpit_angle.png")
	img_cockpit.save_png("/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/proof_grip_cockpit_angle.png")

	# 2. Driver POV (Looking over steering column down at rim and hands)
	cam.position = Vector3(-0.36, 1.05, -0.14)
	cam.look_at(Vector3(-0.36, 0.82, -0.38), Vector3.UP)
	cam.fov = 60.0
	await process_frame
	await process_frame
	var img_pov = root.get_viewport().get_texture().get_image()
	img_pov.save_png("/Users/bobbyinthelobby/{art/docs/visual_direction/references/proof_grip_pov.png")
	img_pov.save_png("/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/proof_grip_pov.png")

	# 3. Windshield Front View (Looking through glass at hands on wheel rim)
	cam.position = Vector3(-0.25, 0.95, -0.72)
	cam.look_at(Vector3(-0.36, 0.84, -0.32), Vector3.UP)
	cam.fov = 48.0
	await process_frame
	await process_frame
	var img_windshield = root.get_viewport().get_texture().get_image()
	img_windshield.save_png("/Users/bobbyinthelobby/{art/docs/visual_direction/references/proof_grip_windshield.png")
	img_windshield.save_png("/Users/bobbyinthelobby/.gemini/antigravity/brain/9e9e065f-c163-4cfc-9c03-fd8f38857a04/proof_grip_windshield.png")

	print("Saved updated POV, Cockpit Angle, and Windshield proofs!")
	quit(0)
