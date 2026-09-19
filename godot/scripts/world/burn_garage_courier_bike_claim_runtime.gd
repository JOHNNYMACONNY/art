class_name BurnGarageCourierBikeClaimRuntime
extends Node3D

## Burnside Production 11 / #158
## Bounded ownership + Garage recovery adapter for the retained Courier Bike.

const InteractableBaseScript = preload("res://scripts/interactions/interactable_base.gd")
const ClaimStoreScript = preload("res://scripts/progress/courier_bike_claim_progress_store.gd")

const CLAIM_SOCKET_PATH := "CourierBikeClaimSocket"
const CLAIM_RADIUS_M := 2.4
const CLAIM_STOP_SPEED_MPS := 0.35
const AFFORDANCE_RADIUS_M := 8.0
const RECOVERY_MIN_DISTANCE_M := 6.0
const SUCCESS_FEEDBACK_MSEC := 1200

var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _contact_runtime: Node = null
var _bike: CourierBike = null
var _claim_socket: Marker3D = null
var _claim_interactable: InteractableBase = null
var _affordance_label: Label3D = null
var _affordance_text: String = ""
var _progress_store = ClaimStoreScript.new()
var _success_until_msec: int = 0
var _bound: bool = false

func configure(root_controller: Node, district: Node3D, wanted_runtime: Node, contact_runtime: Node, bike: CourierBike) -> bool:
	if root_controller == null or district == null or wanted_runtime == null or contact_runtime == null or bike == null:
		return false
	if not wanted_runtime.has_method("get_heat_level") or not wanted_runtime.has_method("get_wanted_state_name"):
		return false
	if not contact_runtime.has_method("get_progress_store"):
		return false
	if not bike.has_method("recover_to_garage"):
		return false
	var socket := district.get_node_or_null(CLAIM_SOCKET_PATH) as Marker3D
	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var interactables = root_controller.get("_interactables")
	if socket == null or touch_ui == null or not (interactables is Array):
		return false

	_root_controller = root_controller
	_district = district
	_wanted_runtime = wanted_runtime
	_contact_runtime = contact_runtime
	_bike = bike
	_claim_socket = socket
	_progress_store.configure()

	_claim_interactable = InteractableBaseScript.new() as InteractableBase
	if _claim_interactable == null:
		return false
	_claim_interactable.name = "CourierBikeClaimInteractable"
	_claim_interactable.interaction_radius = CLAIM_RADIUS_M
	_claim_interactable.sensory_radius = AFFORDANCE_RADIUS_M
	_claim_interactable.interaction_priority = 4.0
	_claim_interactable.is_powered = false
	add_child(_claim_interactable)
	_claim_interactable.global_position = _claim_socket.global_position
	if not interactables.has(_claim_interactable):
		interactables.append(_claim_interactable)

	_affordance_label = Label3D.new()
	_affordance_label.name = "CourierBikeClaimAffordance"
	_affordance_label.font_size = 5
	_affordance_label.outline_size = 2
	_affordance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_affordance_label.no_depth_test = true
	_affordance_label.fixed_size = true
	_affordance_label.modulate = Color(0.95, 0.79, 0.30, 0.96)
	_affordance_label.outline_modulate = Color(0.08, 0.08, 0.07, 0.96)
	_affordance_label.visible = false
	add_child(_affordance_label)
	_affordance_label.global_position = _claim_socket.global_position + Vector3(0.0, 1.15, 0.0)

	var action_callable := Callable(self, "handle_action_pressed")
	if not touch_ui.action_button_pressed.is_connected(action_callable):
		touch_ui.action_button_pressed.connect(action_callable)

	_bound = true
	set_process(true)
	call_deferred("_restore_claimed_bike_on_startup")
	return true

func _exit_tree() -> void:
	if _root_controller == null or _claim_interactable == null:
		return
	var interactables = _root_controller.get("_interactables")
	if interactables is Array:
		interactables.erase(_claim_interactable)

func _process(_delta: float) -> void:
	if not _bound or _claim_socket == null or _claim_interactable == null or _bike == null:
		return
	var now := Time.get_ticks_msec()
	if now < _success_until_msec:
		_claim_interactable.is_powered = false
		_set_affordance("BIKE // CLAIMED", true)
		return

	var player := _get_player()
	if player == null or not _contact_is_known():
		_claim_interactable.is_powered = false
		_set_affordance("", false)
		return
	var player_distance: float = player.global_position.distance_to(_claim_socket.global_position)
	if player_distance > AFFORDANCE_RADIUS_M or not _player_is_on_foot(player):
		_claim_interactable.is_powered = false
		_set_affordance("", false)
		return

	_claim_interactable.is_powered = true
	_claim_interactable.update_player_distance(player.global_position)
	if not _wanted_is_clear():
		_set_affordance("WANTED // GARAGE LOCKED", true)
		return

	if not _progress_store.is_claimed():
		var bike_distance: float = _bike.global_position.distance_to(_claim_socket.global_position)
		if bike_distance <= CLAIM_RADIUS_M:
			if abs(float(_bike.current_speed)) > CLAIM_STOP_SPEED_MPS:
				_set_affordance("STOP TO CLAIM", true)
			else:
				_set_affordance("CLAIM COURIER BIKE // ACTION", true)
		elif bike_distance <= AFFORDANCE_RADIUS_M:
			_set_affordance("BURN // CLAIM BIKE", true)
		else:
			_claim_interactable.is_powered = false
			_set_affordance("", false)
		return

	if _bike.occupant != null:
		_claim_interactable.is_powered = false
		_set_affordance("", false)
		return
	if _bike.global_position.distance_to(_claim_socket.global_position) > RECOVERY_MIN_DISTANCE_M:
		_set_affordance("RECOVER COURIER BIKE // ACTION", true)
	else:
		_claim_interactable.is_powered = false
		_set_affordance("", false)

func handle_action_pressed() -> bool:
	if not _bound or _root_controller == null or _claim_interactable == null:
		return false
	if _root_controller.get("_active_target") != _claim_interactable:
		return false
	return attempt_recovery() if _progress_store.is_claimed() else attempt_claim()

func attempt_claim() -> bool:
	if not _bound or _progress_store.is_claimed() or not _contact_is_known() or not _wanted_is_clear():
		return false
	var player := _get_player()
	if player == null or not _player_is_on_foot(player):
		return false
	if player.global_position.distance_to(_claim_socket.global_position) > CLAIM_RADIUS_M:
		return false
	if _bike.global_position.distance_to(_claim_socket.global_position) > CLAIM_RADIUS_M:
		return false
	if abs(float(_bike.current_speed)) > CLAIM_STOP_SPEED_MPS:
		return false
	if not _progress_store.mark_claimed():
		return false
	_success_until_msec = Time.get_ticks_msec() + SUCCESS_FEEDBACK_MSEC
	_claim_interactable.is_powered = false
	_set_affordance("BIKE // CLAIMED", true)
	return true

func attempt_recovery() -> bool:
	if not _bound or not _progress_store.is_claimed() or not _contact_is_known() or not _wanted_is_clear():
		return false
	var player := _get_player()
	if player == null or not _player_is_on_foot(player):
		return false
	if player.global_position.distance_to(_claim_socket.global_position) > CLAIM_RADIUS_M:
		return false
	if _bike.occupant != null:
		return false
	if _bike.global_position.distance_to(_claim_socket.global_position) <= RECOVERY_MIN_DISTANCE_M:
		return false
	if not bool(_bike.call("recover_to_garage", _claim_socket.global_position)):
		return false
	_success_until_msec = Time.get_ticks_msec() + SUCCESS_FEEDBACK_MSEC
	_claim_interactable.is_powered = false
	_set_affordance("BIKE // CLAIMED", true)
	return true

func restore_claimed_bike_after_replay() -> bool:
	if not _bound or not _progress_store.is_claimed() or _bike == null or _bike.occupant != null:
		return false
	return bool(_bike.call("recover_to_garage", _claim_socket.global_position))

func _restore_claimed_bike_on_startup() -> void:
	if _progress_store.is_claimed():
		restore_claimed_bike_after_replay()

func get_progress_store():
	return _progress_store

func get_claim_interactable() -> InteractableBase:
	return _claim_interactable

func get_affordance_text() -> String:
	return _affordance_text

func get_claim_socket_position() -> Vector3:
	return _claim_socket.global_position if _claim_socket != null else Vector3.INF

func _get_player() -> PlayerRunner:
	if _root_controller == null:
		return null
	var candidate = _root_controller.get("player")
	return candidate as PlayerRunner if candidate is PlayerRunner else null

func _player_is_on_foot(player: PlayerRunner) -> bool:
	return player != null and not player.is_mounted and _root_controller.get("active_vehicle") == null

func _contact_is_known() -> bool:
	if _contact_runtime == null or not _contact_runtime.has_method("get_progress_store"):
		return false
	var store = _contact_runtime.call("get_progress_store")
	return store != null and store.has_method("is_known") and bool(store.call("is_known"))

func _wanted_is_clear() -> bool:
	return _wanted_runtime != null \
		and int(_wanted_runtime.call("get_heat_level")) == 0 \
		and String(_wanted_runtime.call("get_wanted_state_name")) == "CLEAR"

func _set_affordance(text: String, visible_value: bool) -> void:
	_affordance_text = text
	if _affordance_label != null:
		_affordance_label.text = text
		_affordance_label.visible = visible_value
