extends SceneTree

# Verification Test Harness for Headless Scene Rendering & Screenshot Capture

func _init() -> void:
	var scene_resource := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	var root_instance := scene_resource.instantiate()
	root.add_child(root_instance)
	
	# Wait for 30 frames render loop
	for i in range(30):
		await root.get_tree().process_frame
		
	var viewport := root.get_viewport()
	if viewport:
		var img := viewport.get_texture().get_image()
		if img:
			img.save_png("res://golden_slice_v0.png")
			print("[VERIFICATION] Successfully exported screenshot res://golden_slice_v0.png")
			
	quit(0)
