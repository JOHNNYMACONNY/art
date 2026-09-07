class_name BurnsideCompanionPresenceRuntime
extends Node

var _runner: PlayerRunner = null
var _camera: Camera3D = null
var _fb13: FB13CompanionBody = null
var _courier_bike: CourierBike = null
var _scrap_hauler: ScrapHauler = null
var _thrum_event: Node = null

var _active_dock_socket: Node3D = null
var _is_configured: bool = false

func _process(delta: float) -> void:
	if _is_configured and _fb13 and is_instance_valid(_fb13):
		_fb13.tick_presence(delta)

func configure(
	runner: PlayerRunner,
	camera: Camera3D,
	fb13: FB13CompanionBody,
	courier_bike: CourierBike,
	scrap_hauler: ScrapHauler,
	thrum_event: Node
) -> void:
	_runner = runner
	_camera = camera
	_fb13 = fb13
	_courier_bike = courier_bike
	_scrap_hauler = scrap_hauler
	_thrum_event = thrum_event
	_active_dock_socket = null

	if _fb13 and is_instance_valid(_fb13):
		_fb13.configure(_runner, _camera)

	if _courier_bike and _courier_bike.has_signal("state_changed"):
		var cb_bike := Callable(self, "_on_bike_state_changed")
		if not _courier_bike.is_connected("state_changed", cb_bike):
			_courier_bike.connect("state_changed", cb_bike)

	if _scrap_hauler and _scrap_hauler.has_signal("state_changed"):
		var cb_hauler := Callable(self, "_on_hauler_state_changed")
		if not _scrap_hauler.is_connected("state_changed", cb_hauler):
			_scrap_hauler.connect("state_changed", cb_hauler)

	if _thrum_event and _thrum_event.has_signal("thrum_triggered"):
		var cb_thrum := Callable(self, "_on_fb13_thrum_triggered")
		if not _thrum_event.is_connected("thrum_triggered", cb_thrum):
			_thrum_event.connect("thrum_triggered", cb_thrum)

	_is_configured = true

func reset_presence() -> void:
	_active_dock_socket = null
	if _fb13 and is_instance_valid(_fb13):
		var target_parent: Node = get_parent()
		if target_parent != null and _fb13.get_parent() != target_parent:
			_fb13.reparent(target_parent, true)
		if _fb13.has_method("set_active_vehicle"):
			_fb13.call("set_active_vehicle", null)
		_fb13.reset_to_follow_position()

func get_fb13() -> FB13CompanionBody:
	return _fb13

func get_hs7_socket() -> Node3D:
	if _runner and is_instance_valid(_runner):
		return _runner.get_node_or_null("MeshPivot/Torso/HS7CarrySocket") as Node3D
	return null

func get_active_dock_socket() -> Node3D:
	return _active_dock_socket

func get_runtime_snapshot() -> Dictionary:
	return {
		"is_configured": _is_configured,
		"has_runner": _runner != null,
		"has_fb13": _fb13 != null,
		"fb13_state": _fb13.get_presence_state() if _fb13 else -1,
		"active_dock": _active_dock_socket.name if _active_dock_socket else "",
		"follow_distance": _fb13.get_follow_distance() if _fb13 else 0.0,
		"hard_rejoin_count": _fb13.get_hard_rejoin_count() if _fb13 else 0,
		"thrum_reaction_count": _fb13.get_thrum_reaction_count() if _fb13 else 0,
	}

func _on_bike_state_changed(new_state: String) -> void:
	if _fb13 == null or not is_instance_valid(_fb13):
		return
	match new_state:
		"MOUNTING":
			var socket: Node3D = null
			if _courier_bike:
				socket = _courier_bike.get_node_or_null("FB13DockSocket") as Node3D
			_active_dock_socket = socket
			if _fb13.has_method("set_active_vehicle"):
				_fb13.call("set_active_vehicle", _courier_bike)
			_fb13.begin_dock(
				socket,
				FB13CompanionBody.PresenceState.DOCKING_BIKE,
				FB13CompanionBody.PresenceState.DOCKED_BIKE
			)
		"DISMOUNTING":
			var origin: Vector3 = _fb13.global_position
			if _active_dock_socket:
				origin = _active_dock_socket.global_position
			_active_dock_socket = null
			var target_parent: Node = get_parent()
			if target_parent != null and _fb13.get_parent() != target_parent:
				_fb13.reparent(target_parent, true)
			if _fb13.has_method("set_active_vehicle"):
				_fb13.call("set_active_vehicle", null)
			_fb13.release_from_dock(origin)

func _on_hauler_state_changed(new_state: String) -> void:
	if _fb13 == null or not is_instance_valid(_fb13):
		return
	match new_state:
		"MOUNTING":
			var socket: Node3D = null
			if _scrap_hauler:
				socket = _scrap_hauler.get_node_or_null("FB13DockSocket") as Node3D
			_active_dock_socket = socket
			if _fb13.has_method("set_active_vehicle"):
				_fb13.call("set_active_vehicle", _scrap_hauler)
			_fb13.begin_dock(
				socket,
				FB13CompanionBody.PresenceState.DOCKING_HAULER,
				FB13CompanionBody.PresenceState.DOCKED_HAULER
			)
		"DISMOUNTING":
			var origin: Vector3 = _fb13.global_position
			if _active_dock_socket:
				origin = _active_dock_socket.global_position
			_active_dock_socket = null
			var target_parent: Node = get_parent()
			if target_parent != null and _fb13.get_parent() != target_parent:
				_fb13.reparent(target_parent, true)
			if _fb13.has_method("set_active_vehicle"):
				_fb13.call("set_active_vehicle", null)
			_fb13.release_from_dock(origin)

func _on_fb13_thrum_triggered(payload: Dictionary) -> void:
	if _fb13 and is_instance_valid(_fb13):
		_fb13.on_thrum_triggered(payload)
