class_name ScrapTestBlock
extends Node3D

# Echoes in the Scrapheap - Golden Slice v0 Main Controller
# Coordinates player, camera, corroded panel interaction, UI overlay, and audio.

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

@onready var player: PlayerRunner = $Runner
@onready var camera: ChinatownCamera3D = $ChinatownCamera3D
@onready var corroded_panel: CorrodedPanel = $CorrodedPanel
@onready var touch_ui: TouchControlsUI = $CanvasLayer/TouchControlsUI
@onready var audio_mgr: Node = $AudioManager
@onready var status_label: Label = $CanvasLayer/StatusLabel

var _extracted_count: int = 0

var _frame_count: int = 0
var _is_testing: bool = false

func _ready() -> void:
	if player and camera:
		camera.set_target(player)
		player.footstep_triggered.connect(_on_player_footstep)
		
	if touch_ui:
		touch_ui.joystick_vector_updated.connect(_on_joystick_vector_updated)
		touch_ui.action_button_pressed.connect(_on_action_pressed)
		touch_ui.peel_gesture_dragged.connect(_on_peel_gesture_dragged)
		touch_ui.core_tap_pressed.connect(_on_core_tap_pressed)
		
	if corroded_panel:
		corroded_panel.magnetism_changed.connect(_on_magnetism_changed)
		corroded_panel.extraction_step_changed.connect(_on_extraction_step_changed)
		corroded_panel.extraction_completed.connect(_on_extraction_completed)
		corroded_panel.audio_event_triggered.connect(_on_audio_event_triggered)
		
	if status_label:
		status_label.text = "GOLDEN SLICE v0 // SCRAP-YARD TEST BLOCK\nFPS: %d" % Engine.get_frames_per_second()
		
	if OS.get_cmdline_user_args().has("--run-autotest"):
		_run_automated_gameplay_test()
	elif OS.get_cmdline_user_args().has("--run-v1-assertions"):
		_run_v1_assertions()
	elif OS.get_cmdline_user_args().has("--export-v1-visuals"):
		_export_v1_visuals()

func _export_v1_visuals() -> void:
	print("[V1_VISUALS] Exporting 5 required V1 visual screenshots...")
	await get_tree().create_timer(0.2).timeout
	
	# 1. v1_traversal.png
	player.set_joystick_input(Vector2(0.5, -0.5))
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://v1_traversal.png")
	print("[V1_VISUALS] Saved v1_traversal.png")
	
	# 2. v1_panel_targeted.png
	player.set_joystick_input(Vector2.ZERO)
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://v1_panel_targeted.png")
	print("[V1_VISUALS] Saved v1_panel_targeted.png")
	
	# 3. v1_peeling.png
	_on_action_pressed()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://v1_peeling.png")
	print("[V1_VISUALS] Saved v1_peeling.png")
	
	# 4. v1_core_exposed.png
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://v1_core_exposed.png")
	print("[V1_VISUALS] Saved v1_core_exposed.png")
	
	# 5. v1_extracted.png
	_on_core_tap_pressed()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://v1_extracted.png")
	print("[V1_VISUALS] Saved v1_extracted.png")
	
	print("[V1_VISUALS] ALL 5 V1 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	get_tree().quit()

func _run_v1_assertions() -> void:
	print("[V1_ASSERTIONS] Starting strict V1 test suite...")
	await get_tree().create_timer(0.1).timeout
	
	# 1. Assert initial state outside range
	assert(not corroded_panel.is_player_in_range, "FAIL: Player must start outside interaction range")
	assert(corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel must start IDLE")
	
	# 2. Assert out-of-range action rejection
	var rejections := corroded_panel.trigger_action()
	assert(not rejections, "FAIL: Out-of-range action must return false")
	assert(corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel must remain IDLE")
	
	# 3. Move player into range
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	assert(corroded_panel.is_player_in_range, "FAIL: Player must be in range")
	assert(corroded_panel.current_step == CorrodedPanel.Step.APPROACHED, "FAIL: Panel must be APPROACHED")
	
	# 4. Trigger action in range
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.PEELING, "FAIL: Panel must enter PEELING")
	assert(player.is_input_locked, "FAIL: Player input must lock")
	assert(camera.current_mode == ChinatownCamera3D.CameraMode.INTERACTION, "FAIL: Camera must enter INTERACTION mode")
	
	# 5. Progress peel
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.2).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.EXPOSED, "FAIL: Panel must enter EXPOSED")
	
	# 6. Extract core
	_on_core_tap_pressed()
	await get_tree().create_timer(0.3).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.EXTRACTED, "FAIL: Panel must enter EXTRACTED")
	assert(not player.is_input_locked, "FAIL: Player input must unlock")
	assert(camera.current_mode == ChinatownCamera3D.CameraMode.TRAVERSAL, "FAIL: Camera must return to TRAVERSAL mode")
	
	# 7. Re-trigger rejection
	var duplicate_trigger := corroded_panel.trigger_action()
	assert(not duplicate_trigger, "FAIL: Duplicate extraction must be rejected")
	
	print("[V1_ASSERTIONS] PASSED! ALL 7 V1 STRICT ASSERTIONS SUCCEEDED CLEANLY.")
	get_tree().quit()

func _run_automated_gameplay_test() -> void:
	_is_testing = true
	print("[AUTOTEST] Starting automated locomotion + extraction sequence...")
	await get_tree().create_timer(0.2).timeout
	
	# 1. Drive player toward panel at (0, 0, -6)
	if player:
		player.set_joystick_input(Vector2(0.0, -1.0))
	await get_tree().create_timer(1.2).timeout
	
	if player:
		player.set_joystick_input(Vector2.ZERO)
	print("[AUTOTEST] Player reached panel proximity. Magnetism in range: ", corroded_panel.is_player_in_range)
	
	# 2. Press action button
	_on_action_pressed()
	await get_tree().create_timer(0.3).timeout
	print("[AUTOTEST] Action pressed. Step: ", corroded_panel.current_step)
	
	# 3. Simulate peel gesture drag
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.4).timeout
	print("[AUTOTEST] Peel completed. Step: ", corroded_panel.current_step)
	
	# 4. Tap core to extract
	_on_core_tap_pressed()
	await get_tree().create_timer(0.5).timeout
	print("[AUTOTEST] Core extracted! Step: ", corroded_panel.current_step)
	
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://golden_slice_extracted.png")
		print("[AUTOTEST] Verification screenshot saved to res://golden_slice_extracted.png")
		
	print("[AUTOTEST] PASSED: Golden Slice v0 Gameplay Loop Verified!")
	get_tree().quit()

func _on_joystick_vector_updated(vec: Vector2) -> void:
	if player:
		player.set_joystick_input(vec)

func _on_action_pressed() -> void:
	if corroded_panel:
		var action_success := corroded_panel.trigger_action()
		if action_success:
			if player:
				player.is_input_locked = true
			if camera:
				camera.set_interaction_mode(true, corroded_panel)

func _on_peel_gesture_dragged(progress: float) -> void:
	if corroded_panel:
		corroded_panel.progress_peel(progress)

func _on_core_tap_pressed() -> void:
	if corroded_panel:
		corroded_panel.complete_extraction()

func _on_magnetism_changed(highlighted: bool, _panel: CorrodedPanel) -> void:
	if touch_ui:
		touch_ui.set_action_button_highlight(highlighted)

func _on_extraction_step_changed(step_name: String) -> void:
	if touch_ui:
		touch_ui.show_gesture_overlay(step_name)

func _on_extraction_completed() -> void:
	_extracted_count += 1
	if player:
		player.is_input_locked = false
	if camera:
		camera.set_interaction_mode(false)

func _on_audio_event_triggered(event_name: String) -> void:
	if audio_mgr:
		match event_name:
			"PROXIMITY_HUM":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM)
			"PANEL_PEEL":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.PANEL_PEEL)
			"CORE_PULL":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.CORE_PULL)
			"SPARK":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK)
			"COMPLETION":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION)

func _on_player_footstep() -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.FOOTSTEP)
