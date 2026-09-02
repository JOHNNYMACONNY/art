class_name GearsScrapperToolRuntime
extends Node3D

const ScrapperToolPickupScene = preload("res://scenes/interactions/scrapper_tool_pickup.tscn")

const SWING_IMPACT_SEC := 0.14
const SWING_TOTAL_SEC := 0.60
const TOOL_REACH_M := 1.8
const TOOL_FORWARD_DOT := 0.5

enum AccessState { JAMMED, FORCED_OPEN }

var _root_controller: Node = null
var _district: Node3D = null
var _touch_ui: Node = null
var _player: Node3D = null
var _pickup: ScrapperToolPickup = null
var _held_visual: MeshInstance3D = null
var _held: bool = false
var _configured: bool = false

var _access_state: AccessState = AccessState.JAMMED
var _access_barrier: StaticBody3D = null
var _access_mesh: MeshInstance3D = null
var _access_collision: CollisionShape3D = null

var _swing_active: bool = false
var _swing_elapsed: float = 0.0
var _swing_origin: Vector3 = Vector3.ZERO
var _swing_facing: Vector3 = Vector3.FORWARD
var _contact_evaluated: bool = false
var _contact_evaluation_count: int = 0
var _last_contact: String = "NONE"

func _process(delta: float) -> void:
	if _configured:
		process_tool_state(delta)

func configure(root_controller: Node, district: Node3D) -> bool:
	if root_controller == null or district == null:
		return false
	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := root_controller.get_node_or_null("Runner") as Node3D
	var socket := district.get_node_or_null("ServiceAlleyEntrySocket") as Marker3D
	if touch_ui == null or player == null or socket == null:
		return false
	if not touch_ui.has_signal("action_button_pressed") or not touch_ui.has_signal("tool_action_pressed") or not touch_ui.has_signal("replay_pressed"):
		return false
	if not player.has_method("get_facing_direction"):
		return false

	_root_controller = root_controller
	_district = district
	_touch_ui = touch_ui
	_player = player

	_pickup = ScrapperToolPickupScene.instantiate() as ScrapperToolPickup
	if _pickup == null:
		return false
	_pickup.name = "ScrapperToolPickup"
	_root_controller.add_child(_pickup)
	_pickup.global_position = socket.global_position + Vector3(1.15, 0.55, 0.95)

	var interactables = _root_controller.get("_interactables")
	if interactables is Array and not interactables.has(_pickup):
		interactables.append(_pickup)

	_ensure_held_visual()
	_ensure_access_barrier(socket)
	_touch_ui.call("set_tool_action_available", false)

	var action_callable := Callable(self, "_on_action_pressed")
	if not _touch_ui.is_connected("action_button_pressed", action_callable):
		_touch_ui.connect("action_button_pressed", action_callable)
	var tool_callable := Callable(self, "handle_tool_action_pressed")
	if not _touch_ui.is_connected("tool_action_pressed", tool_callable):
		_touch_ui.connect("tool_action_pressed", tool_callable)
	var replay_callable := Callable(self, "reset_runtime")
	if not _touch_ui.is_connected("replay_pressed", replay_callable):
		_touch_ui.connect("replay_pressed", replay_callable)

	_configured = true
	return true

func _ensure_held_visual() -> void:
	if _held_visual != null or _player == null:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.12, 0.82)
	_held_visual = MeshInstance3D.new()
	_held_visual.name = "HeldScrapperTool"
	_held_visual.mesh = mesh
	_held_visual.position = Vector3(0.34, 0.58, -0.38)
	_held_visual.rotation = Vector3(0.15, 0.0, 0.55)
	_held_visual.visible = false
	_player.add_child(_held_visual)

func _ensure_access_barrier(socket: Marker3D) -> void:
	if _access_barrier != null:
		return
	_access_barrier = StaticBody3D.new()
	_access_barrier.name = "JammedServiceAccess"
	add_child(_access_barrier)
	_access_barrier.global_position = socket.global_position + Vector3(0.0, 0.82, 0.0)

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(3.3, 1.55, 0.28)
	_access_mesh = MeshInstance3D.new()
	_access_mesh.name = "BarrierMesh"
	_access_mesh.mesh = box_mesh
	_access_barrier.add_child(_access_mesh)

	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(3.3, 1.55, 0.28)
	_access_collision = CollisionShape3D.new()
	_access_collision.name = "CollisionShape3D"
	_access_collision.shape = box_shape
	_access_barrier.add_child(_access_collision)

func _on_action_pressed() -> void:
	acquire_active_pickup()

func handle_action_pressed() -> bool:
	return acquire_active_pickup()

func acquire_active_pickup() -> bool:
	if not _configured or _held or _pickup == null or not is_instance_valid(_pickup):
		return false
	if _root_controller.get("_active_target") != _pickup:
		return false
	if _player == null:
		return false
	_pickup.update_player_distance(_player.global_position)
	if not _pickup.can_interact(_player.global_position):
		return false
	if not _pickup.acquire():
		return false
	_held = true
	if _held_visual:
		_held_visual.visible = true
	_touch_ui.call("set_tool_action_available", true)
	return true

func handle_tool_action_pressed() -> bool:
	if not _configured or not _held or _touch_ui == null or _player == null:
		return false
	if _swing_active:
		return false
	if int(_touch_ui.get("current_mode")) != int(TouchControlsUI.UIMode.FOOT_TRAVERSAL):
		return false
	var facing: Vector3 = _player.call("get_facing_direction")
	facing.y = 0.0
	if facing.length_squared() <= 0.001:
		return false
	_swing_origin = _player.global_position
	_swing_facing = facing.normalized()
	_swing_elapsed = 0.0
	_contact_evaluated = false
	_swing_active = true
	_last_contact = "PENDING"
	return true

func process_tool_state(delta: float) -> void:
	if not _swing_active:
		return
	_swing_elapsed += maxf(delta, 0.0)
	if not _contact_evaluated and _swing_elapsed >= SWING_IMPACT_SEC:
		_contact_evaluated = true
		_evaluate_contact_once()
	if _swing_elapsed >= SWING_TOTAL_SEC:
		_swing_active = false
		_swing_elapsed = 0.0

func _candidate_distance(target_position: Vector3) -> float:
	var delta := target_position - _swing_origin
	delta.y = 0.0
	if delta.length_squared() <= 0.001:
		return 0.0
	var distance := delta.length()
	if distance > TOOL_REACH_M:
		return INF
	if _swing_facing.dot(delta / distance) < TOOL_FORWARD_DOT:
		return INF
	return distance

func _pursuer_can_receive_stagger(pursuer: Node3D) -> bool:
	if pursuer == null or not bool(pursuer.get("is_active")) or not pursuer.has_method("apply_scrapper_stagger"):
		return false
	var state := int(pursuer.get("current_state"))
	return state == int(PursuerPrototype.PursuerState.CHASING) or state == int(PursuerPrototype.PursuerState.DETOURING)

func _evaluate_contact_once() -> void:
	_contact_evaluation_count += 1
	var best_distance := INF
	var best_kind := "MISS"

	if _access_state == AccessState.JAMMED and _access_barrier != null:
		var access_distance := _candidate_distance(_access_barrier.global_position)
		if access_distance < best_distance:
			best_distance = access_distance
			best_kind = "SERVICE_ACCESS"

	var pursuer := _root_controller.get_node_or_null("PursuerPrototype") as Node3D
	if _pursuer_can_receive_stagger(pursuer):
		var pursuer_distance := _candidate_distance(pursuer.global_position)
		if pursuer_distance < best_distance:
			best_distance = pursuer_distance
			best_kind = "PURSUER"

	_last_contact = best_kind
	if best_kind == "SERVICE_ACCESS":
		_force_access_open()
	elif best_kind == "PURSUER" and pursuer != null:
		if not bool(pursuer.call("apply_scrapper_stagger", _swing_facing)):
			_last_contact = "MISS"

func _force_access_open() -> bool:
	if _access_state != AccessState.JAMMED:
		return false
	_access_state = AccessState.FORCED_OPEN
	if _access_collision != null:
		_access_collision.set_deferred("disabled", true)
	if _access_mesh != null:
		_access_mesh.position.y = -0.9
		_access_mesh.rotation.z = 0.42
	var incident := _root_controller.get_node_or_null("GearsWorkZoneIncident") if _root_controller != null else null
	if incident != null and incident.has_method("trigger_service_access_disruption"):
		incident.call("trigger_service_access_disruption", _access_barrier.global_position)
	return true

func has_tool() -> bool:
	return _held

func get_pickup() -> ScrapperToolPickup:
	return _pickup

func get_access_barrier() -> StaticBody3D:
	return _access_barrier

func get_access_state_name() -> String:
	return AccessState.keys()[_access_state]

func is_service_access_blocking() -> bool:
	return _access_state == AccessState.JAMMED and _access_collision != null and not _access_collision.disabled

func get_contact_evaluation_count() -> int:
	return _contact_evaluation_count

func get_last_contact_name() -> String:
	return _last_contact

func is_swing_active() -> bool:
	return _swing_active

func reset_runtime() -> void:
	_held = false
	_swing_active = false
	_swing_elapsed = 0.0
	_contact_evaluated = false
	_contact_evaluation_count = 0
	_last_contact = "NONE"
	_access_state = AccessState.JAMMED
	if _pickup != null and is_instance_valid(_pickup):
		_pickup.reset_pickup()
	if _held_visual != null and is_instance_valid(_held_visual):
		_held_visual.visible = false
	if _access_collision != null and is_instance_valid(_access_collision):
		_access_collision.set_deferred("disabled", false)
	if _access_mesh != null and is_instance_valid(_access_mesh):
		_access_mesh.position = Vector3.ZERO
		_access_mesh.rotation = Vector3.ZERO
	if _touch_ui != null and is_instance_valid(_touch_ui):
		_touch_ui.call("set_tool_action_available", false)
