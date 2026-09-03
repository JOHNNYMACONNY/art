class_name GearsSurveyedServiceCutRuntime
extends Node3D

const SurveyedRouteProgressStoreScript = preload("res://scripts/progress/surveyed_route_progress_store.gd")
const GearsLocalRouteSheetScript = preload("res://scripts/ui/gears_local_route_sheet.gd")

const ROUTE_ID := "gears.service_alley_north_connector"
const MAX_SAMPLE_JUMP_M := 3.0
const MIN_TRAVERSAL_DISTANCE_M := 12.0
const ENTRY_RADIUS_M := 2.5
const CONNECTOR_RADIUS_M := 3.2
const CORRIDOR_TOLERANCE_M := 1.0
const FOOT_TRAVERSAL_MODE := 0

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

var _map_button: Button = null
var _map_modal: ColorRect = null
var _route_sheet: Control = null
var _map_open := false

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
	if _player == null or _scrapper_runtime == null or _touch_ui == null or _entry_socket == null or _connector == null:
		return false
	if _service_alley_bounds.is_empty() or _connector_bounds.is_empty():
		return false
	if not _scrapper_runtime.has_method("get_access_state_name"):
		return false
	if not _touch_ui.has_signal("map_action_pressed") or not _touch_ui.has_method("trigger_map_action") or not _touch_ui.has_method("set_map_modal_active"):
		return false

	_progress_store = progress_store
	if _progress_store == null:
		_progress_store = SurveyedRouteProgressStoreScript.new()
		_progress_store.call("configure")
	if _progress_store == null or not _progress_store.has_method("is_surveyed") or not _progress_store.has_method("mark_surveyed"):
		return false

	if _touch_ui.has_signal("replay_pressed") and not _touch_ui.replay_pressed.is_connected(_on_replay_pressed):
		_touch_ui.replay_pressed.connect(_on_replay_pressed)
	if not _touch_ui.map_action_pressed.is_connected(_on_map_action_pressed):
		_touch_ui.map_action_pressed.connect(_on_map_action_pressed)
	if _touch_ui.has_signal("ui_mode_changed") and not _touch_ui.ui_mode_changed.is_connected(_on_ui_mode_changed):
		_touch_ui.ui_mode_changed.connect(_on_ui_mode_changed)

	if not _build_map_ui():
		return false
	reset_transient_state()
	refresh_map_presentation()
	_configured = true
	set_physics_process(true)
	set_process(true)
	_refresh_map_button_visibility()
	return true

func _build_map_ui() -> bool:
	var right_touch := _touch_ui.get_node_or_null("SafeAreaRoot/RightTouchArea") as Control
	if right_touch == null:
		return false

	_map_button = right_touch.get_node_or_null("MapButton") as Button
	if _map_button == null:
		_map_button = Button.new()
		_map_button.name = "MapButton"
		_map_button.text = "[ M ] MAP"
		_map_button.anchor_left = 1.0
		_map_button.anchor_top = 0.0
		_map_button.anchor_right = 1.0
		_map_button.anchor_bottom = 0.0
		_map_button.offset_left = -124.0
		_map_button.offset_top = 24.0
		_map_button.offset_right = -24.0
		_map_button.offset_bottom = 72.0
		_map_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_map_button.z_index = 220
		right_touch.add_child(_map_button)
	if not _map_button.pressed.is_connected(_on_map_button_pressed):
		_map_button.pressed.connect(_on_map_button_pressed)

	_map_modal = _touch_ui.get_node_or_null("GearsRouteSheetModal") as ColorRect
	if _map_modal == null:
		_map_modal = ColorRect.new()
		_map_modal.name = "GearsRouteSheetModal"
		_map_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_map_modal.color = Color(0.01, 0.015, 0.018, 0.82)
		_map_modal.mouse_filter = Control.MOUSE_FILTER_STOP
		_map_modal.z_index = 200
		_touch_ui.add_child(_map_modal)

	_route_sheet = _map_modal.get_node_or_null("GearsLocalRouteSheet") as Control
	if _route_sheet == null:
		_route_sheet = GearsLocalRouteSheetScript.new() as Control
		if _route_sheet == null:
			return false
		_route_sheet.name = "GearsLocalRouteSheet"
		_route_sheet.anchor_left = 0.14
		_route_sheet.anchor_top = 0.12
		_route_sheet.anchor_right = 0.86
		_route_sheet.anchor_bottom = 0.88
		_route_sheet.offset_left = 0.0
		_route_sheet.offset_top = 0.0
		_route_sheet.offset_right = 0.0
		_route_sheet.offset_bottom = 0.0
		_map_modal.add_child(_route_sheet)
	if not bool(_route_sheet.call("configure", _district)):
		return false

	_map_modal.visible = false
	_map_open = false
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

func _process(_delta: float) -> void:
	if not _configured:
		return
	_refresh_map_button_visibility()

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
	refresh_map_presentation()

func _on_map_button_pressed() -> void:
	if _touch_ui != null:
		_touch_ui.call("trigger_map_action")

func _on_map_action_pressed() -> void:
	if _map_open:
		_close_map()
		return
	_try_open_map()

func _try_open_map() -> bool:
	if not _configured or _touch_ui == null or _player == null:
		return false
	if int(_touch_ui.get("current_mode")) != FOOT_TRAVERSAL_MODE:
		return false
	if bool(_touch_ui.call("is_interaction_input_locked")):
		return false
	if bool(_player.get("is_input_locked")):
		return false
	_map_open = true
	_player.set("is_input_locked", true)
	_touch_ui.call("set_map_modal_active", true)
	refresh_map_presentation()
	if _map_modal:
		_map_modal.visible = true
	if _map_button:
		_map_button.text = "[ M ] CLOSE"
	_refresh_map_button_visibility()
	return true

func _close_map() -> void:
	if not _map_open:
		return
	_map_open = false
	if _map_modal:
		_map_modal.visible = false
	if _touch_ui != null:
		_touch_ui.call("set_map_modal_active", false)
	if _player != null:
		_player.set("is_input_locked", false)
	if _map_button:
		_map_button.text = "[ M ] MAP"
	_refresh_map_button_visibility()

func _on_ui_mode_changed(mode: int) -> void:
	if mode != FOOT_TRAVERSAL_MODE and _map_open:
		_close_map()
	_refresh_map_button_visibility()

func _refresh_map_button_visibility() -> void:
	if _map_button == null or _touch_ui == null:
		return
	var on_foot := int(_touch_ui.get("current_mode")) == FOOT_TRAVERSAL_MODE
	var gesture_locked := bool(_touch_ui.call("is_interaction_input_locked"))
	_map_button.visible = on_foot and (_map_open or not gesture_locked)

func refresh_map_presentation() -> void:
	if _route_sheet == null:
		return
	var access_state := "JAMMED"
	if _scrapper_runtime != null:
		access_state = String(_scrapper_runtime.call("get_access_state_name"))
	_route_sheet.call("set_route_state", is_route_surveyed(), access_state)

func reset_transient_state() -> void:
	_armed_side = TraversalSide.NONE
	_last_sample = Vector3.ZERO
	_has_last_sample = false
	_travel_distance_m = 0.0

func _on_replay_pressed() -> void:
	if _map_open:
		_close_map()
	reset_transient_state()
	refresh_map_presentation()

func _exit_tree() -> void:
	if _map_open:
		_close_map()

func is_route_surveyed() -> bool:
	return _progress_store != null and bool(_progress_store.call("is_surveyed", ROUTE_ID))

func get_survey_record_count() -> int:
	return _survey_record_count

func get_route_id() -> String:
	return ROUTE_ID

func get_progress_store():
	return _progress_store

func get_map_button() -> Button:
	return _map_button

func get_route_sheet() -> Control:
	return _route_sheet

func is_map_open() -> bool:
	return _map_open

func get_transient_state_name() -> String:
	match _armed_side:
		TraversalSide.ALLEY:
			return "ARMED_ALLEY"
		TraversalSide.CONNECTOR:
			return "ARMED_CONNECTOR"
		_:
			return "IDLE"
