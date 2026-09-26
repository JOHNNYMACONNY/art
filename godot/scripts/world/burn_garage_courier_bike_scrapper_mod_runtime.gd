class_name BurnGarageCourierBikeScrapperModRuntime
extends Node3D

## Burnside Production 14 / #167
## One authored paid Scrap Bash Bar for the durably claimed Courier Bike.
## This owns Garage eligibility + presentation only; Cash authority remains in
## BurnsideCashProgressStore and ownership remains in the P11 claim store.

const InteractableBaseScript = preload("res://scripts/interactions/interactable_base.gd")
const CashStoreScript = preload("res://scripts/progress/burnside_cash_progress_store.gd")

const CLAIM_SOCKET_PATH := "CourierBikeClaimSocket"
const PRICE := CashStoreScript.COURIER_BIKE_BASH_BAR_COST
const CLAIM_RADIUS_M := 2.4
const CLAIM_STOP_SPEED_MPS := 0.35
const AFFORDANCE_RADIUS_M := 8.0
const SUCCESS_FEEDBACK_MSEC := 1200

var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _contact_runtime: Node = null
var _claim_runtime: Node = null
var _cash_runtime: Node = null
var _bike: CourierBike = null
var _claim_socket: Marker3D = null
var _mod_interactable: InteractableBase = null
var _affordance_label: Label3D = null
var _affordance_text: String = ""
var _success_until_msec: int = 0
var _bound: bool = false

func configure(
	root_controller: Node,
	district: Node3D,
	wanted_runtime: Node,
	contact_runtime: Node,
	claim_runtime: Node,
	cash_runtime: Node,
	bike: CourierBike
) -> bool:
	if root_controller == null or district == null or wanted_runtime == null 	or contact_runtime == null or claim_runtime == null or cash_runtime == null or bike == null:
		return false
	if not wanted_runtime.has_method("get_heat_level") or not wanted_runtime.has_method("get_wanted_state_name"):
		return false
	if not contact_runtime.has_method("get_progress_store") or not claim_runtime.has_method("get_progress_store"):
		return false
	for method_name in ["get_progress_store", "get_balance", "get_last_feedback", "attempt_courier_bike_bash_bar_purchase"]:
		if not cash_runtime.has_method(method_name):
			return false
	if not bike.has_method("has_scrap_bash_bar") or not bike.has_method("set_scrap_bash_bar_installed"):
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
	_claim_runtime = claim_runtime
	_cash_runtime = cash_runtime
	_bike = bike
	_claim_socket = socket

	_mod_interactable = InteractableBaseScript.new() as InteractableBase
	if _mod_interactable == null:
		return false
	_mod_interactable.name = "CourierBikeScrapBashBarInteractable"
	_mod_interactable.interaction_radius = CLAIM_RADIUS_M
	_mod_interactable.sensory_radius = AFFORDANCE_RADIUS_M
	_mod_interactable.interaction_priority = 3.9
	_mod_interactable.is_powered = false
	add_child(_mod_interactable)
	_mod_interactable.global_position = _claim_socket.global_position
	if not interactables.has(_mod_interactable):
		interactables.append(_mod_interactable)

	_affordance_label = Label3D.new()
	_affordance_label.name = "CourierBikeScrapBashBarAffordance"
	_affordance_label.font_size = 5
	_affordance_label.outline_size = 2
	_affordance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_affordance_label.no_depth_test = true
	_affordance_label.fixed_size = true
	_affordance_label.modulate = Color(0.95, 0.62, 0.18, 0.96)
	_affordance_label.outline_modulate = Color(0.08, 0.08, 0.07, 0.96)
	_affordance_label.visible = false
	add_child(_affordance_label)
	_affordance_label.global_position = _claim_socket.global_position + Vector3(0.0, 1.45, 0.0)

	var action_callable := Callable(self, "handle_action_pressed")
	if not touch_ui.action_button_pressed.is_connected(action_callable):
		touch_ui.action_button_pressed.connect(action_callable)

	_bound = true
	set_process(true)
	restore_mod_from_receipt()
	return true

func _exit_tree() -> void:
	if _root_controller != null and _mod_interactable != null:
		var interactables = _root_controller.get("_interactables")
		if interactables is Array:
			interactables.erase(_mod_interactable)
		var touch_ui := _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
		if touch_ui != null:
			var action_callable := Callable(self, "handle_action_pressed")
			if touch_ui.action_button_pressed.is_connected(action_callable):
				touch_ui.action_button_pressed.disconnect(action_callable)

func _process(_delta: float) -> void:
	if not _bound or _claim_socket == null or _mod_interactable == null or _bike == null:
		return

	if _has_receipt():
		if not bool(_bike.call("has_scrap_bash_bar")):
			_bike.call("set_scrap_bash_bar_installed", true)
		_mod_interactable.is_powered = false
		if Time.get_ticks_msec() < _success_until_msec:
			_set_affordance("SCRAP BASH BAR // FITTED", true)
		else:
			_set_affordance("", false)
		return

	var player := _get_player()
	if player == null or not _contact_is_known() or not _claim_is_owned() or not _player_is_on_foot(player):
		_mod_interactable.is_powered = false
		_set_affordance("", false)
		return

	var player_distance := player.global_position.distance_to(_claim_socket.global_position)
	if player_distance > AFFORDANCE_RADIUS_M:
		_mod_interactable.is_powered = false
		_set_affordance("", false)
		return

	if not _wanted_is_clear():
		_mod_interactable.is_powered = false
		_set_affordance("WANTED // GARAGE LOCKED", true)
		return

	if _bike.occupant != null or _bike.global_position.distance_to(_claim_socket.global_position) > CLAIM_RADIUS_M:
		_mod_interactable.is_powered = false
		_set_affordance("", false)
		return

	_mod_interactable.is_powered = true
	_mod_interactable.update_player_distance(player.global_position)
	if abs(float(_bike.current_speed)) > CLAIM_STOP_SPEED_MPS:
		_set_affordance("STOP TO FIT BASH BAR", true)
		return

	var balance := int(_cash_runtime.call("get_balance"))
	if balance < PRICE:
		_set_affordance("BASH BAR // %d CASH // NEED %d" % [PRICE, PRICE - balance], true)
	else:
		_set_affordance("FIT SCRAP BASH BAR // %d CASH // ACTION" % PRICE, true)

func handle_action_pressed() -> bool:
	if not _bound or _root_controller == null or _mod_interactable == null:
		return false
	if _root_controller.get("_active_target") != _mod_interactable:
		return false
	return attempt_purchase()

func attempt_purchase() -> bool:
	if not _bound or _has_receipt() or not _contact_is_known() or not _claim_is_owned() or not _wanted_is_clear():
		return false
	var player := _get_player()
	if player == null or not _player_is_on_foot(player):
		return false
	if player.global_position.distance_to(_claim_socket.global_position) > CLAIM_RADIUS_M:
		return false
	if _bike.occupant != null 	or _bike.global_position.distance_to(_claim_socket.global_position) > CLAIM_RADIUS_M 	or abs(float(_bike.current_speed)) > CLAIM_STOP_SPEED_MPS:
		return false

	var purchased := bool(_cash_runtime.call("attempt_courier_bike_bash_bar_purchase"))
	_publish_cash_feedback()
	if not purchased:
		return false
	if not _has_receipt():
		return false

	_bike.call("set_scrap_bash_bar_installed", true)
	_success_until_msec = Time.get_ticks_msec() + SUCCESS_FEEDBACK_MSEC
	_mod_interactable.is_powered = false
	_set_affordance("SCRAP BASH BAR // FITTED", true)
	return true

func restore_mod_from_receipt() -> bool:
	if not _bound or _bike == null:
		return false
	var paid := _has_receipt()
	_bike.call("set_scrap_bash_bar_installed", paid)
	return paid

func get_price() -> int:
	return PRICE

func get_mod_interactable() -> InteractableBase:
	return _mod_interactable

func get_affordance_text() -> String:
	return _affordance_text

func _cash_store():
	if _cash_runtime == null or not _cash_runtime.has_method("get_progress_store"):
		return null
	return _cash_runtime.call("get_progress_store")

func _has_receipt() -> bool:
	var store = _cash_store()
	return store != null 		and store.has_method("has_courier_bike_bash_bar_receipt") 		and bool(store.call("has_courier_bike_bash_bar_receipt"))

func _claim_is_owned() -> bool:
	if _claim_runtime == null or not _claim_runtime.has_method("get_progress_store"):
		return false
	var store = _claim_runtime.call("get_progress_store")
	return store != null and store.has_method("is_claimed") and bool(store.call("is_claimed"))

func _contact_is_known() -> bool:
	if _contact_runtime == null or not _contact_runtime.has_method("get_progress_store"):
		return false
	var store = _contact_runtime.call("get_progress_store")
	return store != null and store.has_method("is_known") and bool(store.call("is_known"))

func _get_player() -> PlayerRunner:
	if _root_controller == null:
		return null
	var candidate = _root_controller.get("player")
	return candidate as PlayerRunner if candidate is PlayerRunner else null

func _player_is_on_foot(player: PlayerRunner) -> bool:
	return player != null 		and not player.is_mounted 		and not player.is_input_locked 		and _root_controller.get("active_vehicle") == null

func _wanted_is_clear() -> bool:
	return _wanted_runtime != null 		and int(_wanted_runtime.call("get_heat_level")) == 0 		and String(_wanted_runtime.call("get_wanted_state_name")) == "CLEAR"

func _publish_cash_feedback() -> void:
	if _root_controller == null or _cash_runtime == null:
		return
	if _root_controller.has_method("_show_cash_notice") and _cash_runtime.has_method("get_last_feedback"):
		_root_controller.call("_show_cash_notice", String(_cash_runtime.call("get_last_feedback")))

func _set_affordance(text: String, visible_value: bool) -> void:
	_affordance_text = text
	if _affordance_label != null:
		_affordance_label.text = text
		_affordance_label.visible = visible_value
