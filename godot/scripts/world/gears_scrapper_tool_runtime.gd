class_name GearsScrapperToolRuntime
extends Node3D

const ScrapperToolPickupScene = preload("res://scenes/interactions/scrapper_tool_pickup.tscn")

var _root_controller: Node = null
var _district: Node3D = null
var _touch_ui: Node = null
var _player: Node3D = null
var _pickup: ScrapperToolPickup = null
var _held_visual: MeshInstance3D = null
var _held: bool = false
var _configured: bool = false

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

func _on_action_pressed() -> void:
	acquire_active_pickup()

func handle_action_pressed() -> bool:
	return acquire_active_pickup()

func acquire_active_pickup() -> bool:
	if not _configured or _held or _pickup == null or not is_instance_valid(_pickup):
		return false
	if _root_controller.get("_active_target") != _pickup:
		return false
	var actor := _player
	if actor == null:
		return false
	_pickup.update_player_distance(actor.global_position)
	if not _pickup.can_interact(actor.global_position):
		return false
	if not _pickup.acquire():
		return false
	_held = true
	if _held_visual:
		_held_visual.visible = true
	_touch_ui.call("set_tool_action_available", true)
	return true

func handle_tool_action_pressed() -> bool:
	if not _configured or not _held or _touch_ui == null:
		return false
	if int(_touch_ui.get("current_mode")) != int(TouchControlsUI.UIMode.FOOT_TRAVERSAL):
		return false
	# Swing behavior begins in Task 3. This seam intentionally does not call Action.
	return false

func has_tool() -> bool:
	return _held

func get_pickup() -> ScrapperToolPickup:
	return _pickup

func reset_runtime() -> void:
	_held = false
	if _pickup != null and is_instance_valid(_pickup):
		_pickup.reset_pickup()
	if _held_visual != null and is_instance_valid(_held_visual):
		_held_visual.visible = false
	if _touch_ui != null and is_instance_valid(_touch_ui):
		_touch_ui.call("set_tool_action_available", false)
