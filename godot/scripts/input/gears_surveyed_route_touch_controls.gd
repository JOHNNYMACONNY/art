class_name GearsSurveyedRouteTouchControls
extends TouchControlsUI

signal map_action_pressed
signal ui_mode_changed(mode: int)

var _map_modal_active := false
var _map_action_available := true
var _action_disabled_before_map := false

func set_map_modal_active(active: bool) -> void:
	if active == _map_modal_active:
		return
	if active:
		_action_disabled_before_map = action_button != null and action_button.disabled
	_map_modal_active = active
	if action_button:
		action_button.disabled = true if active else _action_disabled_before_map
	_refresh_tool_action_button()

func is_map_modal_active() -> bool:
	return _map_modal_active

func set_map_action_available(available: bool) -> void:
	_map_action_available = available

func _map_action_can_emit() -> bool:
	return _map_action_available and current_mode == UIMode.FOOT_TRAVERSAL and not is_interaction_input_locked()

func trigger_map_action() -> void:
	if _map_action_can_emit():
		map_action_pressed.emit()

func _on_action_button_clicked() -> void:
	if _map_modal_active:
		return
	super._on_action_button_clicked()

func _tool_action_can_emit() -> bool:
	return not _map_modal_active and super._tool_action_can_emit()

func set_mode(mode: UIMode) -> void:
	super.set_mode(mode)
	ui_mode_changed.emit(int(mode))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_ev := event as InputEventKey
		if key_ev.pressed and not key_ev.echo and _is_key(key_ev, KEY_M):
			if _map_action_can_emit():
				map_action_pressed.emit()
				if get_viewport():
					get_viewport().set_input_as_handled()
			return
		if _map_modal_active and key_ev.pressed and (_is_key(key_ev, KEY_E) or _is_key(key_ev, KEY_F)):
			if get_viewport():
				get_viewport().set_input_as_handled()
			return
	super._input(event)
