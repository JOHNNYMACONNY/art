class_name BurnsideCompanionPresenceRuntime
extends Node

const HS7_SCENE := preload("res://scenes/entities/hs7_carried_module.tscn")

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
		if not _courier_bike.state_changed.is_connected(_on_bike_state_changed):
			_courier_bike.state_changed.connect(_on_bike_state_changed)

	if _scrap_hauler and _scrap_hauler.has_signal("state_changed"):
		if not _scrap_hauler.state_changed.is_connected(_on_hauler_state_changed):
			_scrap_hauler.state_changed.connect(_on_hauler_state_changed)

	if _thrum_event and _thrum_event.has_signal("thrum_triggered"):
		if not _thrum_event.thrum_triggered.is_connected(_on_fb13_thrum_triggered):
			_thrum_event.thrum_triggered.connect(_on_fb13_thrum_triggered)

	_is_configured = true

func reset_presence() -> void:
	_release_fb13_from_dock()
	if _fb13 and is_instance_valid(_fb13):
		_fb13.reset_to_follow_position()

	var hs7_sock := get_hs7_socket()
	if hs7_sock != null and hs7_sock.get_child_count() == 0:
		var hs7_inst := HS7_SCENE.instantiate()
		hs7_sock.add_child(hs7_inst)

func get_fb13() -> FB13CompanionBody:
	return _fb13

func get_hs7_socket() -> Node3D:
	if _runner and is_instance_valid(_runner):
		return _runner.get_node_or_null("MeshPivot/Torso/HS7CarrySocket") as Node3D
	return null

func get_active_dock_socket() -> Node3D:
	return _active_dock_socket

func get_runtime_snapshot() -> Dictionary:
	var hs7_sock := get_hs7_socket()
	var hs7_state := "CARRIED" if hs7_sock != null and hs7_sock.get_child_count() > 0 else "ABSENT"
	return {
		"is_configured": _is_configured,
		"has_runner": _runner != null,
		"has_fb13": _fb13 != null,
		"fb13_state": _fb13.get_presence_state() if _fb13 else -1,
		"hs7_state": hs7_state,
		"active_dock": _active_dock_socket.name if _active_dock_socket else "",
		"follow_distance": _fb13.get_follow_distance() if _fb13 else 0.0,
		"hard_rejoin_count": _fb13.get_hard_rejoin_count() if _fb13 else 0,
		"thrum_reaction_count": _fb13.get_thrum_reaction_count() if _fb13 else 0,
	}

func _on_bike_state_changed(new_state: String) -> void:
	_handle_vehicle_state_changed(
		_courier_bike,
		new_state,
		FB13CompanionBody.PresenceState.DOCKING_BIKE,
		FB13CompanionBody.PresenceState.DOCKED_BIKE
	)

func _on_hauler_state_changed(new_state: String) -> void:
	_handle_vehicle_state_changed(
		_scrap_hauler,
		new_state,
		FB13CompanionBody.PresenceState.DOCKING_HAULER,
		FB13CompanionBody.PresenceState.DOCKED_HAULER
	)

func _handle_vehicle_state_changed(
	vehicle: Node,
	new_state: String,
	docking_state: FB13CompanionBody.PresenceState,
	docked_state: FB13CompanionBody.PresenceState
) -> void:
	if _fb13 == null or not is_instance_valid(_fb13):
		return
	match new_state:
		"MOUNTING":
			var socket: Node3D = null
			if vehicle:
				socket = vehicle.get_node_or_null("FB13DockSocket") as Node3D
			_active_dock_socket = socket
			_fb13.set_active_vehicle(vehicle)
			_fb13.begin_dock(socket, docking_state, docked_state)
		"DISMOUNTING":
			_release_fb13_from_dock()

func _release_fb13_from_dock() -> void:
	if _fb13 == null or not is_instance_valid(_fb13):
		return
	var origin: Vector3 = _fb13.global_position
	if _active_dock_socket:
		origin = _active_dock_socket.global_position
	_active_dock_socket = null
	var target_parent: Node = get_parent()
	if target_parent != null and _fb13.get_parent() != target_parent:
		_fb13.reparent(target_parent, true)
	_fb13.set_active_vehicle(null)
	_fb13.release_from_dock(origin)

func _on_fb13_thrum_triggered(payload: Dictionary) -> void:
	if _fb13 and is_instance_valid(_fb13):
		_fb13.on_thrum_triggered(payload)
