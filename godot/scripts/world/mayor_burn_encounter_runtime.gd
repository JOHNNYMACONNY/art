class_name MayorBurnEncounterRuntime
extends Node3D

## Burnside Production 18 / #182
## Bounded physical Mayor Burn presence + one local authored Contact moment.
## Relationship persistence remains owned by MayorBurnContactProgressStore.
## Wanted remains authoritative. Existing Garage services remain separate.

const InteractableBaseScript = preload("res://scripts/interactions/interactable_base.gd")
const MayorBurnScene = preload("res://scenes/entities/mayor_burn.tscn")

const SERVICE_SOCKET_PATH := "MissionDestinationSocket"
const ACTOR_OFFSET := Vector3(-1.75, -0.18, 2.05)
const INTERACTION_RADIUS_M := 2.35
const AFFORDANCE_RADIUS_M := 6.5
const INTERACTION_PRIORITY := 4.2
const LINE_HOLD_MSEC := 1750
const FINAL_HOLD_MSEC := 2250

const CLEAR_EXCHANGE := [
	{"speaker": "BURN", "line": "You brought me a city truck with the seal still warm."},
	{"speaker": "RUNNER", "line": "You wanted the truck."},
	{"speaker": "BURN", "line": "I wanted to see if you came back. Armor’s in the bay. Keep the city outside."},
]
const WANTED_REFUSAL := [
	{"speaker": "BURN", "line": "Not with half the city looking over your shoulder. Lose them."},
]

var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _contact_runtime: Node = null
var _contact_store = null
var _player: PlayerRunner = null
var _service_socket: Marker3D = null
var _touch_ui: Node = null

var _actor: Node3D = null
var _contact_interactable: InteractableBase = null
var _affordance_label: Label3D = null
var _affordance_text := ""

var _moment_panel: PanelContainer = null
var _speaker_label: Label = null
var _line_label: Label = null

var _bound := false
var _presentation_mode := ""
var _dialogue_index := -1
var _dialogue_sequence: Array = []
var _line_deadline_msec := 0
var _encounter_start_count := 0
var _idle_phase := 0.0
var _action_button_was_visible := true

func configure(root_controller: Node, district: Node3D, wanted_runtime: Node, contact_runtime: Node) -> bool:
	if root_controller == null or district == null or wanted_runtime == null or contact_runtime == null:
		return false
	if not root_controller.has_method("_get_active_vehicle"):
		return false
	if not wanted_runtime.has_method("get_heat_level") or not wanted_runtime.has_method("get_wanted_state_name"):
		return false
	if not contact_runtime.has_method("get_progress_store"):
		return false

	var player := root_controller.get_node_or_null("Runner") as PlayerRunner
	var socket := district.get_node_or_null(SERVICE_SOCKET_PATH) as Marker3D
	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var safe_root := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot") as Control
	var interactables = root_controller.get("_interactables")
	if player == null or socket == null or touch_ui == null or safe_root == null or not (interactables is Array):
		return false

	_root_controller = root_controller
	_district = district
	_wanted_runtime = wanted_runtime
	_contact_runtime = contact_runtime
	_contact_store = contact_runtime.call("get_progress_store")
	_player = player
	_service_socket = socket
	_touch_ui = touch_ui
	if _contact_store == null or not _contact_store.has_method("is_known"):
		return false

	_actor = MayorBurnScene.instantiate() as Node3D
	if _actor == null:
		return false
	_actor.name = "MayorBurn"
	add_child(_actor)
	_actor.global_position = _service_socket.global_position + ACTOR_OFFSET
	_actor.rotation.y = -PI * 0.5

	_contact_interactable = InteractableBaseScript.new() as InteractableBase
	if _contact_interactable == null:
		return false
	_contact_interactable.name = "MayorBurnEncounterInteractable"
	_contact_interactable.interaction_radius = INTERACTION_RADIUS_M
	_contact_interactable.sensory_radius = AFFORDANCE_RADIUS_M
	_contact_interactable.interaction_priority = INTERACTION_PRIORITY
	_contact_interactable.is_powered = false
	add_child(_contact_interactable)
	_contact_interactable.global_position = _actor.global_position
	if not interactables.has(_contact_interactable):
		interactables.append(_contact_interactable)

	_affordance_label = Label3D.new()
	_affordance_label.name = "MayorBurnEncounterAffordance"
	_affordance_label.font_size = 6
	_affordance_label.outline_size = 2
	_affordance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_affordance_label.no_depth_test = true
	_affordance_label.fixed_size = true
	_affordance_label.modulate = Color(1.0, 0.72, 0.24, 0.98)
	_affordance_label.outline_modulate = Color(0.04, 0.045, 0.055, 0.98)
	_affordance_label.visible = false
	add_child(_affordance_label)
	_affordance_label.global_position = _actor.global_position + Vector3(0.0, 2.35, 0.0)

	_create_moment_ui(safe_root)

	var action_callable := Callable(self, "handle_action_pressed")
	if not _touch_ui.action_button_pressed.is_connected(action_callable):
		_touch_ui.action_button_pressed.connect(action_callable)
	var replay_callable := Callable(self, "reset_encounter_presentation")
	if _touch_ui.has_signal("replay_pressed") and not _touch_ui.replay_pressed.is_connected(replay_callable):
		_touch_ui.replay_pressed.connect(replay_callable)

	_bound = true
	set_process(true)
	process_encounter_state()
	return true

func _exit_tree() -> void:
	if _root_controller != null and _contact_interactable != null:
		var interactables = _root_controller.get("_interactables")
		if interactables is Array:
			interactables.erase(_contact_interactable)
	if _touch_ui != null:
		var action_callable := Callable(self, "handle_action_pressed")
		if _touch_ui.action_button_pressed.is_connected(action_callable):
			_touch_ui.action_button_pressed.disconnect(action_callable)
		var replay_callable := Callable(self, "reset_encounter_presentation")
		if _touch_ui.has_signal("replay_pressed") and _touch_ui.replay_pressed.is_connected(replay_callable):
			_touch_ui.replay_pressed.disconnect(replay_callable)

func _create_moment_ui(safe_root: Control) -> void:
	_moment_panel = PanelContainer.new()
	_moment_panel.name = "MayorBurnCharacterMoment"
	_moment_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_panel.z_index = 41
	_moment_panel.anchor_left = 0.08
	_moment_panel.anchor_top = 0.0
	_moment_panel.anchor_right = 0.92
	_moment_panel.anchor_bottom = 0.0
	_moment_panel.offset_top = 72.0
	_moment_panel.offset_bottom = 182.0
	_moment_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.028, 0.035, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.78, 0.42, 0.09, 0.76)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	_moment_panel.add_theme_stylebox_override("panel", style)
	safe_root.add_child(_moment_panel)

	var stack := VBoxContainer.new()
	stack.name = "MomentStack"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 4)
	_moment_panel.add_child(stack)

	_speaker_label = Label.new()
	_speaker_label.name = "Speaker"
	_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.24, 1.0))
	stack.add_child(_speaker_label)

	_line_label = Label.new()
	_line_label.name = "Line"
	_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.add_theme_font_size_override("font_size", 16)
	_line_label.add_theme_constant_override("outline_size", 4)
	_line_label.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.03, 0.96))
	_line_label.custom_minimum_size = Vector2(0.0, 54.0)
	stack.add_child(_line_label)

func _process(delta: float) -> void:
	if not _bound or _player == null or _actor == null or _contact_interactable == null:
		return

	_animate_actor(delta)

	var distance := _player.global_position.distance_to(_actor.global_position)
	var known := _is_known()
	var valid_on_foot := not _player.is_mounted and not _player.is_input_locked and _get_active_vehicle() == null and _player.current_health > 0.0

	if is_presentation_visible():
		if not known or not valid_on_foot or distance > INTERACTION_RADIUS_M:
			reset_encounter_presentation()
		elif _presentation_mode == "CLEAR" and not _wanted_is_clear():
			reset_encounter_presentation()
		elif _presentation_mode == "WANTED" and _wanted_is_clear():
			reset_encounter_presentation()
		elif _line_deadline_msec > 0 and Time.get_ticks_msec() >= _line_deadline_msec:
			_advance_dialogue()
		if is_presentation_visible():
			_contact_interactable.is_powered = true
			_contact_interactable.update_player_distance(_player.global_position)
			_set_affordance("", false)
			return

	if not known or not valid_on_foot or distance > AFFORDANCE_RADIUS_M:
		_contact_interactable.is_powered = false
		_set_affordance("", false)
		return

	_contact_interactable.is_powered = true
	_contact_interactable.update_player_distance(_player.global_position)
	if distance <= INTERACTION_RADIUS_M:
		_set_affordance("BURN // ACTION", true)
	else:
		_set_affordance("MAYOR BURN", true)

func process_encounter_state() -> void:
	_process(0.0)

func handle_action_pressed() -> bool:
	if not _bound or _root_controller == null or _contact_interactable == null:
		return false
	if _root_controller.get("_active_target") != _contact_interactable:
		return false
	return attempt_contact_encounter(_player)

func attempt_contact_encounter(candidate: Node) -> bool:
	if candidate == null or candidate != _player or is_presentation_visible():
		return false
	if not _is_known():
		return false
	if _player.is_mounted or _player.is_input_locked or _get_active_vehicle() != null or _player.current_health <= 0.0:
		return false
	if _player.global_position.distance_to(_actor.global_position) > INTERACTION_RADIUS_M:
		return false

	_encounter_start_count += 1
	_contact_interactable.is_powered = false
	_set_affordance("", false)
	if _wanted_is_clear():
		_begin_sequence("CLEAR", CLEAR_EXCHANGE)
	else:
		_begin_sequence("WANTED", WANTED_REFUSAL)
	return true

func _begin_sequence(mode: String, sequence: Array) -> void:
	_presentation_mode = mode
	_dialogue_sequence = sequence.duplicate(true)
	_dialogue_index = 0
	_show_current_line()
	_set_actor_engaged(true)
	_set_action_ui_suppressed(true)

func _show_current_line() -> void:
	if _dialogue_index < 0 or _dialogue_index >= _dialogue_sequence.size():
		reset_encounter_presentation()
		return
	var entry: Dictionary = _dialogue_sequence[_dialogue_index]
	if _speaker_label != null:
		_speaker_label.text = String(entry.get("speaker", ""))
	if _line_label != null:
		_line_label.text = String(entry.get("line", ""))
	if _moment_panel != null:
		_moment_panel.visible = true
	var hold := FINAL_HOLD_MSEC if _dialogue_index == _dialogue_sequence.size() - 1 else LINE_HOLD_MSEC
	_line_deadline_msec = Time.get_ticks_msec() + hold

func _advance_dialogue() -> void:
	if not is_presentation_visible():
		return
	if _dialogue_index + 1 >= _dialogue_sequence.size():
		reset_encounter_presentation()
		return
	_dialogue_index += 1
	_show_current_line()

func advance_dialogue_for_test() -> void:
	_advance_dialogue()

func reset_encounter_presentation() -> void:
	_presentation_mode = ""
	_dialogue_sequence.clear()
	_dialogue_index = -1
	_line_deadline_msec = 0
	if _moment_panel != null:
		_moment_panel.visible = false
	if _speaker_label != null:
		_speaker_label.text = ""
	if _line_label != null:
		_line_label.text = ""
	_set_actor_engaged(false)
	_set_action_ui_suppressed(false)

func _set_action_ui_suppressed(suppressed: bool) -> void:
	if _touch_ui == null:
		return
	var action_button := _touch_ui.get("action_button") as Button
	if action_button == null:
		return
	if suppressed:
		_action_button_was_visible = action_button.visible
		action_button.visible = false
		return
	var mode_value := int(_touch_ui.get("current_mode"))
	action_button.visible = _action_button_was_visible and mode_value == 0

func _animate_actor(delta: float) -> void:
	_idle_phase += delta
	var body := _actor.get_node_or_null("BodyRoot") as Node3D
	if body != null:
		body.position.y = sin(_idle_phase * 1.35) * 0.012
	var head := _actor.get_node_or_null("BodyRoot/Head") as Node3D
	if head != null and not is_presentation_visible():
		head.rotation.z = sin(_idle_phase * 0.55) * 0.025

func _set_actor_engaged(engaged: bool) -> void:
	if _actor == null:
		return
	var head := _actor.get_node_or_null("BodyRoot/Head") as Node3D
	var right_arm := _actor.get_node_or_null("BodyRoot/RightArm") as Node3D
	if head != null:
		head.rotation.z = -0.08 if engaged else 0.0
	if right_arm != null:
		right_arm.rotation.z = 0.28 if engaged else 0.12

func _is_known() -> bool:
	return _contact_store != null and bool(_contact_store.call("is_known"))

func _wanted_is_clear() -> bool:
	return _wanted_runtime != null and int(_wanted_runtime.call("get_heat_level")) == 0 and String(_wanted_runtime.call("get_wanted_state_name")) == "CLEAR"

func _get_active_vehicle() -> Node:
	if _root_controller == null or not _root_controller.has_method("_get_active_vehicle"):
		return null
	var value = _root_controller.call("_get_active_vehicle")
	return value if value is Node else null

func _set_affordance(text: String, visible_value: bool) -> void:
	_affordance_text = text
	if _affordance_label != null:
		_affordance_label.text = text
		_affordance_label.visible = visible_value

func get_actor() -> Node3D:
	return _actor

func get_contact_interactable() -> InteractableBase:
	return _contact_interactable

func get_affordance_text() -> String:
	return _affordance_text

func get_dialogue_speaker() -> String:
	return _speaker_label.text if _speaker_label != null and _moment_panel != null and _moment_panel.visible else ""

func get_dialogue_line() -> String:
	return _line_label.text if _line_label != null and _moment_panel != null and _moment_panel.visible else ""

func is_presentation_visible() -> bool:
	return _moment_panel != null and _moment_panel.visible

func get_encounter_start_count() -> int:
	return _encounter_start_count
