extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const RUNS_DIR := "/Volumes/YBF_Storage/gauntlet_runs"
const ARTIFACT_DIR := "/Users/bobbyinthelobby/.gemini/antigravity/brain/90f53442-5c7a-48ca-a505-133e7ada5fab"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
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
	
	# Create dedicated inspection camera for direct landmark asset verification
	var inspect_cam := Camera3D.new()
	inspect_cam.name = "InspectCamera"
	inspect_cam.fov = 45.0
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

	var captures: Array[Dictionary] = [
		{
			"name": "gameplay_mayor_burn_garage.png",
			"type": "gameplay",
			"pos": Vector3(-10.5, 0.20, -41.0)
		},
		{
			"name": "inspect_mayor_burn_garage.png",
			"type": "inspect",
			"cam_pos": Vector3(-7.5, 1.6, -41.0),
			"look_at": Vector3(-11.8, 1.6, -41.0)
		},
		{
			"name": "gameplay_silent_core_site.png",
			"type": "gameplay",
			"pos": Vector3(5.2, 0.20, -27.4)
		},
		{
			"name": "inspect_silent_core_site.png",
			"type": "inspect",
			"cam_pos": Vector3(3.2, 1.4, -27.4),
			"look_at": Vector3(6.2, 1.1, -27.4)
		},
		{
			"name": "gameplay_industrial_vent.png",
			"type": "gameplay",
			"pos": Vector3(0.92, 0.20, -37.6)
		},
		{
			"name": "inspect_industrial_vent.png",
			"type": "inspect",
			"cam_pos": Vector3(-2.8, 2.5, -39.0),
			"look_at": Vector3(0.92, 2.5, -39.0)
		}
	]

	for cap: Dictionary in captures:
		var file_name: String = cap["name"]
		var cap_type: String = cap["type"]

		if cap_type == "gameplay":
			inspect_cam.current = false
			chinatown_cam.current = true
			if player:
				player.velocity = Vector3.ZERO
				player.global_position = cap["pos"]
				chinatown_cam.call("reset_camera_instant", player)
		else:
			chinatown_cam.current = false
			inspect_cam.current = true
			inspect_cam.global_position = cap["cam_pos"]
			inspect_cam.look_at(cap["look_at"])

		for _i in range(12):
			await process_frame

		var img := root.get_viewport().get_texture().get_image()
		if img == null or img.is_empty():
			push_error("Image is empty for " + file_name)
			continue

		var out_runs: String = RUNS_DIR + "/" + file_name
		var out_artifact: String = ARTIFACT_DIR + "/" + file_name
		var err1 := img.save_png(out_runs)
		var err2 := img.save_png(out_artifact)
		print("Saved capture: ", file_name, " status: ", err1, " / ", err2, " size: ", img.get_width(), "x", img.get_height())

	quit(0)
