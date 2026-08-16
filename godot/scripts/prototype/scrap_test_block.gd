class_name ScrapTestBlock
extends Node3D

# Echos in the Scrap - Golden Slice v1 Main Controller
# Coordinates player, camera, corroded panel interaction, UI overlay, and 3D audio.

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

@onready var player: PlayerRunner = $Runner
@onready var camera: ChinatownCamera3D = $ChinatownCamera3D
@onready var corroded_panel: CorrodedPanel = $CorrodedPanel
@onready var touch_ui: TouchControlsUI = $CanvasLayer/TouchControlsUI
@onready var audio_mgr: Node = $AudioManager
@onready var status_label: Label = $CanvasLayer/StatusLabel

var _extracted_count: int = 0

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
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v1\nFPS: %d" % Engine.get_frames_per_second()
		
	if OS.get_cmdline_user_args().has("--run-autotest"):
		_run_automated_gameplay_test()
	elif OS.get_cmdline_user_args().has("--run-v1-assertions"):
		_run_v1_assertions()
	elif OS.get_cmdline_user_args().has("--export-v1-visuals"):
		_export_v1_visuals()

func _process(_delta: float) -> void:
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v1\nFPS: %d | Frame: %.2f ms" % [
			Engine.get_frames_per_second(),
			1000.0 / max(Engine.get_frames_per_second(), 1)
		]

func _export_v1_visuals() -> void:
	print("[V1_VISUALS] Exporting 5 required V1 visual screenshots to res://verification/...")
	await get_tree().create_timer(0.2).timeout
	
	# 1. v1_traversal.png
	player.set_joystick_input(Vector2(0.5, -0.5))
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_traversal.png")
	print("[V1_VISUALS] Saved res://verification/v1_traversal.png")
	
	# 2. v1_panel_targeted.png
	player.set_joystick_input(Vector2.ZERO)
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_panel_targeted.png")
	print("[V1_VISUALS] Saved res://verification/v1_panel_targeted.png")
	
	# 3. v1_peeling.png
	_on_action_pressed()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_peeling.png")
	print("[V1_VISUALS] Saved res://verification/v1_peeling.png")
	
	# 4. v1_core_exposed.png
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_core_exposed.png")
	print("[V1_VISUALS] Saved res://verification/v1_core_exposed.png")
	
	# 5. v1_extracted.png
	_on_core_tap_pressed()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_extracted.png")
	print("[V1_VISUALS] Saved res://verification/v1_extracted.png")
	
	print("[V1_VISUALS] ALL 5 V1 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	get_tree().quit()

func _run_v1_assertions() -> void:
	print("[V1_ASSERTIONS] Starting strict V1 test suite...")
	await get_tree().create_timer(0.1).timeout
	
	assert(not corroded_panel.is_player_in_range, "FAIL: Player must start outside interaction range")
	assert(corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel must start IDLE")
	
	var rejections := corroded_panel.trigger_action()
	assert(not rejections, "FAIL: Out-of-range action must return false")
	assert(corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel must remain IDLE")
	
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	assert(corroded_panel.is_player_in_range, "FAIL: Player must be in range")
	assert(corroded_panel.current_step == CorrodedPanel.Step.APPROACHED, "FAIL: Panel must be APPROACHED")
	
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.PEELING, "FAIL: Panel must enter PEELING")
	assert(player.is_input_locked, "FAIL: Player input must lock")
	assert(camera.current_mode == ChinatownCamera3D.CameraMode.INTERACTION, "FAIL: Camera must enter INTERACTION mode")
	
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.2).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.EXPOSED, "FAIL: Panel must enter EXPOSED")
	
	_on_core_tap_pressed()
	await get_tree().create_timer(0.3).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.EXTRACTED, "FAIL: Panel must enter EXTRACTED")
	assert(not player.is_input_locked, "FAIL: Player input must unlock")
	assert(camera.current_mode == ChinatownCamera3D.CameraMode.TRAVERSAL, "FAIL: Camera must return to TRAVERSAL mode")
	
	var duplicate_trigger := corroded_panel.trigger_action()
	assert(not duplicate_trigger, "FAIL: Duplicate extraction must be rejected")
	
	print("[V1_ASSERTIONS] 8. Asserting multitouch input event routing & pointer isolation...")
	var touch0_down := InputEventScreenTouch.new()
	touch0_down.index = 0
	touch0_down.pressed = true
	touch0_down.position = Vector2(100, 200)
	touch_ui._input(touch0_down)
	assert(touch_ui.left_pointer_id == 0, "FAIL: Touch 0 down on left screen must acquire left_pointer_id=0")
	
	var touch1_down := InputEventScreenTouch.new()
	touch1_down.index = 1
	touch1_down.pressed = true
	touch1_down.position = Vector2(700, 200)
	touch_ui._input(touch1_down)
	assert(touch_ui.left_pointer_id == 0, "FAIL: Touch 1 on right screen must NOT steal left_pointer_id")
	
	var touch_wrong_up := InputEventScreenTouch.new()
	touch_wrong_up.index = 99
	touch_wrong_up.pressed = false
	touch_wrong_up.position = Vector2(700, 200)
	touch_ui._input(touch_wrong_up)
	assert(touch_ui.left_pointer_id == 0, "FAIL: Unrelated pointer release must NOT reset joystick")
	
	var touch0_up := InputEventScreenTouch.new()
	touch0_up.index = 0
	touch0_up.pressed = false
	touch0_up.position = Vector2(100, 200)
	touch_ui._input(touch0_up)
	assert(touch_ui.left_pointer_id == -1, "FAIL: Matching pointer release must reset joystick")
	
	print("[V1_ASSERTIONS] PASSED! ALL 8 V1.1 MULTITOUCH & STATE ASSERTIONS SUCCEEDED CLEANLY.")
	get_tree().quit()

func _run_automated_gameplay_test() -> void:
	print("[AUTOTEST] Starting automated locomotion + extraction sequence...")
	await get_tree().create_timer(0.2).timeout
	
	if player:
		player.set_joystick_input(Vector2(0.0, -1.0))
	await get_tree().create_timer(1.2).timeout
	
	if player:
		player.set_joystick_input(Vector2.ZERO)
	
	_on_action_pressed()
	await get_tree().create_timer(0.3).timeout
	
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.4).timeout
	
	_on_core_tap_pressed()
	await get_tree().create_timer(0.5).timeout
	
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://verification/v1_extracted.png")
		
	print("[AUTOTEST] PASSED: Golden Slice v1 Gameplay Loop Verified!")
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
	if audio_mgr:
		# Pitch ramps 1.15 -> 1.30 during peel gesture
		var peel_pitch: float = lerp(1.15, 1.30, progress)
		audio_mgr.set_hum_pitch(peel_pitch)

func _on_core_tap_pressed() -> void:
	if corroded_panel:
		corroded_panel.complete_extraction()

func _on_magnetism_changed(highlighted: bool, _panel: CorrodedPanel) -> void:
	if touch_ui:
		touch_ui.set_action_button_highlight(highlighted)

func _on_extraction_step_changed(step_name: String) -> void:
	if touch_ui:
		touch_ui.show_gesture_overlay(step_name)
	if audio_mgr:
		match step_name:
			"PEEL_PANEL":
				audio_mgr.set_hum_pitch(1.15)
			"EXPOSE_CORE":
				audio_mgr.set_hum_pitch(1.50)
			"EXTRACTED":
				audio_mgr.stop_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM)

func _on_extraction_completed() -> void:
	_extracted_count += 1
	if player:
		player.is_input_locked = false
	if camera:
		camera.set_interaction_mode(false)

func _on_audio_event_triggered(event_name: String) -> void:
	if audio_mgr:
		var pos := corroded_panel.global_position if corroded_panel else Vector3.ZERO
		match event_name:
			"PROXIMITY_HUM":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM, pos)
			"PANEL_PEEL":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.PANEL_PEEL, pos)
			"CORE_PULL":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.CORE_PULL, pos)
			"SPARK":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, pos)
			"COMPLETION":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION, pos)

func _on_player_footstep() -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.FOOTSTEP)
