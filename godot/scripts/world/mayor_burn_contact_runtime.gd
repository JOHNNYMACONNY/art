class_name MayorBurnContactRuntime
extends Node3D

## Burnside Production 10 / #152
## One authored Mayor Burn Contact consequence at the retained Garage.
## Owns only Burn Contact persistence consumption and the Armor-restock privilege.

const InteractableBaseScript = preload("res://scripts/interactions/interactable_base.gd")
const ProgressStoreScript = preload("res://scripts/progress/mayor_burn_contact_progress_store.gd")
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")

const SERVICE_SOCKET_PATH := "MissionDestinationSocket"
const SERVICE_RADIUS_M := 2.6
const AFFORDANCE_RADIUS_M := 8.0
const SUCCESS_FEEDBACK_MSEC := 1200

var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _player: PlayerRunner = null
var _civic_runtime: Node = null
var _service_socket: Marker3D = null
var _service_interactable: InteractableBase = null
var _affordance_label: Label3D = null
var _affordance_text: String = ""
var _progress_store = null
var _success_until_msec: int = 0
var _bound: bool = false

func configure(root_controller: Node, district: Node3D, wanted_runtime: Node, progress_store = null) -> bool:
	if root_controller == null or district == null or wanted_runtime == null:
		return false
	if not root_controller.has_method("_get_active_vehicle"):
		return false
	if not wanted_runtime.has_method("get_heat_level") or not wanted_runtime.has_method("get_wanted_state_name"):
		return false

	var player := root_controller.get_node_or_null("Runner") as PlayerRunner
	var civic_runtime := root_controller.get_node_or_null("CivicRepossessionRuntime")
	var socket := district.get_node_or_null(SERVICE_SOCKET_PATH) as Marker3D
	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var interactables = root_controller.get("_interactables")
	if player == null or civic_runtime == null or socket == null or touch_ui == null or not (interactables is Array):
		return false
	if not civic_runtime.has_signal("mission_completed"):
		return false

	_root_controller = root_controller
	_district = district
	_wanted_runtime = wanted_runtime
	_player = player
	_civic_runtime = civic_runtime
	_service_socket = socket

	_progress_store = progress_store
	if _progress_store == null:
		_progress_store = ProgressStoreScript.new()
		_progress_store.call("configure")
	if _progress_store == null or not _progress_store.has_method("is_known") or not _progress_store.has_method("mark_known"):
		return false

	_service_interactable = InteractableBaseScript.new() as InteractableBase
	if _service_interactable == null:
		return false
	_service_interactable.name = "MayorBurnArmorRestockInteractable"
	_service_interactable.interaction_radius = SERVICE_RADIUS_M
	_service_interactable.sensory_radius = AFFORDANCE_RADIUS_M
	_service_interactable.interaction_priority = 3.6
	_service_interactable.is_powered = false
	add_child(_service_interactable)
	_service_interactable.global_position = _service_socket.global_position
	if not interactables.has(_service_interactable):
		interactables.append(_service_interactable)

	_affordance_label = Label3D.new()
	_affordance_label.name = "MayorBurnContactAffordance"
	_affordance_label.font_size = 5
	_affordance_label.outline_size = 2
	_affordance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_affordance_label.no_depth_test = true
	_affordance_label.fixed_size = true
	_affordance_label.modulate = Color(0.96, 0.76, 0.26, 0.96)
	_affordance_label.outline_modulate = Color(0.06, 0.06, 0.05, 0.96)
	_affordance_label.visible = false
	add_child(_affordance_label)
	_affordance_label.global_position = _service_socket.global_position + Vector3(0.0, 1.55, 0.0)

	var action_callable := Callable(self, "handle_action_pressed")
	if not touch_ui.action_button_pressed.is_connected(action_callable):
		touch_ui.action_button_pressed.connect(action_callable)
	var completion_callable := Callable(self, "_on_civic_repossession_completed")
	if not _civic_runtime.mission_completed.is_connected(completion_callable):
		_civic_runtime.mission_completed.connect(completion_callable)

	# If this runtime binds after the completion frame, reconcile the retained
	# mission state exactly once rather than requiring the signal to be replayed.
	if _civic_runtime.get("mission") != null and int(_civic_runtime.mission.phase) == int(CivicMissionScript.Phase.COMPLETE):
		_progress_store.call("mark_known")

	_bound = true
	set_process(true)
	return true

func _exit_tree() -> void:
	if _root_controller == null or _service_interactable == null:
		return
	var interactables = _root_controller.get("_interactables")
	if interactables is Array:
		interactables.erase(_service_interactable)

func _process(_delta: float) -> void:
	if not _bound or _service_interactable == null or _service_socket == null or _player == null:
		return

	var now := Time.get_ticks_msec()
	if now < _success_until_msec:
		_service_interactable.is_powered = false
		_set_affordance("ARMOR RESTOCKED", true)
		return

	if not bool(_progress_store.call("is_known")):
		_service_interactable.is_powered = false
		_set_affordance("", false)
		return

	if _root_controller.call("_get_active_vehicle") != null or _player.is_mounted:
		_service_interactable.is_powered = false
		_set_affordance("", false)
		return

	if _player.current_health <= 0.0 or _player.current_armor >= _player.MAX_ARMOR:
		_service_interactable.is_powered = false
		_set_affordance("", false)
		return

	var distance := _player.global_position.distance_to(_service_socket.global_position)
	_service_interactable.update_player_distance(_player.global_position)
	if distance > AFFORDANCE_RADIUS_M:
		_service_interactable.is_powered = false
		_set_affordance("", false)
		return

	if distance > SERVICE_RADIUS_M:
		_service_interactable.is_powered = false
		_set_affordance("BURN // ARMOR STASH", true)
		return

	if not _wanted_is_clear():
		_service_interactable.is_powered = false
		_set_affordance("WANTED // BURN WON'T OPEN", true)
		return

	_service_interactable.is_powered = true
	_set_affordance("RESTOCK ARMOR // ACTION", true)

func handle_action_pressed() -> bool:
	if not _bound or _root_controller == null or _service_interactable == null:
		return false
	if _root_controller.get("_active_target") != _service_interactable:
		return false
	return attempt_armor_restock()

func attempt_armor_restock() -> bool:
	if not _bound or _player == null or _service_socket == null:
		return false
	if not bool(_progress_store.call("is_known")):
		return false
	if _root_controller.call("_get_active_vehicle") != null or _player.is_mounted:
		return false
	if _player.current_health <= 0.0 or _player.current_armor >= _player.MAX_ARMOR:
		return false
	if _player.global_position.distance_to(_service_socket.global_position) > SERVICE_RADIUS_M:
		return false
	if not _wanted_is_clear():
		return false
	if not _player.restore_armor_to_max():
		return false
	_success_until_msec = Time.get_ticks_msec() + SUCCESS_FEEDBACK_MSEC
	_service_interactable.is_powered = false
	_set_affordance("ARMOR RESTOCKED", true)
	return true

func _on_civic_repossession_completed() -> void:
	if _progress_store != null:
		_progress_store.call("mark_known")

func get_contact_state_name() -> String:
	return String(_progress_store.call("get_state_name")) if _progress_store != null else "UNESTABLISHED"

func get_progress_store():
	return _progress_store

func get_service_interactable() -> InteractableBase:
	return _service_interactable

func get_affordance_text() -> String:
	return _affordance_text

func _wanted_is_clear() -> bool:
	return _wanted_runtime != null \
		and int(_wanted_runtime.call("get_heat_level")) == 0 \
		and String(_wanted_runtime.call("get_wanted_state_name")) == "CLEAR"

func _set_affordance(text: String, visible_value: bool) -> void:
	_affordance_text = text
	if _affordance_label != null:
		_affordance_label.text = text
		_affordance_label.visible = visible_value
