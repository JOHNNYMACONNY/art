class_name MayorBurnContactServiceRuntime
extends Node3D

## Burnside Production 10 / #152
## One authored Mayor Burn relationship consequence at the retained Garage.
## This owns Contact persistence + Armor-stash eligibility only. Vehicle repair
## remains owned by BurnGarageRepairRuntime.

const InteractableBaseScript = preload("res://scripts/interactions/interactable_base.gd")
const ContactStoreScript = preload("res://scripts/progress/mayor_burn_contact_progress_store.gd")

const SERVICE_SOCKET_PATH := "MissionDestinationSocket"
const SERVICE_RADIUS_M := 2.6
const AFFORDANCE_RADIUS_M := 8.0
const SUCCESS_FEEDBACK_MSEC := 1200

var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _civic_runtime: Node = null
var _player: PlayerRunner = null
var _service_socket: Marker3D = null
var _contact_interactable: InteractableBase = null
var _affordance_label: Label3D = null
var _affordance_text: String = ""
var _progress_store = ContactStoreScript.new()
var _success_until_msec: int = 0
var _bound: bool = false

func configure(root_controller: Node, district: Node3D, wanted_runtime: Node, civic_runtime: Node) -> bool:
	if root_controller == null or district == null or wanted_runtime == null or civic_runtime == null:
		return false
	if not root_controller.has_method("_get_active_vehicle"):
		return false
	if not wanted_runtime.has_method("get_heat_level") or not wanted_runtime.has_method("get_wanted_state_name"):
		return false
	if not civic_runtime.has_signal("civic_repossession_completed") or not civic_runtime.has_method("is_complete"):
		return false

	var player := root_controller.get_node_or_null("Runner") as PlayerRunner
	var socket := district.get_node_or_null(SERVICE_SOCKET_PATH) as Marker3D
	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var interactables = root_controller.get("_interactables")
	if player == null or socket == null or touch_ui == null or not (interactables is Array):
		return false

	_root_controller = root_controller
	_district = district
	_wanted_runtime = wanted_runtime
	_civic_runtime = civic_runtime
	_player = player
	_service_socket = socket
	_progress_store.configure()

	var completion_callable := Callable(self, "_on_civic_repossession_completed")
	if not _civic_runtime.is_connected("civic_repossession_completed", completion_callable):
		_civic_runtime.connect("civic_repossession_completed", completion_callable)
	if bool(_civic_runtime.call("is_complete")):
		_progress_store.mark_known()

	_contact_interactable = InteractableBaseScript.new() as InteractableBase
	if _contact_interactable == null:
		return false
	_contact_interactable.name = "MayorBurnArmorStashInteractable"
	_contact_interactable.interaction_radius = SERVICE_RADIUS_M
	_contact_interactable.sensory_radius = AFFORDANCE_RADIUS_M
	_contact_interactable.interaction_priority = 3.4
	_contact_interactable.is_powered = false
	add_child(_contact_interactable)
	_contact_interactable.global_position = _service_socket.global_position
	if not interactables.has(_contact_interactable):
		interactables.append(_contact_interactable)

	_affordance_label = Label3D.new()
	_affordance_label.name = "MayorBurnContactAffordance"
	_affordance_label.font_size = 5
	_affordance_label.outline_size = 2
	_affordance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_affordance_label.no_depth_test = true
	_affordance_label.fixed_size = true
	_affordance_label.modulate = Color(0.42, 0.86, 0.96, 0.96)
	_affordance_label.outline_modulate = Color(0.04, 0.06, 0.08, 0.96)
	_affordance_label.visible = false
	add_child(_affordance_label)
	_affordance_label.global_position = _service_socket.global_position + Vector3(0.0, 1.45, 0.0)

	var action_callable := Callable(self, "handle_action_pressed")
	if not touch_ui.action_button_pressed.is_connected(action_callable):
		touch_ui.action_button_pressed.connect(action_callable)

	_bound = true
	set_process(true)
	return true

func _exit_tree() -> void:
	if _civic_runtime != null:
		var completion_callable := Callable(self, "_on_civic_repossession_completed")
		if _civic_runtime.is_connected("civic_repossession_completed", completion_callable):
			_civic_runtime.disconnect("civic_repossession_completed", completion_callable)
	if _root_controller != null and _contact_interactable != null:
		var interactables = _root_controller.get("_interactables")
		if interactables is Array:
			interactables.erase(_contact_interactable)
		var touch_ui := _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
		if touch_ui != null:
			var action_callable := Callable(self, "handle_action_pressed")
			if touch_ui.action_button_pressed.is_connected(action_callable):
				touch_ui.action_button_pressed.disconnect(action_callable)

func _process(_delta: float) -> void:
	if not _bound or _contact_interactable == null or _service_socket == null or _player == null:
		return

	if not _progress_store.is_known() \
	or _player.is_mounted \
	or _player.is_input_locked \
	or _get_active_vehicle() != null \
	or _player.current_health <= 0.0:
		_contact_interactable.is_powered = false
		_set_affordance("", false)
		return

	var distance := _player.global_position.distance_to(_service_socket.global_position)
	if distance > AFFORDANCE_RADIUS_M:
		_contact_interactable.is_powered = false
		_set_affordance("", false)
		return

	# Wanted authority outranks stale success presentation immediately.
	if distance <= SERVICE_RADIUS_M and not _wanted_is_clear():
		_contact_interactable.is_powered = false
		_set_affordance("WANTED // BURN WON'T OPEN", true)
		return

	# Brief success feedback is valid only while the player remains in the
	# on-foot Garage context. It never owns eligibility or blocks Wanted.
	if Time.get_ticks_msec() < _success_until_msec:
		_contact_interactable.is_powered = false
		_set_affordance("ARMOR RESTOCKED", true)
		return

	if _player.current_armor >= PlayerRunner.MAX_ARMOR:
		_contact_interactable.is_powered = false
		_set_affordance("", false)
		return

	_contact_interactable.is_powered = true
	_contact_interactable.update_player_distance(_player.global_position)
	if distance <= SERVICE_RADIUS_M:
		_set_affordance("RESTOCK ARMOR // ACTION", true)
	else:
		_set_affordance("BURN // ARMOR STASH", true)

func _on_civic_repossession_completed() -> void:
	_progress_store.mark_known()

func handle_action_pressed() -> bool:
	if not _bound or _root_controller == null or _contact_interactable == null:
		return false
	if _root_controller.get("_active_target") != _contact_interactable:
		return false
	return attempt_armor_restock(_player)

func attempt_armor_restock(candidate: Node) -> bool:
	if not _bound or candidate == null or candidate != _player:
		return false
	if not _progress_store.is_known():
		return false
	if _player.is_mounted or _player.is_input_locked or _get_active_vehicle() != null:
		return false
	if _player.current_health <= 0.0 or _player.current_armor >= PlayerRunner.MAX_ARMOR:
		return false
	if not is_player_in_service_radius(_player):
		return false
	if not _wanted_is_clear():
		return false
	if not _player.restock_armor():
		return false
	_success_until_msec = Time.get_ticks_msec() + SUCCESS_FEEDBACK_MSEC
	_contact_interactable.is_powered = false
	_set_affordance("ARMOR RESTOCKED", true)
	return true

func is_player_in_service_radius(candidate: Node) -> bool:
	return candidate is Node3D and _service_socket != null \
		and (candidate as Node3D).global_position.distance_to(_service_socket.global_position) <= SERVICE_RADIUS_M

func get_progress_store():
	return _progress_store

func get_contact_interactable() -> InteractableBase:
	return _contact_interactable

func get_affordance_text() -> String:
	return _affordance_text

func get_service_socket_position() -> Vector3:
	return _service_socket.global_position if _service_socket != null else Vector3.INF

func _get_active_vehicle() -> Node:
	if _root_controller == null or not _root_controller.has_method("_get_active_vehicle"):
		return null
	var vehicle = _root_controller.call("_get_active_vehicle")
	return vehicle if vehicle is Node else null

func _wanted_is_clear() -> bool:
	return _wanted_runtime != null \
		and int(_wanted_runtime.call("get_heat_level")) == 0 \
		and String(_wanted_runtime.call("get_wanted_state_name")) == "CLEAR"

func _set_affordance(text: String, visible_value: bool) -> void:
	_affordance_text = text
	if _affordance_label != null:
		_affordance_label.text = text
		_affordance_label.visible = visible_value
