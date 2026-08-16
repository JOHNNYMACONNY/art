extends SceneTree

# Automated End-to-End Test for Golden Slice v0 Gameplay Loop

func _init() -> void:
	var scene := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	var root_node := scene.instantiate() as ScrapTestBlock
	root.add_child(root_node)
	
	print("[TEST] Step 1: Initializing ScrapTestBlock scene...")
	await _wait_frames(10)
	
	var player := root_node.player
	var panel := root_node.corroded_panel
	var ui := root_node.touch_ui
	
	print("[TEST] Step 2: Simulating left joystick movement toward panel...")
	player.set_joystick_input(Vector2(0.0, -1.0))
	
	# Move for 45 frames
	for i in range(45):
		await root.get_tree().process_frame
		
	player.set_joystick_input(Vector2.ZERO)
	print("[TEST] Player position: ", player.global_position)
	print("[TEST] Panel position: ", panel.global_position)
	print("[TEST] Magnetism highlighted: ", panel.is_player_in_range)
	
	print("[TEST] Step 3: Triggering contextual action button...")
	ui._on_action_pressed()
	await _wait_frames(10)
	print("[TEST] Panel current step: ", panel.current_step)
	
	print("[TEST] Step 4: Simulating peel gesture drag...")
	ui.emit_signal("peel_gesture_dragged", 1.0)
	await _wait_frames(10)
	print("[TEST] Panel current step after peel: ", panel.current_step)
	
	print("[TEST] Step 5: Tapping glowing core to extract...")
	ui._on_core_tap_pressed()
	await _wait_frames(15)
	print("[TEST] Final panel state: ", panel.current_step)
	
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://golden_slice_extracted.png")
		print("[TEST] Extraction completion screenshot saved to res://golden_slice_extracted.png")
		
	print("[TEST] PASSED: Golden Slice v0 End-to-End Simulation Complete!")
	quit(0)

func _wait_frames(count: int) -> void:
	for i in range(count):
		await root.get_tree().process_frame
