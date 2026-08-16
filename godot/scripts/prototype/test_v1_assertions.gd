extends SceneTree

# Strict V1 Automated Assertions Test Suite for Echos in the Scrap

func _init() -> void:
	print("[V1_TEST] Loading res://scenes/prototype/scrap_test_block.tscn...")
	var scene := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	var root_node := scene.instantiate() as ScrapTestBlock
	root.add_child(root_node)
	
	await _wait_frames(5)
	
	var player := root_node.player
	var panel := root_node.corroded_panel
	var ui := root_node.touch_ui
	var camera := root_node.camera
	
	print("[V1_TEST] 1. Asserting initial state outside range...")
	assert(not panel.is_player_in_range, "FAIL: Player should start outside interaction range")
	assert(panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel should start IDLE")
	
	print("[V1_TEST] 2. Asserting out-of-range action rejection...")
	var triggered_out_of_range := panel.trigger_action()
	assert(not triggered_out_of_range, "FAIL: Out-of-range action must be rejected")
	assert(panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel must remain IDLE on invalid action")
	
	print("[V1_TEST] 3. Moving player into interaction range...")
	player.global_position = panel.global_position + Vector3(0, 0, 1.8)
	await _wait_frames(10)
	
	assert(panel.is_player_in_range, "FAIL: Player must be in range after move")
	assert(panel.current_step == CorrodedPanel.Step.APPROACHED, "FAIL: Panel must enter APPROACHED state")
	
	print("[V1_TEST] 4. Triggering action inside range...")
	ui._on_action_pressed()
	await _wait_frames(5)
	
	assert(panel.current_step == CorrodedPanel.Step.PEELING, "FAIL: Panel must enter PEELING state")
	assert(player.is_input_locked, "FAIL: Player locomotion must lock during extraction")
	assert(camera.current_mode == ChinatownCamera3D.CameraMode.INTERACTION, "FAIL: Camera must enter INTERACTION mode")
	
	print("[V1_TEST] 5. Progressing peel gesture...")
	ui._on_peel_gesture_dragged(1.0)
	await _wait_frames(5)
	assert(panel.current_step == CorrodedPanel.Step.EXPOSED, "FAIL: Panel must enter EXPOSED state after peel")
	
	print("[V1_TEST] 6. Tapping glowing core to extract...")
	ui._on_core_tap_pressed()
	await _wait_frames(10)
	
	assert(panel.current_step == CorrodedPanel.Step.EXTRACTED, "FAIL: Panel must enter EXTRACTED state")
	assert(not player.is_input_locked, "FAIL: Player input must unlock on extraction complete")
	assert(camera.current_mode == ChinatownCamera3D.CameraMode.TRAVERSAL, "FAIL: Camera must return to TRAVERSAL mode")
	
	print("[V1_TEST] 7. Asserting no duplicate extraction...")
	var retriggered := panel.trigger_action()
	assert(not retriggered, "FAIL: Completed panel cannot be re-triggered")
	
	print("[V1_TEST] ALL ASSERTIONS PASSED CLEANLY! V1 Correctness Verified.")
	quit(0)

func _wait_frames(count: int) -> void:
	for i in range(count):
		await root.get_tree().process_frame
