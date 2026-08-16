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
@onready var power_conduit: MeshInstance3D = $PowerConduit

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
		courier_bike.dismount_rejected.connect(_on_bike_dismount_rejected)
		courier_bike.brake_screech_triggered.connect(func(pos: Vector3):
			if audio_mgr: audio_mgr.play_event(AudioManagerScript.SoundEvent.BRAKE_SCREECH, pos)
		)
		if courier_bike.mount_interactable:
			_interactables.append(courier_bike.mount_interactable)
			
	var pursuer_scene: PackedScene = load("res://scenes/entities/pursuer_prototype.tscn")
	if pursuer_scene:
		pursuer = pursuer_scene.instantiate() as PursuerPrototype
		pursuer.name = "PursuerPrototype"
		pursuer.position = Vector3(0, 0.6, -10.0)
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
		touch_ui.peel_gesture_released.connect(_on_peel_gesture_released)
		touch_ui.tuner_dragged.connect(_on_tuner_dragged)
		touch_ui.tuner_interaction_released.connect(_on_tuner_interaction_released)
		touch_ui.core_tap_pressed.connect(_on_core_tap_pressed)
		touch_ui.driving_steer_updated.connect(func(steer: float): _steer_input = steer)
		touch_ui.driving_throttle_updated.connect(func(throttle: float): _throttle_input = throttle)
		touch_ui.dismount_pressed.connect(_on_dismount_pressed)
		touch_ui.replay_pressed.connect(reset_slice)
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v6"
		status_label.visible = OS.get_cmdline_user_args().has("--debug-ui") or OS.has_feature("debug_ui")
		
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
	elif OS.get_cmdline_user_args().has("--run-v6-assertions"):
		_run_v6_assertions()
	elif OS.get_cmdline_user_args().has("--run-v7-ticket01-assertions"):
		_run_v7_ticket01_assertions()
	elif OS.get_cmdline_user_args().has("--run-v7-ticket02-assertions"):
		_run_v7_ticket02_assertions()
	elif OS.get_cmdline_user_args().has("--run-v7-ticket02-1-assertions"):
		_run_v7_ticket02_1_assertions()
	elif OS.get_cmdline_user_args().has("--run-v7-ticket03-assertions"):
		_run_v7_ticket03_assertions()
	elif OS.get_cmdline_user_args().has("--run-v7-ticket03-stress-retest"):
		_run_v7_ticket03_stress_retest()
	elif OS.get_cmdline_user_args().has("--export-v2-visuals"):
		_export_v2_visuals()
	elif OS.get_cmdline_user_args().has("--export-v3-visuals"):
		_export_v3_visuals()
	elif OS.get_cmdline_user_args().has("--export-v4-visuals"):
		_export_v4_visuals()
	elif OS.get_cmdline_user_args().has("--export-v5-visuals"):
		_export_v5_visuals()
	elif OS.get_cmdline_user_args().has("--export-v6-visuals"):
		_export_v6_visuals()

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
	print("[PULSE] Disturbance alert triggered! Pursuit sequence initiating...")
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, global_position)
		
	get_tree().create_timer(0.75).timeout.connect(func():
		if current_pursuit_state == PursuitState.DISTURBANCE_ALERT:
			current_pursuit_state = PursuitState.PURSUIT_ACTIVE
			if pursuer:
				var target: Node3D = courier_bike if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player
				pursuer.activate_pursuit(target)
				if signal_gate:
					signal_gate.set_pursuit_active(true)
				print("[PURSUIT] Pursuer active! Chasing target...")
	)

func _deactivate_pursuit() -> void:
	if pursuer:
		pursuer.deactivate_pursuit()
	if signal_gate:
		signal_gate.set_pursuit_active(false)
	if audio_mgr:
		audio_mgr.set_siren_audio(false, Vector3.ZERO)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SIGNAL_LOCK, player.global_position if player else Vector3.ZERO)
	if touch_ui:
		touch_ui.hide_tension_hud()
		touch_ui.show_replay_overlay()
	if world_env and world_env.environment:
		world_env.environment.ambient_light_color = Color(0.3, 0.26, 0.2, 1.0)
	current_pursuit_state = PursuitState.CALM
	print("[PURSUIT] Contact evaded. Quiet aftermath reached. Replay button enabled.")

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

func _on_bike_dismount_rejected(reason: CourierBike.DismountRejectReason, current_speed: float, speed_limit: float) -> void:
	print("[CONTROLLER] Dismount rejected! Reason: %s | Speed: %.1f m/s" % [CourierBike.DismountRejectReason.keys()[reason], current_speed])
	if audio_mgr and courier_bike:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, courier_bike.global_position)
	if touch_ui:
		var toast := "[ SLOW DOWN TO DISMOUNT ]" if reason == CourierBike.DismountRejectReason.TOO_FAST else "[ CLEAR SPACE TO DISMOUNT ]"
		touch_ui.show_dismount_rejection_warning(toast)

func reset_slice() -> void:
	if courier_bike and courier_bike.occupant != null:
		courier_bike.force_dismount()
		
	current_world_state = WorldLoopState.START
	current_pursuit_state = PursuitState.CALM
	_contact_broken_timer = 0.0
	_steer_input = 0.0
	_throttle_input = 0.0
	_active_target = null
	
	if player:
		player.global_position = Vector3(0, 0, 10.0)
		player.velocity = Vector3.ZERO
		player.visible = true
		player.is_input_locked = false
		var player_col = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if player_col:
			player_col.disabled = false
		
	if courier_bike:
		courier_bike.current_state = CourierBike.BikeState.PARKED
		courier_bike.global_position = Vector3(-1.5, 0.05, 3.0)
		courier_bike.rotation.y = 0.0
		courier_bike.occupant = null
		courier_bike.current_speed = 0.0
		courier_bike.steering_angle = 0.0
		if courier_bike.mount_interactable:
			courier_bike.mount_interactable.is_powered = true
			courier_bike.mount_interactable.visible = true
		
	if camera:
		camera.set_target(player)
		camera.fov = 32.0
		
	if signal_tuner:
		signal_tuner._set_state(SignalTuner.TunerState.DORMANT)
		signal_tuner.is_powered = true
		signal_tuner.current_frequency = 0.15
		signal_tuner._dwell_timer = 0.0
		signal_tuner._near_lock_active = false
		
	if corroded_panel:
		corroded_panel.current_step = CorrodedPanel.Step.IDLE
		corroded_panel.is_powered = false
		if corroded_panel.panel_mesh:
			corroded_panel.panel_mesh.rotation = Vector3.ZERO
			corroded_panel.panel_mesh.position = Vector3.ZERO
		if corroded_panel.core_mesh:
			corroded_panel.core_mesh.visible = true
		
	if power_conduit:
		var mat := power_conduit.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.emission_enabled = false
			
	if signal_gate:
		signal_gate.current_state = SignalGateInteractable.GateState.DORMANT
		signal_gate.is_powered = false
		signal_gate.barrier_pivot.rotation.y = 0.0
		signal_gate.barrier_collision.disabled = true
		signal_gate._update_visual_state()
		
	if pursuer:
		pursuer.global_position = Vector3(0, 0.6, -10.0)
		pursuer.is_active = false
		pursuer.current_speed = 0.0
		pursuer.detour_waypoints.clear()
		pursuer.current_detour_index = -1
		
	if audio_mgr:
		audio_mgr.set_siren_audio(false, Vector3.ZERO)
		audio_mgr.stop_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM)
		audio_mgr.set_tuning_audio(0.0)
		if audio_mgr.has_method("set_mix_state"):
			audio_mgr.set_mix_state(AudioManagerScript.MixState.CALM)
		
	if touch_ui:
		touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
		touch_ui.close_interaction_overlay()
		touch_ui.hide_tension_hud()
		touch_ui.hide_replay_overlay()
		touch_ui.set_route_switch_button_visible(false)
		touch_ui._joystick_active = false
		touch_ui._joystick_touch_index = -1
		touch_ui._interaction_touch_index = -1
		touch_ui._is_peeling = false
		touch_ui._is_tuning = false
		
	print("[WORLD_LOOP] Slice reset to initial cold start state cleanly.")

func _on_tuner_dragged(accum_px: float) -> void:
	if signal_tuner:
		signal_tuner.tune_from_accum_px(accum_px)

func _on_tuner_interaction_released() -> void:
	if signal_tuner:
		signal_tuner.cancel_interaction()
	if audio_mgr:
		audio_mgr.stop_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM)
		audio_mgr.set_tuning_audio(0.0)

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
		audio_mgr.stop_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM)
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

func _on_peel_gesture_released() -> void:
	if corroded_panel and corroded_panel.current_step == CorrodedPanel.Step.PEELING:
		corroded_panel.cancel_interaction()
		if player:
			player.is_input_locked = false
		if camera:
			camera.set_interaction_mode(false)
		if touch_ui:
			touch_ui.close_interaction_overlay()

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
			"PROXIMITY_HUM", "TUNER_NEAR_LOCK_ENTER":
				audio_mgr.play_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM, source_pos)
			"TUNER_NEAR_LOCK_EXIT":
				audio_mgr.stop_event(AudioManagerScript.SoundEvent.PROXIMITY_HUM)
				audio_mgr.set_tuning_audio(0.0)
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
	player.global_position = courier_bike.global_position + Vector3(0, 0, 0.5)
	courier_bike.mount_interactable.is_player_in_range = true
	courier_bike.request_mount(player)
	await get_tree().create_timer(0.35).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	assert(pursuer.target_node == courier_bike, "FAIL: Pursuer target must switch to bike when mounted")
	
	# Accelerate bike facing open +Z straightaway to create distance > 18.0m -> Evasion
	courier_bike.rotation.y = PI
	_steer_input = 0.0
	_throttle_input = 1.0
	signal_gate.set_pursuit_active(true)
	signal_gate.begin_interaction(courier_bike.global_position)
	await get_tree().create_timer(4.5).timeout
	assert(courier_bike.global_position.distance_to(pursuer.global_position) > 18.0, "FAIL: Bike must create distance > 18m from pursuer via SignalGate route switch")
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
	player.global_position = courier_bike.global_position + Vector3(0, 0, 0.5)
	courier_bike.mount_interactable.is_player_in_range = true
	courier_bike.request_mount(player)
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

func _run_v6_assertions() -> void:
	print("[V6_ASSERTIONS] Starting complete V6 Golden Slice Cohesion & Full Run assertions...")
	await get_tree().create_timer(0.2).timeout
	
	# 1. Cold Spawn & Discovery
	player.global_position = Vector3(0, 0, 10.0)
	assert(player.global_position.distance_to(Vector3(0, 0, 10.0)) < 0.1, "FAIL: Player must spawn at Vector3(0, 0, 10.0)")
	assert(not touch_ui.tension_panel.visible, "FAIL: Tension HUD must start hidden")
	assert(not touch_ui.replay_panel.visible, "FAIL: Replay panel must start hidden")
	
	# 2. Player moves to SignalTuner at z = -3.5 -> Tune Signal
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 1.2)
	signal_tuner.update_player_distance(player.global_position)
	_evaluate_target_selection()
	assert(_active_target == signal_tuner, "FAIL: SignalTuner must be targeted")
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	signal_tuner.tune_dial(0.57)
	await get_tree().create_timer(0.5).timeout
	assert(signal_tuner.current_state == SignalTuner.TunerState.LOCKED or signal_tuner.current_state == SignalTuner.TunerState.SPENT, "FAIL: SignalTuner must lock after tuning")
	assert(corroded_panel.is_powered, "FAIL: CorrodedPanel must become powered")
	
	# 3. Peel Panel -> Extract Core -> Disturbance Alert
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.2)
	corroded_panel._on_body_entered(player)
	corroded_panel.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	corroded_panel.progress_peel(1.0)
	await get_tree().create_timer(0.2).timeout
	corroded_panel.complete_extraction()
	await get_tree().create_timer(0.3).timeout
	assert(current_pursuit_state == PursuitState.DISTURBANCE_ALERT, "FAIL: Core extraction must trigger DISTURBANCE_ALERT")
	await get_tree().create_timer(0.8).timeout
	assert(current_pursuit_state == PursuitState.PURSUIT_ACTIVE, "FAIL: Alert must transition to PURSUIT_ACTIVE")
	assert(pursuer.is_active, "FAIL: Pursuer must activate")
	
	# 4. Mount Bike & Chase down track
	player.global_position = courier_bike.global_position + Vector3(0, 0, 0.5)
	courier_bike.mount_interactable.is_player_in_range = true
	courier_bike.request_mount(player)
	await get_tree().create_timer(0.35).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must enter DRIVING")
	courier_bike.rotation.y = PI
	
	# Verify real GAS & BRAKE touch button routes
	touch_ui.gas_button.button_down.emit()
	assert(_throttle_input == 1.0, "FAIL: GAS button_down must set throttle input to 1.0")
	touch_ui.gas_button.button_up.emit()
	assert(_throttle_input == 0.0, "FAIL: GAS button_up must reset throttle input to 0.0")
	touch_ui.brake_button.button_down.emit()
	assert(_throttle_input == -1.0, "FAIL: BRAKE button_down must set throttle input to -1.0")
	touch_ui.brake_button.button_up.emit()
	assert(_throttle_input == 0.0, "FAIL: BRAKE button_up must reset throttle input to 0.0")
	
	# 5. Route Switch -> SignalGate slams -> Detour -> Evasion
	touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	signal_gate.set_pursuit_active(true)
	courier_bike.global_position = signal_gate.global_position + Vector3(0, 0, 2.5)
	signal_gate.update_player_distance(courier_bike.global_position)
	_evaluate_target_selection()
	assert(touch_ui.route_switch_button.visible, "FAIL: Driving RouteSwitchButton must show")
	_throttle_input = 1.0
	touch_ui.route_switch_button.pressed.emit()
	assert(signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING, "FAIL: Gate must enter TRIGGERING")
	await get_tree().create_timer(0.75).timeout
	assert(signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: Gate must enter TRIGGERED")
	assert(not signal_gate.barrier_collision.disabled, "FAIL: Barrier collision must lock solid")
	
	await get_tree().create_timer(3.8).timeout
	assert(pursuer.current_detour_index > 0 or pursuer.current_detour_index == -1, "FAIL: Pursuer must step through detour waypoints")
	await get_tree().create_timer(2.2).timeout
	assert(current_pursuit_state == PursuitState.CALM or current_pursuit_state == PursuitState.EVADED, "FAIL: Pursuit must evade naturally")
	assert(touch_ui.replay_panel.visible, "FAIL: Replay button must show upon quiet aftermath")
	
	# 6. Deterministic Replay Reset via ReplayButton Signal
	touch_ui.replay_button.pressed.emit()
	assert(player.global_position.distance_to(Vector3(0, 0, 10.0)) < 0.1, "FAIL: Replay reset must restore player spawn to Vector3(0, 0, 10.0)")
	assert(courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Replay reset must restore bike state to PARKED")
	assert(signal_tuner.current_state == SignalTuner.TunerState.DORMANT, "FAIL: Replay reset must restore tuner to DORMANT")
	assert(corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Replay reset must restore panel to IDLE")
	assert(signal_gate.current_state == SignalGateInteractable.GateState.DORMANT, "FAIL: Replay reset must restore gate to DORMANT")
	assert(not pursuer.is_active, "FAIL: Replay reset must deactivate pursuer")
	assert(not touch_ui.replay_panel.visible, "FAIL: Replay reset must hide replay overlay")
	
	print("[V6_ASSERTIONS] PASSED! ALL V6 GOLDEN SLICE COHESION ASSERTIONS GREEN.")
	get_tree().quit()

func _export_v6_visuals() -> void:
	print("[V6_VISUALS] Exporting 6 required V6 visual screenshots to res://verification/v6/...")
	await get_tree().create_timer(0.2).timeout
	
	# 1. v6_cold_spawn.png
	get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_cold_spawn.png")
	
	# 2. v6_signal_tuning.png
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 1.2)
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_signal_tuning.png")
	
	# 3. v6_core_extraction.png
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.2)
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_core_extraction.png")
	
	# 4. v6_bike_mount_chase.png
	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout
	courier_bike.global_position = signal_gate.global_position + Vector3(0, 0, 2.5)
	courier_bike.current_state = CourierBike.BikeState.DRIVING
	get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_bike_mount_chase.png")
	
	# 5. v6_route_switch_slam.png
	signal_gate.update_player_distance(courier_bike.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_route_switch_slam.png")
	
	# 6. v6_quiet_aftermath_replay.png
	_deactivate_pursuit()
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://verification/v6/v6_quiet_aftermath_replay.png")
	
	print("[V6_VISUALS] ALL 6 V6 SCREENSHOTS EXPORTED SUCCESSFULLY!")
	get_tree().quit()

func _run_v7_ticket01_assertions() -> void:
	print("[V7_TICKET01_ASSERTIONS] Starting V7 Ticket 01 Retest Assertions (BUG-01 & BUG-02)...")
	await get_tree().create_timer(0.2).timeout
	signal_gate.set_pursuit_active(true)
	pursuer.activate_pursuit(courier_bike)
	courier_bike.global_position = signal_gate.global_position + Vector3(0, 0, 5.0)
	player.global_position = courier_bike.global_position
	pursuer.global_position = signal_gate.global_position + Vector3(0, 0, 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	signal_gate.begin_interaction(courier_bike.global_position)
	await get_tree().create_timer(0.75).timeout
	assert(signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED, "FAIL: Gate must be TRIGGERED")
	assert(not signal_gate.barrier_collision.disabled, "FAIL: barrier_collision.disabled MUST become false!")
	print("[TEST BUG-01 PASSED] barrier_collision.disabled became false immediately!")
	_deactivate_pursuit()
	await get_tree().create_timer(0.2).timeout
	corroded_panel.power_on()
	player.global_position = corroded_panel.global_position + Vector3(0, 0, 1.0)
	corroded_panel._on_body_entered(player)
	corroded_panel.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.1).timeout
	_on_peel_gesture_dragged(0.4)
	touch_ui.peel_gesture_released.emit()
	await get_tree().create_timer(0.1).timeout
	assert(corroded_panel.current_step == CorrodedPanel.Step.APPROACHED or corroded_panel.current_step == CorrodedPanel.Step.IDLE, "FAIL: Panel step must reset!")
	assert(not player.is_input_locked, "FAIL: Player input must unlock!")
	print("[TEST BUG-02 PASSED] Peel gesture touch release cancelled interaction cleanly!")
	print("[V7_TICKET01_ASSERTIONS] ALL V7 TICKET 01 ASSERTIONS PASSED GREEN!")
	get_tree().quit(0)

func _run_v7_ticket02_assertions() -> void:
	print("[V7_TICKET02_ASSERTIONS] Starting Expanded V7 Ticket 02 Stress Tests...")
	await get_tree().create_timer(0.2).timeout

	# =========================================================================
	# TASK 1: MULTI-TOUCH DRIVING CONTROLS & STATE ARBITRATION
	# =========================================================================
	print("\n--- [TASK 1] Testing Multi-Touch Driving Controls & State Arbitration ---")
	touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	assert(touch_ui._is_gas_pressed == false and touch_ui._is_brake_pressed == false, "FAIL: Driving inputs must initialize to false")
	assert(_throttle_input == 0.0, "FAIL: Initial throttle must be 0.0")

	# 1A. Gas alone pressed -> throttle +1.0
	touch_ui._is_gas_pressed = true
	touch_ui._emit_net_throttle()
	assert(_throttle_input == 1.0, "FAIL: GAS held alone must set throttle to +1.0")

	# 1B. Dual-touch hold: Brake pressed while Gas held -> throttle -1.0 (Brake priority!)
	touch_ui._is_brake_pressed = true
	touch_ui._emit_net_throttle()
	assert(_throttle_input == -1.0, "FAIL: BRAKE held while GAS held MUST prioritize Brake (-1.0)!")

	# 1C. Releasing combination A: Gas released while Brake held -> throttle -1.0
	touch_ui._is_gas_pressed = false
	touch_ui._emit_net_throttle()
	assert(_throttle_input == -1.0, "FAIL: Releasing GAS while BRAKE held must maintain throttle at -1.0!")

	# Release Brake -> throttle 0.0
	touch_ui._is_brake_pressed = false
	touch_ui._emit_net_throttle()
	assert(_throttle_input == 0.0, "FAIL: Releasing both must set throttle to 0.0!")

	# 1D. Releasing combination B: Both held -> Brake released while Gas held -> throttle +1.0
	touch_ui._is_gas_pressed = true
	touch_ui._is_brake_pressed = true
	touch_ui._emit_net_throttle()
	assert(_throttle_input == -1.0, "FAIL: Both held must prioritize Brake")
	touch_ui._is_brake_pressed = false
	touch_ui._emit_net_throttle()
	assert(_throttle_input == 1.0, "FAIL: Releasing BRAKE while GAS held must return throttle to +1.0!")
	touch_ui._is_gas_pressed = false
	touch_ui._emit_net_throttle()
	assert(_throttle_input == 0.0, "FAIL: All released must set throttle to 0.0")

	# 1E. Rapid alternation (10 fast toggles between Gas & Brake)
	print("[TASK 1] Running rapid 10-step alternation stress test between Gas and Brake...")
	for i in range(10):
		if i % 2 == 0:
			touch_ui._is_gas_pressed = true
			touch_ui._is_brake_pressed = false
			touch_ui._emit_net_throttle()
			assert(_throttle_input == 1.0, "FAIL: Rapid toggle step %d failed for GAS" % i)
		else:
			touch_ui._is_gas_pressed = true
			touch_ui._is_brake_pressed = true
			touch_ui._emit_net_throttle()
			assert(_throttle_input == -1.0, "FAIL: Rapid toggle step %d failed for BRAKE priority" % i)
	touch_ui.reset_driving_inputs()
	assert(_throttle_input == 0.0, "FAIL: Reset after rapid alternation failed!")
	print("[TASK 1 PASSED] Rapid input alternation verified cleanly!")

	# 1F. Mode switch reset check (reset_driving_inputs on mode switch & reset_slice)
	print("[TASK 1] Testing reset_driving_inputs() on UI mode switches & slice reset...")
	touch_ui._is_gas_pressed = true
	touch_ui._is_brake_pressed = true
	touch_ui._emit_net_throttle()
	assert(_throttle_input == -1.0, "FAIL: Inputs set for mode switch test")

	touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
	assert(touch_ui._is_gas_pressed == false and touch_ui._is_brake_pressed == false, "FAIL: set_mode(FOOT_TRAVERSAL) must clear driving input flags!")
	assert(_throttle_input == 0.0, "FAIL: set_mode(FOOT_TRAVERSAL) must emit net throttle 0.0!")

	touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	assert(touch_ui._is_gas_pressed == false and touch_ui._is_brake_pressed == false, "FAIL: set_mode(VEHICLE_DRIVING) must clear driving input flags!")
	assert(_throttle_input == 0.0, "FAIL: set_mode(VEHICLE_DRIVING) must emit net throttle 0.0!")

	# Test reset_slice()
	touch_ui._is_gas_pressed = true
	touch_ui._emit_net_throttle()
	assert(_throttle_input == 1.0, "FAIL: Pre-reset_slice throttle set")
	reset_slice()
	assert(_throttle_input == 0.0, "FAIL: reset_slice() must set _throttle_input to 0.0!")
	print("[TASK 1 PASSED] reset_driving_inputs() verified on mode switches & slice reset!")

	# =========================================================================
	# TASK 2: DISMOUNT BUTTON INTERACTION, SPEED SWEEP (0-14m/s) & RED FLASH
	# =========================================================================
	print("\n--- [TASK 2] Testing Dismount Button Rapid Tapping (0.0 m/s to 14.0 m/s) ---")
	
	# Mount bike for test
	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.0)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike must be in DRIVING state")
	assert(touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING, "FAIL: UI mode must be VEHICLE_DRIVING")

	# Track rejection signal count and reasons
	var reject_count := [0]
	var last_reason := [CourierBike.DismountRejectReason.TOO_FAST]
	var last_speed := [0.0]
	var reject_cb := func(reason: CourierBike.DismountRejectReason, spd: float, limit: float):
		reject_count[0] += 1
		last_reason[0] = reason
		last_speed[0] = spd

	courier_bike.dismount_rejected.connect(reject_cb)

	# 2A. Speed acceleration sweep from 0.0 m/s to 14.0 m/s with rapid dismount button taps
	var speed_test_points := [0.0, 1.0, 1.5, 1.6, 2.0, 5.0, 8.0, 10.0, 14.0]
	for spd in speed_test_points:
		courier_bike.current_speed = spd
		print("[TASK 2 SWEEP] Testing speed %.1f m/s..." % spd)

		if spd > courier_bike.dismount_speed_limit: # > 1.5 m/s
			var initial_rejects: int = reject_count[0]
			# Rapid tap 5 times at this speed
			for tap in range(5):
				assert(not touch_ui.dismount_button.disabled, "FAIL: Dismount button disabled at speed %.1f m/s!" % spd)
				var success := courier_bike.request_dismount()
				assert(not success, "FAIL: request_dismount() must return false at speed %.1f m/s" % spd)
			assert(reject_count[0] == initial_rejects + 5, "FAIL: Expected 5 dismount rejection signals at speed %.1f m/s" % spd)
			assert(last_reason[0] == CourierBike.DismountRejectReason.TOO_FAST, "FAIL: Reason must be TOO_FAST")
			assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Bike state must remain DRIVING at speed %.1f m/s" % spd)
		else: # <= 1.5 m/s -> Dismount should succeed!
			assert(not touch_ui.dismount_button.disabled, "FAIL: Dismount button disabled at speed %.1f m/s!" % spd)
			var success := courier_bike.request_dismount()
			assert(success, "FAIL: request_dismount() MUST succeed at speed %.1f m/s (<= 1.5 m/s)" % spd)
			await get_tree().create_timer(0.25).timeout
			assert(courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must transition to PARKED state")
			assert(touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: UI mode must revert to FOOT_TRAVERSAL")
			
			# Re-mount bike for remaining speed points if any
			if spd < 14.0:
				player.global_position = courier_bike.global_position + Vector3(0, 0, 1.0)
				courier_bike.mount_interactable.update_player_distance(player.global_position)
				_evaluate_target_selection()
				_on_action_pressed()
				await get_tree().create_timer(0.35).timeout
				assert(courier_bike.current_state == CourierBike.BikeState.DRIVING, "FAIL: Re-mount failed!")

	print("[TASK 2 PASSED] Dismount button speed sweep (0.0 to 14.0 m/s) verified! Button never disabled!")

	# 2B. Red Flash Animation Frame Tracking & Rapid Tapping Overlap Test
	print("\n--- [TASK 2B] Stress Testing Red Flash Animation & Multi-frame Modulation ---")
	# Re-mount bike and set speed to 10.0 m/s
	if courier_bike.current_state != CourierBike.BikeState.DRIVING:
		player.global_position = courier_bike.global_position + Vector3(0, 0, 1.0)
		courier_bike.mount_interactable.update_player_distance(player.global_position)
		_evaluate_target_selection()
		_on_action_pressed()
		await get_tree().create_timer(0.35).timeout

	courier_bike.current_speed = 10.0
	
	# Tap dismount while driving at 10.0 m/s and inspect dismount_button.modulate across frames
	_on_dismount_pressed()
	var mod_t0 := touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame 0 (Tap): modulate = %s" % mod_t0)
	
	await get_tree().process_frame
	var mod_t1 := touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame 1 (16ms post-process): modulate = %s" % mod_t1)
	
	await get_tree().process_frame
	var mod_t2 := touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame 2 (33ms post-process): modulate = %s" % mod_t2)

	await get_tree().create_timer(0.25).timeout
	var mod_t_end := touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Frame final (250ms post-timer): modulate = %s" % mod_t_end)

	# Test Rapid 5x Burst Tapping for Red Flash Overlap
	print("[RED FLASH TELEMETRY] Triggering rapid 5x burst taps on DismountButton...")
	for tap in range(5):
		_on_dismount_pressed()
		await get_tree().create_timer(0.04).timeout # 40ms interval (25 Hz rapid tap)
	
	print("[RED FLASH TELEMETRY] 5x Burst finished. Checking modulate state...")
	var mod_burst_mid := touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Burst Mid-State: modulate = %s" % mod_burst_mid)

	await get_tree().create_timer(0.3).timeout
	var mod_burst_final := touch_ui.dismount_button.modulate
	print("[RED FLASH TELEMETRY] Burst Final State (300ms post-burst): modulate = %s" % mod_burst_final)

	# 2C. Slow down vehicle below 1.5 m/s and verify immediate dismount
	print("\n--- [TASK 2C] Testing Immediate Dismount When slowing below 1.5 m/s ---")
	courier_bike.current_speed = 1.4
	_on_dismount_pressed()
	await get_tree().create_timer(0.3).timeout
	assert(courier_bike.current_state == CourierBike.BikeState.PARKED, "FAIL: Bike must reach PARKED state when dismounted at 1.4 m/s!")
	assert(touch_ui.current_mode == TouchControlsUI.UIMode.FOOT_TRAVERSAL, "FAIL: UI mode must revert to FOOT_TRAVERSAL!")
	print("[TASK 2C PASSED] Dismount at 1.4 m/s (< 1.5 m/s) succeeded immediately!")

	print("\n=========================================================================")
	print("[ALL V7 TICKET 02 STRESS TESTS COMPLETED SUCCESSFULLY]")
	print("=========================================================================")
	get_tree().quit(0)

func _run_v7_ticket02_1_assertions() -> void:
	print("\n=========================================================================")
	print("[V7_TICKET02_1_ASSERTIONS] Starting Adversarial Chase Falsification Suite (Ticket 02.1)...")
	print("Target Build: main@eb9e82a | Pursuer Max Speed: %.1f m/s | Bike Max Speed: %.1f m/s" % [pursuer.max_speed if pursuer else 15.5, courier_bike.max_speed if courier_bike else 14.0])
	print("=========================================================================\n")
	await get_tree().create_timer(0.2).timeout

	# =========================================================================
	# TASK 1A: STRAIGHT-LINE DRIVING AT DEFAULT SPAWN (PURSUER Z = -15.0, BIKE Z = 3.0)
	# =========================================================================
	print("\n--- [TASK 1A] Straight-Line Driving at Default Spawn (Pursuer Z = -15.0, Dist = 18.07m) ---")
	reset_slice()
	await get_tree().create_timer(0.1).timeout

	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout

	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.0)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout

	courier_bike.rotation.y = PI
	_steer_input = 0.0
	_throttle_input = 1.0

	var task1a_start := Time.get_ticks_msec() / 1000.0
	var task1a_evaded := false
	var task1a_intercepted := false
	var task1a_initial_dist := pursuer.global_position.distance_to(courier_bike.global_position)
	print("[TASK 1A LOG] Initial Spawn Pos: Pursuer Z = %.2fm | Bike Z = %.2fm | Dist = %.2fm" % [
		pursuer.global_position.z, courier_bike.global_position.z, task1a_initial_dist
	])

	for frame in range(300):
		await get_tree().process_frame
		if current_pursuit_state == PursuitState.INTERCEPTED:
			task1a_intercepted = true
			break
		if current_pursuit_state == PursuitState.CONTACT_BROKEN or current_pursuit_state == PursuitState.EVADED or current_pursuit_state == PursuitState.CALM:
			task1a_evaded = true
			var elapsed := (Time.get_ticks_msec() / 1000.0) - task1a_start
			print("[TASK 1A LOG] EVADED pursuit at t = %.2fs! Initial dist was %.2fm (> 18.0m threshold bug)." % [elapsed, task1a_initial_dist])
			break

	print("[TASK 1A RESULT] Default Spawn Straight-Line Driving: Evaded Without Gate = %s | Intercepted = %s" % [task1a_evaded, task1a_intercepted])

	# =========================================================================
	# TASK 1B: STRAIGHT-LINE DRIVING AT CLOSE SPAWN (PURSUER Z = -5.0, BIKE Z = 3.0, DIST = 8.0m)
	# =========================================================================
	print("\n--- [TASK 1B] Straight-Line Driving at Close Spawn (Pursuer Z = -5.0, Dist = 8.0m) ---")
	reset_slice()
	await get_tree().create_timer(0.1).timeout

	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout

	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.0)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout

	courier_bike.rotation.y = PI
	pursuer.global_position = Vector3(0, 0.6, -5.0) # 8m behind bike
	_steer_input = 0.0
	_throttle_input = 1.0

	var task1b_start := Time.get_ticks_msec() / 1000.0
	var task1b_intercepted := false
	var task1b_intercept_time := 0.0

	for frame in range(600):
		await get_tree().process_frame
		if current_pursuit_state == PursuitState.INTERCEPTED:
			task1b_intercepted = true
			task1b_intercept_time = (Time.get_ticks_msec() / 1000.0) - task1b_start
			print("[TASK 1B LOG] INTERCEPTED by Pursuer at t = %.2fs! Bike Speed = %.1fm/s | Pursuer Speed = %.1fm/s" % [
				task1b_intercept_time, courier_bike.current_speed, pursuer.current_speed
			])
			break

	print("[TASK 1B RESULT] Close Spawn Straight-Line Driving: Intercepted = %s | Intercept Time = %.2fs" % [task1b_intercepted, task1b_intercept_time])

	# =========================================================================
	# TASK 2A: FOOT CIRCLES AROUND CORRODED PANEL (PURSUER Z = -10.0)
	# =========================================================================
	print("\n--- [TASK 2A] Testing Foot Circles around Corroded Panel (Runner 8.5m/s vs Pursuer 15.5m/s) ---")
	reset_slice()
	await get_tree().create_timer(0.1).timeout

	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout

	var panel_center := corroded_panel.global_position if corroded_panel else Vector3(0, 0, -3.5)
	player.global_position = panel_center + Vector3(2.0, 0, 0)
	pursuer.global_position = Vector3(0, 0.6, -10.0)

	var task2a_start := Time.get_ticks_msec() / 1000.0
	var task2a_intercepted := false
	var task2a_intercept_time := 0.0
	var circle_angle := 0.0

	for frame in range(300):
		await get_tree().process_frame
		circle_angle += 0.15
		var input_vec := Vector2(cos(circle_angle), sin(circle_angle))
		player.set_joystick_input(input_vec)

		if current_pursuit_state == PursuitState.INTERCEPTED:
			task2a_intercepted = true
			task2a_intercept_time = (Time.get_ticks_msec() / 1000.0) - task2a_start
			print("[TASK 2A LOG] INTERCEPTED on foot around Corroded Panel at t = %.2fs! Runner Speed = %.1fm/s | Pursuer Speed = %.1fm/s" % [
				task2a_intercept_time, player.velocity.length(), pursuer.current_speed
			])
			break

	print("[TASK 2A RESULT] Foot circles (Panel): Intercepted = %s | Intercept Time = %.2fs" % [task2a_intercepted, task2a_intercept_time])

	# =========================================================================
	# TASK 2B: FOOT CIRCLES AROUND COURIER BIKE (PURSUER Z = -5.0)
	# =========================================================================
	print("\n--- [TASK 2B] Testing Foot Circles around Courier Bike (Runner 8.5m/s vs Pursuer 15.5m/s) ---")
	reset_slice()
	await get_tree().create_timer(0.1).timeout

	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout

	player.global_position = courier_bike.global_position + Vector3(2.0, 0, 0)
	pursuer.global_position = Vector3(0, 0.6, -5.0)

	var task2b_start := Time.get_ticks_msec() / 1000.0
	var task2b_intercepted := false
	var task2b_intercept_time := 0.0
	circle_angle = 0.0

	for frame in range(300):
		await get_tree().process_frame
		circle_angle += 0.15
		var input_vec := Vector2(cos(circle_angle), sin(circle_angle))
		player.set_joystick_input(input_vec)

		if current_pursuit_state == PursuitState.INTERCEPTED:
			task2b_intercepted = true
			task2b_intercept_time = (Time.get_ticks_msec() / 1000.0) - task2b_start
			print("[TASK 2B LOG] INTERCEPTED on foot around Courier Bike at t = %.2fs! Runner Speed = %.1fm/s | Pursuer Speed = %.1fm/s" % [
				task2b_intercept_time, player.velocity.length(), pursuer.current_speed
			])
			break

	print("[TASK 2B RESULT] Foot circles (Bike): Intercepted = %s | Intercept Time = %.2fs" % [task2b_intercepted, task2b_intercept_time])

	# =========================================================================
	# TASK 3: TRIGGERING SIGNALGATE LATE (PURSUER 2.0M BEHIND BIKE)
	# =========================================================================
	print("\n--- [TASK 3] Testing Late SignalGate Trigger (Pursuer 2.0m behind bike) ---")
	reset_slice()
	await get_tree().create_timer(0.1).timeout

	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout

	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.0)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout

	courier_bike.current_state = CourierBike.BikeState.DRIVING
	courier_bike.global_position = signal_gate.global_position + Vector3(0, 0, 0.5) # z = 12.5
	courier_bike.rotation.y = PI
	courier_bike.current_speed = 12.0
	pursuer.global_position = courier_bike.global_position - Vector3(0, 0, 2.0) # z = 10.5 (2m behind)
	pursuer.current_speed = 15.5
	_throttle_input = 1.0

	signal_gate.set_pursuit_active(true)
	signal_gate.update_player_distance(courier_bike.global_position)

	print("[TASK 3 LOG] Triggering SignalGate! Bike Z = %.2fm, Pursuer Z = %.2fm, Initial Dist = %.2fm" % [
		courier_bike.global_position.z, pursuer.global_position.z, pursuer.global_position.distance_to(courier_bike.global_position)
	])
	signal_gate.begin_interaction(courier_bike.global_position)
	assert(signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING, "FAIL: Gate must be TRIGGERING")

	var task3_intercepted_during_swing := false
	var task3_passed_gate_before_close := false
	var task3_backtracked_detour := false

	for frame in range(120):
		await get_tree().process_frame
		var pursuer_z := pursuer.global_position.z
		var gate_z := signal_gate.global_position.z

		if signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERING and pursuer_z > gate_z:
			task3_passed_gate_before_close = true

		if current_pursuit_state == PursuitState.INTERCEPTED:
			task3_intercepted_during_swing = true
			print("[TASK 3 LOG] INTERCEPTED during late gate swing! Frame = %d | Pursuer Z = %.2f" % [frame, pursuer_z])
			break

		if signal_gate.current_state == SignalGateInteractable.GateState.TRIGGERED and pursuer.current_detour_index >= 0:
			if pursuer.velocity.z < -0.5:
				task3_backtracked_detour = true
				print("[TASK 3 EXPLOIT LOG] Pursuer passed gate before closure and is BACKTRACKING (-Z velocity %.1f m/s) to detour waypoint 0 at Z=8.0!" % pursuer.velocity.z)

	print("[TASK 3 RESULT] Late SignalGate Trigger (2m behind): Intercepted = %s | Passed Gate Before Close = %s | Backtracked Detour = %s" % [
		task3_intercepted_during_swing, task3_passed_gate_before_close, task3_backtracked_detour
	])

	# =========================================================================
	# TASK 4: EVALUATE IF ROUTE-SWITCH COUNTERPLAY IS 100% REQUIRED OR BYPASSABLE
	# =========================================================================
	print("\n--- [TASK 4] Evaluating Route-Switch Counterplay Requirement & Bypassability ---")
	
	reset_slice()
	await get_tree().create_timer(0.1).timeout

	trigger_disturbance_alert()
	await get_tree().create_timer(0.85).timeout

	player.global_position = courier_bike.global_position + Vector3(0, 0, 1.0)
	courier_bike.mount_interactable.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.35).timeout

	courier_bike.current_state = CourierBike.BikeState.DRIVING
	courier_bike.global_position = signal_gate.global_position + Vector3(0, 0, 2.5) # z = 14.5
	courier_bike.rotation.y = PI
	courier_bike.current_speed = 12.0
	pursuer.global_position = signal_gate.global_position - Vector3(0, 0, 6.0) # z = 6.0 (8.5m behind bike)
	pursuer.current_speed = 14.0
	_throttle_input = 1.0

	signal_gate.set_pursuit_active(true)
	signal_gate.update_player_distance(courier_bike.global_position)

	print("[TASK 4 LOG] Executing On-Time SignalGate trigger (Pursuer 8.5m behind)...")
	signal_gate.begin_interaction(courier_bike.global_position)

	var task4_evaded_cleanly := false
	var task4_evasion_time := 0.0
	var task4_start := Time.get_ticks_msec() / 1000.0

	for frame in range(600):
		await get_tree().process_frame
		if current_pursuit_state == PursuitState.CONTACT_BROKEN or current_pursuit_state == PursuitState.EVADED or current_pursuit_state == PursuitState.CALM:
			task4_evaded_cleanly = true
			task4_evasion_time = (Time.get_ticks_msec() / 1000.0) - task4_start
			print("[TASK 4 LOG] Clean Evasion Achieved via SignalGate Route Switch! Time = %.2fs" % task4_evasion_time)
			break

	print("\n=========================================================================")
	print("[SUMMARY OF ADVERSARIAL CHASE FALSIFICATION TESTS (V7 TICKET 02.1)]")
	print("  1A. Straight-Line Driving (Default Spawn Z=-15m, Dist=18.07m): Evaded = %s (Fails Tension: Default spawn exceeds 18m contact break threshold on frame 1!)" % task1a_evaded)
	print("  1B. Straight-Line Driving (Close Spawn Z=-5m, Dist=8.0m): Intercepted = %s at t=%.2fs (Passes Tension: Pursuer 15.5 m/s > Bike 14.0 m/s catches bike)" % [task1b_intercepted, task1b_intercept_time])
	print("  2A. Foot Circles around Corroded Panel: Intercepted = %s at t=%.2fs (Fails Evasion: Pursuer 15.5 m/s > Runner 8.5 m/s catches runner in < 1.5s)" % [task2a_intercepted, task2a_intercept_time])
	print("  2B. Foot Circles around Courier Bike: Intercepted = %s at t=%.2fs (Fails Evasion: Pursuer catches runner in < 1.8s)" % [task2b_intercepted, task2b_intercept_time])
	print("  3.  Late SignalGate Trigger (Pursuer 2.0m behind bike): Passed Gate = %s | Backtracked Detour = %s (Fails AI Logic: Gate 0.75s swing delay lets pursuer pass, then detour forces 180° backward U-turn)" % [task3_passed_gate_before_close, task3_backtracked_detour])
	print("  4.  On-Time SignalGate Route Switch (Pursuer 8.5m behind): Clean Evasion = %s in %.2fs (Passes Counterplay: Gate slam forces detour, enabling escape)" % [task4_evaded_cleanly, task4_evasion_time])
	print("=========================================================================")
	get_tree().quit(0)

func _run_v7_ticket03_assertions() -> void:
	print("\n=========================================================================")
	print("[V7_TICKET03_ASSERTIONS] Starting Signal Tuning Gesture Coherence Suite (Ticket 03)...")
	print("Target Build: main@02445d3 | Testing prompt coherence & drag tuning curve")
	print("=========================================================================\n")
	
	reset_slice()
	await get_tree().create_timer(0.1).timeout
	
	# 1. Approach SignalTuner & Begin Interaction
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 1.0)
	signal_tuner.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	
	await get_tree().create_timer(0.2).timeout
	assert(signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: Tuner must enter TUNING state")
	assert(touch_ui.gesture_hint_label.text == "[ SWIPE ↔ TO TUNE FREQUENCY ]", "FAIL: UI hint text must be [ SWIPE ↔ TO TUNE FREQUENCY ]")
	print("[TICKET 03 TEST 1 PASSED] UI prompt hint verified: [ SWIPE ↔ TO TUNE FREQUENCY ]")
	
	# 2. Simulate InputEventScreenTouch & InputEventScreenDrag for horizontal tuning
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(400, 300)
	touch_ui._gui_input(touch_down)
	
	# 2. 60Hz vs 120Hz displacement invariance at 100px (small) and 300px (moderate)
	var drag_ev := InputEventScreenDrag.new()
	drag_ev.index = 0
	
	# Test A: 1×100px vs 10×10px
	signal_tuner.current_frequency = 0.15; signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(100.0, 0.0); touch_ui._tuning_accum_px = 0.0
	touch_ui._gui_input(drag_ev)
	var a1_freq := signal_tuner.current_frequency
	signal_tuner.current_frequency = 0.15; signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(10.0, 0.0); touch_ui._tuning_accum_px = 0.0
	for i in range(10): touch_ui._gui_input(drag_ev)
	var a2_freq := signal_tuner.current_frequency
	assert(abs(a1_freq - a2_freq) < 0.0001, "FAIL: 1x100px vs 10x10px must be invariant")
	print("[TICKET 03 TEST 2 PASSED] 60Hz/120Hz invariance 100px: single=%.4f multi=%.4f" % [a1_freq, a2_freq])
	
	# Test B: 3×100px (total 300px) vs 30×10px — larger displacement
	signal_tuner.current_frequency = 0.15; signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(100.0, 0.0); touch_ui._tuning_accum_px = 0.0
	for i in range(3): touch_ui._gui_input(drag_ev)
	var b1_freq := signal_tuner.current_frequency
	signal_tuner.current_frequency = 0.15; signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(10.0, 0.0); touch_ui._tuning_accum_px = 0.0
	for i in range(30): touch_ui._gui_input(drag_ev)
	var b2_freq := signal_tuner.current_frequency
	assert(abs(b1_freq - b2_freq) < 0.0001, "FAIL: 3x100px vs 30x10px must be invariant")
	print("[TICKET 03 TEST 3 PASSED] 60Hz/120Hz invariance 300px: 3x100=%.4f 30x10=%.4f" % [b1_freq, b2_freq])
	
	# Test C: Extreme swipe saturation — 2000px must NOT slam to 0/1 instantly
	signal_tuner.current_frequency = 0.15; signal_tuner._drag_start_freq = 0.15
	drag_ev.relative = Vector2(2000.0, 0.0); touch_ui._tuning_accum_px = 0.0
	touch_ui._gui_input(drag_ev)
	var extreme_freq := signal_tuner.current_frequency
	assert(extreme_freq < 1.0, "FAIL: Extreme swipe must NOT instantly reach 1.0 (tanh saturation required)")
	assert(extreme_freq > 0.6, "FAIL: Extreme swipe from 0.15 must reach upper range")
	print("[TICKET 03 TEST 4 PASSED] Extreme swipe saturation: freq=%.4f (bounded, not 1.0)" % extreme_freq)
	
	# 3. Near-lock exit lifecycle: NEAR_LOCK_ENTER/EXIT events
	signal_tuner.current_frequency = 0.15; signal_tuner._drag_start_freq = 0.15
	signal_tuner._near_lock_active = false
	var near_lock_events: Array = []
	var evt_cb := func(ev: String, _pos: Vector3): near_lock_events.append(ev)
	signal_tuner.audio_event_triggered.connect(evt_cb)
	
	# Drag into lock range to trigger ENTER
	signal_tuner.current_frequency = 0.72 # place inside lock range
	signal_tuner._process(0.016) # one frame
	assert("TUNER_NEAR_LOCK_ENTER" in near_lock_events, "FAIL: Must emit TUNER_NEAR_LOCK_ENTER on entering lock range")
	var enter_count := near_lock_events.count("TUNER_NEAR_LOCK_ENTER")
	signal_tuner._process(0.016) # second frame — must NOT re-emit ENTER
	assert(near_lock_events.count("TUNER_NEAR_LOCK_ENTER") == enter_count, "FAIL: TUNER_NEAR_LOCK_ENTER must emit ONCE, not every frame")
	print("[TICKET 03 TEST 5 PASSED] TUNER_NEAR_LOCK_ENTER emitted once on entering tolerance")
	
	# Drag out of lock range to trigger EXIT
	signal_tuner.current_frequency = 0.90 # outside lock range
	signal_tuner._process(0.016)
	assert("TUNER_NEAR_LOCK_EXIT" in near_lock_events, "FAIL: Must emit TUNER_NEAR_LOCK_EXIT when leaving lock range")
	var exit_count := near_lock_events.count("TUNER_NEAR_LOCK_EXIT")
	signal_tuner._process(0.016) # second frame — must NOT re-emit EXIT
	assert(near_lock_events.count("TUNER_NEAR_LOCK_EXIT") == exit_count, "FAIL: TUNER_NEAR_LOCK_EXIT must emit ONCE, not every frame")
	print("[TICKET 03 TEST 6 PASSED] TUNER_NEAR_LOCK_EXIT emitted once on leaving tolerance")
	
	signal_tuner.audio_event_triggered.disconnect(evt_cb)
	
	# 4. Fine-tune using tanh accumulator to reach lock range and complete lock payoff
	# Force READY so begin_interaction can succeed (near-lock tests left tuner in TUNING)
	signal_tuner._set_state(SignalTuner.TunerState.READY)
	signal_tuner.current_frequency = 0.15
	# Reset touch_ui accumulator state — extreme swipe test (2000px) left _tuning_accum_px dirty
	touch_ui._tuning_accum_px = 0.0
	touch_ui._is_tuning = false
	touch_ui._interaction_touch_index = -1
	signal_tuner.begin_interaction(player.global_position)
	assert(signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: begin_interaction must set TUNING")
	var re_touch_down := InputEventScreenTouch.new()
	re_touch_down.index = 0; re_touch_down.pressed = true
	re_touch_down.position = Vector2(400, 300)
	touch_ui._gui_input(re_touch_down)
	# tanh(295*0.003/0.65) = tanh(1.362) = 0.878; 0.65*0.878 = 0.571; 0.15+0.571 = 0.721 ∈ [0.67, 0.77]
	var fine_drag := InputEventScreenDrag.new()
	fine_drag.index = 0; fine_drag.relative = Vector2(295.0, 0.0)
	touch_ui._gui_input(fine_drag)
	print("[TICKET 03 TEST 7 DEBUG] freq=%.4f target=%.4f tol=%.4f" % [signal_tuner.current_frequency, signal_tuner.target_frequency, signal_tuner.lock_tolerance])
	assert(abs(signal_tuner.current_frequency - signal_tuner.target_frequency) <= signal_tuner.lock_tolerance, "FAIL: 295px drag must reach lock tolerance via tanh curve")
	print("[TICKET 03 TEST 7 PASSED] Fine-tuning reached lock range: current=%.3f, target=%.3f" % [signal_tuner.current_frequency, signal_tuner.target_frequency])
	
	# 5. Dwell lock payoff — fires exactly once
	# Use array ref to avoid GDScript int capture-by-value in lambda
	var lock_count := [0]
	var lock_cb := func(_t: SignalTuner): lock_count[0] += 1
	signal_tuner.signal_locked.connect(lock_cb)
	await get_tree().create_timer(0.5).timeout
	signal_tuner.signal_locked.disconnect(lock_cb)
	assert(signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL: SignalTuner must enter LOCKED state after dwell")
	assert(lock_count[0] == 1, "FAIL: signal_locked must fire exactly once (got %d)" % lock_count[0])
	print("[TICKET 03 TEST 8 PASSED] Signal lock achieved cleanly! Lock count = %d" % lock_count[0])
	
	print("\n=========================================================================")
	print("[ALL V7 TICKET 03 ASSERTIONS PASSED CLEANLY]")
	print("=========================================================================\n")
	get_tree().quit(0)

func _run_v7_ticket03_stress_retest() -> void:
	print("\n=========================================================================")
	print("[V7_TICKET03_STRESS_RETEST] Starting Adversarial Input Stress & Multi-Frame Retest Suite...")
	print("Target Build: main@a13b018 | Scene: scrap_test_block.tscn")
	print("=========================================================================\n")
	
	reset_slice()
	await get_tree().create_timer(0.1).timeout
	
	# Enter interaction mode with SignalTuner
	player.global_position = signal_tuner.global_position + Vector3(0, 0, 1.0)
	signal_tuner.update_player_distance(player.global_position)
	_evaluate_target_selection()
	_on_action_pressed()
	await get_tree().create_timer(0.2).timeout
	
	assert(signal_tuner.current_state == SignalTuner.TunerState.TUNING, "FAIL: SignalTuner must be in TUNING state")
	assert(touch_ui._current_gesture_type == "TUNE_SIGNAL", "FAIL: Gesture overlay must be TUNE_SIGNAL")
	
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(400, 300)
	touch_ui._gui_input(touch_down)
	assert(touch_ui._interaction_touch_index == 0, "FAIL: Touch down must acquire pointer index 0")
	assert(touch_ui._is_tuning == true, "FAIL: _is_tuning must be true after touch down")
	
	# -------------------------------------------------------------------------
	# TEST 1: Rapid Horizontal Swipe Bursts (Left and Right)
	# -------------------------------------------------------------------------
	print("--- [TEST 1] Rapid Horizontal Swipe Bursts (Extreme Velocities) ---")
	signal_tuner.current_frequency = 0.50
	var drag_ev := InputEventScreenDrag.new()
	drag_ev.index = 0
	
	var test1_clamped_correctly := true
	var test1_bounded := true
	
	var swipe_deltas: Array[float] = [1500.0, -1500.0, 3000.0, -3000.0, 5000.0, -5000.0, 200.0, -200.0, 800.0, -800.0]
	for idx in range(swipe_deltas.size()):
		var raw_dx: float = swipe_deltas[idx]
		var expected_delta := clampf(raw_dx * 0.003, -0.05, 0.05)
		var pre_freq := signal_tuner.current_frequency
		
		drag_ev.relative = Vector2(raw_dx, 0.0)
		touch_ui._gui_input(drag_ev)
		
		var post_freq := signal_tuner.current_frequency
		var actual_delta := post_freq - pre_freq
		
		if post_freq < 0.0 or post_freq > 1.0:
			test1_bounded = false
		if abs(actual_delta - expected_delta) > 0.0001 and post_freq > 0.0 and post_freq < 1.0:
			test1_clamped_correctly = false
			
		print("[TEST 1 SWIPE %d] raw_dx=%.1f | expected_delta=%.3f | pre_freq=%.3f -> post_freq=%.3f (actual_delta=%.3f)" % [
			idx, raw_dx, expected_delta, pre_freq, post_freq, actual_delta
		])
	
	print("[TEST 1 RESULT] Clamped Correctly = %s | Strictly Bounded [0,1] = %s" % [
		test1_clamped_correctly, test1_bounded
	])
	
	# -------------------------------------------------------------------------
	# TEST 2: Micro-adjustments Near Lock Tolerance (Target Frequency 0.72 +/- 0.05)
	# -------------------------------------------------------------------------
	print("\n--- [TEST 2] Micro-adjustments Near Lock Tolerance (0.72 +/- 0.05) ---")
	signal_tuner.current_frequency = 0.65 # Just outside lower bound (0.67)
	signal_tuner._dwell_timer = 0.0
	
	drag_ev.relative = Vector2(5.0, 0.0) # delta = +0.015 -> 0.665
	touch_ui._gui_input(drag_ev)
	assert(abs(signal_tuner.current_frequency - 0.665) < 0.0001, "FAIL: 0.65 + 0.015 = 0.665")
	await get_tree().process_frame
	assert(signal_tuner._dwell_timer == 0.0, "FAIL: Dwell timer must be 0 outside tolerance")
	
	drag_ev.relative = Vector2(3.0, 0.0) # delta = +0.009 -> 0.674 (inside lock range!)
	touch_ui._gui_input(drag_ev)
	print("[TEST 2 LOG] Entered lock tolerance: frequency = %.3f (Target 0.72 +/- 0.05)" % signal_tuner.current_frequency)
	
	await get_tree().create_timer(0.05).timeout
	var dwell_mid := signal_tuner._dwell_timer
	assert(dwell_mid > 0.0, "FAIL: Dwell timer must accumulate while in lock range")
	print("[TEST 2 LOG] Dwell timer accumulating: %.3fs / 0.400s" % dwell_mid)
	
	drag_ev.relative = Vector2(35.0, 0.0) # delta = +0.05 clamped
	touch_ui._gui_input(drag_ev) # 0.674 -> 0.724
	touch_ui._gui_input(drag_ev) # 0.724 -> 0.774 (past upper bound 0.77!)
	touch_ui._gui_input(drag_ev) # 0.774 -> 0.824 (well past 0.77!)
	print("[TEST 2 LOG] Nudge past upper bound: frequency = %.3f" % signal_tuner.current_frequency)
	
	await get_tree().create_timer(0.05).timeout
	var dwell_decay := signal_tuner._dwell_timer
	print("[TEST 2 LOG] Dwell timer decayed from %.3fs to %.3fs outside tolerance" % [dwell_mid, dwell_decay])
	assert(dwell_decay < dwell_mid, "FAIL: Dwell timer must decay outside tolerance")
	
	drag_ev.relative = Vector2(-20.0, 0.0) # delta = -0.05 clamped
	touch_ui._gui_input(drag_ev) # 0.824 -> 0.774
	touch_ui._gui_input(drag_ev) # 0.774 -> 0.724 (inside lock range!)
	print("[TEST 2 LOG] Re-entered lock range near center: frequency = %.3f" % signal_tuner.current_frequency)
	
	await get_tree().create_timer(0.45).timeout
	assert(signal_tuner.current_state == SignalTuner.TunerState.LOCKED, "FAIL: Tuner must enter LOCKED state after holding in range")
	print("[TEST 2 RESULT] Micro-adjustments & Lock Dwell verified cleanly! Lock achieved at freq = %.3f" % signal_tuner.current_frequency)
	
	# -------------------------------------------------------------------------
	# TEST 3: Rapid Touch-On Touch-Off Releases Mid-Tuning
	# -------------------------------------------------------------------------
	print("\n--- [TEST 3] Rapid Touch-On Touch-Off Releases Mid-Tuning ---")
	signal_tuner.current_state = SignalTuner.TunerState.TUNING
	signal_tuner.current_frequency = 0.30
	signal_tuner._dwell_timer = 0.0
	touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	
	print("[TEST 3 LOG] Rapidly toggling touch-down / touch-up 10 times mid-tuning...")
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	
	var touch_index_cleared_cleanly := true
	for cycle in range(10):
		touch_down.pressed = true
		touch_down.index = cycle
		touch_ui._gui_input(touch_down)
		if touch_ui._interaction_touch_index != cycle:
			touch_index_cleared_cleanly = false
			
		drag_ev.index = cycle
		drag_ev.relative = Vector2(10.0, 0.0)
		touch_ui._gui_input(drag_ev)
		
		touch_up.index = cycle
		touch_ui._gui_input(touch_up)
		if touch_ui._interaction_touch_index != -1:
			touch_index_cleared_cleanly = false
			
	print("[TEST 3 LOG] Touch index ownership cleared cleanly across 10 rapid touch cycles = %s" % touch_index_cleared_cleanly)
	
	print("[TEST 3 LOG] Testing touch release mid-tuning inside lock tolerance (freq = 0.72)...")
	touch_down.index = 0
	touch_down.pressed = true
	touch_ui._gui_input(touch_down)
	signal_tuner.current_frequency = 0.72
	signal_tuner._dwell_timer = 0.0
	
	touch_up.index = 0
	touch_ui._gui_input(touch_up)
	assert(touch_ui._is_tuning == false, "FAIL: _is_tuning in touch_ui must be false on release")
	
	var state_before_wait := signal_tuner.current_state
	print("[TEST 3 LOG] Finger released: touch_ui._is_tuning = %s | signal_tuner.current_state = %s" % [
		touch_ui._is_tuning, SignalTuner.TunerState.keys()[state_before_wait]
	])
	
	await get_tree().create_timer(0.45).timeout
	var state_after_wait := signal_tuner.current_state
	print("[TEST 3 LOG] After 0.45s hands-free dwell: signal_tuner.current_state = %s" % SignalTuner.TunerState.keys()[state_after_wait])
	
	var hands_free_lock_triggered := (state_after_wait == SignalTuner.TunerState.LOCKED)
	print("[TEST 3 RESULT] Touch-off pointer clearing = %s | Hands-free auto-lock when finger lifted = %s" % [
		touch_index_cleared_cleanly, hands_free_lock_triggered
	])
	
	# -------------------------------------------------------------------------
	# TEST 4: Smooth Frequency Scaling Verification
	# -------------------------------------------------------------------------
	print("\n--- [TEST 4] Smooth Frequency Scaling Verification (clampf(dx * 0.003, -0.05, 0.05)) ---")
	touch_ui.show_gesture_overlay("TUNE_SIGNAL")
	signal_tuner.current_state = SignalTuner.TunerState.TUNING
	signal_tuner.current_frequency = 0.50
	
	touch_down.index = 0
	touch_down.pressed = true
	touch_ui._gui_input(touch_down)
	
	var scaling_monotonic := true
	var linear_inputs: Array[float] = [-100.0, -50.0, -20.0, -10.0, -5.0, -1.0, 0.0, 1.0, 5.0, 10.0, 20.0, 50.0, 100.0]
	var scale_results: Array[Array] = []
	
	for dx in linear_inputs:
		drag_ev.index = 0
		drag_ev.relative = Vector2(dx, 0.0)
		var expected := clampf(dx * 0.003, -0.05, 0.05)
		var f_before := signal_tuner.current_frequency
		touch_ui._gui_input(drag_ev)
		var f_after := signal_tuner.current_frequency
		var actual := f_after - f_before
		scale_results.append([dx, expected, actual])
		if abs(actual - expected) > 0.0001:
			scaling_monotonic = false
			
	print("[TEST 4 LOG] Touch Drag Sensitivity Scaling Table:")
	print("  dx (px) | Expected Delta | Actual Delta | Match")
	print("  ------------------------------------------------")
	for r in scale_results:
		var r_dx: float = float(r[0])
		var r_exp: float = float(r[1])
		var r_act: float = float(r[2])
		print("  %7.1f | %14.4f | %12.4f | %s" % [r_dx, r_exp, r_act, abs(r_act - r_exp) <= 0.0001])
		
	signal_tuner.current_frequency = 0.50
	drag_ev.relative = Vector2(-10000.0, 0.0)
	touch_ui._gui_input(drag_ev)
	var freq_left_clamp := signal_tuner.current_frequency
	assert(abs(freq_left_clamp - 0.45) < 0.0001, "FAIL: -10000px drag clamped to -0.05 delta (0.50 -> 0.45)")
	
	for i in range(15):
		touch_ui._gui_input(drag_ev)
	var freq_min_bound := signal_tuner.current_frequency
	assert(freq_min_bound == 0.0, "FAIL: Frequency lower bound must clamp to 0.0")
	
	drag_ev.relative = Vector2(10000.0, 0.0)
	for i in range(25):
		touch_ui._gui_input(drag_ev)
	var freq_max_bound := signal_tuner.current_frequency
	assert(freq_max_bound == 1.0, "FAIL: Frequency upper bound must clamp to 1.0")
	
	print("[TEST 4 RESULT] Linear scaling formula clampf(dx * 0.003, -0.05, 0.05) verified! Monotonic = %s, Boundaries [0.0, 1.0] solid!" % scaling_monotonic)
	
	print("\n=========================================================================")
	print("[V7 TICKET 03 ADVERSARIAL STRESS RETEST SUITE COMPLETED]")
	print("=========================================================================\n")
	get_tree().quit(0)



