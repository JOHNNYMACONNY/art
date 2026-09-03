class_name GearsSurveyedServiceCutRuntime
extends Node3D

const SurveyedRouteProgressStoreScript = preload("res://scripts/progress/surveyed_route_progress_store.gd")

const ROUTE_ID := "gears.service_alley_north_connector"
const MAX_SAMPLE_JUMP_M := 3.0
const MIN_TRAVERSAL_DISTANCE_M := 12.0
const ENTRY_RADIUS_M := 2.5
const CONNECTOR_RADIUS_M := 3.2
const CORRIDOR_TOLERANCE_M := 1.0

enum TraversalSide {
	NONE,
	ALLEY,
	CONNECTOR,
}

var _root_controller: Node = null
var _district: Node3D = null
var _player: Node3D = null
var _scrapper_runtime: Node = null
var _touch_ui: Node = null
var _entry_socket: Node3D = null
var _connector: Node3D = null
var _service_alley_bounds: Dictionary = {}
var _connector_bounds: Dictionary = {}
var _progress_store = null

var _configured := false
var _armed_side := TraversalSide.NONE
var _last_sample := Vector3.ZERO
var _has_last_sample := false
var _travel_distance_m := 0.0
var _survey_record_count := 0

func configure(root_controller: Node, district: Node3D, progress_store = null) -> bool:
	if root_controller == null or district == null:
		return false
	_root_controller = root_controller
	_district = district
	_player = root_controller.get_node_or_null("Runner") as Node3D
	_scrapper_runtime = root_controller.get_node_or_null("GearsScrapperToolRuntime")
	_touch_ui = root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	_entry_socket = district.get_node_or_null("ServiceAlleyEntrySocket") as Node3D
	_connector = district.get_node_or_null("NorthConnector") as Node3D
	_service_alley_bounds = _surface_bounds("ServiceAlley")
	_connector_bounds = _surface_bounds("NorthConnector")
	if _player == null or _scrapper_runtime == null or _entry_socket == null or _connector == null:
		return false
	if _service_alley_bounds.is_empty() or _connector_bounds.is_empty():
		return false
	if not _scrapper_runtime.has_method("get_access_state_name"):
		return false

	_progress_store = progress_store
	if _progress_store == null:
		_progress_store = SurveyedRouteProgressStoreScript.new()
		_progress_store.call("configure")
	if _progress_store == null or not _progress_store.has_method("is_surveyed") or not _progress_store.has_method("mark_surveyed"):
		return false

	if _touch_ui != null and _touch_ui.has_signal("replay_pressed"):
		if not _touch_ui.replay_pressed.is_connected(_on_replay_pressed):
			_touch_ui.replay_pressed.connect(_on_replay_pressed)

	reset_transient_state()
	_configured = true
	set_physics_process(true)
	return true

func _surface_bounds(body_name: String) -> Dictionary:
	if _district == null:
		return {}
	var body := _district.get_node_or_null(body_name) as Node3D
	var collider := _district.get_node_or_null("%s/CollisionShape3D" % body_name) as CollisionShape3D
	if body == null or collider == null:
		return {}
	var shape := collider.shape as BoxShape3D
	if shape == null:
		return {}
	var half := shape.size * 0.5
	return {
		"min_x": body.global_position.x - half.x,
		"max_x": body.global_position.x + half.x,
		"min_z": body.global_position.z - half.z,
		"max_z": body.global_position.z + half.z,
	}

func _physics_process(_delta: float) -> void:
	if not _configured or _player == null or is_route_surveyed():
		return
	sample_player_position(_player.global_position)

func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _is_access_open() -> bool:
	return _scrapper_runtime != null and String(_scrapper_runtime.call("get_access_state_name")) == "FORCED_OPEN"

func _side_for_position(position: Vector3) -> int:
	if _entry_socket != null and _horizontal_distance(position, _entry_socket.global_position) <= ENTRY_RADIUS_M:
		return TraversalSide.ALLEY
	if _connector != null and _horizontal_distance(position, _connector.global_position) <= CONNECTOR_RADIUS_M:
		return TraversalSide.CONNECTOR
	return TraversalSide.NONE

func _point_in_bounds(position: Vector3, bounds: Dictionary, tolerance: float) -> bool:
	if bounds.is_empty():
		return false
	return position.x >= float(bounds.get("min_x", 0.0)) - tolerance \
		and position.x <= float(bounds.get("max_x", 0.0)) + tolerance \
		and position.z >= float(bounds.get("min_z", 0.0)) - tolerance \
		and position.z <= float(bounds.get("max_z", 0.0)) + tolerance

func _is_in_route_corridor(position: Vector3) -> bool:
	return _point_in_bounds(position, _service_alley_bounds, CORRIDOR_TOLERANCE_M) \
		or _point_in_bounds(position, _connector_bounds, CORRIDOR_TOLERANCE_M)

func sample_player_position(position: Vector3) -> void:
	if not _configured or is_route_surveyed():
		return
	if not _is_access_open():
		reset_transient_state()
		return

	var sample_side := _side_for_position(position)
	if _armed_side == TraversalSide.NONE:
		if sample_side == TraversalSide.NONE:
			return
		_armed_side = sample_side
		_last_sample = position
		_has_last_sample = true
		_travel_distance_m = 0.0
		return

	if not _has_last_sample:
		reset_transient_state()
		return

	var step_distance := _horizontal_distance(_last_sample, position)
	if step_distance > MAX_SAMPLE_JUMP_M:
		reset_transient_state()
		return
	if not _is_in_route_corridor(position):
		reset_transient_state()
		return

	_travel_distance_m += step_distance
	_last_sample = position

	if sample_side == TraversalSide.NONE or sample_side == _armed_side:
		return
	if _travel_distance_m < MIN_TRAVERSAL_DISTANCE_M:
		return

	if bool(_progress_store.call("mark_surveyed", ROUTE_ID)):
		_survey_record_count += 1
	reset_transient_state()

func reset_transient_state() -> void:
	_armed_side = TraversalSide.NONE
	_last_sample = Vector3.ZERO
	_has_last_sample = false
	_travel_distance_m = 0.0

func _on_replay_pressed() -> void:
	reset_transient_state()

func is_route_surveyed() -> bool:
	return _progress_store != null and bool(_progress_store.call("is_surveyed", ROUTE_ID))

func get_survey_record_count() -> int:
	return _survey_record_count

func get_route_id() -> String:
	return ROUTE_ID

func get_progress_store():
	return _progress_store

func get_transient_state_name() -> String:
	match _armed_side:
		TraversalSide.ALLEY:
			return "ARMED_ALLEY"
		TraversalSide.CONNECTOR:
			return "ARMED_CONNECTOR"
		_:
			return "IDLE"
