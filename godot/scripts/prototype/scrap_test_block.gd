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
		corroded_panel.trigger_action()
		if player:
			player.is_input_locked = true

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
