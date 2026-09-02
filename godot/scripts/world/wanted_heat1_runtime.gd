extends Node

## Burnside Production 01 / #119 + Production 02 / #122
## Thin Heat-1 runtime adapter over the retained golden-slice player/pursuer/HUD seams.
## It owns open-world authority knowledge plus one bounded civic-report interference seam,
## not mission pursuit, a police director, or a generalized hacking framework.

const WantedAuthorityScript = preload("res://scripts/world/wanted_authority.gd")
const CivicServiceAlarmScene = preload("res://scenes/interactions/civic_service_alarm.tscn")
const CivicReportAccessScene = preload("res://scenes/interactions/civic_report_access.tscn")

const LEGACY_PURSUIT_CALM := 0
const CONTACT_LOSS_GRACE_SECONDS := 0.8
const RESPONSE_SPAWN := Vector3(0.0, 0.6, -10.0)

var wanted_authority = WantedAuthorityScript.new()
var search_anchor: Node3D = null

var _scene_controller: Node = null
var _player: Node3D = null
var _pursuer: Node3D = null
var _touch_ui: Node = null
var _alarm: CivicServiceAlarm = null
var _report_access: CivicReportAccess = null
var _wanted_label: Label = null
var _contact_loss_timer: float = 0.0
var _saved_intercept_distance: float = 1.5
var _intercept_override_active: bool = false
var _bound: bool = false

func _ready() -> void:
	call_deferred("_bind_current_scene_if_ready")

func _process(delta: float) -> void:
	var current := get_tree().current_scene
	if current != null and current != _scene_controller:
		bind_to_scene(current)
	if _bound:
		process_wanted(delta)

func _bind_current_scene_if_ready() -> void:
	var current := get_tree().current_scene
	if current != null:
		bind_to_scene(current)

func bind_to_scene(scene: Node) -> bool:
	if scene == null:
		return false
	if scene == _scene_controller and _bound:
		return true

	_unbind_scene()

	var player_node := scene.get_node_or_null("Runner") as Node3D
	var touch_node := scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var canvas := scene.get_node_or_null("CanvasLayer") as CanvasLayer
	var pursuer_node = scene.get("pursuer")
	if player_node == null or touch_node == null or canvas == null or not (pursuer_node is Node3D):
		return false

	_scene_controller = scene
	_player = player_node
	_touch_ui = touch_node
	_pursuer = pursuer_node as Node3D
	_saved_intercept_distance = float(_pursuer.get("intercept_distance"))

	search_anchor = Node3D.new()
	search_anchor.name = "WantedSearchAnchor"
	_scene_controller.add_child(search_anchor)

	_alarm = CivicServiceAlarmScene.instantiate() as CivicServiceAlarm
	if _alarm == null:
		_unbind_scene()
		return false
	_alarm.name = "CivicServiceAlarm"
	_scene_controller.add_child(_alarm)

	_report_access = CivicReportAccessScene.instantiate() as CivicReportAccess
	if _report_access == null:
		_unbind_scene()
		return false
	_report_access.name = "CivicReportAccess"
	_scene_controller.add_child(_report_access)

	var utility_plate := _scene_controller.get_node_or_null("GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate") as Node3D
	if utility_plate != null:
		_alarm.global_position = utility_plate.global_position + Vector3(0.0, -1.8, 0.35)
		_report_access.global_position = utility_plate.global_position + Vector3(0.0, -1.8, 3.55)
	else:
		_alarm.global_position = Vector3(0.9, 1.0, -38.65)
		_report_access.global_position = Vector3(0.9, 1.0, -35.45)

	var interactables = _scene_controller.get("_interactables")
	if interactables is Array:
		if not interactables.has(_alarm):
			interactables.append(_alarm)
		if not interactables.has(_report_access):
			interactables.append(_report_access)

	var report_callable := Callable(self, "_on_report_requested")
	if not _alarm.report_requested.is_connected(report_callable):
		_alarm.report_requested.connect(report_callable)
	var interference_callable := Callable(self, "_on_report_interference_requested")
	if not _report_access.report_interference_requested.is_connected(interference_callable):
		_report_access.report_interference_requested.connect(interference_callable)

	_wanted_label = Label.new()
	_wanted_label.name = "WantedStatusLabel"
	_wanted_label.anchor_left = 1.0
	_wanted_label.anchor_right = 1.0
	_wanted_label.anchor_top = 0.0
	_wanted_label.anchor_bottom = 0.0
	_wanted_label.offset_left = -280.0
	_wanted_label.offset_top = 16.0
	_wanted_label.offset_right = -16.0
	_wanted_label.offset_bottom = 46.0
	_wanted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wanted_label.visible = false
	canvas.add_child(_wanted_label)

	var action_callable := Callable(self, "handle_action_pressed")
	if not _touch_ui.action_button_pressed.is_connected(action_callable):
		_touch_ui.action_button_pressed.connect(action_callable)
	var replay_callable := Callable(self, "reset_runtime")
	if not _touch_ui.replay_pressed.is_connected(replay_callable):
		_touch_ui.replay_pressed.connect(replay_callable)

	wanted_authority.reset()
	_contact_loss_timer = 0.0
	_bound = true
	_update_hud()
	return true

func handle_action_pressed() -> bool:
	if not _bound or _scene_controller == null or _alarm == null or _report_access == null:
		return false
	var active_target = _scene_controller.get("_active_target")
	if active_target != _alarm and active_target != _report_access:
		return false
	var actor := _get_player_target()
	if actor == null:
		return false
	if active_target == _report_access:
		_report_access.update_player_distance(actor.global_position)
		return _report_access.begin_interaction(actor.global_position)
	_alarm.update_player_distance(actor.global_position)
	return _alarm.begin_interaction(actor.global_position)

func request_civic_report(observed_position: Vector3) -> bool:
	if not _bound or _alarm == null or not is_instance_valid(_alarm):
		return false
	return _alarm.trigger_report(observed_position)

func get_heat_level() -> int:
	return wanted_authority.get_heat_level() if wanted_authority != null else 0

func get_wanted_state_name() -> String:
	return wanted_authority.get_wanted_state_name() if wanted_authority != null else "CLEAR"

func process_wanted(delta: float) -> void:
	if not _bound or _scene_controller == null or _pursuer == null:
		return

	var legacy_state := int(_scene_controller.get("current_pursuit_state"))
	if legacy_state != LEGACY_PURSUIT_CALM:
		if wanted_authority.get_heat_level() > 0:
			_yield_to_legacy_pursuit()
		return

	var state_name := wanted_authority.get_wanted_state_name()
	if state_name == "CLEAR":
		_update_hud()
		return

	var target := _get_player_target()
	if target == null:
		return

	if state_name == "CONTACT":
		if has_direct_observation(_pursuer, target):
			_contact_loss_timer = 0.0
			var reason := wanted_authority.get_last_reason()
			if String(reason).begins_with("contact_lost:"):
				wanted_authority.reacquire("pursuer_direct_observation", target.global_position, _get_target_direction(target))
			else:
				wanted_authority.observe_contact("pursuer_direct_observation", target.global_position, _get_target_direction(target))
			_pursuer.set("target_node", target)
		else:
			_contact_loss_timer += maxf(delta, 0.0)
			_set_search_anchor(wanted_authority.get_last_known_position())
			_pursuer.set("target_node", search_anchor)
			if _contact_loss_timer >= CONTACT_LOSS_GRACE_SECONDS:
				_contact_loss_timer = 0.0
				wanted_authority.lose_contact(
					wanted_authority.get_last_known_position(),
					wanted_authority.get_last_known_direction(),
					"pursuer_los_broken"
				)
	elif state_name == "SEARCH":
		_set_search_anchor(wanted_authority.get_last_known_position())
		_pursuer.set("target_node", search_anchor)
		if has_direct_observation(_pursuer, target):
			if wanted_authority.reacquire("pursuer_direct_observation", target.global_position, _get_target_direction(target)):
				_contact_loss_timer = 0.0
				_pursuer.set("target_node", target)
		elif wanted_authority.advance_search(maxf(delta, 0.0)):
			_on_evasion()

	_update_hud()

func has_direct_observation(observer: Node3D, target: Node3D) -> bool:
	if observer == null or target == null or not observer.is_inside_tree() or not target.is_inside_tree():
		return false
	var world := observer.get_world_3d()
	if world == null:
		return false
	var from := observer.global_position + Vector3(0.0, 0.7, 0.0)
	var to := target.global_position + Vector3(0.0, 0.7, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var excluded: Array[RID] = []
	if observer is CollisionObject3D:
		excluded.append((observer as CollisionObject3D).get_rid())
	if target is CollisionObject3D:
		excluded.append((target as CollisionObject3D).get_rid())
	query.exclude = excluded
	var hit := world.direct_space_state.intersect_ray(query)
	return hit.is_empty()

func reset_runtime() -> void:
	var had_open_world_response := wanted_authority.get_heat_level() > 0
	wanted_authority.reset()
	_contact_loss_timer = 0.0
	_restore_open_world_interception()
	_restore_civic_reporting_service()
	if had_open_world_response and _pursuer != null and is_instance_valid(_pursuer) and _legacy_pursuit_is_calm():
		if _pursuer.has_method("reset_pursuer"):
			_pursuer.call("reset_pursuer", RESPONSE_SPAWN)
	_update_hud()

func _on_report_interference_requested() -> void:
	if _alarm == null or not is_instance_valid(_alarm):
		return
	_alarm.report_enabled = false

func _on_report_requested(report_source: String, observed_position: Vector3, contact_source: String) -> void:
	if not _bound or not _legacy_pursuit_is_calm():
		return
	if wanted_authority.get_heat_level() > 0:
		return
	var target := _get_player_target()
	if target == null:
		return
	if not wanted_authority.submit_report(report_source, observed_position, _get_target_direction(target), contact_source):
		return

	_set_search_anchor(observed_position)
	_disable_open_world_interception()
	if _pursuer.has_method("reset_pursuer"):
		_pursuer.call("reset_pursuer", RESPONSE_SPAWN)
	if _pursuer.has_method("activate_pursuit"):
		_pursuer.call("activate_pursuit", search_anchor)
	_update_hud()

func _restore_civic_reporting_service() -> void:
	if _alarm != null and is_instance_valid(_alarm):
		_alarm.report_enabled = true
		_alarm.reset_alarm()
	if _report_access != null and is_instance_valid(_report_access):
		_report_access.reset_access()

func _yield_to_legacy_pursuit() -> void:
	wanted_authority.reset()
	_contact_loss_timer = 0.0
	_restore_open_world_interception()
	if _pursuer != null and is_instance_valid(_pursuer) and _pursuer.has_method("reset_pursuer"):
		_pursuer.call("reset_pursuer", RESPONSE_SPAWN)
	_restore_civic_reporting_service()
	_update_hud()

func _on_evasion() -> void:
	_contact_loss_timer = 0.0
	_restore_open_world_interception()
	if _alarm != null and is_instance_valid(_alarm):
		_alarm.reset_alarm()
	if _pursuer != null and is_instance_valid(_pursuer) and _pursuer.has_method("start_de_escalation"):
		_pursuer.call("start_de_escalation")
	_update_hud()

func _get_player_target() -> Node3D:
	if _scene_controller == null:
		return _player
	if _scene_controller.has_method("_get_active_vehicle"):
		var active = _scene_controller.call("_get_active_vehicle")
		if active is Node3D:
			return active as Node3D
	return _player

func _get_target_direction(target: Node3D) -> Vector3:
	if target is CharacterBody3D:
		var velocity := (target as CharacterBody3D).velocity
		velocity.y = 0.0
		if velocity.length_squared() > 0.01:
			return velocity.normalized()
	var forward := -target.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized() if forward.length_squared() > 0.000001 else Vector3.ZERO

func _set_search_anchor(position: Vector3) -> void:
	if search_anchor != null and is_instance_valid(search_anchor):
		search_anchor.global_position = position

func _disable_open_world_interception() -> void:
	if _pursuer == null or _intercept_override_active:
		return
	_saved_intercept_distance = float(_pursuer.get("intercept_distance"))
	_pursuer.set("intercept_distance", -1.0)
	_intercept_override_active = true

func _restore_open_world_interception() -> void:
	if _pursuer == null or not _intercept_override_active:
		return
	_pursuer.set("intercept_distance", _saved_intercept_distance)
	_intercept_override_active = false

func _legacy_pursuit_is_calm() -> bool:
	return _scene_controller != null and int(_scene_controller.get("current_pursuit_state")) == LEGACY_PURSUIT_CALM

func _update_hud() -> void:
	if _wanted_label == null or not is_instance_valid(_wanted_label):
		return
	var heat := wanted_authority.get_heat_level()
	var state_name := wanted_authority.get_wanted_state_name()
	_wanted_label.visible = heat > 0 and state_name != "CLEAR"
	_wanted_label.text = "HEAT %d // %s" % [heat, state_name] if _wanted_label.visible else ""

func _unbind_scene() -> void:
	_restore_open_world_interception()
	wanted_authority.reset()
	_contact_loss_timer = 0.0

	if _touch_ui != null and is_instance_valid(_touch_ui):
		var action_callable := Callable(self, "handle_action_pressed")
		if _touch_ui.action_button_pressed.is_connected(action_callable):
			_touch_ui.action_button_pressed.disconnect(action_callable)
		var replay_callable := Callable(self, "reset_runtime")
		if _touch_ui.replay_pressed.is_connected(replay_callable):
			_touch_ui.replay_pressed.disconnect(replay_callable)

	if _scene_controller != null and is_instance_valid(_scene_controller):
		var interactables = _scene_controller.get("_interactables")
		if interactables is Array:
			if _alarm != null and is_instance_valid(_alarm):
				interactables.erase(_alarm)
			if _report_access != null and is_instance_valid(_report_access):
				interactables.erase(_report_access)

	for node in [_alarm, _report_access, search_anchor, _wanted_label]:
		if node != null and is_instance_valid(node):
			node.queue_free()

	_scene_controller = null
	_player = null
	_pursuer = null
	_touch_ui = null
	_alarm = null
	_report_access = null
	search_anchor = null
	_wanted_label = null
	_bound = false
