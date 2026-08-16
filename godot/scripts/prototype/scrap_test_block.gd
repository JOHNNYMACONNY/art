class_name ScrapTestBlock
extends Node3D

# Echos in the Scrap - Golden Slice v2 Main Controller
# Coordinates player, camera, signal tuner, corroded panel, UI overlay, and 3D audio.

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

@onready var player: PlayerRunner = $Runner
@onready var camera: ChinatownCamera3D = $ChinatownCamera3D
@onready var corroded_panel: CorrodedPanel = $CorrodedPanel
@onready var touch_ui: TouchControlsUI = $CanvasLayer/TouchControlsUI
@onready var audio_mgr: Node = $AudioManager
@onready var status_label: Label = $CanvasLayer/StatusLabel

var signal_tuner: SignalTuner = null
var _extracted_count: int = 0
var _active_target: Node3D = null

func _ready() -> void:
	# Instantiate SignalTuner in scene
	var tuner_scene: PackedScene = load("res://scenes/interactions/signal_tuner.tscn")
	if tuner_scene:
		signal_tuner = tuner_scene.instantiate() as SignalTuner
		signal_tuner.name = "SignalTuner"
		signal_tuner.position = Vector3(0, 0.4, -3.5)
		add_child(signal_tuner)
		signal_tuner.signal_locked.connect(_on_tuner_signal_locked)
		signal_tuner.audio_event_triggered.connect(_on_audio_event_triggered)
		
	if player and camera:
		camera.set_target(player)
		player.footstep_triggered.connect(_on_player_footstep)
		
	if touch_ui:
		touch_ui.joystick_vector_updated.connect(_on_joystick_vector_updated)
		touch_ui.action_button_pressed.connect(_on_action_pressed)
		touch_ui.peel_gesture_dragged.connect(_on_peel_gesture_dragged)
		touch_ui.tuner_dragged.connect(_on_tuner_dragged)
		touch_ui.core_tap_pressed.connect(_on_core_tap_pressed)
		
	if corroded_panel:
		corroded_panel.is_powered = false # Unpowered until SignalTuner locked!
		corroded_panel.magnetism_changed.connect(_on_magnetism_changed)
		corroded_panel.extraction_step_changed.connect(_on_extraction_step_changed)
		corroded_panel.extraction_completed.connect(_on_extraction_completed)
		corroded_panel.audio_event_triggered.connect(_on_audio_event_triggered)
		
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

func _process(_delta: float) -> void:
	if player:
		if signal_tuner:
			signal_tuner.update_player_distance(player.global_position)
		_evaluate_target_selection()
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v2\nFPS: %d | Frame: %.2f ms" % [
			Engine.get_frames_per_second(),
			1000.0 / max(Engine.get_frames_per_second(), 1)
		]

func _evaluate_target_selection() -> void:
	if not player or not touch_ui:
		return
		
	# Tuner targeting takes priority if ready and unlocked
	if signal_tuner and signal_tuner.current_state == SignalTuner.TunerState.READY:
		if _active_target != signal_tuner:
			_active_target = signal_tuner
			touch_ui.set_action_button_highlight(true)
	elif corroded_panel and corroded_panel.is_powered and corroded_panel.current_step == CorrodedPanel.Step.APPROACHED:
		if _active_target != corroded_panel:
			_active_target = corroded_panel
			touch_ui.set_action_button_highlight(true)
	else:
		if _active_target != null:
			_active_target = null
			touch_ui.set_action_button_highlight(false)

func _on_action_pressed() -> void:
	if _active_target == signal_tuner and signal_tuner:
		if signal_tuner.begin_tuning():
			if player:
				player.is_input_locked = true
			if camera:
				camera.set_interaction_mode(true, signal_tuner)
			if touch_ui:
				touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	elif _active_target == corroded_panel and corroded_panel:
		var action_success := corroded_panel.trigger_action()
		if action_success:
			if player:
				player.is_input_locked = true
			if camera:
				camera.set_interaction_mode(true, corroded_panel)
			if touch_ui:
				touch_ui.show_gesture_overlay("PEEL_PANEL")

func _on_tuner_dragged(delta_freq: float) -> void:
	if signal_tuner:
		signal_tuner.tune_dial(delta_freq)

func _on_tuner_signal_locked(_tuner: SignalTuner) -> void:
	print("[WORLD_LOOP] SIGNAL LOCKED! Powering up Corroded Panel...")
	if player:
		player.is_input_locked = false
	if camera:
		camera.set_interaction_mode(false)
	if touch_ui:
		touch_ui.show_gesture_overlay("TRAVERSAL")
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
	if touch_ui:
		touch_ui.show_gesture_overlay("TRAVERSAL")

func _on_audio_event_triggered(event_name: String) -> void:
	if audio_mgr:
		var pos := signal_tuner.global_position if signal_tuner else Vector3.ZERO
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
func _run_v2_assertions() -> void:
	print("[V2_ASSERTIONS] Starting strict V2 SignalTuner & World State assertions...")
	await get_tree().create_timer(0.1).timeout
	
	# 1. Initial state outside sensory range: Tuner DORMANT, Panel unpowered
	player.global_position = Vector3(0, 0, 10.0)
	await get_tree().create_timer(0.1).timeout
	signal_tuner.update_player_distance(player.global_position)
	assert(signal_tuner != null, "FAIL: SignalTuner must exist")
	assert(signal_tuner.current_state == SignalTuner.TunerState.DORMANT, "FAIL: Tuner must start DORMANT")
	assert(not corroded_panel.is_powered, "FAIL: CorrodedPanel must start UNPOWERED")
	
	# 2. Approach Tuner to sensory radius (5.0m)
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 5.0)
	await get_tree().create_timer(0.2).timeout
	signal_tuner.update_player_distance(player.global_position)
	assert(signal_tuner.current_state == SignalTuner.TunerState.ATTRACTING, "FAIL: Tuner must enter ATTRACTING")
	
	# 3. Approach Tuner to interaction radius (2.0m)
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 2.0)
	await get_tree().create_timer(0.2).timeout
	signal_tuner.update_player_distance(player.global_position)
	_evaluate_target_selection()
	assert(signal_tuner.current_state == SignalTuner.TunerState.READY, "FAIL: Tuner must enter READY")
	assert(_active_target == signal_tuner, "FAIL: Active target must be SignalTuner")
	
	# 4. Trigger tuning action
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	assert(signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: Tuner must enter TUNING")
	assert(player.is_input_locked, "FAIL: Player locomotion must lock during tuning")
	
	# 5. Tune dial to target frequency (~0.72)
	signal_tuner.tune_dial(0.57) # 0.15 + 0.57 = 0.72 target
	await get_tree().create_timer(0.5).timeout
	assert(signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL: Tuner must lock signal")
	
	# 6. Assert World state causality (Panel powered on lock)
	assert(corroded_panel.is_powered, "FAIL: CorrodedPanel must power on upon Signal Lock")
	assert(not player.is_input_locked, "FAIL: Player locomotion must unlock after lock")
	
	print("[V2_ASSERTIONS] PASSED! ALL 6 V2 TICKET 01 & 02 ASSERTIONS SUCCEEDED CLEANLY.")
	get_tree().quit()

func _run_automated_gameplay_test() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
