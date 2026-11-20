extends Node

signal scrap_job_completed

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
var _completion_emitted_for_run: bool = false

var _mission_panel: PanelContainer = null
var _objective_label: Label = null
var _bike_wayfinding_label: Label = null
var _panel_wayfinding_label: Label = null
var _contact_label: Label = null
var _navigation_camera: Camera3D = null
var _opening_bike_marker: Label3D = null
var _tuner_mast_marker: Label3D = null
var _core_panel_marker: Label3D = null

func _ready() -> void:
	_root_controller = get_parent()
	mission = MissionScript.new()
	mission.start()
	call_deferred("_try_bind_runtime")

func _process(_delta: float) -> void:
	if not _bound:
		_try_bind_runtime()
		return

	_update_opening_bike_marker()
	_update_bike_wayfinding()
	_update_panel_wayfinding()
	_update_tuner_mast_marker()
	_update_core_panel_marker()
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
	_navigation_camera = _root_controller.get_node_or_null("ChinatownCamera3D") as Camera3D
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
	_ensure_opening_bike_marker()
	_ensure_tuner_mast_marker()
	_ensure_core_panel_marker()
	_update_opening_bike_marker()
	_update_tuner_mast_marker()
	_update_core_panel_marker()
	_ensure_hud()
	_refresh_hud()
	print("[MISSION_NARRATIVE_01] Runtime bound to retained golden-slice systems")

# Opening-objective landmark, scoped to the authored bike phase. Does not reveal
# the unsurveyed service cut or take ownership of bike/mount/save state.
func _ensure_opening_bike_marker() -> void:
	if _opening_bike_marker != null or _courier_bike == null:
		return
	_opening_bike_marker = Label3D.new()
	_opening_bike_marker.name = "OpeningCourierBikeMarker"
	_opening_bike_marker.position = Vector3(0.0, 2.65, 0.0)
	_opening_bike_marker.text = "COURIER BIKE"
	_opening_bike_marker.font_size = 40
	_opening_bike_marker.pixel_size = 0.007
	_opening_bike_marker.outline_size = 12
	_opening_bike_marker.outline_modulate = Color(0.03, 0.035, 0.04, 1.0)
	_opening_bike_marker.modulate = Color(1.0, 0.81, 0.27, 1.0)
	_opening_bike_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_opening_bike_marker.no_depth_test = true
	_courier_bike.add_child(_opening_bike_marker)

func _update_opening_bike_marker() -> void:
	if _opening_bike_marker != null:
		_opening_bike_marker.visible = mission != null and mission.phase == MissionScript.Phase.GET_BIKE

# A short camera-relative bearing belongs to the already disclosed first objective.
# Unlike fixed-time navigation, this updates as the follow camera turns and as
# players move past the bike; it does not bypass obstacles or select actions.
func _screen_relative_bearing(to_objective: Vector3) -> String:
	if _navigation_camera == null or to_objective.length_squared() <= 0.01:
		return "LOOK FOR LANDMARK"
	var forward: Vector3 = -_navigation_camera.global_transform.basis.z
	var right: Vector3 = _navigation_camera.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	if forward.length_squared() <= 0.01 or right.length_squared() <= 0.01:
		return "LOOK FOR LANDMARK"
	var direction: Vector3 = to_objective.normalized()
	var ahead: float = direction.dot(forward.normalized())
	var side: float = direction.dot(right.normalized())
	if absf(ahead) > absf(side) * 1.5:
		return "AHEAD" if ahead >= 0.0 else "BEHIND"
	if absf(side) > absf(ahead) * 1.5:
		return "RIGHT" if side >= 0.0 else "LEFT"
	var depth: String = "AHEAD" if ahead >= 0.0 else "BACK"
	var lateral: String = "RIGHT" if side >= 0.0 else "LEFT"
	return "%s-%s" % [depth, lateral]

func _update_bike_wayfinding() -> void:
	if _bike_wayfinding_label == null:
		return
	var active: bool = mission != null and mission.phase == MissionScript.Phase.GET_BIKE \
		and _runner != null and _courier_bike != null
	_bike_wayfinding_label.visible = active
	if not active:
		return
	var to_bike: Vector3 = _courier_bike.global_position - _runner.global_position
	to_bike.y = 0.0
	var distance_m: float = to_bike.length()
	var bearing: String = "SEEK [E] RIDE BIKE" if distance_m <= 2.5 else _screen_relative_bearing(to_bike)
	var label_text: String = "COURIER BIKE // %dm // %s" % [ceili(distance_m), bearing]
	if _bike_wayfinding_label.text != label_text:
		_bike_wayfinding_label.text = label_text

# The customs core is named by the mission after the tuner lock. Do not
# advertise an actionable E outside the retained panel's 2.5m action radius.
func _update_panel_wayfinding() -> void:
	if _panel_wayfinding_label == null:
		return
	var active: bool = mission != null and mission.phase == MissionScript.Phase.EXTRACT_CORE \
		and _runner != null and _corroded_panel != null
	_panel_wayfinding_label.visible = active
	if not active:
		return
	var to_panel: Vector3 = _corroded_panel.global_position - _runner.global_position
	to_panel.y = 0.0
	var distance_m: float = to_panel.length()
	var bearing: String = "SEEK [E] PEEL PANEL" if distance_m <= 2.5 else _screen_relative_bearing(to_panel)
	var label_text: String = "CORE PANEL // %dm // %s" % [ceili(distance_m), bearing]
	if _panel_wayfinding_label.text != label_text:
		_panel_wayfinding_label.text = label_text

# Authored mast is already identified by the mission objective. This landmark
# only marks that known target and does not disclose unsurveyed service routes.
func _ensure_tuner_mast_marker() -> void:
	if _tuner_mast_marker != null or _signal_tuner == null:
		return
	_tuner_mast_marker = Label3D.new()
	_tuner_mast_marker.name = "MissionTunerMastMarker"
	_tuner_mast_marker.position = Vector3(0.0, 2.35, 0.0)
	_tuner_mast_marker.text = "TUNER MAST"
	_tuner_mast_marker.font_size = 40
	_tuner_mast_marker.pixel_size = 0.007
	_tuner_mast_marker.outline_size = 12
	_tuner_mast_marker.outline_modulate = Color(0.03, 0.035, 0.04, 1.0)
	_tuner_mast_marker.modulate = Color(0.45, 0.94, 1.0, 1.0)
	_tuner_mast_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tuner_mast_marker.no_depth_test = true
	_signal_tuner.add_child(_tuner_mast_marker)

func _update_tuner_mast_marker() -> void:
	if _tuner_mast_marker == null or mission == null:
		return
	var needs_mast: bool = mission.phase == MissionScript.Phase.TRAVERSE_TO_TUNER
	var needs_spoof: bool = mission.phase == MissionScript.Phase.SPOOF_SIGNAL
	_tuner_mast_marker.visible = needs_mast or needs_spoof
	var marker_text: String = "SPOOF SIGNAL" if needs_spoof else "TUNER MAST"
	if _tuner_mast_marker.text != marker_text:
		_tuner_mast_marker.text = marker_text

# Phase-gated visual landmark for the disclosed extraction objective.
# Presentation only: actual E eligibility remains on CorrodedPanel.
func _ensure_core_panel_marker() -> void:
	if _core_panel_marker != null or _corroded_panel == null:
		return
	_core_panel_marker = Label3D.new()
	_core_panel_marker.name = "MissionCorePanelMarker"
	_core_panel_marker.position = Vector3(0.0, 2.25, 0.0)
	_core_panel_marker.text = "CORE PANEL"
	_core_panel_marker.font_size = 40
	_core_panel_marker.pixel_size = 0.007
	_core_panel_marker.outline_size = 12
	_core_panel_marker.outline_modulate = Color(0.03, 0.035, 0.04, 1.0)
	_core_panel_marker.modulate = Color(1.0, 0.81, 0.27, 1.0)
	_core_panel_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_core_panel_marker.no_depth_test = true
	_corroded_panel.add_child(_core_panel_marker)

func _update_core_panel_marker() -> void:
	if _core_panel_marker != null:
		_core_panel_marker.visible = mission != null and mission.phase == MissionScript.Phase.EXTRACT_CORE

# Selection hint only: the retained interactable still owns proximity,
# power and action eligibility. This prevents a nearby parked bike from
# stealing E while the player is legitimately working the mission terminal.
func get_mission_priority_interactable() -> InteractableBase:
	if not _bound or mission == null:
		return null
	if mission.phase == MissionScript.Phase.SPOOF_SIGNAL:
		return _signal_tuner as InteractableBase
	if mission.phase == MissionScript.Phase.EXTRACT_CORE:
		return _corroded_panel as InteractableBase
	return null

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
		if not _completion_emitted_for_run:
			_completion_emitted_for_run = true
			scrap_job_completed.emit()

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
	_completion_emitted_for_run = false
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
	_mission_panel.offset_top = 40.0
	_mission_panel.offset_right = 460.0
	_mission_panel.offset_bottom = 160.0

	var flat_style := StyleBoxFlat.new()
	flat_style.bg_color = Color(0.04, 0.05, 0.07, 0.45)
	flat_style.corner_radius_top_left = 4
	flat_style.corner_radius_top_right = 4
	flat_style.corner_radius_bottom_right = 4
	flat_style.corner_radius_bottom_left = 4
	flat_style.content_margin_left = 10
	flat_style.content_margin_top = 6
	flat_style.content_margin_right = 10
	flat_style.content_margin_bottom = 6
	_mission_panel.add_theme_stylebox_override("panel", flat_style)
	safe_root.add_child(_mission_panel)

	var margin := MarginContainer.new()
	margin.name = "MissionMargin"
	_make_input_transparent(margin)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	_mission_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "MissionStack"
	_make_input_transparent(stack)
	stack.add_theme_constant_override("separation", 3)
	margin.add_child(stack)

	var title := Label.new()
	title.name = "MissionTitle"
	_make_input_transparent(title)
	title.text = "SCRAP JOB 01 // CITY PROPERTY"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22, 1.0))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	stack.add_child(title)

	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_make_input_transparent(_objective_label)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size = Vector2(400.0, 0.0)
	_objective_label.add_theme_font_size_override("font_size", 14)
	_objective_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_objective_label.add_theme_constant_override("outline_size", 3)
	_objective_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	stack.add_child(_objective_label)

	_bike_wayfinding_label = Label.new()
	_bike_wayfinding_label.name = "BikeWayfindingLabel"
	_make_input_transparent(_bike_wayfinding_label)
	_bike_wayfinding_label.custom_minimum_size = Vector2(400.0, 0.0)
	_bike_wayfinding_label.add_theme_font_size_override("font_size", 13)
	_bike_wayfinding_label.add_theme_color_override("font_color", Color(1.0, 0.81, 0.27, 1.0))
	_bike_wayfinding_label.add_theme_constant_override("outline_size", 3)
	_bike_wayfinding_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	stack.add_child(_bike_wayfinding_label)

	_panel_wayfinding_label = Label.new()
	_panel_wayfinding_label.name = "PanelWayfindingLabel"
	_make_input_transparent(_panel_wayfinding_label)
	_panel_wayfinding_label.custom_minimum_size = Vector2(400.0, 0.0)
	_panel_wayfinding_label.add_theme_font_size_override("font_size", 13)
	_panel_wayfinding_label.add_theme_color_override("font_color", Color(1.0, 0.81, 0.27, 1.0))
	_panel_wayfinding_label.add_theme_constant_override("outline_size", 3)
	_panel_wayfinding_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	stack.add_child(_panel_wayfinding_label)

	_contact_label = Label.new()
	_contact_label.name = "ContactLabel"
	_make_input_transparent(_contact_label)
	_contact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contact_label.custom_minimum_size = Vector2(400.0, 0.0)
	_contact_label.add_theme_font_size_override("font_size", 12)
	_contact_label.add_theme_color_override("font_color", Color(0.85, 0.94, 1.0, 0.9))
	_contact_label.add_theme_constant_override("outline_size", 3)
	_contact_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	stack.add_child(_contact_label)

var _subtitle_tween: Tween

func _refresh_hud() -> void:
	_ensure_hud()
	if _objective_label == null or _contact_label == null:
		return
	_objective_label.text = mission.objective
	_update_bike_wayfinding()
	_update_panel_wayfinding()
	_update_core_panel_marker()
	_contact_label.text = mission.contact_line
	_contact_label.modulate.a = 1.0
	if _subtitle_tween != null and _subtitle_tween.is_valid():
		_subtitle_tween.kill()
	if not mission.contact_line.is_empty():
		_subtitle_tween = _contact_label.create_tween()
		if _subtitle_tween != null:
			_subtitle_tween.tween_interval(5.5)
			_subtitle_tween.tween_property(_contact_label, "modulate:a", 0.0, 0.8)
