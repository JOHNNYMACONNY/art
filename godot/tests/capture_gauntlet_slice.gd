extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const RUNS_DIR := "/Volumes/YBF_Storage/gauntlet_runs"

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
	var camera := scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	var bike := scene.get_node_or_null("CourierBike") as CharacterBody3D
	var hauler := scene.get_node_or_null("ScrapHauler") as CharacterBody3D
	var proof := scene.get_node_or_null("GearsStyleProof") as Node3D
	
	# Hide debug / mobile touch HUD for authentic environment render
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
		
	if bike:
		bike.velocity = Vector3.ZERO
		bike.global_position = Vector3(-9.2, 0.15, -38.5)
		bike.rotation.y = PI * 0.95
		
	if hauler:
		hauler.velocity = Vector3.ZERO
		hauler.global_position = Vector3(-5.2, 0.25, -29.5)
		hauler.rotation.y = PI
		
	if player and camera:
		player.velocity = Vector3.ZERO
		player.global_position = Vector3(-8.2, 0.20, -34.5)
		camera.call("reset_camera_instant", player)
		
	for _i in range(12):
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		push_error("Image is empty")
		quit(1)
		return

	var out_filename := "capture.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_filename = arg.trim_prefix("--out=")

	var out_path := RUNS_DIR + "/" + out_filename
	var err := img.save_png(out_path)
	print("Saved gauntlet capture to: ", out_path, " status: ", err, " size: ", img.get_width(), "x", img.get_height())
	quit(0 if err == OK else 1)
