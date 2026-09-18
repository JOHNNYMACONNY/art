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
const PropStreetVendorScript = preload("res://scripts/props/prop_street_vendor.gd")
const PropUtilityPoleScript = preload("res://scripts/props/prop_utility_pole.gd")
const PropVendingMachineScript = preload("res://scripts/props/prop_vending_machine.gd")
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

const PURSUER_INTERCEPT_DAMAGE: float = 35.0
const SOFT_FAILURE_RECOVERY_HEALTH: float = 60.0

signal soft_failure_started
signal soft_failure_recovered

@onready var player: PlayerRunner = $Runner
@onready var camera: ChinatownCamera3D = $ChinatownCamera3D
@onready var corroded_panel: CorrodedPanel = $CorrodedPanel
@onready var touch_ui: TouchControlsUI = $CanvasLayer/TouchControlsUI
@onready var audio_mgr: Node = $AudioManager
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var power_conduit: MeshInstance3D = $PowerConduit
@onready var companion_presence_runtime: BurnsideCompanionPresenceRuntime = get_node_or_null("BurnsideCompanionPresenceRuntime")
@onready var fb13_companion_body: FB13CompanionBody = get_node_or_null("FB13CompanionBody")

var signal_tuner: SignalTuner = null
var courier_bike: CourierBike = null
var scrap_hauler: CharacterBody3D = null
var muscle_coupe: MuscleCoupe = null
var salvage_lockbox: StaticBody3D = null
var quota_kiosk: StaticBody3D = null
var scrap_dumpster: StaticBody3D = null
var street_vendor: StaticBody3D = null
var utility_pole: PropUtilityPole = null
var vending_machine: StaticBody3D = null
var traffic_barriers: Array[PropTrafficBarrier] = []
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

var _vitals_hud: PanelContainer = null
var _health_bar: ProgressBar = null
var _armor_bar: ProgressBar = null

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
			_check_pursuer_ram(impact_speed, col_pos, courier_bike)
			_check_kiosk_ram_breach(impact_speed, col_pos)
			_check_dumpster_ram(impact_speed, col_pos, courier_bike)
			_check_vendor_ram(impact_speed, col_pos, courier_bike)
			_check_barrier_ram(impact_speed, col_pos, courier_bike)
			_check_utility_pole_ram(impact_speed, col_pos, courier_bike)
			_check_crawler_ram(impact_speed, col_pos, courier_bike)
			_check_vending_machine_ram(impact_speed, col_pos, courier_bike)
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
			_check_pursuer_ram(impact_speed, col_pos, scrap_hauler)
			_check_kiosk_ram_breach(impact_speed, col_pos)
			_check_dumpster_ram(impact_speed, col_pos, scrap_hauler)
			_check_vendor_ram(impact_speed, col_pos, scrap_hauler)
			_check_barrier_ram(impact_speed, col_pos, scrap_hauler)
			_check_utility_pole_ram(impact_speed, col_pos, scrap_hauler)
			_check_crawler_ram(impact_speed, col_pos, scrap_hauler)
			_check_vending_machine_ram(impact_speed, col_pos, scrap_hauler)
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
			_check_pursuer_ram(impact_speed, col_pos, muscle_coupe)
			_check_kiosk_ram_breach(impact_speed, col_pos)
			_check_dumpster_ram(impact_speed, col_pos, muscle_coupe)
			_check_vendor_ram(impact_speed, col_pos, muscle_coupe)
			_check_barrier_ram(impact_speed, col_pos, muscle_coupe)
			_check_utility_pole_ram(impact_speed, col_pos, muscle_coupe)
			_check_crawler_ram(impact_speed, col_pos, muscle_coupe)
			_check_vending_machine_ram(impact_speed, col_pos, muscle_coupe)
		)
		if muscle_coupe.mount_interactable:
			_interactables.append(muscle_coupe.mount_interactable)
			
	if companion_presence_runtime and fb13_companion_body:
		companion_presence_runtime.configure(
			player,
			camera,
			fb13_companion_body,
			courier_bike,
			scrap_hauler as ScrapHauler,
			get_node_or_null("FB13ThrumWorldEvent")
		)
			
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
		
	var signal_gate_scene: PackedScene = load("res://scenes/interactions/signal_gate.tscn")
	if signal_gate_scene:
		signal_gate = signal_gate_scene.instantiate() as SignalGateInteractable
		signal_gate.name = "SignalGate"
		signal_gate.position = Vector3(-1.5, 0.5, 12.0)
		add_child(signal_gate)
		signal_gate.gate_triggered.connect(_on_signal_gate_triggered)
		_interactables.append(signal_gate)

	var lockbox_scene: PackedScene = load("res://scenes/props/prop_salvage_lockbox.tscn")
	if lockbox_scene:
		salvage_lockbox = lockbox_scene.instantiate() as StaticBody3D
		salvage_lockbox.name = "PropSalvageLockbox"
		# Keep the optional combat prop clear of the retained Signal Gate pursuer
		# detour corridor (first waypoint is around x=2.5, z=8.0).
		salvage_lockbox.position = Vector3(5.5, 0.0, 7.0)
		add_child(salvage_lockbox)
		salvage_lockbox.hit_received.connect(_on_lockbox_hit_received)
		salvage_lockbox.lockbox_breached.connect(_on_lockbox_breached)
		salvage_lockbox.alarm_triggered.connect(_on_lockbox_alarm_triggered)

	var kiosk_scene: PackedScene = load("res://scenes/props/prop_quota_kiosk.tscn")
	if kiosk_scene:
		quota_kiosk = kiosk_scene.instantiate() as StaticBody3D
		quota_kiosk.name = "PropQuotaKiosk"
		quota_kiosk.position = Vector3(-9.8, 0.0, -30.5)
		add_child(quota_kiosk)
		quota_kiosk.quota_deposited.connect(_on_quota_deposited)
		quota_kiosk.quota_fulfilled.connect(_on_quota_fulfilled)
		quota_kiosk.hit_received.connect(_on_kiosk_hit_received)
		quota_kiosk.alarm_triggered.connect(_on_kiosk_alarm_triggered)
		quota_kiosk.kiosk_breached.connect(_on_kiosk_breached)
		var kiosk_area = quota_kiosk.get_node_or_null("QuotaKioskInteractable") as InteractableBase
		if kiosk_area:
			_interactables.append(kiosk_area)

	var dumpster_scene: PackedScene = load("res://scenes/props/prop_scrap_dumpster.tscn")
	if dumpster_scene:
		scrap_dumpster = dumpster_scene.instantiate() as StaticBody3D
		scrap_dumpster.name = "PropScrapDumpster"
		scrap_dumpster.position = Vector3(-10.8, 0.0, -32.5)
		add_child(scrap_dumpster)
		scrap_dumpster.dumpster_scavenged.connect(_on_dumpster_scavenged)
		scrap_dumpster.player_entered_hiding.connect(_on_dumpster_player_entered_hiding)
		scrap_dumpster.player_exited_hiding.connect(_on_dumpster_player_exited_hiding)
		scrap_dumpster.hit_received.connect(_on_dumpster_hit_received)
		scrap_dumpster.dumpster_rammed.connect(_on_dumpster_rammed)
		var dumpster_area = scrap_dumpster.get_node_or_null("ScrapDumpsterInteractable") as InteractableBase
		if dumpster_area:
			_interactables.append(dumpster_area)

	var gears_slice = get_node_or_null("GearsDistrictSlice01B")
	if gears_slice and gears_slice.has_node("StreetClutter/StreetVendor"):
		street_vendor = gears_slice.get_node("StreetClutter/StreetVendor") as StaticBody3D
		street_vendor.position = Vector3(-8.5, 0.0, -22.0)
	else:
		var vendor_scene: PackedScene = load("res://scenes/props/prop_street_vendor.tscn")
		if vendor_scene:
			street_vendor = vendor_scene.instantiate() as StaticBody3D
			street_vendor.name = "PropStreetVendor"
			street_vendor.position = Vector3(-8.5, 0.0, -22.0)
			add_child(street_vendor)

	if street_vendor:
		street_vendor.tune_up_purchased.connect(_on_vendor_tune_up_purchased)
		street_vendor.hit_received.connect(_on_vendor_hit_received)
		street_vendor.vendor_rammed.connect(_on_vendor_rammed)
		var vendor_area = street_vendor.get_node_or_null("StreetVendorInteractable") as InteractableBase
		if vendor_area:
			_interactables.append(vendor_area)

	traffic_barriers.clear()
	if gears_slice and gears_slice.has_node("StreetClutter"):
		var clutter = gears_slice.get_node("StreetClutter")
		for child in clutter.get_children():
			if child is PropTrafficBarrier:
				traffic_barriers.append(child)
	if traffic_barriers.is_empty():
		var barrier_scene: PackedScene = load("res://scenes/props/prop_traffic_barrier.tscn")
		if barrier_scene:
			var b1 = barrier_scene.instantiate() as PropTrafficBarrier
			b1.name = "TrafficBarrier1"
			b1.position = Vector3(-2.5, 0.0, -28.0)
			add_child(b1)
			traffic_barriers.append(b1)
			var b2 = barrier_scene.instantiate() as PropTrafficBarrier
			b2.name = "TrafficBarrier2"
			b2.position = Vector3(-0.5, 0.0, -28.0)
			add_child(b2)
			traffic_barriers.append(b2)

	for barrier in traffic_barriers:
		barrier.barrier_hit.connect(func(hit_pos: Vector3, _dir: Vector3):
			if audio_mgr:
				audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
		)
		barrier.barrier_breached.connect(func(_impact_speed: float, _ram_dir: Vector3):
			if audio_mgr:
				audio_mgr.play_event(AudioManagerScript.SoundEvent.COLLISION_HEAD_ON, barrier.global_position)
				audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, barrier.global_position)
			trigger_disturbance_alert()
		)

	var pole_scene: PackedScene = load("res://scenes/props/prop_utility_pole.tscn")
	if pole_scene:
		utility_pole = pole_scene.instantiate() as PropUtilityPole
		utility_pole.name = "PropUtilityPole"
		utility_pole.position = Vector3(-6.2, 0.0, -18.0)
		add_child(utility_pole)
		utility_pole.grid_overloaded.connect(_on_utility_pole_grid_overloaded)
		utility_pole.hit_received.connect(_on_utility_pole_hit_received)
		utility_pole.pole_rammed.connect(_on_utility_pole_rammed)
		var pole_area = utility_pole.get_node_or_null("UtilityPoleInteractable") as InteractableBase
		if pole_area:
			_interactables.append(pole_area)

	var vending_scene: PackedScene = load("res://scenes/props/prop_vending_machine.tscn")
	if vending_scene:
		vending_machine = vending_scene.instantiate() as PropVendingMachine
		vending_machine.name = "PropVendingMachine"
		vending_machine.position = Vector3(-6.5, 0.0, -25.0)
		vending_machine.setup_audio(audio_mgr)
		add_child(vending_machine)
		vending_machine.terminal_hacked.connect(_on_vending_machine_hacked)
		vending_machine.terminal_breached.connect(_on_vending_machine_breached)
		vending_machine.hit_received.connect(_on_vending_machine_hit_received)
		vending_machine.vending_machine_rammed.connect(_on_vending_machine_rammed)
		var vending_area := vending_machine.get_node_or_null("VendingMachineInteractable") as InteractableBase
		if vending_area:
			_interactables.append(vending_area)

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
		# The optional crawler patrol runs beside, not through, the retained
		# Signal Tuner interaction lane. This keeps both authored interactions
		# reachable without priority hacks.
		utility_crawler.position = Vector3(1.0, 0.05, 1.5)
		utility_crawler.patrol_waypoints = [Vector3(1.0, 0.05, 1.5), Vector3(1.0, 0.05, 6.0)]
		utility_crawler.safe_anchor = Vector3(1.0, 0.05, 0.8)
		utility_crawler.setup_audio(audio_mgr)
		add_child(utility_crawler)
		ambient_actors.append(utility_crawler)
		var crawler_area := utility_crawler.get_node_or_null("UtilityCrawlerInteractable") as InteractableBase
		if crawler_area:
			_interactables.append(crawler_area)
		if utility_crawler.has_signal("crawler_intercepted"):
			utility_crawler.connect("crawler_intercepted", _on_crawler_intercepted)
		if utility_crawler.has_signal("hit_received"):
			utility_crawler.connect("hit_received", _on_crawler_hit_received)
		if utility_crawler.has_signal("crawler_disabled"):
			utility_crawler.connect("crawler_disabled", _on_crawler_disabled)
		if utility_crawler.has_signal("crawler_rammed"):
			utility_crawler.connect("crawler_rammed", _on_crawler_rammed)
		
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
		player.vitals_changed.connect(_update_vitals_hud)
		player.depleted.connect(_begin_soft_failure)
		_ensure_vitals_hud()
		_update_vitals_hud(player.current_health, player.current_armor)
		
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
	if player:
		player.set_safe_recovery_enabled(
			current_pursuit_state == PursuitState.CALM
			or current_pursuit_state == PursuitState.EVADED
			or current_pursuit_state == PursuitState.RETRY_READY
		)
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
				if pursuer.current_state == PursuerPrototype.PursuerState.STUNNED:
					pass
				elif _is_vehicle_ramming(target, pursuer):
					var speed: float = 0.0
					if "current_speed" in target:
						speed = abs(target.current_speed)
					elif target is CharacterBody3D:
						speed = (target as CharacterBody3D).velocity.length()
					_check_pursuer_ram(maxf(speed, 5.0), pursuer.global_position, target)
				else:
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

func _is_vehicle_ramming(target: Node3D, pursuer_node: PursuerPrototype) -> bool:
	if not target or target == player:
		return false
	if target != active_vehicle and target != courier_bike and target != scrap_hauler and target != muscle_coupe:
		return false

	var speed: float = 0.0
	var forward: Vector3 = -target.global_transform.basis.z
	if "current_speed" in target:
		speed = abs(target.current_speed)
	elif target is CharacterBody3D:
		var vel := (target as CharacterBody3D).velocity
		speed = vel.length()
		if speed > 0.5:
			forward = vel.normalized()

	if speed < 4.0:
		return false

	var to_pursuer := (pursuer_node.global_position - target.global_position).normalized()
	to_pursuer.y = 0.0
	return forward.dot(to_pursuer) > 0.2

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

	if player:
		player.apply_damage(PURSUER_INTERCEPT_DAMAGE)
		# PlayerRunner.depleted is the generic Soft Failure seam. If this hit
		# depleted Health, the synchronous signal already entered recovery.
		if player.current_health <= 0.0:
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

func _begin_soft_failure() -> void:
	current_pursuit_state = PursuitState.INTERCEPTED
	soft_failure_started.emit()
	print("[SOFT_FAILURE] Runner depleted. Ending immediate danger without resetting durable progress...")

	_last_pursuit_vehicle = _get_active_vehicle() if _get_active_vehicle() else _last_pursuit_vehicle
	_steer_input = 0.0
	_throttle_input = 0.0
	_handbrake_input = false
	if player:
		player.is_input_locked = true
	if courier_bike:
		courier_bike.force_dismount()
	if scrap_hauler:
		scrap_hauler.force_dismount()
	if muscle_coupe:
		muscle_coupe.force_dismount()
	if audio_mgr:
		audio_mgr.clear_radio_interference()
	_end_pursuit_common(true)
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.PURSUIT_INTERCEPTED, player.global_position if player else Vector3.ZERO)
	if touch_ui:
		touch_ui.show_replay_overlay(true)
		touch_ui.show_tension_hud("[ DOWN // RECOVERING ]")

	get_tree().create_timer(0.8).timeout.connect(func():
		if current_pursuit_state != PursuitState.INTERCEPTED:
			return
		if player:
			player.global_position = _recovery_marker + Vector3(-1.5, 0, 0)
			player.velocity = Vector3.ZERO
			player.reset_vitals(SOFT_FAILURE_RECOVERY_HEALTH, 0.0)
			player.is_input_locked = false
		if courier_bike:
			courier_bike.global_position = _recovery_marker
			courier_bike.rotation = Vector3.ZERO
		if scrap_hauler:
			scrap_hauler.global_position = _recovery_marker + Vector3(3.0, 0, 0)
			scrap_hauler.rotation = Vector3.ZERO
		current_pursuit_state = PursuitState.RETRY_READY
		if touch_ui:
			touch_ui.hide_tension_hud()
		if audio_mgr:
			audio_mgr.clear_radio_duck()
		soft_failure_recovered.emit()
		print("[SOFT_FAILURE] Recovery complete. Durable progress preserved; retry authority ready.")
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
	var active_veh := _get_active_vehicle()
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
		elif scrap_dumpster and (_active_target == scrap_dumpster.get_node_or_null("ScrapDumpsterInteractable") or (is_instance_valid(scrap_dumpster) and _active_target != null and _active_target.get_parent() == scrap_dumpster)):
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				var verb: String = "SEARCH"
				if _active_target.has_method("get_action_verb"):
					_active_target.set("is_pursuit_active", current_pursuit_state == PursuitState.PURSUIT_ACTIVE or current_pursuit_state == PursuitState.DISTURBANCE_ALERT)
					verb = _active_target.get_action_verb()
				touch_ui.action_button.text = "[E] " + verb
		elif street_vendor and (_active_target == street_vendor.get_node_or_null("StreetVendorInteractable") or (is_instance_valid(street_vendor) and _active_target != null and _active_target.get_parent() == street_vendor)):
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				var verb: String = "TUNE-UP"
				if _active_target.has_method("get_action_verb"):
					verb = _active_target.get_action_verb()
				if verb == "TUNE-UP":
					touch_ui.action_button.text = "[E] TUNE-UP // 150"
				else:
					touch_ui.action_button.text = "[E] " + verb
		elif utility_pole and (_active_target == utility_pole.get_node_or_null("UtilityPoleInteractable") or (is_instance_valid(utility_pole) and _active_target != null and _active_target.get_parent() == utility_pole)):
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				var verb: String = "TAP GRID"
				if _active_target.has_method("get_action_verb"):
					verb = _active_target.get_action_verb()
				touch_ui.action_button.text = "[E] " + verb
		elif utility_crawler and (_active_target == utility_crawler.get_node_or_null("UtilityCrawlerInteractable") or (is_instance_valid(utility_crawler) and _active_target != null and _active_target.get_parent() == utility_crawler)):
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				var verb: String = "INTERCEPT"
				if _active_target.has_method("get_action_verb"):
					verb = _active_target.get_action_verb()
				touch_ui.action_button.text = "[E] " + verb
		elif vending_machine and (_active_target == vending_machine.get_node_or_null("VendingMachineInteractable") or (is_instance_valid(vending_machine) and _active_target != null and _active_target.get_parent() == vending_machine)):
			touch_ui.set_action_button_highlight(true)
			if touch_ui.action_button:
				var verb: String = "HACK TERMINAL"
				if _active_target.has_method("get_action_verb"):
					verb = _active_target.get_action_verb()
				touch_ui.action_button.text = "[E] " + verb
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
	elif quota_kiosk and (_active_target == quota_kiosk.get_node_or_null("QuotaKioskInteractable") or (is_instance_valid(quota_kiosk) and _active_target.get_parent() == quota_kiosk)):
		if _active_target.has_method("set_player_reference"):
			_active_target.set_player_reference(player)
		_active_target.begin_interaction(active_pos)
	elif scrap_dumpster and (_active_target == scrap_dumpster.get_node_or_null("ScrapDumpsterInteractable") or (is_instance_valid(scrap_dumpster) and _active_target != null and _active_target.get_parent() == scrap_dumpster)):
		if _active_target.has_method("set_player_reference"):
			_active_target.set_player_reference(player)
		if _active_target.has_method("set_pursuit_active"):
			_active_target.set_pursuit_active(current_pursuit_state == PursuitState.PURSUIT_ACTIVE or current_pursuit_state == PursuitState.DISTURBANCE_ALERT)
		_active_target.begin_interaction(active_pos)
	elif street_vendor and (_active_target == street_vendor.get_node_or_null("StreetVendorInteractable") or (is_instance_valid(street_vendor) and _active_target != null and _active_target.get_parent() == street_vendor)):
		if _active_target.has_method("set_player_reference"):
			_active_target.set_player_reference(player)
		_active_target.begin_interaction(active_pos)
	elif utility_pole and (_active_target == utility_pole.get_node_or_null("UtilityPoleInteractable") or (is_instance_valid(utility_pole) and _active_target != null and _active_target.get_parent() == utility_pole)):
		if _active_target.has_method("set_player_reference"):
			_active_target.set_player_reference(player)
		_active_target.begin_interaction(active_pos)
	elif utility_crawler and (_active_target == utility_crawler.get_node_or_null("UtilityCrawlerInteractable") or (is_instance_valid(utility_crawler) and _active_target != null and _active_target.get_parent() == utility_crawler)):
		if _active_target.has_method("set_player_reference"):
			_active_target.set_player_reference(player)
		_active_target.begin_interaction(active_pos)
	elif vending_machine and (_active_target == vending_machine.get_node_or_null("VendingMachineInteractable") or (is_instance_valid(vending_machine) and _active_target != null and _active_target.get_parent() == vending_machine)):
		if _active_target.has_method("set_player_reference"):
			_active_target.set_player_reference(player)
		_active_target.begin_interaction(active_pos)

func _check_kiosk_ram_breach(impact_speed: float, col_pos: Vector3) -> void:
	if quota_kiosk and not quota_kiosk.is_breached:
		if col_pos.distance_to(quota_kiosk.global_position) < 4.0:
			if impact_speed >= 4.5:
				quota_kiosk.apply_vehicle_ram(impact_speed, Vector3.FORWARD)

func _check_dumpster_ram(impact_speed: float, col_pos: Vector3, vehicle_source: Node3D = null) -> void:
	if scrap_dumpster and not scrap_dumpster.is_rammed:
		if col_pos.distance_to(scrap_dumpster.global_position) < 4.5:
			if impact_speed >= 4.5:
				var ram_dir: Vector3 = -vehicle_source.global_transform.basis.z if vehicle_source else Vector3.FORWARD
				scrap_dumpster.apply_vehicle_ram(impact_speed, ram_dir, vehicle_source)

func _check_vendor_ram(impact_speed: float, col_pos: Vector3, vehicle_source: Node3D = null) -> void:
	if street_vendor and not street_vendor.is_rammed:
		if col_pos.distance_to(street_vendor.global_position) < 4.5:
			if impact_speed >= 4.5:
				var ram_dir: Vector3 = -vehicle_source.global_transform.basis.z if vehicle_source else Vector3.FORWARD
				street_vendor.apply_vehicle_ram(impact_speed, ram_dir, vehicle_source)

func _check_barrier_ram(impact_speed: float, col_pos: Vector3, vehicle_source: Node3D = null) -> void:
	for barrier in traffic_barriers:
		if is_instance_valid(barrier) and not barrier.is_breached:
			if col_pos.distance_to(barrier.global_position) < 4.5:
				if impact_speed >= 5.0:
					var ram_dir: Vector3 = -vehicle_source.global_transform.basis.z if vehicle_source else Vector3.FORWARD
					barrier.apply_vehicle_ram(impact_speed, ram_dir, vehicle_source)

func _check_utility_pole_ram(impact_speed: float, col_pos: Vector3, vehicle_source: Node3D = null) -> void:
	if utility_pole and not utility_pole.is_rammed:
		if col_pos.distance_to(utility_pole.global_position) < 4.5:
			if impact_speed >= 4.5:
				var ram_dir: Vector3 = -vehicle_source.global_transform.basis.z if vehicle_source else Vector3.FORWARD
				utility_pole.apply_vehicle_ram(impact_speed, ram_dir, vehicle_source)

func _check_crawler_ram(impact_speed: float, col_pos: Vector3, vehicle_source: Node3D = null) -> void:
	if utility_crawler and not utility_crawler.is_rammed:
		if col_pos.distance_to(utility_crawler.global_position) < 4.0:
			if impact_speed >= 4.5:
				var ram_dir: Vector3 = -vehicle_source.global_transform.basis.z if vehicle_source else Vector3.FORWARD
				utility_crawler.apply_vehicle_ram(impact_speed, ram_dir, vehicle_source)

func _check_vending_machine_ram(impact_speed: float, col_pos: Vector3, vehicle_source: Node3D = null) -> void:
	if vending_machine and not vending_machine.is_rammed:
		if col_pos.distance_to(vending_machine.global_position) < 4.0:
			if impact_speed >= 4.5:
				var ram_dir: Vector3 = -vehicle_source.global_transform.basis.z if vehicle_source else Vector3.FORWARD
				vending_machine.apply_vehicle_ram(impact_speed, ram_dir, vehicle_source)

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

func _check_pursuer_ram(impact_speed: float, col_pos: Vector3, vehicle: Node3D = null) -> bool:
	if not pursuer or not pursuer.is_active or pursuer.current_state == PursuerPrototype.PursuerState.INACTIVE:
		return false
	if pursuer.current_state == PursuerPrototype.PursuerState.STUNNED or pursuer.current_state == PursuerPrototype.PursuerState.EVADED_DISENGAGED:
		return false
	if col_pos.distance_to(pursuer.global_position) > 4.5:
		return false

	var ram_dir := pursuer.global_position - (vehicle.global_position if vehicle else col_pos)
	ram_dir.y = 0.0
	if vehicle and vehicle is CharacterBody3D:
		var veh_vel = (vehicle as CharacterBody3D).velocity
		if veh_vel.length() > 1.5:
			ram_dir = veh_vel

	var success: bool = pursuer.apply_vehicle_ram(impact_speed, ram_dir, vehicle)
	if success:
		if audio_mgr:
			audio_mgr.play_event(AudioManagerScript.SoundEvent.COLLISION_HEAD_ON, pursuer.global_position)
			audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, pursuer.global_position)
		if vehicle and "current_speed" in vehicle:
			vehicle.current_speed *= 0.65
		print("[WORLD] VEHICLE RAM SUCCESS! Pursuer disabled by %s at %.1f m/s" % [vehicle.name if vehicle else "vehicle", impact_speed])
		return true
	return false

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

func _on_quota_deposited(amount: int, _total_deposited: int, remaining: int) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SIGNAL_LOCK, quota_kiosk.global_position if quota_kiosk else Vector3.ZERO)
	if status_label:
		status_label.text = "[QUOTA KIOSK] DEPOSITED +%d SCRAP // %d REMAINING" % [amount, remaining]

func _on_quota_fulfilled(total_deposited: int) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION, quota_kiosk.global_position if quota_kiosk else Vector3.ZERO)
	if status_label:
		status_label.text = "[QUOTA KIOSK] CIVIC QUOTA FULFILLED! (%d SCRAP) // CLEARANCE GRANTED" % total_deposited
	if current_pursuit_state == PursuitState.PURSUIT_ACTIVE or current_pursuit_state == PursuitState.DISTURBANCE_ALERT:
		_end_pursuit_common(false)
		if pursuer:
			pursuer.start_de_escalation()

func _on_kiosk_hit_received(remaining_durability: int, hit_pos: Vector3, _impulse_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, hit_pos)
	if status_label:
		status_label.text = "[MUNICIPAL KIOSK TAMPER] DURABILITY %d/3 // SECURITY WARNING" % remaining_durability

func _on_kiosk_alarm_triggered(source_pos: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SIREN_ALARM, source_pos)
	if current_pursuit_state == PursuitState.CALM:
		trigger_disturbance_alert()
	if status_label:
		status_label.text = "[SECURITY ALERT] MUNICIPAL KIOSK TAMPER // PURSUIT INITIATED"

func _on_kiosk_breached(reward: int, breach_pos: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION, breach_pos)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, breach_pos)
	if status_label:
		status_label.text = "[MUNICIPAL KIOSK BREACHED] +%d EMERGENCY SCRAP CASHOUT!" % reward

func _on_dumpster_scavenged(reward: int, pos: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION, pos)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, pos)
	if status_label:
		status_label.text = "[DUMPSTER SCAVENGED] +%d SALVAGE SCRAP EXTRACTED" % reward

func _on_dumpster_player_entered_hiding(_hiding_player: CharacterBody3D) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, scrap_dumpster.global_position if scrap_dumpster else Vector3.ZERO)
	if current_pursuit_state == PursuitState.PURSUIT_ACTIVE or current_pursuit_state == PursuitState.DISTURBANCE_ALERT:
		_end_pursuit_common(false)
		if pursuer:
			pursuer.start_de_escalation()
	if status_label:
		status_label.text = "[STEALTH EVASION] CONCEALED IN DUMPSTER // PURSUIT DE-ESCALATING"

func _on_dumpster_player_exited_hiding(_exited_player: CharacterBody3D) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, scrap_dumpster.global_position if scrap_dumpster else Vector3.ZERO)
	if status_label:
		status_label.text = "[STEALTH EVASION] EXITED DUMPSTER // ON FOOT"

func _on_dumpster_hit_received(remaining_durability: int, hit_pos: Vector3, _impulse_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, hit_pos)
	if status_label:
		status_label.text = "[DUMPSTER TAMPER] DURABILITY %d/3" % remaining_durability

func _on_dumpster_rammed(impact_speed: float, _ram_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COLLISION_HEAD_ON, scrap_dumpster.global_position if scrap_dumpster else Vector3.ZERO)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, scrap_dumpster.global_position if scrap_dumpster else Vector3.ZERO)
	if status_label:
		status_label.text = "[DUMPSTER RAMMED] IMPACT AT %.1f M/S" % impact_speed

func _on_vendor_tune_up_purchased(cost: int, duration: float, pos: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COMPLETION, pos)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, pos)
	if courier_bike and courier_bike.has_method("apply_tune_up"):
		courier_bike.apply_tune_up(duration)
	if muscle_coupe and muscle_coupe.has_method("apply_tune_up"):
		muscle_coupe.apply_tune_up(duration)
	if status_label:
		status_label.text = "[STREET VENDOR] TUNE-UP ACQUIRED! (+35%% SPEED // %.0fs SURGE)" % duration

func _on_vendor_hit_received(remaining_durability: int, hit_pos: Vector3, _impulse_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, hit_pos)
	if status_label:
		status_label.text = "[VENDOR TAMPER] DURABILITY %d/3" % remaining_durability

func _on_vendor_rammed(impact_speed: float, _ram_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COLLISION_HEAD_ON, street_vendor.global_position if street_vendor else Vector3.ZERO)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, street_vendor.global_position if street_vendor else Vector3.ZERO)
	if status_label:
		status_label.text = "[VENDOR RAMMED] CANOPY DESTROYED AT %.1f M/S" % impact_speed

func _on_utility_pole_grid_overloaded(shockwave_radius: float, origin_pos: Vector3) -> void:
	if pursuer and is_instance_valid(pursuer) and pursuer.is_active:
		if origin_pos.distance_to(pursuer.global_position) <= shockwave_radius:
			pursuer.apply_emp_stun(4.0)
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, origin_pos)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.DISTURBANCE_ALERT, origin_pos)
	trigger_disturbance_alert()
	if status_label:
		status_label.text = "[EMP GRID OVERLOAD] 9.0M SHOCKWAVE DETONATED // PURSUERS STUNNED"

func _on_utility_pole_hit_received(remaining_durability: int, hit_pos: Vector3, _impulse_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
		if remaining_durability <= 0:
			audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, hit_pos)
	if status_label:
		status_label.text = "[POLE TAMPER] TRANSFORMER DURABILITY %d/3" % remaining_durability

func _on_utility_pole_rammed(impact_speed: float, _ram_dir: Vector3) -> void:
	if audio_mgr:
		audio_mgr.play_event(AudioManagerScript.SoundEvent.COLLISION_HEAD_ON, utility_pole.global_position if utility_pole else Vector3.ZERO)
		audio_mgr.play_event(AudioManagerScript.SoundEvent.SPARK, utility_pole.global_position if utility_pole else Vector3.ZERO)
	trigger_disturbance_alert()
	if status_label:
		status_label.text = "[POLE RAMMED] TRANSFORMER BLOWN AT %.1f M/S" % impact_speed

func _on_crawler_intercepted(reward: int, _pos: Vector3) -> void:
	if status_label:
		status_label.text = "[CRAWLER INTERCEPTED] +%d SCRAP HARVESTED" % reward

func _on_crawler_hit_received(remaining_durability: int, _hit_pos: Vector3, _impulse_dir: Vector3) -> void:
	if status_label:
		status_label.text = "[CRAWLER TAMPER] DURABILITY %d/2" % remaining_durability

func _on_crawler_disabled(reward: int, _pos: Vector3) -> void:
	if status_label:
		status_label.text = "[CRAWLER DISABLED] 2/2 HITS // +%d SCRAP EXTRACTED" % reward

func _on_crawler_rammed(impact_speed: float, _ram_dir: Vector3) -> void:
	if status_label:
		status_label.text = "[CRAWLER WRECKED] HIGH-SPEED IMPACT AT %.1f M/S // ALARM ACTIVE" % impact_speed

func _on_vending_machine_hacked(reward: int, _pos: Vector3) -> void:
	if status_label:
		status_label.text = "[TERMINAL HACKED] +%d CONTRABAND SCRAP DISPENSED" % reward
	var vending_event = get_node_or_null("VendingMachineWorldEvent")
	if vending_event and vending_event.has_method("notify_hacked"):
		vending_event.notify_hacked(reward, _pos)

func _on_vending_machine_hit_received(remaining_durability: int, _hit_pos: Vector3, _impulse_dir: Vector3) -> void:
	if status_label:
		status_label.text = "[VENDING TAMPER] CHASSIS DURABILITY %d/3" % remaining_durability

func _on_vending_machine_breached(reward: int, _pos: Vector3) -> void:
	trigger_disturbance_alert()
	if status_label:
		status_label.text = "[VENDING BREACHED] VAULT SHATTERED // +%d SCRAP SPILLED" % reward
	var vending_event = get_node_or_null("VendingMachineWorldEvent")
	if vending_event and vending_event.has_method("notify_breached"):
		vending_event.notify_breached(reward, _pos)

func _on_vending_machine_rammed(impact_speed: float, _ram_dir: Vector3) -> void:
	trigger_disturbance_alert()
	if status_label:
		status_label.text = "[VENDING WRECKED] HIGH-SPEED IMPACT AT %.1f M/S // ALARM ACTIVE" % impact_speed
	var vending_event = get_node_or_null("VendingMachineWorldEvent")
	if vending_event and vending_event.has_method("notify_rammed"):
		vending_event.notify_rammed(impact_speed, _ram_dir)

func _set_hud_input_transparent(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ensure_vitals_hud() -> void:
	if _vitals_hud != null:
		return
	var safe_root := get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot") as Control
	if safe_root == null:
		return

	_vitals_hud = PanelContainer.new()
	_vitals_hud.name = "VitalsHUD"
	_set_hud_input_transparent(_vitals_hud)
	_vitals_hud.z_index = 38
	_vitals_hud.offset_left = 24.0
	_vitals_hud.offset_top = 174.0
	_vitals_hud.offset_right = 244.0
	_vitals_hud.offset_bottom = 258.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.035, 0.045, 0.72)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 8
	panel_style.content_margin_top = 6
	panel_style.content_margin_right = 8
	panel_style.content_margin_bottom = 6
	_vitals_hud.add_theme_stylebox_override("panel", panel_style)
	safe_root.add_child(_vitals_hud)

	var margin := MarginContainer.new()
	margin.name = "VitalsMargin"
	_set_hud_input_transparent(margin)
	_vitals_hud.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "VitalsStack"
	_set_hud_input_transparent(stack)
	stack.add_theme_constant_override("separation", 2)
	margin.add_child(stack)

	var health_label := Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HEALTH"
	health_label.add_theme_font_size_override("font_size", 11)
	_set_hud_input_transparent(health_label)
	stack.add_child(health_label)

	_health_bar = ProgressBar.new()
	_health_bar.name = "HealthBar"
	_health_bar.min_value = 0.0
	_health_bar.max_value = PlayerRunner.MAX_HEALTH
	_health_bar.show_percentage = false
	_health_bar.custom_minimum_size = Vector2(196.0, 10.0)
	_set_hud_input_transparent(_health_bar)
	stack.add_child(_health_bar)

	var armor_label := Label.new()
	armor_label.name = "ArmorLabel"
	armor_label.text = "ARMOR"
	armor_label.add_theme_font_size_override("font_size", 10)
	_set_hud_input_transparent(armor_label)
	stack.add_child(armor_label)

	_armor_bar = ProgressBar.new()
	_armor_bar.name = "ArmorBar"
	_armor_bar.min_value = 0.0
	_armor_bar.max_value = PlayerRunner.MAX_ARMOR
	_armor_bar.show_percentage = false
	_armor_bar.custom_minimum_size = Vector2(196.0, 8.0)
	_set_hud_input_transparent(_armor_bar)
	stack.add_child(_armor_bar)

func _update_vitals_hud(health: float, armor: float) -> void:
	_ensure_vitals_hud()
	if _health_bar:
		_health_bar.value = health
	if _armor_bar:
		_armor_bar.value = armor

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
	if courier_bike and courier_bike.has_method("reset_condition"):
		courier_bike.reset_condition()
	if scrap_hauler and scrap_hauler.has_method("reset_condition"):
		scrap_hauler.reset_condition()
	active_vehicle = null
	if companion_presence_runtime:
		companion_presence_runtime.reset_presence()
		
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
		player.reset_vitals()
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
		courier_bike.tune_up_time_remaining = 0.0
		if courier_bike.visual_root: courier_bike.visual_root.rotation = Vector3.ZERO
		if courier_bike.mount_interactable:
			courier_bike.mount_interactable.is_powered = true
			courier_bike.mount_interactable.visible = true

	if scrap_hauler:
		scrap_hauler.current_state = ScrapHaulerScript.VehicleState.PARKED
		scrap_hauler.current_gear = ScrapHaulerScript.GearState.FORWARD
		scrap_hauler.is_handbrake_active = false
		scrap_hauler._gear_settle_timer = 0.0
		scrap_hauler.global_position = Vector3(1.0, 0.05, 6.0)
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
		muscle_coupe.tune_up_time_remaining = 0.0
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

	var crawler_event = get_node_or_null("UtilityCrawlerWorldEvent")
	if crawler_event and crawler_event.has_method("reset_world_event"):
		crawler_event.reset_world_event()

	var vending_event = get_node_or_null("VendingMachineWorldEvent")
	if vending_event and vending_event.has_method("reset_world_event"):
		vending_event.reset_world_event()

	if vending_machine and vending_machine.has_method("reset_vending_machine"):
		vending_machine.reset_vending_machine()

	if salvage_lockbox and salvage_lockbox.has_method("reset_lockbox"):
		salvage_lockbox.reset_lockbox()

	if quota_kiosk and quota_kiosk.has_method("reset_kiosk"):
		quota_kiosk.reset_kiosk()

	if scrap_dumpster and scrap_dumpster.has_method("reset_dumpster"):
		scrap_dumpster.reset_dumpster()

	if street_vendor and street_vendor.has_method("reset_vendor"):
		street_vendor.reset_vendor()

	for barrier in traffic_barriers:
		if is_instance_valid(barrier) and barrier.has_method("reset_barrier"):
			barrier.reset_barrier()

	if utility_pole and utility_pole.has_method("reset_pole"):
		utility_pole.reset_pole()

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

