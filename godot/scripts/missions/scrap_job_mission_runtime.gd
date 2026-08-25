extends Node

## Thin adapter from the retained golden-slice runtime into the authored
## Mission/Narrative 01 state. It observes existing production signals and does
## not take ownership of vehicle, pursuit, camera, interaction or audio logic.

const MissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const TUNER_ARRIVAL_RADIUS := 5.0

var mission = null
var _root_controller: Node = null
var _courier_bike = null
var _signal_tuner = null
var _corroded_panel = null
var _signal_gate = null
var _pursuer = null
var _bound: bool = false
var _pursuer_was_active: bool = false

var _mission_panel: PanelContainer = null
var _objective_label: Label = null
var _contact_label: Label = null

func _ready() -> void:
	_root_controller = get_parent()
	mission = MissionScript.new()
	mission.start()
	call_deferred("_try_bind_runtime")

func _process(_delta: float) -> void:
	if not _bound:
		_try_bind_runtime()
		return

	if mission.phase == MissionScript.Phase.TRAVERSE_TO_TUNER \
	and _courier_bike != null \
	and _signal_tuner != null \
	and _courier_bike.get("occupant") != null \
	and _courier_bike.global_position.distance_to(_signal_tuner.global_position) <= TUNER_ARRIVAL_RADIUS:
		if mission.on_tuner_arrived():
			_refresh_hud()

	var pursuer_active := bool(_pursuer.get("is_active")) if _pursuer != null else false
	if pursuer_active and not _pursuer_was_active:
		var changed := false
		if mission.phase == MissionScript.Phase.FAILED:
			changed = mission.on_retry_started() or changed
		elif mission.phase == MissionScript.Phase.PURSUIT_COMPLICATION:
			changed = mission.on_pursuit_active() or changed
		if changed:
			_refresh_hud()
	_pursuer_was_active = pursuer_active

	_maybe_restart_after_full_slice_reset()

func _try_bind_runtime() -> void:
	if _bound or _root_controller == null:
		return

	_courier_bike = _root_controller.get("courier_bike")
	_signal_tuner = _root_controller.get("signal_tuner")
	_corroded_panel = _root_controller.get("corroded_panel")
	_signal_gate = _root_controller.get("signal_gate")
	_pursuer = _root_controller.get("pursuer")
	if _courier_bike == null or _signal_tuner == null or _corroded_panel == null or _signal_gate == null or _pursuer == null:
		return

	_courier_bike.mounted.connect(_on_courier_bike_mounted)
	_signal_tuner.signal_locked.connect(_on_signal_locked)
	_corroded_panel.extraction_completed.connect(_on_core_extracted)
	_signal_gate.gate_triggered.connect(_on_gate_triggered)
	_pursuer.intercepted_target.connect(_on_intercepted)
	_pursuer.de_escalation_completed.connect(_on_escape_complete)
	_pursuer_was_active = bool(_pursuer.get("is_active"))
	_bound = true
	_ensure_hud()
	_refresh_hud()
	print("[MISSION_NARRATIVE_01] Runtime bound to retained golden-slice systems")

func _on_courier_bike_mounted(_player) -> void:
	if mission.on_courier_bike_mounted():
		_refresh_hud()

func _on_signal_locked(_tuner) -> void:
	if mission.on_signal_locked():
		_refresh_hud()

func _on_core_extracted() -> void:
	if mission.on_core_extracted():
		_refresh_hud()

func _on_gate_triggered() -> void:
	if mission.on_gate_triggered():
		_refresh_hud()

func _on_intercepted() -> void:
	if mission.on_intercepted():
		_refresh_hud()

func _on_escape_complete() -> void:
	if mission.on_escape_complete():
		_refresh_hud()

func _maybe_restart_after_full_slice_reset() -> void:
	if mission.phase != MissionScript.Phase.COMPLETE and mission.phase != MissionScript.Phase.FAILED:
		return
	if _pursuer != null and bool(_pursuer.get("is_active")):
		return
	# Full replay resets solved tuner/panel state. Fast pursuit retry deliberately
	# preserves the extracted panel, so this cannot accidentally replay setup.
	if int(_signal_tuner.get("current_state")) != 0 or int(_corroded_panel.get("current_step")) != 0:
		return
	mission = MissionScript.new()
	mission.start()
	_refresh_hud()
	print("[MISSION_NARRATIVE_01] Full slice reset detected; authored job restarted")

func _ensure_hud() -> void:
	if _mission_panel != null:
		return
	var safe_root := _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot") as Control
	if safe_root == null:
		return

	_mission_panel = PanelContainer.new()
	_mission_panel.name = "MissionHUD"
	_mission_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_panel.z_index = 40
	_mission_panel.offset_left = 24.0
	_mission_panel.offset_top = 24.0
	_mission_panel.offset_right = 500.0
	_mission_panel.offset_bottom = 138.0
	safe_root.add_child(_mission_panel)

	var margin := MarginContainer.new()
	margin.name = "MissionMargin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	_mission_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "MissionStack"
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)

	var title := Label.new()
	title.name = "MissionTitle"
	title.text = "SCRAP JOB 01 // CITY PROPERTY"
	title.add_theme_font_size_override("font_size", 17)
	stack.add_child(title)

	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size = Vector2(440.0, 0.0)
	_objective_label.add_theme_font_size_override("font_size", 15)
	stack.add_child(_objective_label)

	_contact_label = Label.new()
	_contact_label.name = "ContactLabel"
	_contact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contact_label.custom_minimum_size = Vector2(440.0, 0.0)
	_contact_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(_contact_label)

func _refresh_hud() -> void:
	_ensure_hud()
	if _objective_label == null or _contact_label == null:
		return
	_objective_label.text = mission.objective
	_contact_label.text = mission.contact_line
