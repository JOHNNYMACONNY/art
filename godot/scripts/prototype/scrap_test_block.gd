class_name ScrapTestBlock
extends Node3D

# Echos in the Scrap - Golden Slice v5 Main Controller
# Integrated V5 Environmental Evasion / Scrap Route Switch

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
## M04: preload MemoryEchoController to avoid global class_name lookup in headless
const MemoryEchoController = preload("res://scripts/prototype/memory_echo_controller.gd")
const ScrapHaulerScript = preload("res://scripts/vehicles/scrap_hauler.gd")
const MuscleCoupeScript = preload("res://scripts/vehicles/muscle_coupe.gd")
const SalvageLockboxScript = preload("res://scripts/props/salvage_lockbox.gd")
const ScrapWorkerScript = preload("res://scripts/entities/scrap_worker.gd")
const UtilityCrawlerScript = preload("res://scripts/entities/utility_crawler.gd")
const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramDirectorScript = preload("res://scripts/audio/radio/radio_program_director.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")

enum WorldLoopState {
	START,
	SIGNAL_LOCKED,
	PANEL_POWERED,
	CORE_EXTRACTED,
	## M04: echo sequence window between extraction and disturbance
	MEMORY_ECHO,
	LOOP_COMPLETE
}

enum PursuitState {
	CALM,
	DISTURBANCE_ALERT,
	PURSUIT_ACTIVE,
	CONTACT_BROKEN,
	EVADED,
	INTERCEPTED,
	RETRY_READY
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
var scrap_hauler: CharacterBody3D = null
var muscle_coupe: MuscleCoupe = null
var salvage_lockbox: StaticBody3D = null
var scrap_worker_1: CharacterBody3D = null
var scrap_worker_2: CharacterBody3D = null
var utility_crawler: CharacterBody3D = null
var ambient_actors: Array[CharacterBody3D] = []
var active_vehicle: Node3D = null
var pursuer: PursuerPrototype = null
var signal_gate: SignalGateInteractable = null
## M04: Memory Echo controller (instantiated at runtime)
var echo_controller = null

var current_world_state: WorldLoopState = WorldLoopState.START
var current_pursuit_state: PursuitState = PursuitState.CALM

var _extracted_count: int = 0
var _active_target: InteractableBase = null
var _interactables: Array[InteractableBase] = []

var _steer_input: float = 0.0
var _throttle_input: float = 0.0
var _handbrake_input: bool = false
var _contact_broken_timer: float = 0.0
var _recovery_marker: Vector3 = Vector3(-1.5, 0.05, 3.0)
var _last_pursuit_vehicle: Node3D = null
var _is_retrying_chase: bool = false
var _radio_enabled: bool = true
var _radio_station_id: String = RadioStationCatalogScript.DEFAULT_STATION_ID
var _radio_owner: Node3D = null

func get_radio_owner() -> Node3D:
	return _radio_owner

func is_radio_enabled() -> bool:
	return _radio_enabled

func get_radio_station_id() -> String:
	return _radio_station_id

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
		courier_bike.collision_contact.connect(func(head_on_ratio: float, impact_speed: float, col_pos: Vector3):
			if audio_mgr: audio_mgr.on_collision_contact(head_on_ratio, impact_speed, col_pos)
			_check_checkpoint_ram_breach(impact_speed, col_pos)
		)
		if courier_bike.mount_interactable:
			_interactables.append(courier_bike.mount_interactable)

	var hauler_scene: PackedScene = load("res://scenes/vehicles/scrap_hauler.tscn")
	if hauler_scene:
		scrap_hauler = hauler_scene.instantiate() as CharacterBody3D
		scrap_hauler.name = "ScrapHauler"
		scrap_hauler.position = Vector3(4.0, 0.05, 3.0)
		add_child(scrap_hauler)
		scrap_hauler.mounted.connect(_on_hauler_mounted)
		scrap_hauler.dismounted.connect(_on_hauler_dismounted)
		scrap_hauler.dismount_rejected.connect(_on_bike_dismount_rejected)
		scrap_hauler.brake_screech_triggered.connect(func(pos: Vector3):
			if audio_mgr: audio_mgr.play_event(AudioManagerScript.SoundEvent.BRAKE_SCREECH, pos)
		)
		scrap_hauler.collision_contact.connect(func(head_on_ratio: float, impact_speed: float, col_pos: Vector3):
			if audio_mgr: audio_mgr.on_collision_contact(head_on_ratio, impact_speed, col_pos)
			_check_checkpoint_ram_breach(impact_speed, col_pos)
		)
		if scrap_hauler.mount_interactable:
			_interactables.append(scrap_hauler.mount_interactable)

	var coupe_scene: PackedScene = load("res://scenes/vehicles/muscle_coupe.tscn")
	if coupe_scene:
		muscle_coupe = coupe_scene.instantiate() as MuscleCoupe
		muscle_coupe.name = "MuscleCoupe"
		muscle_coupe.position = Vector3(-3.5, 0.05, 3.0)
		add_child(muscle_coupe)
		muscle_coupe.mounted.connect(_on_coupe_mounted)
		muscle_coupe.dismounted.connect(_on_coupe_dismounted)
		muscle_coupe.dismount_rejected.connect(_on_bike_dismount_rejected)
		muscle_coupe.brake_screech_triggered.connect(func(pos: Vector3):
			if audio_mgr: audio_mgr.play_event(AudioManagerScript.SoundEvent.BRAKE_SCREECH, pos)
		)
		muscle_coupe.collision_contact.connect(func(head_on_ratio: float, impact_speed: float, col_pos: Vector3):
			if audio_mgr: audio_mgr.on_collision_contact(head_on_ratio, impact_speed, col_pos)
			_check_checkpoint_ram_breach(impact_speed, col_pos)
		)
		if muscle_coupe.mount_interactable:
			_interactables.append(muscle_coupe.mount_interactable)
			
	var pursuer_scene: PackedScene = load("res://scenes/entities/pursuer_prototype.tscn")
	if pursuer_scene:
		pursuer = pursuer_scene.instantiate() as PursuerPrototype
		pursuer.name = "PursuerPrototype"
		pursuer.position = Vector3(0, 0.6, -10.0)
		add_child(pursuer)
		pursuer.intercepted_target.connect(_on_pursuer_intercepted)
		pursuer.de_escalation_completed.connect(func():
			if current_pursuit_state == PursuitState.EVADED:
				current_pursuit_state = PursuitState.CALM
		)
		
	var gate_scene: PackedScene = load("res://scenes/interactions/signal_gate.tscn")
	if gate_scene:
		signal_gate = gate_scene.instantiate() as SignalGateInteractable
		signal_gate.name = "SignalGate"
		signal_gate.position = Vector3(-1.5, 0.5, 12.0)
		add_child(signal_gate)
		signal_gate.gate_triggered.connect(_on_signal_gate_triggered)
		_interactables.append(signal_gate)

	var lockbox_scene: PackedScene = load("res://scenes/props/prop_salvage_lockbox.tscn")
	if lockbox_scene:
		salvage_lockbox = lockbox_scene.instantiate() as StaticBody3D
		salvage_lockbox.name = "PropSalvageLockbox"
		salvage_lockbox.position = Vector3(2.5, 0.0, 6.5)
		add_child(salvage_lockbox)
		salvage_lockbox.hit_received.connect(_on_lockbox_hit_received)
		salvage_lockbox.lockbox_breached.connect(_on_lockbox_breached)
		salvage_lockbox.alarm_triggered.connect(_on_lockbox_alarm_triggered)

	var worker_scene: PackedScene = load("res://scenes/entities/scrap_worker.tscn")
	if worker_scene:
		scrap_worker_1 = worker_scene.instantiate() as CharacterBody3D
		scrap_worker_1.name = "ScrapWorker1"
		scrap_worker_1.position = Vector3(-5.5, 0.05, 1.0)
		scrap_worker_1.patrol_waypoints = [Vector3(-5.5, 0.05, 1.0), Vector3(-6.0, 0.05, -0.5)]
		scrap_worker_1.safe_anchor = Vector3(-6.0, 0.05, 2.5)
		scrap_worker_1.setup_audio(audio_mgr)
		add_child(scrap_worker_1)
		ambient_actors.append(scrap_worker_1)

		scrap_worker_2 = worker_scene.instantiate() as CharacterBody3D
		scrap_worker_2.name = "ScrapWorker2"
		scrap_worker_2.position = Vector3(-4.5, 0.05, 7.0)
		scrap_worker_2.patrol_waypoints = [Vector3(-4.5, 0.05, 7.0), Vector3(-5.5, 0.05, 5.0)]
		scrap_worker_2.safe_anchor = Vector3(-6.0, 0.05, 7.5)
		scrap_worker_2.setup_audio(audio_mgr)
		add_child(scrap_worker_2)
		ambient_actors.append(scrap_worker_2)

	var crawler_scene: PackedScene = load("res://scenes/entities/utility_crawler.tscn")
	if crawler_scene:
		utility_crawler = crawler_scene.instantiate() as CharacterBody3D
		utility_crawler.name = "UtilityCrawler"
		utility_crawler.position = Vector3(1.0, 0.05, -2.0)
		utility_crawler.patrol_waypoints = [Vector3(1.0, 0.05, -2.0), Vector3(1.0, 0.05, 3.0)]
		utility_crawler.safe_anchor = Vector3(1.0, 0.05, -4.5)
		utility_crawler.setup_audio(audio_mgr)
		add_child(utility_crawler)
		ambient_actors.append(utility_crawler)
		
	if corroded_panel:
		corroded_panel.magnetism_changed.connect(_on_magnetism_changed)
		corroded_panel.extraction_step_changed.connect(_on_extraction_step_changed)
		corroded_panel.extraction_completed.connect(_on_extraction_completed)
		corroded_panel.audio_event_triggered.connect(_on_audio_event_triggered)
		_interactables.append(corroded_panel)
		
	if player and camera:
		camera.set_target(player)
		player.footstep_triggered.connect(_on_player_footstep)
		player.strike_triggered.connect(_on_player_strike_triggered)
		
	if touch_ui:
		touch_ui.joystick_vector_updated.connect(_on_joystick_vector_updated)
		touch_ui.action_button_pressed.connect(_on_action_pressed)
		touch_ui.strike_pressed.connect(_on_strike_pressed)
		touch_ui.peel_gesture_dragged.connect(_on_peel_gesture_dragged)
		touch_ui.peel_gesture_released.connect(_on_peel_gesture_released)
		touch_ui.tuner_dragged.connect(_on_tuner_dragged)
		touch_ui.tuner_interaction_released.connect(_on_tuner_interaction_released)
		touch_ui.core_tap_pressed.connect(_on_core_tap_pressed)
		touch_ui.driving_steer_updated.connect(func(steer: float): _steer_input = steer)
		touch_ui.driving_throttle_updated.connect(func(throttle: float): _throttle_input = throttle)
		touch_ui.driving_handbrake_updated.connect(func(active: bool): _handbrake_input = active)
		touch_ui.dismount_pressed.connect(_on_dismount_pressed)
		touch_ui.radio_toggle_pressed.connect(_on_radio_toggle_pressed)
		touch_ui.replay_pressed.connect(reset_slice)
		touch_ui.retry_chase_pressed.connect(retry_chase)
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v6"
		status_label.visible = OS.get_cmdline_user_args().has("--debug-ui") or OS.has_feature("debug_ui")
		
	if OS.get_cmdline_user_args().has("--run-v1-assertions"):
		preload("res://tests/embedded/v1_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v2-assertions"):
		preload("res://tests/embedded/v2_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v3-assertions"):
		preload("res://tests/embedded/v3_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v4-assertions"):
		preload("res://tests/embedded/v4_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v5-assertions"):
		preload("res://tests/embedded/v5_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v6-assertions"):
		preload("res://tests/embedded/v6_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket01-assertions"):
		preload("res://tests/embedded/v7_ticket01_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket02-assertions"):
		preload("res://tests/embedded/v7_ticket02_assertions.gd").run_ticket02(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket02-1-assertions"):
		preload("res://tests/embedded/v7_ticket02_assertions.gd").run_ticket02_1(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket03-assertions"):
		preload("res://tests/embedded/v7_ticket03_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket03-stress-retest"):
		preload("res://tests/embedded/v7_ticket03_assertions.gd").run_stress_retest(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket04-1-assertions"):
		preload("res://tests/embedded/v7_ticket04_assertions.gd").run_04_1(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket04-2-assertions"):
		preload("res://tests/embedded/v7_ticket04_assertions.gd").run_04_2(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket04-3-assertions"):
		preload("res://tests/embedded/v7_ticket04_assertions.gd").run_04_3(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket05-assertions"):
		preload("res://tests/embedded/v7_ticket05_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v7-ticket06-assertions") or OS.get_cmdline_user_args().has("--run-v7-ticket06-1-assertions") or OS.get_cmdline_user_args().has("--run-v7-ticket06-2-assertions") or OS.get_cmdline_user_args().has("--run-v7-ticket06-3-assertions"):
		preload("res://tests/embedded/v7_ticket06_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--export-v2-visuals"):
		preload("res://tests/embedded/v4_v3_v2_export_visuals.gd").export_v2_visuals(self)
	elif OS.get_cmdline_user_args().has("--export-v3-visuals"):
		preload("res://tests/embedded/v4_v3_v2_export_visuals.gd").export_v3_visuals(self)
	elif OS.get_cmdline_user_args().has("--export-v4-visuals"):
		preload("res://tests/embedded/v4_v3_v2_export_visuals.gd").export_v4_visuals(self)
	elif OS.get_cmdline_user_args().has("--export-v5-visuals"):
		preload("res://tests/embedded/v5_assertions.gd").export_visuals(self)
	elif OS.get_cmdline_user_args().has("--export-v6-visuals"):
		preload("res://tests/embedded/v6_assertions.gd").export_visuals(self)
	elif OS.get_cmdline_user_args().has("--export-v8-proof"):
		preload("res://tests/embedded/v8_telemetry.gd").export_v8_proof(self)
	elif OS.get_cmdline_user_args().has("--export-v8-baseline"):
		print("[V8_BENCHMARKS] ERROR: V7 baseline is immutable and must be captured from baseline SHA 4745650. Overwrite prevented.")
		get_tree().quit(1)
	elif OS.get_cmdline_user_args().has("--export-v8-dressed"):
		preload("res://tests/embedded/v8_telemetry.gd").export_v8_benchmarks(self, "v8_dressed")
	elif OS.get_cmdline_user_args().has("--run-v8-telemetry"):
		preload("res://tests/embedded/v8_telemetry.gd").run_telemetry(self)
	elif OS.get_cmdline_user_args().has("--export-v8-safe-area-proof"):
		preload("res://tests/embedded/v8_safe_area_assertions.gd").export_safe_area_proof(self)
	elif OS.get_cmdline_user_args().has("--export-v8-mobile-gameplay-states"):
		preload("res://tests/embedded/v8_safe_area_assertions.gd").export_mobile_gameplay_states(self)
	elif OS.get_cmdline_user_args().has("--run-v8-safe-area-assertions"):
		preload("res://tests/embedded/v8_safe_area_assertions.gd").run_safe_area_assertions(self)
	elif OS.get_cmdline_user_args().has("--run-v8-thumb-reach-assertions"):
		preload("res://tests/embedded/v8_touch_assertions.gd").run_thumb_reach_assertions(self)
	elif OS.get_cmdline_user_args().has("--run-v8-multitouch-assertions"):
		preload("res://tests/embedded/v8_touch_assertions.gd").run_multitouch_assertions(self)
	elif OS.get_cmdline_user_args().has("--export-v8-aftermath-proof"):
		preload("res://tests/embedded/v8_aftermath_assertions.gd").export_aftermath_proof(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m03-aftermath-assertions"):
		preload("res://tests/embedded/v8_aftermath_assertions.gd").run_aftermath_assertions(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m04-echo-assertions"):
		preload("res://tests/embedded/v8_m04_echo_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m05-hero-identity-assertions"):
		preload("res://tests/embedded/v8_m05_hero_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m06-vehicle-class-assertions"):
		preload("res://tests/embedded/v8_m06_vehicle_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m07-world-life-assertions"):
		preload("res://tests/embedded/v8_m07_world_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m15-fast-retry-assertions") or OS.get_cmdline_user_args().has("--run-v8-m15-assertions"):
		preload("res://tests/embedded/v8_m15_retry_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m21-audio-registry-assertions") or OS.get_cmdline_user_args().has("--run-v8-m21-assertions"):
		preload("res://tests/embedded/v8_m21_audio_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m22-radio-director-assertions") or OS.get_cmdline_user_args().has("--run-v8-m22-radio-program-assertions") or OS.get_cmdline_user_args().has("--run-v8-m22-assertions"):
		preload("res://tests/embedded/v8_m22_radio_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m23-vehicle-radio-assertions") or OS.get_cmdline_user_args().has("--run-v8-m23-radio-assertions") or OS.get_cmdline_user_args().has("--run-v8-m23-assertions"):
		preload("res://tests/embedded/v8_m23_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m24-radio-mix-assertions") or OS.get_cmdline_user_args().has("--run-v8-m24-assertions"):
		preload("res://tests/embedded/v8_m24_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-m25-echo-radio-interference-assertions") or OS.get_cmdline_user_args().has("--run-v8-m25-assertions"):
		preload("res://tests/embedded/v8_m25_assertions.gd").run(self)
	elif OS.get_cmdline_user_args().has("--run-v8-readability") or OS.get_cmdline_user_args().has("--run-v8-assertions"):
		preload("res://tests/embedded/v8_camera_assertions.gd").run_dynamic_readability(self)
func _get_active_vehicle() -> Node3D:
	if active_vehicle:
		return active_vehicle
	if courier_bike and courier_bike.occupant != null:
		return courier_bike
	if scrap_hauler and scrap_hauler.occupant != null:
		return scrap_hauler
	return null

func _process(delta: float) -> void:
	var active_veh := _get_active_vehicle()
	var active_pos: Vector3 = active_veh.global_position if active_veh else player.global_position
	for item in _interactables:
		if item:
			item.update_player_distance(active_pos)
	_evaluate_target_selection()
		
	if active_veh:
		if active_veh.has_method("set_drive_inputs"):
			active_veh.set_drive_inputs(_throttle_input, _steer_input, delta, _handbrake_input)
		if touch_ui and "current_speed" in active_veh and "dismount_speed_limit" in active_veh:
			touch_ui.set_dismount_button_enabled(abs(active_veh.current_speed) <= active_veh.dismount_speed_limit)
		if audio_mgr and "current_speed" in active_veh and "max_speed" in active_veh:
			var speed_ratio: float = abs(active_veh.current_speed) / active_veh.max_speed
			audio_mgr.set_engine_audio(speed_ratio, active_veh.global_position)
			
	# Ambient world actors proximity threat / avoidance check
	var active_entity: CharacterBody3D = active_veh if active_veh else player
	if active_entity:
		for actor in ambient_actors:
			if is_instance_valid(actor) and actor.has_method("check_proximity_threat"):
				actor.check_proximity_threat(active_entity.global_position, active_entity.velocity)
			
	_process_pursuit_loop(delta)
	_process_radio_interference()
		
	if status_label:
		status_label.text = "ECHOS IN THE SCRAP // GOLDEN SLICE v5 [%s | PURSUIT: %s]\nFPS: %d | Frame: %.2f ms" % [
			WorldLoopState.keys()[current_world_state],
			PursuitState.keys()[current_pursuit_state],
			Engine.get_frames_per_second(),
			1000.0 / max(Engine.get_frames_per_second(), 1)
		]

func _process_radio_interference() -> void:
	if not audio_mgr:
		return
	# Cheap authoritative gates first — never create radio player from eligibility check
	var active_veh: Node3D = _get_active_vehicle()
	if not (
		current_world_state == WorldLoopState.PANEL_POWERED
		and corroded_panel != null
		and active_veh != null
		and _radio_owner == active_veh
		and is_radio_enabled()
	):
		audio_mgr.clear_radio_interference()
		return
	# Only after cheap gates pass: inspect existing player without creating it
	var radio_player = audio_mgr.get_existing_radio_player()
	if not (
		radio_player != null
		and radio_player.is_playing()
		and not radio_player.is_paused()
		and radio_player.is_stream_playing()
	):
		audio_mgr.clear_radio_interference()
		return
	audio_mgr.update_radio_interference(corroded_panel.global_position, active_veh.global_position, true)

func _process_pursuit_loop(delta: float) -> void:
	if current_pursuit_state == PursuitState.PURSUIT_ACTIVE and pursuer and pursuer.is_active:
		var target: Node3D = _get_active_vehicle() if _get_active_vehicle() else player
		if target:
			var dist := pursuer.global_position.distance_to(target.global_position)
			if touch_ui:
				touch_ui.update_pursuer_proximity(dist)
			if audio_mgr:
				audio_mgr.set_pursuit_pressure(dist, pursuer.global_position)
				
			var contact_threshold: float = 1.6
			if dist < contact_threshold:
				_on_pursuer_intercepted()
			elif dist > 18.0:
				_contact_broken_timer += delta
				if _contact_broken_timer >= 3.0:
					_contact_broken_timer = 0.0
					current_pursuit_state = PursuitState.CONTACT_BROKEN
					print("[PURSUIT] Contact broken! Evasion decay started...")
					get_tree().create_timer(1.0).timeout.connect(func():
						if current_pursuit_state == PursuitState.CONTACT_BROKEN:
							current_pursuit_state = PursuitState.EVADED
							_on_successful_evasion()
					)
			else:
				_contact_broken_timer = move_toward(_contact_broken_timer, 0.0, delta)

func _begin_disturbance_sequence(expected_source_state: PursuitState) -> bool:
	if current_pursuit_state != expected_source_state:
		print("[PURSUIT] Rejected disturbance sequence: source state mismatch (expected %s, got %s)" % [PursuitState.keys()[expected_source_state], PursuitState.keys()[current_pursuit_state]])
		return false
		
	current_pursuit_state = PursuitState.DISTURBANCE_ALERT
	_last_pursuit_vehicle = _get_active_vehicle() if _get_active_vehicle() else _last_pursuit_vehicle
	print("[PULSE] Disturbance alert triggered! Pursuit sequence initiating...")
	if audio_mgr:
		audio_mgr.set_mix_state(AudioManagerScript.MixState.DISTURBANCE)
		
	for actor in ambient_actors:
		if is_instance_valid(actor) and actor.has_method("trigger_alarm"):
			actor.trigger_alarm()
		
	get_tree().create_timer(0.75).timeout.connect(func():
		if current_pursuit_state == PursuitState.DISTURBANCE_ALERT:
			current_pursuit_state = PursuitState.PURSUIT_ACTIVE
			if audio_mgr:
				audio_mgr.set_mix_state(AudioManagerScript.MixState.PURSUIT_PRESSURE)
			if pursuer:
				var target: Node3D = _get_active_vehicle() if _get_active_vehicle() else player
				pursuer.activate_pursuit(target)
				if signal_gate:
					signal_gate.set_pursuit_active(true)
				print("[PURSUIT] Pursuer active! Chasing target...")
	)
	return true

func trigger_disturbance_alert() -> void:
	_begin_disturbance_sequence(PursuitState.CALM)

func _end_pursuit_common(preserve_radio_duck: bool = false) -> void:
	if pursuer:
		pursuer.reset_pursuer()
	if signal_gate:
		signal_gate.set_pursuit_active(false)
	if audio_mgr:
		audio_mgr.clear_pursuit_pressure(preserve_radio_duck)
	if touch_ui:
		touch_ui.hide_tension_hud()

func _on_successful_evasion() -> void:
	if signal_gate:
		signal_gate.set_pursuit_active(false)
	if touch_ui:
		touch_ui.hide_tension_hud()
		touch_ui.show_replay_overlay(false)
		
	if pursuer:
		pursuer.start_de_escalation()
		
	if audio_mgr:
		audio_mgr.start_pursuit_release_decay(1.0)
		audio_mgr.set_mix_state(AudioManagerScript.MixState.EVASION_RELEASE)
		
	if world_env and world_env.environment:
		world_env.environment.ambient_light_color = Color(0.3, 0.26, 0.2, 1.0)
		
	current_pursuit_state = PursuitState.EVADED
	print("[PURSUIT] Contact evaded. Pursuer transitioning to de-escalation retreat. Quiet aftermath reached.")

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
	if current_pursuit_state == PursuitState.INTERCEPTED or current_pursuit_state == PursuitState.RETRY_READY:
		return
		
	current_pursuit_state = PursuitState.INTERCEPTED
	print("[PURSUIT] TARGET INTERCEPTED! Resetting to recovery marker...")
	
	_last_pursuit_vehicle = _get_active_vehicle() if _get_active_vehicle() else _last_pursuit_vehicle
	_steer_input = 0.0
	_throttle_input = 0.0
	_handbrake_input = false
	if player: player.is_input_locked = true
	if courier_bike: courier_bike.force_dismount()
	if scrap_hauler: scrap_hauler.force_dismount()
	if muscle_coupe: muscle_coupe.force_dismount()
	if audio_mgr:
		audio_mgr.clear_radio_interference()
	_end_pursuit_common(true)
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED, player.global_position if player else Vector3.ZERO)
	if touch_ui:
		touch_ui.show_replay_overlay(true)
		
	get_tree().create_timer(0.8).timeout.connect(func():
		if current_pursuit_state != PursuitState.INTERCEPTED:
			return
		if player:
			player.global_position = _recovery_marker + Vector3(-1.5, 0, 0)
			player.is_input_locked = false
			player.velocity = Vector3.ZERO
		if courier_bike:
			courier_bike.global_position = _recovery_marker
			courier_bike.rotation = Vector3.ZERO
		if scrap_hauler:
			scrap_hauler.global_position = _recovery_marker + Vector3(3.0, 0, 0)
			scrap_hauler.rotation = Vector3.ZERO
			
		current_pursuit_state = PursuitState.RETRY_READY
		if audio_mgr:
			audio_mgr.clear_radio_duck()
		print("[PURSUIT] Recovery complete. Transitioned to RETRY_READY.")
	)

func retry_chase() -> void:
	if current_pursuit_state != PursuitState.RETRY_READY:
		print("[PURSUIT_RETRY] Rejected retry_chase: not in RETRY_READY state (current: %s) -> zero mutation" % PursuitState.keys()[current_pursuit_state])
		return
		
	if not corroded_panel or corroded_panel.current_step != CorrodedPanel.Step.EXTRACTED:
		print("[PURSUIT_RETRY] Rejected retry_chase: CorrodedPanel not EXTRACTED -> zero mutation")
		return
		
	print("[PURSUIT_RETRY] Fast pursuit retry initiated! Preserving solved Tuner/Panel/Echo...")
	
	_steer_input = 0.0
	_throttle_input = 0.0
	_handbrake_input = false
	
	if touch_ui:
		touch_ui.hide_replay_overlay()
		touch_ui.reset_all_input_states()
		touch_ui.hide_tension_hud()
		
	if audio_mgr:
		audio_mgr.clear_pursuit_pressure()
		audio_mgr.stop_event(AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED)
		audio_mgr.reset_audio_instant()
		
	_end_pursuit_common()
	_contact_broken_timer = 0.0
	
	if pursuer:
		pursuer.reset_pursuer(Vector3(0, 0.6, -10.0))
		
	if signal_gate:
		signal_gate.current_state = SignalGateInteractable.GateState.READY
		signal_gate.barrier_pivot.rotation.y = 0.0
		signal_gate.barrier_collision.disabled = true
		signal_gate.is_powered = true
		signal_gate._update_visual_state()
		
	for actor in ambient_actors:
		if is_instance_valid(actor) and actor.has_method("reset_actor"):
			actor.reset_actor()
			
	var target_veh: Node3D = _last_pursuit_vehicle if _last_pursuit_vehicle else courier_bike
	if target_veh == scrap_hauler and scrap_hauler != null:
		scrap_hauler.global_position = Vector3(4.0, 0.05, 2.0)
		scrap_hauler.rotation = Vector3.ZERO
		scrap_hauler.velocity = Vector3.ZERO
		scrap_hauler.current_speed = 0.0
		if courier_bike:
			courier_bike.global_position = Vector3(-1.5, 0.05, 3.0)
			courier_bike.current_state = CourierBike.BikeState.PARKED
		
		player.global_position = scrap_hauler.global_position + Vector3(0, 0, 0.5)
		scrap_hauler.mount_interactable.update_player_distance(player.global_position)
		scrap_hauler.request_mount(player)
		active_vehicle = scrap_hauler
	else:
		if courier_bike:
			courier_bike.global_position = Vector3(-1.5, 0.05, 3.0)
			courier_bike.rotation = Vector3.ZERO
			courier_bike.velocity = Vector3.ZERO
			courier_bike.current_speed = 0.0
			if scrap_hauler:
				scrap_hauler.global_position = Vector3(4.0, 0.05, 2.0)
				scrap_hauler.current_state = ScrapHaulerScript.VehicleState.PARKED
			
			player.global_position = courier_bike.global_position + Vector3(0, 0, 0.5)
			courier_bike.mount_interactable.update_player_distance(player.global_position)
			courier_bike.request_mount(player)
			active_vehicle = courier_bike
			
	if player:
		player.is_input_locked = false
		player.velocity = Vector3.ZERO
		
	if camera:
		camera.reset_camera_instant(active_vehicle if active_vehicle else player)
		
	if touch_ui:
		touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
		touch_ui.set_route_switch_button_visible(false)
		
	# Canonical disturbance sequence authority
	var started: bool = _begin_disturbance_sequence(PursuitState.RETRY_READY)
	if started:
		print("[PURSUIT_RETRY] Fast pursuit retry ready! Disturbance alert re-triggered.")

func _evaluate_target_selection() -> void:
	if not player or not touch_ui:
		return
		
	var best_target: InteractableBase = null
	var best_score: float = -9999.0
	var active_veh: Node3D = _get_active_vehicle()
	var active_pos: Vector3 = active_veh.global_position if active_veh else player.global_position
	
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

	var checkpoint_event = get_node_or_null("SecurityCheckpointWorldEvent")
	var is_checkpoint_standoff: bool = checkpoint_event != null and checkpoint_event.current_state == 1 # State.STANDOFF

	var contraband_event = get_node_or_null("AlleyContrabandDropWorldEvent")
	var is_contraband_stash: bool = contraband_event != null and contraband_event.current_state == 1 # State.DISCOVERED
	var is_contraband_delivery: bool = false
	if contraband_event != null and contraband_event.current_state == 2: # State.COLLECTED
		var exit_sock = contraband_event._exit_socket
		if exit_sock and active_pos.distance_to(exit_sock.global_position) <= contraband_event.EXIT_RADIUS_M:
			is_contraband_delivery = true

	if touch_ui.current_mode == TouchControlsUI.UIMode.VEHICLE_DRIVING:
		if is_checkpoint_standoff:
			touch_ui.set_route_switch_button_visible(true)
			if touch_ui.route_switch_button:
				touch_ui.route_switch_button.text = "[F] PAY TOLL // 150"
		elif is_contraband_stash:
			touch_ui.set_route_switch_button_visible(true)
			if touch_ui.route_switch_button:
				touch_ui.route_switch_button.text = "[F] SECURE STASH"
		elif is_contraband_delivery:
			touch_ui.set_route_switch_button_visible(true)
			if touch_ui.route_switch_button:
				touch_ui.route_switch_button.text = "[F] DELIVER DROP"
		else:
			if touch_ui.route_switch_button:
				touch_ui.route_switch_button.text = "[ ROUTE ]"
			touch_ui.set_route_switch_button_visible(_active_target is SignalGateInteractable)
	else:
		if is_checkpoint_standoff:
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				touch_ui.action_button.text = "[E] PAY TOLL // 150"
		elif is_contraband_stash:
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				touch_ui.action_button.text = "[E] SECURE STASH"
		elif is_contraband_delivery:
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				touch_ui.action_button.text = "[E] DELIVER DROP"
		else:
			if touch_ui.action_button:
				touch_ui.action_button.text = "[E] ACTION"
			touch_ui.set_action_button_highlight(_active_target != null)

func _on_action_pressed() -> void:
	var checkpoint_event = get_node_or_null("SecurityCheckpointWorldEvent")
	if checkpoint_event and checkpoint_event.current_state == 1: # State.STANDOFF
		if checkpoint_event.pay_toll():
			if touch_ui:
				if touch_ui.route_switch_button:
					touch_ui.route_switch_button.text = "[ ROUTE ]"
				touch_ui.set_route_switch_button_visible(false)
				if touch_ui.action_button:
					touch_ui.action_button.text = "[E] ACTION"
			return

	var active_veh: Node3D = _get_active_vehicle()
	var active_pos: Vector3 = active_veh.global_position if active_veh else (player.global_position if player else Vector3.ZERO)

	var contraband_event = get_node_or_null("AlleyContrabandDropWorldEvent")
	if contraband_event:
		if contraband_event.current_state == 1: # State.DISCOVERED
			if contraband_event.collect_stash():
				if touch_ui:
					if touch_ui.route_switch_button:
						touch_ui.route_switch_button.text = "[ ROUTE ]"
					touch_ui.set_route_switch_button_visible(false)
					if touch_ui.action_button:
						touch_ui.action_button.text = "[E] ACTION"
				return
		elif contraband_event.current_state == 2: # State.COLLECTED
			var exit_sock = contraband_event._exit_socket
			if exit_sock and active_pos.distance_to(exit_sock.global_position) <= contraband_event.EXIT_RADIUS_M:
				if contraband_event.deliver_drop():
					if touch_ui:
						if touch_ui.route_switch_button:
							touch_ui.route_switch_button.text = "[ ROUTE ]"
						touch_ui.set_route_switch_button_visible(false)
						if touch_ui.action_button:
							touch_ui.action_button.text = "[E] ACTION"
					return

	if not _active_target or not player:
		if player and not player.is_mounted and not player.is_input_locked:
			player.strike()
		return

		
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

func _check_checkpoint_ram_breach(impact_speed: float, col_pos: Vector3) -> void:
	var checkpoint_event = get_node_or_null("SecurityCheckpointWorldEvent")
	if checkpoint_event and (checkpoint_event.current_state == 1 or checkpoint_event.current_state == 0):
		var checkpoint_prop = checkpoint_event._checkpoint_prop
		if checkpoint_prop and col_pos.distance_to(checkpoint_prop.global_position) < 5.0:
			if impact_speed >= 5.0:
				checkpoint_event.ram_breach(impact_speed)
				if touch_ui:
					if touch_ui.route_switch_button:
						touch_ui.route_switch_button.text = "[ ROUTE ]"
					touch_ui.set_route_switch_button_visible(false)

func _on_bike_mounted(player_ref: PlayerRunner) -> void:
	active_vehicle = courier_bike
	_on_vehicle_mounted_generic(courier_bike, player_ref)

func _on_hauler_mounted(player_ref: PlayerRunner) -> void:
	active_vehicle = scrap_hauler
	_on_vehicle_mounted_generic(scrap_hauler, player_ref)

func _on_coupe_mounted(player_ref: PlayerRunner) -> void:
	active_vehicle = muscle_coupe
	_on_vehicle_mounted_generic(muscle_coupe, player_ref)

func _on_vehicle_mounted_generic(veh: Node3D, _player_ref: PlayerRunner) -> void:
	active_vehicle = veh
	_radio_owner = veh
	if touch_ui:
		touch_ui.set_mode(TouchControlsUI.UIMode.VEHICLE_DRIVING)
	if camera and veh:
		camera.set_target(veh)
	if audio_mgr and veh:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.BIKE_MOUNT, veh.global_position)
		var radio_player = audio_mgr.get_radio_player()
		if _radio_enabled:
			radio_player.fade_in_and_resume(0.18)
		else:
			radio_player.pause()
		if touch_ui:
			touch_ui.update_radio_button_state(_radio_enabled, _radio_station_id)
	if pursuer and pursuer.is_active:
		pursuer.target_node = veh

func _on_bike_dismounted() -> void:
	_on_vehicle_dismounted_generic(courier_bike)

func _on_hauler_dismounted() -> void:
	_on_vehicle_dismounted_generic(scrap_hauler)

func _on_coupe_dismounted() -> void:
	_on_vehicle_dismounted_generic(muscle_coupe)

func _on_vehicle_dismounted_generic(exiting_vehicle: Node3D = null) -> void:
	if exiting_vehicle == null or _radio_owner == exiting_vehicle:
		_radio_owner = null
		if audio_mgr:
			audio_mgr.clear_radio_interference()
			var radio_player = audio_mgr.get_radio_player()
			if radio_player and radio_player.is_playing() and not radio_player.is_paused():
				radio_player.fade_out_and_pause(0.20)

	if exiting_vehicle == null or active_vehicle == exiting_vehicle:
		active_vehicle = null
		if touch_ui:
			touch_ui.set_mode(TouchControlsUI.UIMode.FOOT_TRAVERSAL)
		if camera and player:
			camera.set_target(player)
		if audio_mgr and player:
			audio_mgr.play_event(AudioManagerScript.SoundEvent.BIKE_DISMOUNT, player.global_position)
			audio_mgr.stop_event(AudioManagerScript.SoundEvent.ENGINE_REV)
			audio_mgr.clear_vehicle_feedback()
		if pursuer and pursuer.is_active:
			pursuer.target_node = player

func _on_strike_pressed() -> void:
	if player and not player.is_mounted and not player.is_input_locked:
		player.strike()

func _on_player_strike_triggered(hit_target: Node3D, hit_pos: Vector3) -> void:
	if hit_target:
		if audio_mgr:
			audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
	else:
		if audio_mgr:
			audio_mgr.play_event(AudioManagerScript.SoundEvent.COLLISION_GLANCE, hit_pos)

func _on_lockbox_hit_received(remaining_durability: int, hit_pos: Vector3, _impulse_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, hit_pos)
	if status_label and (status_label.visible or OS.get_cmdline_user_args().has("--debug-ui")):
		status_label.text = "[SALVAGE HIT] LOCKBOX INTEGRITY: %d/3" % remaining_durability

func _on_lockbox_alarm_triggered(source_pos: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SIREN_ALARM, source_pos)
	if current_pursuit_state == PursuitState.CALM:
		trigger_disturbance_alert()

func _on_lockbox_breached(reward: int, breach_pos: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION, breach_pos)
	if status_label:
		status_label.text = "[MUNICIPAL LOCKBOX BREACHED] +%d SCRAP // SECURITY ALARM ACTIVE" % reward

func _on_radio_toggle_pressed() -> void:
	var veh := _get_active_vehicle()
	if not veh or not audio_mgr:
		return
	_radio_enabled = not _radio_enabled
	var radio_player = audio_mgr.get_radio_player()
	if _radio_enabled:
		radio_player.fade_in_and_resume(0.18)
	else:
		audio_mgr.clear_radio_interference()
		radio_player.fade_out_and_pause(0.18)
	if touch_ui:
		touch_ui.update_radio_button_state(_radio_enabled, _radio_station_id)

func _on_dismount_pressed() -> void:
	var veh := _get_active_vehicle()
	if veh and veh.has_method("request_dismount"):
		veh.request_dismount()

func _on_bike_dismount_rejected(reason: int, current_speed: float, _speed_limit: float) -> void:
	print("[CONTROLLER] Dismount rejected! Reason: %s | Speed: %.1f m/s" % [CourierBike.DismountRejectReason.keys()[reason], current_speed])
	var veh := _get_active_vehicle()
	var pos := veh.global_position if veh else player.global_position
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.DISMOUNT_REJECTED, pos)
	if touch_ui:
		var toast := "[ SLOW DOWN TO DISMOUNT ]" if reason == CourierBike.DismountRejectReason.TOO_FAST else "[ CLEAR SPACE TO DISMOUNT ]"
		touch_ui.show_dismount_rejection_warning(toast)

func reset_slice() -> void:
	if courier_bike and courier_bike.occupant != null:
		courier_bike.force_dismount()
	if scrap_hauler and scrap_hauler.occupant != null:
		scrap_hauler.force_dismount()
	if muscle_coupe and muscle_coupe.occupant != null:
		muscle_coupe.force_dismount()
	active_vehicle = null
		
	current_world_state = WorldLoopState.START
	current_pursuit_state = PursuitState.CALM
	_contact_broken_timer = 0.0
	_steer_input = 0.0
	_throttle_input = 0.0
	_handbrake_input = false
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
		courier_bike.current_gear = CourierBike.GearState.FORWARD
		courier_bike.is_handbrake_active = false
		courier_bike._gear_settle_timer = 0.0
		courier_bike.global_position = Vector3(-1.5, 0.05, 3.0)
		courier_bike.rotation.y = 0.0
		courier_bike.occupant = null
		courier_bike.current_speed = 0.0
		courier_bike.steering_angle = 0.0
		if courier_bike.visual_root: courier_bike.visual_root.rotation = Vector3.ZERO
		if courier_bike.mount_interactable:
			courier_bike.mount_interactable.is_powered = true
			courier_bike.mount_interactable.visible = true

	if scrap_hauler:
		scrap_hauler.current_state = ScrapHaulerScript.VehicleState.PARKED
		scrap_hauler.current_gear = ScrapHaulerScript.GearState.FORWARD
		scrap_hauler.is_handbrake_active = false
		scrap_hauler._gear_settle_timer = 0.0
		scrap_hauler.global_position = Vector3(3.5, 0.05, 3.0)
		scrap_hauler.rotation.y = 0.0
		scrap_hauler.occupant = null
		scrap_hauler.current_speed = 0.0
		scrap_hauler.steering_angle = 0.0
		if scrap_hauler.visual_root: scrap_hauler.visual_root.rotation = Vector3.ZERO
		if scrap_hauler.mount_interactable:
			scrap_hauler.mount_interactable.is_powered = true
			scrap_hauler.mount_interactable.visible = true

	if muscle_coupe:
		muscle_coupe.current_state = MuscleCoupeScript.VehicleState.PARKED
		muscle_coupe.current_gear = MuscleCoupeScript.GearState.FORWARD
		muscle_coupe.is_handbrake_active = false
		muscle_coupe._gear_settle_timer = 0.0
		muscle_coupe.global_position = Vector3(-3.5, 0.05, 3.0)
		muscle_coupe.rotation.y = 0.0
		muscle_coupe.occupant = null
		muscle_coupe.current_speed = 0.0
		muscle_coupe.steering_angle = 0.0
		if muscle_coupe.visual_root: muscle_coupe.visual_root.rotation = Vector3.ZERO
		if muscle_coupe.mount_interactable:
			muscle_coupe.mount_interactable.is_powered = true
			muscle_coupe.mount_interactable.visible = true
		
	if camera:
		camera.reset_camera_instant(player)
		
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
		pursuer.reset_pursuer(Vector3(0, 0.6, -10.0))
		
	if audio_mgr:
		audio_mgr.reset_audio_instant()
		
	## M04: reset echo state — no timer/audio/overlay leakage into next replay
	if echo_controller:
		echo_controller.reset_echo()
		
	## M07: reset living ambient yard actors to initial positions and AMBIENT state
	for actor in ambient_actors:
		if is_instance_valid(actor) and actor.has_method("reset_actor"):
			actor.reset_actor()
	
	_last_pursuit_vehicle = null
	_is_retrying_chase = false
	_radio_enabled = true
	_radio_station_id = RadioStationCatalogScript.DEFAULT_STATION_ID
	_radio_owner = null
	
	var checkpoint_event = get_node_or_null("SecurityCheckpointWorldEvent")
	if checkpoint_event and checkpoint_event.has_method("reset_world_event"):
		checkpoint_event.reset_world_event()

	var contraband_event = get_node_or_null("AlleyContrabandDropWorldEvent")
	if contraband_event and contraband_event.has_method("reset_world_event"):
		contraband_event.reset_world_event()

	if salvage_lockbox and salvage_lockbox.has_method("reset_lockbox"):
		salvage_lockbox.reset_lockbox()

	if touch_ui:
		touch_ui.reset_all_input_states()
		touch_ui.set_route_switch_button_visible(false)
		if touch_ui.route_switch_button:
			touch_ui.route_switch_button.text = "[ ROUTE ]"
		if touch_ui.action_button:
			touch_ui.action_button.text = "[E] ACTION"
		touch_ui.hide_replay_overlay()
		touch_ui.update_radio_button_state(true, _radio_station_id)
		
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
	if player:
		player.is_input_locked = false
	if camera:
		camera.set_interaction_mode(false)
	if touch_ui:
		touch_ui.close_interaction_overlay()

func _on_tuner_frequency_changed(freq: float, accuracy: float) -> void:
	if audio_mgr:
		audio_mgr.set_tuning_audio(accuracy)
	if touch_ui:
		touch_ui.update_tuner_feedback(freq, accuracy)

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
	if audio_mgr:
		audio_mgr.clear_radio_interference()
	_extracted_count += 1
	current_world_state = WorldLoopState.CORE_EXTRACTED
	print("[WORLD_LOOP] MICRO-PLAY LOOP COMPLETE! Core extracted.")
	## M04: instead of directly triggering disturbance, route through echo sequence
	_trigger_echo_sequence()
	
	if player:
		player.is_input_locked = false
	if camera:
		camera.set_interaction_mode(false)
	if touch_ui:
		touch_ui.close_interaction_overlay()

## M04B: start echo sequence; disturbance fires only after echo_completed
func _trigger_echo_sequence() -> bool:
	if current_world_state != WorldLoopState.CORE_EXTRACTED:
		print("[WORLD_LOOP] Rejecting echo sequence: world state is not CORE_EXTRACTED (current: %s)" % WorldLoopState.keys()[current_world_state])
		return false
	if echo_controller and (echo_controller.has_completed() or echo_controller.current_phase != MemoryEchoController.EchoPhase.IDLE):
		print("[WORLD_LOOP] Rejecting echo sequence: echo already active or completed (phase: %s)" % MemoryEchoController.EchoPhase.keys()[echo_controller.current_phase])
		return false
		
	print("[WORLD_LOOP] Entering Memory Echo sequence...")
	# Lazy-initialize echo controller on first use
	if not echo_controller:
		echo_controller = MemoryEchoController.new()
		echo_controller.name = "MemoryEchoController"
		add_child(echo_controller)
		echo_controller.echo_completed.connect(_on_echo_completed)
	echo_controller.setup(audio_mgr)
	echo_controller.arm_for_extraction()
	return echo_controller.trigger_echo()

## M04: fired by echo_controller.echo_completed — hands off to disturbance
func _on_echo_completed() -> void:
	print("[WORLD_LOOP] Echo complete — triggering disturbance alert")
	trigger_disturbance_alert()

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

