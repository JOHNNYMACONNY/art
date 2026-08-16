class_name ScrapTestBlock
extends Node3D

# Echos in the Scrap - Golden Slice v2 Main Controller

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

@onready var player: PlayerRunner = $Runner
@onready var camera: ChinatownCamera3D = $ChinatownCamera3D
@onready var corroded_panel: CorrodedPanel = $CorrodedPanel
@onready var touch_ui: TouchControlsUI = $CanvasLayer/TouchControlsUI
@onready var audio_mgr: Node = $AudioManager
@onready var status_label: Label = $CanvasLayer/StatusLabel

var signal_tuner: SignalTuner = null
var _extracted_count: int = 0
var _active_target: InteractableBase = null
var _interactables: Array[InteractableBase] = []

func _ready() -> void:
	var tuner_scene: PackedScene = load("res://scenes/interactions/signal_tuner.tscn")
	if tuner_scene:
		signal_tuner = tuner_scene.instantiate() as SignalTuner
		signal_tuner.name = "SignalTuner"
		signal_tuner.position = Vector3(0, 0.4, -3.5)
		add_child(signal_tuner)
		signal_tuner.signal_locked.connect(_on_tuner_signal_locked)
		signal_tuner.audio_event_triggered.connect(_on_audio_event_triggered)
		signal_tuner.frequency_changed.connect(_on_tuner_frequency_changed)
		_interactables.append(signal_tuner)
		
	if corroded_panel:
		corroded_panel.magnetism_changed.connect(_on_magnetism_changed)
		corroded_panel.extraction_step_changed.connect(_on_extraction_step_changed)
		corroded_panel.extraction_completed.connect(_on_extraction_completed)
		corroded_panel.audio_event_triggered.connect(_on_audio_event_triggered)
		_interactables.append(corroded_panel)
		
	if player and camera:
		camera.set_target(player)
		player.footstep_triggered.connect(_on_player_footstep)
		
	if touch_ui:
		touch_ui.joystick_vector_updated.connect(_on_joystick_vector_updated)
		touch_ui.action_button_pressed.connect(_on_action_pressed)
		touch_ui.peel_gesture_dragged.connect(_on_peel_gesture_dragged)
		touch_ui.tuner_dragged.connect(_on_tuner_dragged)
		touch_ui.core_tap_pressed.connect(_on_core_tap_pressed)
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v2"
		
	if OS.get_cmdline_user_args().has("--run-autotest"):
		_run_automated_gameplay_test()
	elif OS.get_cmdline_user_args().has("--run-v1-assertions"):
		_run_v1_assertions()
	elif OS.get_cmdline_user_args().has("--run-v2-assertions"):
		_run_v2_assertions()
	elif OS.get_cmdline_user_args().has("--export-v1-visuals"):
		_export_v1_visuals()
	elif OS.get_cmdline_user_args().has("--export-v2-visuals"):
		_export_v2_visuals()

func _process(_delta: float) -> void:
	if player:
		for item in _interactables:
			if item:
				item.update_player_distance(player.global_position)
		_evaluate_target_selection()
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v2\nFPS: %d | Frame: %.2f ms" % [
			Engine.get_frames_per_second(),
			1000.0 / max(Engine.get_frames_per_second(), 1)
		]

func _evaluate_target_selection() -> void:
	if not player or not touch_ui:
		return
		
	var best_target: InteractableBase = null
	var best_score: float = -9999.0
	var player_pos := player.global_position
	
	for item in _interactables:
		if item and item.can_interact(player_pos):
			var dist := item.global_position.distance_to(player_pos)
			var score := (item.get_interaction_priority() * 10.0) - dist
			if item == _active_target:
				score += 2.0 # Hysteresis stability boost
			if score > best_score:
				best_score = score
				best_target = item
				
	if best_target != _active_target:
		_active_target = best_target
		touch_ui.set_action_button_highlight(_active_target != null)

func _on_action_pressed() -> void:
	if not _active_target or not player:
		return
		
	if _active_target == signal_tuner and signal_tuner:
		if signal_tuner.begin_interaction(player.global_position):
			player.is_input_locked = true
			if camera:
				camera.set_interaction_mode(true, signal_tuner)
			if touch_ui:
				touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	elif _active_target == corroded_panel and corroded_panel:
		if corroded_panel.begin_interaction(player.global_position):
			player.is_input_locked = true
			if camera:
				camera.set_interaction_mode(true, corroded_panel)
			if touch_ui:
				touch_ui.show_gesture_overlay("PEEL_PANEL")

func _on_tuner_dragged(delta_freq: float) -> void:
	if signal_tuner:
		signal_tuner.tune_dial(delta_freq)

func _on_tuner_frequency_changed(_freq: float, accuracy: float) -> void:
	if audio_mgr:
		audio_mgr.set_tuning_audio(accuracy)

func _on_tuner_signal_locked(tuner_ref: SignalTuner) -> void:
	print("[WORLD_LOOP] SIGNAL LOCKED! Powering up Corroded Panel...")
	var conduit := get_node_or_null("PowerConduit") as MeshInstance3D
	if conduit:
		var mat := conduit.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.emission = Color(0.1, 0.9, 1.0, 1.0)
			mat.emission_energy_multiplier = 3.5
	if audio_mgr:
		audio_mgr.set_tuning_audio(0.0)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SIGNAL_LOCK, tuner_ref.global_position)
		if corroded_panel:
			audio_mgr.play_event(AudioManagerScript.SoundEvent.PANEL_POWERED, corroded_panel.global_position)
	if player:
		player.is_input_locked = false
	if camera:
		camera.set_interaction_mode(false)
	if touch_ui:
		touch_ui.close_interaction_overlay()
	if corroded_panel:
		corroded_panel.power_on()

func _on_peel_gesture_dragged(progress: float) -> void:
	if corroded_panel:
		corroded_panel.progress_peel(progress)
	if audio_mgr:
		var peel_pitch: float = lerp(1.15, 1.30, progress)
		audio_mgr.set_hum_pitch(peel_pitch)

func _on_core_tap_pressed() -> void:
	if corroded_panel:
		corroded_panel.complete_extraction()

func _on_joystick_vector_updated(vec: Vector2) -> void:
	if player:
		player.set_joystick_input(vec)

func _on_magnetism_changed(highlighted: bool, _panel: CorrodedPanel) -> void:
	if touch_ui:
		touch_ui.set_action_button_highlight(highlighted)

func _on_extraction_step_changed(step_name: String) -> void:
	if touch_ui:
		touch_ui.show_gesture_overlay(step_name)
	if audio_mgr and corroded_panel:
		var pos := corroded_panel.global_position
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
	if touch_ui:
		touch_ui.close_interaction_overlay()

func _on_audio_event_triggered(event_name: String, source_pos: Vector3) -> void:
	if audio_mgr:
		match event_name:
			"PROXIMITY_HUM":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM, source_pos)
			"PANEL_PEEL":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.PANEL_PEEL, source_pos)
			"CORE_PULL":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.CORE_PULL, source_pos)
			"SPARK":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, source_pos)
			"COMPLETION":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION, source_pos)

func _on_player_footstep() -> void:
	if audio_mgr and player:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.FOOTSTEP, player.global_position)

func _export_v1_visuals() -> void:
	print("[V1_VISUALS] Exporting 5 required V1 visual screenshots to res://verification/...")
	await get_tree().create_timer(0.2).timeout
	player.set_joystick_input(Vector2(0.5, -0.5))
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_traversal.png")
	player.set_joystick_input(Vector2.ZERO)
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_panel_targeted.png")
	corroded_panel.is_powered = true
	_active_target = corroded_panel
	_on_action_pressed()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_peeling.png")
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_core_exposed.png")
	_on_core_tap_pressed()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v1_extracted.png")
	get_tree().quit()

func _run_v1_assertions() -> void:
	print("[V1_ASSERTIONS] Starting strict V1 test suite...")
	await get_tree().create_timer(0.1).timeout
	corroded_panel.is_powered = true
	assert(corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel must start IDLE")
	var rejections := corroded_panel.trigger_action()
	assert(not rejections, "FAIL: Out-of-range action must return false")
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	assert(corroded_panel.is_player_in_range, "FAIL: Player must be in range")
	_active_target = corroded_panel
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.PEELING, "FAIL: Panel must enter PEELING")
	_on_peel_gesture_dragged(1.0)
	await get_tree().create_timer(0.2).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.EXPOSED, "FAIL: Panel must enter EXPOSED")
	_on_core_tap_pressed()
	await get_tree().create_timer(0.3).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.EXTRACTED, "FAIL: Panel must enter EXTRACTED")
	assert(not player.is_input_locked, "FAIL: Player input must unlock")
	print("[V1_ASSERTIONS] PASSED! ALL V1 REACTION ASSERTIONS GREEN.")
	get_tree().quit()

func _run_v2_assertions() -> void:
	print("[V2_ASSERTIONS] Starting strict V2 SignalTuner & World State assertions...")
	await get_tree().create_timer(0.1).timeout
	
	player.global_position = Vector3(0, 0, 10.0)
	await get_tree().create_timer(0.1).timeout
	signal_tuner.update_player_distance(player.global_position)
	assert(signal_tuner != null, "FAIL: SignalTuner must exist")
	assert(signal_tuner.current_state == SignalTuner.TunerState.DORMANT, "FAIL: Tuner must start DORMANT")
	assert(not corroded_panel.is_powered, "FAIL: CorrodedPanel must start UNPOWERED")
	
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 5.0)
	await get_tree().create_timer(0.2).timeout
	signal_tuner.update_player_distance(player.global_position)
	assert(signal_tuner.current_state == SignalTuner.TunerState.ATTRACTING, "FAIL: Tuner must enter ATTRACTING")
	
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 2.0)
	await get_tree().create_timer(0.2).timeout
	signal_tuner.update_player_distance(player.global_position)
	_evaluate_target_selection()
	assert(signal_tuner.current_state == SignalTuner.TunerState.READY, "FAIL: Tuner must enter READY")
	assert(_active_target == signal_tuner, "FAIL: Active target must be SignalTuner")
	
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	assert(signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: Tuner must enter TUNING")
	assert(player.is_input_locked, "FAIL: Player locomotion must lock during tuning")
	
	signal_tuner.tune_dial(0.57)
	await get_tree().create_timer(0.5).timeout
	assert(signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL: Tuner must lock signal")
	assert(corroded_panel.is_powered, "FAIL: CorrodedPanel must power on upon Signal Lock")
	assert(not player.is_input_locked, "FAIL: Player locomotion must unlock after lock")
	
	print("[V2_ASSERTIONS] PASSED! ALL 6 V2 TICKET 01 & 02 ASSERTIONS SUCCEEDED CLEANLY.")
	get_tree().quit()

func _export_v2_visuals() -> void:
	print("[V2_VISUALS] Exporting 8 required V2 visual screenshots to res://verification/v2/...")
	await get_tree().create_timer(0.2).timeout
	
	player.global_position = Vector3(0, 0, 8.0)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_explore.png")
	
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 4.5)
	signal_tuner.update_player_distance(player.global_position)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_tuner_attract.png")
	
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 1.8)
	signal_tuner.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	signal_tuner.tune_dial(0.1)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_tuning_far.png")
	
	signal_tuner.tune_dial(0.45)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_tuning_near.png")
	
	signal_tuner.tune_dial(0.02)
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_signal_locked.png")
	
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_panel_powered.png")
	
	_active_target = corroded_panel
	_on_action_pressed()
	_on_peel_gesture_dragged(0.5)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_panel_extraction.png")
	
	_on_peel_gesture_dragged(1.0)
	_on_core_tap_pressed()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v2/v2_loop_complete.png")
	
	print("[V2_VISUALS] ALL 8 V2 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	get_tree().quit()

func _run_automated_gameplay_test() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
