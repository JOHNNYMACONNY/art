extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const RUNS_DIR := "/Volumes/YBF_Storage/gauntlet_runs"
const ARTIFACT_DIR := "/Users/bobbyinthelobby/.gemini/antigravity/brain/90f53442-5c7a-48ca-a505-133e7ada5fab"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var capture_target := "all"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_target = arg.trim_prefix("--capture=")

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load scene")
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	
	# Wait for ready and physics settle
	for _i in range(5):
		await process_frame
	await physics_frame
	for _i in range(3):
		await process_frame
		
	var player := scene.get_node_or_null("Runner") as CharacterBody3D
	var chinatown_cam := scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	var proof := scene.get_node_or_null("GearsStyleProof") as Node3D
	
	# Create dedicated inspection camera
	var inspect_cam := Camera3D.new()
	inspect_cam.name = "InspectCamera"
	scene.add_child(inspect_cam)

	# Hide debug / mobile touch HUD
	for node in scene.find_children("*", "CanvasLayer", true, false):
		if node is CanvasLayer:
			node.visible = false
	for node in scene.find_children("*", "Control", true, false):
		if node is Control:
			node.visible = false
			
	if proof:
		proof.call("set_lighting_mode", "dusk")

	var env_node := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.background_mode = Environment.BG_COLOR
		env_node.environment.background_color = Color(0.15, 0.16, 0.19, 1.0)
		env_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env_node.environment.ambient_light_color = Color(0.38, 0.40, 0.45, 1.0)
		env_node.environment.ambient_light_energy = 1.4
		env_node.environment.glow_enabled = true
		env_node.environment.glow_intensity = 0.6
		env_node.environment.glow_bloom = 0.20

	var configs := {
		"gameplay_mayor_burn_garage": {
			"type": "gameplay",
			"pos": Vector3(-10.5, 0.20, -41.0)
		},
		"inspect_mayor_burn_garage": {
			"type": "inspect",
			"cam_pos": Vector3(-9.2, 1.8, -41.0),
			"look_at": Vector3(-11.8, 1.8, -41.0),
			"fov": 65.0
		},
		"gameplay_silent_core_site": {
			"type": "gameplay",
			"pos": Vector3(5.2, 0.20, -27.4)
		},
		"inspect_silent_core_site": {
			"type": "inspect",
			"cam_pos": Vector3(6.2, 1.15, -24.8),
			"look_at": Vector3(6.2, 1.0, -27.28),
			"fov": 48.0
		},
		"gameplay_industrial_vent": {
			"type": "gameplay",
			"pos": Vector3(0.92, 0.20, -37.6)
		},
		"inspect_industrial_vent": {
			"type": "inspect",
			"cam_pos": Vector3(-1.8, 2.8, -39.0),
			"look_at": Vector3(0.92, 2.8, -39.0),
			"fov": 42.0
		},
		"gameplay_sidewalk_clutter": {
			"type": "gameplay",
			"pos": Vector3(-8.8, 0.20, -34.6)
		},
		"inspect_newspaper_bins": {
			"type": "inspect",
			"cam_pos": Vector3(-8.4, 1.3, -33.0),
			"look_at": Vector3(-9.55, 0.6, -34.6),
			"fov": 45.0
		},
		"inspect_window_display": {
			"type": "inspect",
			"cam_pos": Vector3(-10.0, 1.35, -34.2),
			"look_at": Vector3(-11.88, 1.25, -34.2),
			"fov": 55.0
		},
		"inspect_junction_box": {
			"type": "inspect",
			"cam_pos": Vector3(-7.8, 1.65, -35.5),
			"look_at": Vector3(-9.28, 1.6, -35.5),
			"fov": 32.0
		}
	}

	if not configs.has(capture_target):
		push_error("Unknown capture target: " + capture_target)
		quit(1)
		return

	var conf: Dictionary = configs[capture_target]
	var cap_type: String = conf["type"]

	if cap_type == "gameplay":
		inspect_cam.current = false
		chinatown_cam.make_current()
		if player:
			player.visible = true
			player.velocity = Vector3.ZERO
			player.global_position = conf["pos"]
			chinatown_cam.call("reset_camera_instant", player)
	else:
		chinatown_cam.current = false
		inspect_cam.make_current()
		inspect_cam.fov = float(conf.get("fov", 45.0))
		if player:
			player.visible = false
			player.velocity = Vector3.ZERO
			player.global_position = Vector3(0.0, 0.2, 0.0)
		var silent_core_node := scene.get_node_or_null("SilentCore")
		if silent_core_node and silent_core_node is Node3D:
			silent_core_node.visible = false
		inspect_cam.global_position = conf["cam_pos"]
		inspect_cam.look_at(conf["look_at"])

	for _i in range(15):
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		push_error("Image is empty for " + capture_target)
		quit(1)
		return

	var out_filename := capture_target + ".png"
	var out_runs: String = RUNS_DIR + "/" + out_filename
	var out_artifact: String = ARTIFACT_DIR + "/" + out_filename
	var err1 := img.save_png(out_runs)
	var err2 := img.save_png(out_artifact)
	print("Saved capture: ", out_filename, " status: ", err1, " / ", err2, " size: ", img.get_width(), "x", img.get_height())

	quit(0)
