class_name ScrapTestBlock
extends Node3D

# Echos in the Scrap - Golden Slice v5 Main Controller
# Integrated V5 Environmental Evasion / Scrap Route Switch

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

enum WorldLoopState {
	START,
	SIGNAL_LOCKED,
	PANEL_POWERED,
	CORE_EXTRACTED,
	LOOP_COMPLETE
}

enum PursuitState {
	CALM,
	DISTURBANCE_ALERT,
	PURSUIT_ACTIVE,
	CONTACT_BROKEN,
	EVADED,
	INTERCEPTED
}

@onready var player: PlayerRunner = $Runner
@onready var camera: ChinatownCamera3D = $ChinatownCamera3D
@onready var corroded_panel: CorrodedPanel = $CorrodedPanel
@onready var touch_ui: TouchControlsUI = $CanvasLayer/TouchControlsUI
@onready var audio_mgr: Node = $AudioManager
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var world_env: WorldEnvironment = $WorldEnvironment

var signal_tuner: SignalTuner = null
var courier_bike: CourierBike = null
var pursuer: PursuerPrototype = null
var signal_gate: SignalGateInteractable = null

var current_world_state: WorldLoopState = WorldLoopState.START
var current_pursuit_state: PursuitState = PursuitState.CALM

var _extracted_count: int = 0
var _active_target: InteractableBase = null
var _interactables: Array[InteractableBase] = []

var _steer_input: float = 0.0
var _throttle_input: float = 0.0
var _contact_broken_timer: float = 0.0
var _recovery_marker: Vector3 = Vector3(-1.5, 0.05, 3.0)

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
		
	var bike_scene: PackedScene = load("res://scenes/vehicles/courier_bike.tscn")
	if bike_scene:
		courier_bike = bike_scene.instantiate() as CourierBike
		courier_bike.name = "CourierBike"
		courier_bike.position = _recovery_marker
		add_child(courier_bike)
		courier_bike.mounted.connect(_on_bike_mounted)
		courier_bike.dismounted.connect(_on_bike_dismounted)
		courier_bike.brake_screech_triggered.connect(func(pos: Vector3):
			if audio_mgr: audio_mgr.play_event(AudioManagerScript.SoundEvent.BRAKE_SCREECH, pos)
		)
		if courier_bike.mount_interactable:
			_interactables.append(courier_bike.mount_interactable)
			
	var pursuer_scene: PackedScene = load("res://scenes/entities/pursuer_prototype.tscn")
	if pursuer_scene:
		pursuer = pursuer_scene.instantiate() as PursuerPrototype
		pursuer.name = "PursuerPrototype"
		pursuer.position = Vector3(0, 0.6, -15.0)
		add_child(pursuer)
		pursuer.intercepted_target.connect(_on_pursuer_intercepted)
		
	var gate_scene: PackedScene = load("res://scenes/interactions/signal_gate.tscn")
	if gate_scene:
		signal_gate = gate_scene.instantiate() as SignalGateInteractable
		signal_gate.name = "SignalGate"
		signal_gate.position = Vector3(-1.5, 0.5, 12.0)
		add_child(signal_gate)
		signal_gate.gate_triggered.connect(_on_signal_gate_triggered)
		_interactables.append(signal_gate)
		
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
		touch_ui.driving_steer_updated.connect(func(steer: float): _steer_input = steer)
		touch_ui.driving_throttle_updated.connect(func(throttle: float): _throttle_input = throttle)
		touch_ui.dismount_pressed.connect(_on_dismount_pressed)
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v5"
		
	if OS.get_cmdline_user_args().has("--run-v1-assertions"):
		_run_v1_assertions()
	elif OS.get_cmdline_user_args().has("--run-v2-assertions"):
		_run_v2_assertions()
	elif OS.get_cmdline_user_args().has("--run-v3-assertions"):
		_run_v3_assertions()
	elif OS.get_cmdline_user_args().has("--run-v4-assertions"):
		_run_v4_assertions()
	elif OS.get_cmdline_user_args().has("--run-v5-assertions"):
		_run_v5_assertions()
	elif OS.get_cmdline_user_args().has("--export-v2-visuals"):
		_export_v2_visuals()
	elif OS.get_cmdline_user_args().has("--export-v3-visuals"):
		_export_v3_visuals()
	elif OS.get_cmdline_user_args().has("--export-v4-visuals"):
		_export_v4_visuals()
	elif OS.get_cmdline_user_args().has("--export-v5-visuals"):
		_export_v5_visuals()

func _process(delta: float) -> void:
	var active_pos: Vector3 = courier_bike.global_position if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player.global_position
	for item in _interactables:
		if item:
			item.update_player_distance(active_pos)
	_evaluate_target_selection()
		
	if courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING:
		courier_bike.set_drive_inputs(_throttle_input, _steer_input, delta)
		if touch_ui:
			touch_ui.set_dismount_button_enabled(abs(courier_bike.current_speed) <= courier_bike.dismount_speed_limit)
		if audio_mgr:
			var speed_ratio: float = abs(courier_bike.current_speed) / courier_bike.max_speed
			audio_mgr.set_engine_audio(speed_ratio, courier_bike.global_position)
			
	_process_pursuit_loop(delta)
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v5 [%s | PURSUIT: %s]\nFPS: %d | Frame: %.2f ms" % [
			WorldLoopState.keys()[current_world_state],
			PursuitState.keys()[current_pursuit_state],
			Engine.get_frames_per_second(),
			1000.0 / max(Engine.get_frames_per_second(), 1)
		]

func _process_pursuit_loop(delta: float) -> void:
	if current_pursuit_state == PursuitState.PURSUIT_ACTIVE and pursuer and pursuer.is_active:
		var target: Node3D = courier_bike if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player
		if target:
			var dist := pursuer.global_position.distance_to(target.global_position)
			if touch_ui:
				touch_ui.update_pursuer_proximity(dist)
			if audio_mgr:
				audio_mgr.set_siren_audio(true, pursuer.global_position)
				
			if dist > 18.0:
				_contact_broken_timer += delta
				if _contact_broken_timer >= 3.0:
					_contact_broken_timer = 0.0
					current_pursuit_state = PursuitState.CONTACT_BROKEN
					print("[PURSUIT] Contact broken! Evasion decay started...")
					await get_tree().create_timer(1.0).timeout
					current_pursuit_state = PursuitState.EVADED
					_deactivate_pursuit()
			else:
				_contact_broken_timer = move_toward(_contact_broken_timer, 0.0, delta)

func trigger_disturbance_alert() -> void:
	if current_pursuit_state != PursuitState.CALM:
		return
		
	current_pursuit_state = PursuitState.DISTURBANCE_ALERT
	print("[PURSUIT] DISTURBANCE ALERT DETECTED!")
	
	if touch_ui:
		touch_ui.show_tension_hud("[ ALERT: DISTURBANCE DETECTED ]")
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, corroded_panel.global_position if corroded_panel else Vector3.ZERO)
		
	if world_env and world_env.environment:
		world_env.environment.ambient_light_color = Color(0.4, 0.1, 0.1, 1.0)
		
	get_tree().create_timer(0.75).timeout.connect(func():
		if current_pursuit_state == PursuitState.DISTURBANCE_ALERT:
			current_pursuit_state = PursuitState.PURSUIT_ACTIVE
			if signal_gate:
				signal_gate.set_pursuit_active(true)
			if touch_ui:
				touch_ui.show_tension_hud("[ ALERT: PURSUIT ACTIVE ]")
			if pursuer:
				var target: Node3D = courier_bike if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player
				pursuer.activate_pursuit(target)
	)

func _deactivate_pursuit() -> void:
	if pursuer:
		pursuer.deactivate_pursuit()
	if signal_gate:
		signal_gate.set_pursuit_active(false)
	if audio_mgr:
		audio_mgr.set_siren_audio(false, Vector3.ZERO)
	if touch_ui:
		touch_ui.hide_tension_hud()
	if world_env and world_env.environment:
		world_env.environment.ambient_light_color = Color(0.3, 0.26, 0.2, 1.0)
	current_pursuit_state = PursuitState.CALM
	print("[PURSUIT] Contact evaded. Environment returned to CALM.")

func _on_signal_gate_triggered() -> void:
	print("[GATE] Signal Gate Triggered! Slamming scrap barrier...")
	if audio_mgr and signal_gate:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.GATE_SLAM, signal_gate.global_position)
		
	if pursuer:
		# Detour waypoints routing pursuer around physical barrier arm
		var waypoints: Array[Vector3] = [
			Vector3(2.5, 0.6, 8.0),
			Vector3(2.5, 0.6, 18.0),
			Vector3(-1.5, 0.6, 26.0)
		]
		pursuer.set_detour_path(waypoints)

func _on_pursuer_intercepted() -> void:
	if current_pursuit_state == PursuitState.INTERCEPTED:
		return
		
	current_pursuit_state = PursuitState.INTERCEPTED
	print("[PURSUIT] TARGET INTERCEPTED! Resetting to recovery marker...")
	
	if player: player.is_input_locked = true
	if courier_bike: courier_bike.force_dismount()
	if pursuer: pursuer.deactivate_pursuit()
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, player.global_position if player else Vector3.ZERO)
		audio_mgr.set_siren_audio(false, Vector3.ZERO)
		
	get_tree().create_timer(0.8).timeout.connect(func():
		if player:
			player.global_position = _recovery_marker + Vector3(-1.5, 0, 0)
			player.is_input_locked = false
			player.velocity = Vector3.ZERO
		if courier_bike:
			courier_bike.global_position = _recovery_marker
			courier_bike.rotation = Vector3.ZERO
			
		_deactivate_pursuit()
	)

func _evaluate_target_selection() -> void:
	if not player or not touch_ui:
		return
		
	var best_target: InteractableBase = null
	var best_score: float = -9999.0
	var active_pos: Vector3 = courier_bike.global_position if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player.global_position
	
	for item in _interactables:
		if item and item.can_interact(active_pos):
			var dist := item.global_position.distance_to(active_pos)
			var score := (item.get_interaction_priority() * 10.0) - dist
			if item == _active_target:
				score += 2.0
			if score > best_score:
				best_score = score
				best_target = item
				
	if best_target != _active_target:
		_active_target = best_target
		touch_ui.set_action_button_highlight(_active_target != null)
		if touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING:
			touch_ui.set_route_switch_button_visible(_active_target is SignalGateInteractable)

func _on_action_pressed() -> void:
	if not _active_target or not player:
		return
		
	var active_pos: Vector3 = courier_bike.global_position if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player.global_position
		
	if _active_target is MountInteractable:
		(_active_target as MountInteractable).set_player_reference(player)
		_active_target.begin_interaction(active_pos)
	elif _active_target is SignalGateInteractable:
		(_active_target as SignalGateInteractable).begin_interaction(active_pos)
	elif _active_target == signal_tuner and signal_tuner:
		if signal_tuner.begin_interaction(active_pos):
			player.is_input_locked = true
			if camera:
				camera.set_interaction_mode(true, signal_tuner)
			if touch_ui:
				touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	elif _active_target == corroded_panel and corroded_panel:
		if corroded_panel.begin_interaction(active_pos):
			player.is_input_locked = true
			if camera:
				camera.set_interaction_mode(true, corroded_panel)
			if touch_ui:
				touch_ui.show_gesture_overlay("PEEL_PANEL")

func _on_bike_mounted(_player_ref: PlayerRunner) -> void:
	if touch_ui:
		touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	if camera and courier_bike:
		camera.set_target(courier_bike)
	if audio_mgr and courier_bike:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.BIKE_MOUNT, courier_bike.global_position)
	if pursuer and pursuer.is_active:
		pursuer.target_node = courier_bike

func _on_bike_dismounted() -> void:
	if touch_ui:
		touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	if camera and player:
		camera.set_target(player)
	if audio_mgr and player:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.BIKE_DISMOUNT, player.global_position)
		audio_mgr.stop_event(AudioManagerScript.SoundEvent.ENGINE_REV)
	if pursuer and pursuer.is_active:
		pursuer.target_node = player

func _on_dismount_pressed() -> void:
	if courier_bike:
		courier_bike.request_dismount()

func _on_tuner_dragged(delta_freq: float) -> void:
	if signal_tuner:
		signal_tuner.tune_dial(delta_freq)

func _on_tuner_frequency_changed(_freq: float, accuracy: float) -> void:
	if audio_mgr:
		audio_mgr.set_tuning_audio(accuracy)

func _on_tuner_signal_locked(tuner_ref: SignalTuner) -> void:
	print("[WORLD_LOOP] SIGNAL LOCKED! Powering up Corroded Panel...")
	current_world_state = WorldLoopState.SIGNAL_LOCKED
	
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
		current_world_state = WorldLoopState.PANEL_POWERED

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
	current_world_state = WorldLoopState.CORE_EXTRACTED
	print("[WORLD_LOOP] MICRO-PLAY LOOP COMPLETE! Core extracted.")
	trigger_disturbance_alert()
	
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
	assert(current_world_state == WorldLoopState.START, "FAIL: World state must start START")
	
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
	assert(current_world_state == WorldLoopState.PANEL_POWERED, "FAIL: World state must advance to PANEL_POWERED")
	assert(not player.is_input_locked, "FAIL: Player locomotion must unlock after lock")
	
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.8)
	await get_tree().create_timer(0.3).timeout
	_active_target = corroded_panel
	_on_action_pressed()
	_on_peel_gesture_dragged(1.0)
	_on_core_tap_pressed()
	await get_tree().create_timer(0.4).timeout
	assert(current_world_state == WorldLoopState.CORE_EXTRACTED, "FAIL: World state must reach CORE_EXTRACTED")
	
	print("[V2_ASSERTIONS] PASSED! ALL V2 MICRO-PLAY LOOP ASSERTIONS SUCCEEDED CLEANLY.")
	get_tree().quit()

func _run_v3_assertions() -> void:
	print("[V3_ASSERTIONS] Starting complete V3 Courier Bike Vehicle Feel Slice assertions...")
	await get_tree().create_timer(0.1).timeout
	assert(courier_bike != null, "FAIL: CourierBike must exist")
	assert(courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must start PARKED")
	assert(courier_bike.occupant == null, "FAIL: Bike occupant must start null")
	
	assert(audio_mgr._engine_stream != null, "FAIL: Audio manager engine stream must exist")
	assert(audio_mgr._hum_stream != null, "FAIL: Audio manager hum stream must exist")
	
	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.5)
	await get_tree().create_timer(0.2).timeout
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	
	assert(courier_bike.current_state == CourierBike.BikeState.MOUNTING, "FAIL: Bike must enter MOUNTING")
	await get_tree().create_timer(0.35).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	assert(courier_bike.occupant == player, "FAIL: Occupant must be player")
	assert(player.is_input_locked, "FAIL: Player input must be locked while mounted")
	assert(touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING, "FAIL: Touch UI must enter VEHICLE_DRIVING")
	
	var initial_rot := courier_bike.rotation.y
	_steer_input = 0.5
	_throttle_input = 1.0
	await get_tree().create_timer(1.0).timeout
	assert(courier_bike.current_speed > 5.0, "FAIL: Bike speed must accelerate under throttle")
	assert(courier_bike.rotation.y != initial_rot, "FAIL: Steering must change bike heading")
	assert(player.global_position.distance_to(courier_bike.rider_socket.global_position) < 0.1, "FAIL: Rider avatar must remain bound to RiderSocket")
	
	_steer_input = 0.0
	_throttle_input = -1.0
	await get_tree().create_timer(0.8).timeout
	assert(courier_bike.current_speed <= 0.1, "FAIL: Forward braking must reach near-zero before reverse")
	await get_tree().create_timer(0.8).timeout
	assert(courier_bike.current_speed < 0.0, "FAIL: Continued negative throttle must reverse")
	assert(courier_bike.current_speed >= courier_bike.max_reverse_speed, "FAIL: Reverse speed must be limited")
	
	_throttle_input = 1.0
	await get_tree().create_timer(1.0).timeout
	assert(abs(courier_bike.current_speed) > courier_bike.dismount_speed_limit, "FAIL: Bike speed must be > 1.5 m/s")
	var rejected_dismount := courier_bike.request_dismount()
	assert(not rejected_dismount, "FAIL: High-speed dismount must be rejected")
	
	_throttle_input = 0.0
	courier_bike.current_speed = 0.0
	
	_on_dismount_pressed()
	assert(courier_bike.current_state == CourierBike.BikeState.DISMOUNTING, "FAIL: Bike state must transition DISMOUNTING before PARKED")
	await get_tree().create_timer(0.3).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must return to PARKED after dismount")
	assert(courier_bike.occupant == null, "FAIL: Occupant must clear after dismount")
	assert(not player.is_input_locked, "FAIL: Player input must unlock after dismount")
	assert(touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: Touch UI must return to FOOT_TRAVERSAL")
	
	print("[V3_ASSERTIONS] PASSED! ALL V3 COURIER BIKE VEHICLE FEEL SLICE ASSERTIONS GREEN.")
	get_tree().quit()

func _run_v4_assertions() -> void:
	print("[V4_ASSERTIONS] Starting complete V4 Pressure & Pursuit Slice assertions...")
	await get_tree().create_timer(0.1).timeout
	_steer_input = 0.0
	_throttle_input = 0.0
	assert(pursuer != null, "FAIL: PursuerPrototype must exist")
	assert(current_pursuit_state == PursuitState.CALM, "FAIL: Pursuit state must start CALM")
	assert(not pursuer.is_active, "FAIL: Pursuer must start INACTIVE")
	
	# Gate 0 Proof 1: Siren Spatial Position Updating
	audio_mgr.set_siren_audio(true, Vector3(5, 1, 5))
	assert(audio_mgr._siren_player.global_position == Vector3(5, 1, 5), "FAIL: Siren position A must update")
	audio_mgr.set_siren_audio(true, Vector3(-10, 2, 15))
	assert(audio_mgr._siren_player.global_position == Vector3(-10, 2, 15), "FAIL: Siren position B must update while playing")
	audio_mgr.set_siren_audio(false, Vector3.ZERO)
	
	# Gate 0 Proof 2: Touch Pointer Isolation
	touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 7
	touch_down.pressed = true
	touch_down.position = Vector2(600, 300)
	touch_ui._gui_input(touch_down)
	assert(touch_ui._interaction_touch_index == 7, "FAIL: Interaction touch must acquire index 7")
	
	var wrong_drag := InputEventScreenDrag.new()
	wrong_drag.index = 9
	wrong_drag.relative = Vector2(100, 0)
	var tuner_emitted: Array = [false]
	var tune_cb := func(_df: float): tuner_emitted[0] = true
	touch_ui.tuner_dragged.connect(tune_cb)
	touch_ui._gui_input(wrong_drag)
	assert(not tuner_emitted[0], "FAIL: Wrong pointer drag must NOT emit tuner_dragged")
	
	var right_drag := InputEventScreenDrag.new()
	right_drag.index = 7
	right_drag.relative = Vector2(100, 0)
	touch_ui._gui_input(right_drag)
	assert(tuner_emitted[0], "FAIL: Matching pointer drag MUST emit tuner_dragged")
	touch_ui.tuner_dragged.disconnect(tune_cb)
	
	var wrong_up := InputEventScreenTouch.new()
	wrong_up.index = 9
	wrong_up.pressed = false
	touch_ui._gui_input(wrong_up)
	assert(touch_ui._interaction_touch_index == 7, "FAIL: Wrong pointer release must NOT clear ownership")
	
	var right_up := InputEventScreenTouch.new()
	right_up.index = 7
	right_up.pressed = false
	touch_ui._gui_input(right_up)
	assert(touch_ui._interaction_touch_index == -1, "FAIL: Matching pointer release MUST clear ownership")
	touch_ui.close_interaction_overlay()
	
	# Trigger disturbance alert
	trigger_disturbance_alert()
	assert(current_pursuit_state == PursuitState.DISTURBANCE_ALERT, "FAIL: Core extraction must trigger DISTURBANCE_ALERT")
	await get_tree().create_timer(0.85).timeout
	assert(current_pursuit_state == PursuitState.PURSUIT_ACTIVE, "FAIL: Disturbance must transition to PURSUIT_ACTIVE")
	assert(pursuer.is_active, "FAIL: Pursuer must activate")
	assert(pursuer.target_node == player, "FAIL: Pursuer target must be player on foot")
	
	# Mount bike during pursuit -> Pursuer switches target to bike
	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.5)
	await get_tree().create_timer(0.2).timeout
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	assert(pursuer.target_node == courier_bike, "FAIL: Pursuer target must switch to bike when mounted")
	
	# Accelerate bike facing open +Z straightaway to create distance > 18.0m -> Evasion
	courier_bike.rotation.y = PI
	_steer_input = 0.0
	_throttle_input = 1.0
	await get_tree().create_timer(4.5).timeout
	print("[DEBUG] Bike pos: ", courier_bike.global_position, " Pursuer pos: ", pursuer.global_position, " Dist: ", courier_bike.global_position.distance_to(pursuer.global_position))
	assert(courier_bike.global_position.distance_to(pursuer.global_position) > 18.0, "FAIL: Bike must create distance > 18m from pursuer")
	await get_tree().create_timer(3.2).timeout
	assert(current_pursuit_state == PursuitState.CONTACT_BROKEN or current_pursuit_state == PursuitState.EVADED or current_pursuit_state == PursuitState.CALM, "FAIL: Contact must break when distance > 18m")
	
	await get_tree().create_timer(1.2).timeout
	assert(current_pursuit_state == PursuitState.CALM, "FAIL: Pursuit must return to CALM after evasion")
	assert(not pursuer.is_active, "FAIL: Pursuer must deactivate after evasion")
	
	# Gate 0 Proof 3: Mounted Interception Force Dismount Recovery
	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.5)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must be DRIVING before interception")
	
	_on_pursuer_intercepted()
	await get_tree().create_timer(0.95).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Interception must reset bike state to PARKED")
	assert(courier_bike.occupant == null, "FAIL: Bike occupant must be null after interception")
	assert(not player.is_input_locked, "FAIL: Player input must unlock after interception")
	assert(touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: Touch UI must reset to FOOT_TRAVERSAL")
	assert(camera.target_node == player, "FAIL: Camera target must reset to player")
	assert(current_pursuit_state == PursuitState.CALM, "FAIL: Pursuit state must reset to CALM")
	
	print("[V4_ASSERTIONS] PASSED! ALL V4 PRESSURE & PURSUIT SLICE ASSERTIONS GREEN.")
	get_tree().quit()

func _run_v5_assertions() -> void:
	print("[V5_ASSERTIONS] Starting complete V5 Environmental Evasion / Scrap Route Switch assertions...")
	await get_tree().create_timer(0.1).timeout
	assert(signal_gate != null, "FAIL: SignalGateInteractable must exist")
	assert(signal_gate.current_state == SignalGateInteractable.GateState.DORMANT, "FAIL: SignalGate must start DORMANT")
	
	# DISTURBANCE_ALERT keeps gate DORMANT
	trigger_disturbance_alert()
	assert(signal_gate.current_state == SignalGateInteractable.GateState.DORMANT, "FAIL: DISTURBANCE_ALERT must keep gate DORMANT")
	
	# PURSUIT_ACTIVE makes gate READY
	await get_tree().create_timer(0.85).timeout
	assert(signal_gate.current_state == SignalGateInteractable.GateState.READY, "FAIL: PURSUIT_ACTIVE must make SignalGate READY")
	
	# Player mounts bike and approaches SignalGate -> Driving RouteSwitchButton becomes visible
	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.5)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	courier_bike.rotation.y = PI
	
	courier_bike.global_position = signal_gate.global_position + Vector3(0, 0, 2.5)
	signal_gate.update_player_distance(courier_bike.global_position)
	_evaluate_target_selection()
	assert(_active_target == signal_gate, "FAIL: Target selection must highlight SignalGate")
	assert(touch_ui.route_switch_button.visible, "FAIL: Driving RouteSwitchButton must become visible")
	
	# Trigger SignalGate via UI action press -> GATE_SLAM audio event & physical barrier slam
	_throttle_input = 1.0
	_on_action_pressed()
	assert(signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING, "FAIL: SignalGate must enter TRIGGERING")
	assert(signal_gate.barrier_collision.disabled, "FAIL: Barrier collision shape must remain disabled until swing completes and safety sweep volume is clear")
	await get_tree().create_timer(0.75).timeout
	assert(signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: SignalGate must enter TRIGGERED")
	assert(not signal_gate.barrier_collision.disabled, "FAIL: Barrier collision shape must activate after sweep safety check passes")
	assert(abs(signal_gate.barrier_pivot.rotation.y - deg_to_rad(90.0)) < 0.1, "FAIL: Barrier pivot must swing 90 degrees")
	assert(pursuer.current_detour_index == 0, "FAIL: SignalGate trigger must set pursuer detour path")
	
	# Continue driving bike down shortcut channel -> Pursuer steps through detour waypoints -> Evasion
	await get_tree().create_timer(3.8).timeout
	assert(pursuer.current_detour_index > 0 or pursuer.current_detour_index == -1, "FAIL: Pursuer must progress through detour waypoints")
	await get_tree().create_timer(2.2).timeout
	assert(current_pursuit_state == PursuitState.CONTACT_BROKEN or current_pursuit_state == PursuitState.EVADED or current_pursuit_state == PursuitState.CALM, "FAIL: Contact must break naturally after detour reroute")
	await get_tree().create_timer(1.2).timeout
	assert(current_pursuit_state == PursuitState.CALM, "FAIL: Pursuit must return to CALM after evasion")
	assert(signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: Triggered gate remains spent TRIGGERED after pursuit ends")
	
	print("[V5_ASSERTIONS] PASSED! ALL V5 ENVIRONMENTAL EVASION SLICE ASSERTIONS GREEN.")
	get_tree().quit()

func _export_v5_visuals() -> void:
	print("[V5_VISUALS] Exporting 6 required V5 visual screenshots to res://verification/v5/...")
	await get_tree().create_timer(0.2).timeout
	
	# 1. v5_gate_dormant.png
	get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_gate_dormant.png")
	
	# 2. v5_gate_ready.png
	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_gate_ready.png")
	
	# 3. v5_gate_triggering.png
	courier_bike.global_position = signal_gate.global_position + Vector3(0, 0, 1.5)
	courier_bike.current_state = CourierBike.BikeState.DRIVING
	signal_gate.update_player_distance(courier_bike.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.15).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_gate_triggering.png")
	
	# 4. v5_barrier_slam.png
	await get_tree().create_timer(0.45).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_barrier_slam.png")
	
	# 5. v5_pursuer_detour.png
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_pursuer_detour.png")
	
	# 6. v5_shortcut_evasion.png
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v5/v5_shortcut_evasion.png")
	
	print("[V5_VISUALS] ALL 6 V5 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	get_tree().quit()

func _export_v4_visuals() -> void:
	print("[V4_VISUALS] Exporting 6 required V4 visual screenshots to res://verification/v4/...")
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_calm.png")
	trigger_disturbance_alert()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_disturbance.png")
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_pursuit_foot.png")
	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.5)
	await get_tree().create_timer(0.2).timeout
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.15).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_mounting_under_pressure.png")
	await get_tree().create_timer(0.25).timeout
	_throttle_input = 1.0
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_driving_escape.png")
	await get_tree().create_timer(3.0).timeout
	_throttle_input = 0.0
	get_viewport().get_texture().get_image().save_png("res://verification/v4/v4_evaded_calm.png")
	print("[V4_VISUALS] ALL 6 V4 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	get_tree().quit()

func _export_v3_visuals() -> void:
	print("[V3_VISUALS] Exporting 6 required V3 visual screenshots to res://verification/v3/...")
	await get_tree().create_timer(0.2).timeout
	player.global_position = courier_bike.global_position + Vector3(0, 0, 3.5)
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_parked.png")
	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.5)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.15).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_mounting.png")
	await get_tree().create_timer(0.2).timeout
	_throttle_input = 1.0
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_driving_straight.png")
	_steer_input = 0.8
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_cornering.png")
	_steer_input = 0.0
	_throttle_input = -1.0
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_braking.png")
	_throttle_input = 0.0
	courier_bike.current_speed = 0.0
	_on_dismount_pressed()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v3/v3_dismounted.png")
	print("[V3_VISUALS] ALL 6 V3 SCREENSHOTS EXPORTED SUCCESSFULLY!")
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
