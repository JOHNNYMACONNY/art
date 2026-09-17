class_name BurnGarageRepairRuntime
extends Node3D

## Burnside Production 07 / #137
## Bounded Garage repair adapter over retained vehicle, interaction, Wanted and
## authored Gears geography. It owns vehicle repair eligibility only.

const InteractableBaseScript = preload("res://scripts/interactions/interactable_base.gd")
const REPAIR_SOCKET_PATH := "MissionDestinationSocket"
const REPAIR_RADIUS_M := 2.6
const REPAIR_STOP_SPEED_MPS := 0.35
const AFFORDANCE_RADIUS_M := 8.0
const SUCCESS_FEEDBACK_MSEC := 1200

var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _repair_socket: Marker3D = null
var _repair_interactable: InteractableBase = null
var _affordance_label: Label3D = null
var _affordance_text: String = ""
var _success_until_msec: int = 0
var _bound: bool = false

func configure(root_controller: Node, district: Node3D, wanted_runtime: Node) -> bool:
	if root_controller == null or district == null or wanted_runtime == null:
		return false
	if not root_controller.has_method("_get_active_vehicle"):
		return false
	if not wanted_runtime.has_method("get_heat_level") or not wanted_runtime.has_method("get_wanted_state_name"):
		return false
	var socket := district.get_node_or_null(REPAIR_SOCKET_PATH) as Marker3D
	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var interactables = root_controller.get("_interactables")
	if socket == null or touch_ui == null or not (interactables is Array):
		return false

	_root_controller = root_controller
	_district = district
	_wanted_runtime = wanted_runtime
	_repair_socket = socket

	_repair_interactable = InteractableBaseScript.new() as InteractableBase
	if _repair_interactable == null:
		return false
	_repair_interactable.name = "BurnGarageRepairInteractable"
	_repair_interactable.interaction_radius = REPAIR_RADIUS_M
	_repair_interactable.sensory_radius = AFFORDANCE_RADIUS_M
	_repair_interactable.interaction_priority = 3.5
	_repair_interactable.is_powered = false
	add_child(_repair_interactable)
	_repair_interactable.global_position = _repair_socket.global_position
	if not interactables.has(_repair_interactable):
		interactables.append(_repair_interactable)

	_affordance_label = Label3D.new()
	_affordance_label.name = "BurnGarageRepairAffordance"
	_affordance_label.font_size = 5
	_affordance_label.outline_size = 2
	_affordance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_affordance_label.no_depth_test = true
	_affordance_label.fixed_size = true
	_affordance_label.modulate = Color(0.95, 0.79, 0.30, 0.96)
	_affordance_label.outline_modulate = Color(0.08, 0.08, 0.07, 0.96)
	_affordance_label.visible = false
	add_child(_affordance_label)
	_affordance_label.global_position = _repair_socket.global_position + Vector3(0.0, 1.15, 0.0)

	var action_callable := Callable(self, "handle_action_pressed")
	if not touch_ui.action_button_pressed.is_connected(action_callable):
		touch_ui.action_button_pressed.connect(action_callable)

	_bound = true
	set_process(true)
	return true

func _exit_tree() -> void:
	if _root_controller == null or _repair_interactable == null:
		return
	var interactables = _root_controller.get("_interactables")
	if interactables is Array:
		interactables.erase(_repair_interactable)

func _process(_delta: float) -> void:
	if not _bound or _repair_interactable == null or _repair_socket == null:
		return
	var now := Time.get_ticks_msec()
	if now < _success_until_msec:
		_repair_interactable.is_powered = false
		_set_affordance("ROADWORTHY", true)
		return

	var vehicle := _get_active_vehicle()
	if not _is_supported_vehicle(vehicle) or String(vehicle.call("get_condition_name")) == "ROADWORTHY":
		_repair_interactable.is_powered = false
		_set_affordance("", false)
		return

	_repair_interactable.is_powered = true
	_repair_interactable.update_player_distance(vehicle.global_position)
	var distance: float = (vehicle as Node3D).global_position.distance_to(_repair_socket.global_position)
	if distance > AFFORDANCE_RADIUS_M:
		_set_affordance("", false)
		return
	if distance <= REPAIR_RADIUS_M:
		if abs(float(vehicle.get("current_speed"))) > REPAIR_STOP_SPEED_MPS:
			_set_affordance("STOP TO REPAIR", true)
		elif not _wanted_is_clear():
			_set_affordance("WANTED // SERVICE LOCKED", true)
		else:
			_set_affordance("REPAIR // ACTION", true)
	else:
		_set_affordance("BURN // REPAIR", true)

func handle_action_pressed() -> bool:
	if not _bound or _root_controller == null or _repair_interactable == null:
		return false
	if _root_controller.get("_active_target") != _repair_interactable:
		return false
	return attempt_repair(_get_active_vehicle())

func attempt_repair(vehicle: Node) -> bool:
	if not _bound or vehicle == null or vehicle != _get_active_vehicle():
		return false
	if not _is_supported_vehicle(vehicle):
		return false
	if String(vehicle.call("get_condition_name")) == "ROADWORTHY":
		return false
	if not is_vehicle_in_repair_radius(vehicle):
		return false
	if abs(float(vehicle.get("current_speed"))) > REPAIR_STOP_SPEED_MPS:
		return false
	if not _wanted_is_clear():
		return false
	if not bool(vehicle.call("repair_condition")):
		return false
	_success_until_msec = Time.get_ticks_msec() + SUCCESS_FEEDBACK_MSEC
	_repair_interactable.is_powered = false
	_set_affordance("ROADWORTHY", true)
	return true

func is_vehicle_in_repair_radius(vehicle: Node) -> bool:
	return vehicle is Node3D and _repair_socket != null \
		and (vehicle as Node3D).global_position.distance_to(_repair_socket.global_position) <= REPAIR_RADIUS_M

func get_repair_socket_position() -> Vector3:
	return _repair_socket.global_position if _repair_socket != null else Vector3.INF

func get_repair_interactable() -> InteractableBase:
	return _repair_interactable

func get_affordance_text() -> String:
	return _affordance_text

func _get_active_vehicle() -> Node:
	if _root_controller == null or not _root_controller.has_method("_get_active_vehicle"):
		return null
	var vehicle = _root_controller.call("_get_active_vehicle")
	return vehicle if vehicle is Node else null

func _is_supported_vehicle(vehicle: Node) -> bool:
	return vehicle is CourierBike or vehicle is ScrapHauler

func _wanted_is_clear() -> bool:
	return _wanted_runtime != null \
		and _wanted_runtime.has_method("get_heat_level") \
		and _wanted_runtime.has_method("get_wanted_state_name") \
		and int(_wanted_runtime.call("get_heat_level")) == 0 \
		and String(_wanted_runtime.call("get_wanted_state_name")) == "CLEAR"

func _set_affordance(text: String, visible_value: bool) -> void:
	_affordance_text = text
	if _affordance_label != null:
		_affordance_label.text = text
		_affordance_label.visible = visible_value
