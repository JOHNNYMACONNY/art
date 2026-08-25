extends Node

## Thin authored adapter for Mission/Narrative 02. Existing production systems
## retain authority over vehicles, pursuit, Signal Gate, camera, radio and replay.

const MissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")
const CityThatForgotRuntimeScript = preload("res://scripts/missions/city_that_forgot_runtime.gd")
const RETURN_ZONE_POSITION := Vector3(7.0, 0.08, 8.0)
const RETURN_ZONE_RADIUS := 2.6

var mission = MissionScript.new()
var _root_controller: Node = null
var _mission_one_runtime = null
var _scrap_hauler = null
var _signal_gate = null
var _bound: bool = false

var _return_zone: MeshInstance3D = null
var _mission_title: Label = null
var _objective_label: Label = null
var _contact_label: Label = null

func _ready() -> void:
	_root_controller = get_parent()
	_ensure_mission_three_runtime()
	call_deferred("_try_bind_runtime")

func _process(_delta: float) -> void:
	if not _bound:
		_try_bind_runtime()
		return

	var mission_one_complete: bool = _mission_one_runtime != null \
	and _mission_one_runtime.mission.phase == ScrapJobMissionScript.Phase.COMPLETE

	if mission.phase == MissionScript.Phase.LOCKED and mission_one_complete:
		if mission.unlock_after_scrap_job():
			_refresh_hud()
	elif mission.phase != MissionScript.Phase.LOCKED and not mission_one_complete:
		_reset_for_full_replay()
		return

	# The Hauler is retained production state and can already be occupied when
	# Mission 01 completes. Reconcile that authoritative state so a one-shot mount
	# signal consumed while this mission was LOCKED cannot strand GET_HAULER.
	if mission.phase == MissionScript.Phase.GET_HAULER \
	and _scrap_hauler != null \
	and _scrap_hauler.get("occupant") != null:
		_on_hauler_mounted(_scrap_hauler.get("occupant"))

	var root_pursuit_state := int(_root_controller.get("current_pursuit_state"))
	var changed := false
	if mission.phase == MissionScript.Phase.ESCAPE \
	and root_pursuit_state == int(ScrapTestBlockScript.PursuitState.INTERCEPTED):
		changed = mission.on_intercepted() or changed
	elif mission.phase == MissionScript.Phase.FAILED \
	and root_pursuit_state == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE):
		changed = mission.on_retry_started() or changed
	elif mission.phase == MissionScript.Phase.ESCAPE \
	and root_pursuit_state == int(ScrapTestBlockScript.PursuitState.EVADED):
		if mission.on_evasion_complete():
			changed = true
			_set_return_zone_visible(true)

	if mission.phase == MissionScript.Phase.DELIVERY \
	and _return_zone != null \
	and _scrap_hauler != null \
	and _scrap_hauler.global_position.distance_to(_return_zone.global_position) <= RETURN_ZONE_RADIUS:
		if mission.on_return_zone_entered():
			changed = true
			_set_return_zone_visible(false)

	if changed:
		_refresh_hud()

func _ensure_mission_three_runtime() -> void:
	if _root_controller == null or _root_controller.get_node_or_null("CityThatForgotRuntime") != null:
		return
	var runtime := CityThatForgotRuntimeScript.new()
	runtime.name = "CityThatForgotRuntime"
	_root_controller.add_child(runtime)

func _try_bind_runtime() -> void:
	if _bound or _root_controller == null:
		return

	_mission_one_runtime = _root_controller.get_node_or_null("MissionScrapJobRuntime")
	_scrap_hauler = _root_controller.get("scrap_hauler")
	_signal_gate = _root_controller.get("signal_gate")
	var mission_hud := _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/MissionHUD")
	if _mission_one_runtime == null or _scrap_hauler == null or _signal_gate == null or mission_hud == null:
		return

	_mission_title = mission_hud.find_child("MissionTitle", true, false) as Label
	_objective_label = mission_hud.find_child("ObjectiveLabel", true, false) as Label
	_contact_label = mission_hud.find_child("ContactLabel", true, false) as Label
	if _mission_title == null or _objective_label == null or _contact_label == null:
		return

	_scrap_hauler.mounted.connect(_on_hauler_mounted)
	_signal_gate.gate_triggered.connect(_on_signal_gate_triggered)
	_create_return_zone()
	_bound = true
	print("[MISSION_NARRATIVE_02] Runtime bound to retained Scrap Hauler/pursuit systems")

func _on_hauler_mounted(_player) -> void:
	if not _bound:
		return
	if not mission.on_vehicle_mounted(_scrap_hauler.name):
		return
	_refresh_hud()
	# Pursuit remains controller-owned. This only asks the existing disturbance
	# authority to begin from its canonical CALM state.
	if _root_controller.has_method("trigger_disturbance_alert"):
		_root_controller.call("trigger_disturbance_alert")

func _on_signal_gate_triggered() -> void:
	if mission.on_gate_triggered():
		_refresh_hud()

func _create_return_zone() -> void:
	if _return_zone != null:
		return
	_return_zone = MeshInstance3D.new()
	_return_zone.name = "CivicRepossessionReturnZone"
	_return_zone.position = RETURN_ZONE_POSITION
	_return_zone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var zone_mesh := CylinderMesh.new()
	zone_mesh.top_radius = RETURN_ZONE_RADIUS
	zone_mesh.bottom_radius = RETURN_ZONE_RADIUS
	zone_mesh.height = 0.08
	zone_mesh.radial_segments = 32
	_return_zone.mesh = zone_mesh

	var zone_material := StandardMaterial3D.new()
	zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone_material.albedo_color = Color(0.9, 0.72, 0.2, 0.35)
	zone_material.emission_enabled = true
	zone_material.emission = Color(0.8, 0.5, 0.08, 1.0)
	zone_material.emission_energy_multiplier = 1.2
	_return_zone.material_override = zone_material

	var label := Label3D.new()
	label.text = "BURN // GARAGE"
	label.position = Vector3(0, 0.7, 0)
	label.font_size = 24
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_return_zone.add_child(label)

	_root_controller.add_child(_return_zone)
	_set_return_zone_visible(false)

func _set_return_zone_visible(visible_value: bool) -> void:
	if _return_zone != null:
		_return_zone.visible = visible_value

func _refresh_hud() -> void:
	if _mission_title == null or _objective_label == null or _contact_label == null:
		return
	_mission_title.text = "CIVIC REPOSSESSION // MAYOR BURN"
	_objective_label.text = mission.objective
	_contact_label.text = mission.contact_line

func _restore_mission_one_hud() -> void:
	if _mission_title == null or _objective_label == null or _contact_label == null or _mission_one_runtime == null:
		return
	_mission_title.text = "SCRAP JOB 01 // CITY PROPERTY"
	_objective_label.text = _mission_one_runtime.mission.objective
	_contact_label.text = _mission_one_runtime.mission.contact_line

func _reset_for_full_replay() -> void:
	mission = MissionScript.new()
	_set_return_zone_visible(false)
	_restore_mission_one_hud()
	print("[MISSION_NARRATIVE_02] Full replay detected; Civic Repossession relocked")
