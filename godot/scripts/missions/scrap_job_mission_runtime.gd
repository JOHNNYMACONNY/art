extends Node

## Thin adapter from the retained golden-slice runtime into the authored
## Mission/Narrative 01 state. It observes existing production signals/state and
## does not take ownership of vehicle, pursuit, camera, interaction or audio logic.

const MissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")
const TUNER_ARRIVAL_RADIUS := 5.0

var mission = null
var _root_controller: Node = null
var _runner: Node3D = null
var _courier_bike = null
var _signal_tuner = null
var _corroded_panel = null
var _signal_gate = null
var _pursuer = null
var _bound: bool = false

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

	var changed := false
	# The bike mount is the authored prerequisite, but the player may park short
	# of the mast and finish the approach on foot. Track the rider rather than
	# requiring the bike to remain occupied at the arrival boundary.
	if mission.phase == MissionScript.Phase.TRAVERSE_TO_TUNER \
	and _runner != null \
	and _signal_tuner != null \
	and _runner.global_position.distance_to(_signal_tuner.global_position) <= TUNER_ARRIVAL_RADIUS:
		changed = mission.on_tuner_arrived() or changed

	# Production interactions and pursuit authority already exist outside this
	# adapter. Reconcile their retained state every frame so one-shot signals used
	# before the authored prerequisite cannot strand the job, and so the root
	# controller's interception decision wins over the reset pursuer entity.
	changed = _reconcile_retained_progress() or changed
	if changed:
		_refresh_hud()

	_maybe_restart_after_full_slice_reset()

func _try_bind_runtime() -> void:
	if _bound or _root_controller == null:
		return

	_runner = _root_controller.get_node_or_null("Runner") as Node3D
	_courier_bike = _root_controller.get("courier_bike")
	_signal_tuner = _root_controller.get("signal_tuner")
	_corroded_panel = _root_controller.get("corroded_panel")
	_signal_gate = _root_controller.get("signal_gate")
	_pursuer = _root_controller.get("pursuer")
	if _runner == null or _courier_bike == null or _signal_tuner == null or _corroded_panel == null or _signal_gate == null or _pursuer == null:
		return

	_courier_bike.mounted.connect(_on_courier_bike_mounted)
	_signal_tuner.signal_locked.connect(_on_signal_locked)
	_corroded_panel.extraction_completed.connect(_on_core_extracted)
	_signal_gate.gate_triggered.connect(_on_gate_triggered)
	_pursuer.de_escalation_completed.connect(_on_escape_complete)
	_bound = true
	_ensure_hud()
	_refresh_hud()
	print("[MISSION_NARRATIVE_01] Runtime bound to retained golden-slice systems")

func _reconcile_retained_progress() -> bool:
	if not _bound or _root_controller == null:
		return false

	var tuner_solved := int(_signal_tuner.get("current_state")) >= int(SignalTuner.TunerState.LOCKED)
	var core_extracted := int(_corroded_panel.get("current_step")) == int(CorrodedPanel.Step.EXTRACTED)
	var root_pursuit_state := int(_root_controller.get("current_pursuit_state"))
	var pursuit_active := root_pursuit_state == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE)
	var intercepted := root_pursuit_state == int(ScrapTestBlockScript.PursuitState.INTERCEPTED)

	return mission.reconcile_retained_progress(
		tuner_solved,
		core_extracted,
		pursuit_active,
		intercepted
	)

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
	if int(_signal_tuner.get("current_state")) != int(SignalTuner.TunerState.DORMANT) \
	or int(_corroded_panel.get("current_step")) != int(CorrodedPanel.Step.IDLE):
		return
	mission = MissionScript.new()
	mission.start()
	_refresh_hud()
	print("[MISSION_NARRATIVE_01] Full slice reset detected; authored job restarted")

func _make_input_transparent(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ensure_hud() -> void:
	if _mission_panel != null:
		return
	var safe_root := _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot") as Control
	if safe_root == null:
		return

	_mission_panel = PanelContainer.new()
	_mission_panel.name = "MissionHUD"
	_make_input_transparent(_mission_panel)
	_mission_panel.z_index = 40
	_mission_panel.offset_left = 24.0
	_mission_panel.offset_top = 78.0
	_mission_panel.offset_right = 500.0
	_mission_panel.offset_bottom = 200.0
	safe_root.add_child(_mission_panel)

	var margin := MarginContainer.new()
	margin.name = "MissionMargin"
	_make_input_transparent(margin)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	_mission_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "MissionStack"
	_make_input_transparent(stack)
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)

	var title := Label.new()
	title.name = "MissionTitle"
	_make_input_transparent(title)
	title.text = "SCRAP JOB 01 // CITY PROPERTY"
	title.add_theme_font_size_override("font_size", 17)
	stack.add_child(title)

	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_make_input_transparent(_objective_label)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size = Vector2(440.0, 0.0)
	_objective_label.add_theme_font_size_override("font_size", 15)
	stack.add_child(_objective_label)

	_contact_label = Label.new()
	_contact_label.name = "ContactLabel"
	_make_input_transparent(_contact_label)
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
