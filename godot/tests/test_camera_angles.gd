extends SceneTree

const OUT_DIR := "res://../docs/visual_direction/references"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.16, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.70, 0.72, 0.76, 1.0)
	env.ambient_light_energy = 1.2
	env_node.environment = env
	root_node.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 38.0, 0.0)
	sun.light_energy = 1.35
	root_node.add_child(sun)

	# Dedicated cabin spotlight for hands
	var cabin_light := OmniLight3D.new()
	cabin_light.position = Vector3(0.36, 1.25, 0.35)
	cabin_light.light_color = Color(1.0, 0.95, 0.88, 1.0)
	cabin_light.light_energy = 2.5
	cabin_light.omni_range = 2.5
	root_node.add_child(cabin_light)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 32.0
	root_node.add_child(cam)

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var coupe_scene := load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root_node.add_child(coupe)
	coupe.position = Vector3.ZERO
	coupe.rotation_degrees = Vector3(0.0, 180.0, 0.0)

	var coupe_seat = coupe.find_child("Seat_Driver", true, false)
	var runner_c = runner_scene.instantiate()
	coupe.add_child(runner_c)
	runner_c.set_vehicle_driving_posture(true, "car")
	runner_c.position = coupe_seat.position + Vector3(0.0, -0.78, 0.18)
	runner_c.rotation = Vector3.ZERO

	var ap = runner_c.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.play("car_drive")
	ap.advance(0.1)

	# Angle 1: Driver Cockpit Over-the-shoulder POV looking down at wheel
	cam.position = Vector3(0.18, 1.18, -0.15)
	cam.look_at(Vector3(0.36, 0.80, 0.35), Vector3.UP)
	for _i in range(12): await process_frame
	var img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/macro_test_pov.png")
	print("Saved macro_test_pov.png")

	# Angle 2: Steep Windshield Inward Down-Angle (clear over hood)
	cam.position = Vector3(0.36, 1.35, 0.85)
	cam.look_at(Vector3(0.36, 0.80, 0.35), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/macro_test_steep_windshield.png")
	print("Saved macro_test_steep_windshield.png")

	# Angle 3: Passenger Console Quarter Angle looking across at wheel & hands
	cam.position = Vector3(-0.15, 1.05, 0.28)
	cam.look_at(Vector3(0.36, 0.80, 0.35), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/macro_test_passenger.png")
	print("Saved macro_test_passenger.png")

	# Angle 4: Close Front Windshield at high angle
	cam.position = Vector3(0.48, 1.28, 0.95)
	cam.look_at(Vector3(0.36, 0.80, 0.35), Vector3.UP)
	for _i in range(12): await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/macro_test_front_high.png")
	print("Saved macro_test_front_high.png")

	quit(0)
