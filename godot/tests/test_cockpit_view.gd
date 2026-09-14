extends SceneTree

const OUT_PATH := "res://../docs/visual_direction/references/test_cockpit_view.png"

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

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, -145.0, 0.0)
	fill.light_color = Color(0.60, 0.70, 0.85, 1.0)
	fill.light_energy = 0.65
	root_node.add_child(fill)

	# Direct light aiming through windshield and side window into cockpit
	var cabin_light := DirectionalLight3D.new()
	cabin_light.rotation_degrees = Vector3(-35.0, 160.0, 0.0)
	cabin_light.light_color = Color(1.0, 0.98, 0.92, 1.0)
	cabin_light.light_energy = 1.65
	root_node.add_child(cabin_light)

	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(40.0, 0.2, 40.0)
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, -0.1, 0.0)
	root_node.add_child(ground)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 40.0
	root_node.add_child(cam)

	var coupe_scene := load("res://scenes/vehicles/muscle_coupe.tscn") as PackedScene
	var coupe = coupe_scene.instantiate()
	root_node.add_child(coupe)
	coupe.set_physics_process(false)
	coupe.set_process(false)
	coupe.position = Vector3.ZERO
	coupe.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	var c_col = coupe.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if c_col: c_col.disabled = true

	var runner_scene := load("res://scenes/player/runner.tscn") as PackedScene
	var runner_c = runner_scene.instantiate()
	coupe.add_child(runner_c)
	runner_c.set_physics_process(false)
	runner_c.set_process(false)
	var rc_col = runner_c.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if rc_col: rc_col.disabled = true

	var coupe_seat = coupe.find_child("Seat_Driver", true, false)
	runner_c.set_vehicle_driving_posture(true, "car")
	runner_c.position = coupe_seat.position + Vector3(0.0, -0.78, 0.18)
	runner_c.rotation = Vector3.ZERO

	var ap = runner_c.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.play("car_drive")
	ap.advance(0.1)

	# Position camera inside cockpit at center console looking across at wheel and hands
	cam.fov = 65.0
	cam.position = Vector3(0.36, 1.18, 0.05)
	cam.look_at(Vector3(0.36, 0.80, 0.42), Vector3.UP)

	for _i in range(12): await process_frame
	var img = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_PATH)
	print("Saved test_cockpit_view.png")

	quit(0)
