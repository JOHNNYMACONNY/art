class_name TouchControlsUI
extends Control

# Echos in the Scrap - Dual-Thumb Touch Controls UI (V8 M02 Mobile Safe-Area & Touch Ergonomics)
# Features SafeAreaRoot Boundary, Coordinate-Safe DisplayServer Integration,
# Deterministic Simulator API, Floating Joystick Clamping, and Stale Touch Purging.

signal joystick_vector_updated(vec: Vector2)
signal action_button_pressed
signal peel_gesture_dragged(progress: float)
signal peel_gesture_released
signal tuner_dragged(accum_px: float)
signal tuner_interaction_released
signal core_tap_pressed
signal driving_steer_updated(steer: float)
signal driving_throttle_updated(throttle: float)
signal driving_handbrake_updated(active: bool)
signal dismount_pressed
signal radio_toggle_pressed
signal replay_pressed
signal retry_chase_pressed
signal safe_area_updated(resolved_canvas_rect: Rect2)

enum UIMode {
	FOOT_TRAVERSAL,
	VEHICLE_DRIVING
}

@export var max_joystick_radius: float = 80.0
@export var debug_hud_enabled: bool = false

var current_mode: UIMode = UIMode.FOOT_TRAVERSAL

# SafeAreaRoot hierarchy references (with automatic fallback to direct child if not nested)
@onready var safe_area_root: Control = _find_or_self("SafeAreaRoot")
@onready var left_touch_area: Control = _find_node_recursive("LeftTouchArea")
@onready var right_touch_area: Control = _find_node_recursive("RightTouchArea")
@onready var joystick_base: Control = _find_node_recursive("JoystickBase")
@onready var joystick_handle: Control = _find_node_recursive("JoystickKnob")
@onready var action_button: Button = _find_node_recursive("ActionButton")

@onready var driving_panel: Control = _find_node_recursive("DrivingOverlayPanel")
@onready var gas_button: Button = _find_node_recursive("ThrottleButton")
@onready var brake_button: Button = _find_node_recursive("BrakeButton")
@onready var handbrake_button: Button = _find_node_recursive("HandbrakeButton")
@onready var radio_button: Button = _find_node_recursive("RadioButton")
@onready var dismount_button: Button = _find_node_recursive("DismountButton")
@onready var route_switch_button: Button = _find_node_recursive("RouteSwitchButton")

@onready var gesture_panel: Control = _find_node_recursive("GestureOverlayPanel")
@onready var gesture_hint_label: Label = _find_node_recursive("GestureLabel")
@onready var core_tap_button: Button = _find_node_recursive("CorePullButton")

@onready var tension_panel: Control = _find_node_recursive("TensionHUDPanel")
@onready var alert_label: Label = _find_node_recursive("AlertLabel")
@onready var proximity_label: Label = _find_node_recursive("ProximityLabel")

@onready var replay_panel: Control = _find_node_recursive("ReplayOverlayPanel")
@onready var replay_button: Button = _find_node_recursive("ReplayButton")
@onready var retry_chase_button: Button = _find_node_recursive("RetryChaseButton")

var _joystick_active: bool = false
var _joystick_touch_index: int = -1
var _interaction_touch_index: int = -1
var _gas_touch_index: int = -1
var _brake_touch_index: int = -1
var _handbrake_touch_index: int = -1
var _joystick_center_pos: Vector2 = Vector2.ZERO
var _joystick_handle_rest_pos: Vector2 = Vector2.ZERO
var _current_joystick_vec: Vector2 = Vector2.ZERO
var _is_peeling: bool = false
var _is_tuning: bool = false
var _is_mouse_interacting: bool = false
var _current_gesture_type: String = ""
var _tuning_accum_px: float = 0.0
var _is_gas_pressed: bool = false
var _is_brake_pressed: bool = false
var _is_handbrake_pressed: bool = false

# Desktop keyboard state is kept separate from touch ownership, then composed into
# the same normalized vehicle intent signals used by mobile controls.
var _keyboard_forward_pressed: bool = false
var _keyboard_reverse_pressed: bool = false
var _keyboard_left_pressed: bool = false
var _keyboard_right_pressed: bool = false
var _keyboard_handbrake_pressed: bool = false

const MOUSE_POINTER_INDEX: int = -999

func is_pointer_index_claimed(index: int) -> bool:
	if index == -1 or index == MOUSE_POINTER_INDEX:
		return false
	return (
		(_joystick_active and _joystick_touch_index == index) or
		(_is_gas_pressed and _gas_touch_index == index) or
		(_is_brake_pressed and _brake_touch_index == index) or
		(_is_handbrake_pressed and _handbrake_touch_index == index) or
		((_is_peeling or _is_tuning) and _interaction_touch_index == index)
	)

# Safe-Area simulation override storage
var _simulated_safe_area: Rect2i = Rect2i()
var _simulated_screen_size: Vector2i = Vector2i()

func _find_or_self(node_name: String) -> Control:
	var n: Node = get_node_or_null(node_name)
	if n is Control:
		return n as Control
	return self

func _find_node_recursive(target_name: String) -> Control:
	return _search_node(self, target_name)

func _search_node(current: Node, target_name: String) -> Control:
	if current.name == target_name and current is Control:
		return current as Control
	for child in current.get_children():
		var found := _search_node(child, target_name)
		if found:
			return found
	return null

func _emit_net_throttle() -> void:
	var throttle := 0.0
	if current_mode == UIMode.VEHICLE_DRIVING and (_keyboard_forward_pressed or _keyboard_reverse_pressed):
		var forward_value := 1.0 if _keyboard_forward_pressed else 0.0
		var reverse_value := 1.0 if _keyboard_reverse_pressed else 0.0
		throttle = forward_value - reverse_value
	elif _is_brake_pressed:
		throttle = -1.0
	elif _is_gas_pressed:
		throttle = 1.0
	driving_throttle_updated.emit(throttle)

func _emit_net_steer() -> void:
	var steer := 0.0
	if current_mode == UIMode.VEHICLE_DRIVING and (_keyboard_left_pressed or _keyboard_right_pressed):
		var right_value := 1.0 if _keyboard_right_pressed else 0.0
		var left_value := 1.0 if _keyboard_left_pressed else 0.0
		steer = right_value - left_value
	elif current_mode == UIMode.VEHICLE_DRIVING and _joystick_active:
		steer = _current_joystick_vec.x
	driving_steer_updated.emit(steer)

func _emit_net_handbrake() -> void:
	driving_handbrake_updated.emit(_is_handbrake_pressed or _keyboard_handbrake_pressed)

func _reset_keyboard_driving_inputs() -> void:
	_keyboard_forward_pressed = false
	_keyboard_reverse_pressed = false
	_keyboard_left_pressed = false
	_keyboard_right_pressed = false
	_keyboard_handbrake_pressed = false

func _sync_keyboard_driving_inputs_from_input() -> void:
	_keyboard_forward_pressed = Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP)
	_keyboard_reverse_pressed = Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN)
	_keyboard_left_pressed = Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT)
	_keyboard_right_pressed = Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT)
	_keyboard_handbrake_pressed = Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE)

func reset_driving_inputs() -> void:
	_is_gas_pressed = false
	_gas_touch_index = -1
	_is_brake_pressed = false
	_brake_touch_index = -1
	_is_handbrake_pressed = false
	_handbrake_touch_index = -1
	_reset_keyboard_driving_inputs()
	_emit_net_throttle()
	_emit_net_steer()
	_emit_net_handbrake()

func reset_all_input_states() -> void:
	_stop_joystick()
	reset_driving_inputs()
	close_interaction_overlay()
	hide_replay_overlay()
	hide_tension_hud()

# ==============================================================================
# SAFE-AREA COMPUTATION & SIMULATOR API
# ==============================================================================

func set_simulated_safe_area(safe_rect: Rect2i, screen_size: Vector2i = Vector2i.ZERO) -> void:
	_simulated_safe_area = safe_rect
	_simulated_screen_size = screen_size
	_update_safe_area_layout()

func clear_simulated_safe_area() -> void:
	_simulated_safe_area = Rect2i()
	_simulated_screen_size = Vector2i()
	_update_safe_area_layout()

func get_resolved_safe_rect() -> Rect2:
	var vp_rect := get_viewport_rect()
	var safe_pixels: Rect2i
	var screen_sz: Vector2i

	if _simulated_safe_area.has_area():
		safe_pixels = _simulated_safe_area
		screen_sz = _simulated_screen_size if _simulated_screen_size != Vector2i.ZERO else DisplayServer.window_get_size()
		if screen_sz == Vector2i.ZERO:
			screen_sz = Vector2i(int(vp_rect.size.x), int(vp_rect.size.y))
	else:
		safe_pixels = DisplayServer.get_display_safe_area()
		screen_sz = DisplayServer.window_get_size()
		if screen_sz == Vector2i.ZERO:
			screen_sz = Vector2i(int(vp_rect.size.x), int(vp_rect.size.y))

	# If safe_pixels is empty/zero (desktop standard), return full viewport
	if safe_pixels.size.x <= 0 or safe_pixels.size.y <= 0:
		return vp_rect

	# In Godot with aspect="keep", calculate uniform scale and pillarbox/letterbox offsets
	var scale_x: float = float(screen_sz.x) / vp_rect.size.x
	var scale_y: float = float(screen_sz.y) / vp_rect.size.y
	var uniform_scale: float = minf(scale_x, scale_y)
	if uniform_scale <= 0.0001:
		uniform_scale = 1.0

	var rendered_w: float = vp_rect.size.x * uniform_scale
	var rendered_h: float = vp_rect.size.y * uniform_scale
	var offset_x: float = (float(screen_sz.x) - rendered_w) * 0.5
	var offset_y: float = (float(screen_sz.y) - rendered_h) * 0.5

	# Convert physical screen safe pixel boundaries to 960x540 canvas coordinates
	var canvas_x1: float = clampf((float(safe_pixels.position.x) - offset_x) / uniform_scale, 0.0, vp_rect.size.x)
	var canvas_y1: float = clampf((float(safe_pixels.position.y) - offset_y) / uniform_scale, 0.0, vp_rect.size.y)
	var canvas_x2: float = clampf((float(safe_pixels.position.x + safe_pixels.size.x) - offset_x) / uniform_scale, 0.0, vp_rect.size.x)
	var canvas_y2: float = clampf((float(safe_pixels.position.y + safe_pixels.size.y) - offset_y) / uniform_scale, 0.0, vp_rect.size.y)

	var canvas_w: float = maxf(0.0, canvas_x2 - canvas_x1)
	var canvas_h: float = maxf(0.0, canvas_y2 - canvas_y1)

	return Rect2(canvas_x1, canvas_y1, canvas_w, canvas_h)

func _update_safe_area_layout() -> void:
	# Crucial invariant: purge all active touches when layout changes to avoid sticky pointers
	reset_all_input_states()

	var safe_rect := get_resolved_safe_rect()
	var vp_rect := get_viewport_rect()

	if safe_area_root and safe_area_root != self:
		safe_area_root.anchor_left = 0.0
		safe_area_root.anchor_top = 0.0
		safe_area_root.anchor_right = 1.0
		safe_area_root.anchor_bottom = 1.0
		safe_area_root.offset_left = safe_rect.position.x
		safe_area_root.offset_top = safe_rect.position.y
		safe_area_root.offset_right = -(vp_rect.size.x - (safe_rect.position.x + safe_rect.size.x))
		safe_area_root.offset_bottom = -(vp_rect.size.y - (safe_rect.position.y + safe_rect.size.y))

	safe_area_updated.emit(safe_rect)

func _on_viewport_size_changed() -> void:
	_update_safe_area_layout()

func _on_action_button_clicked() -> void:
	action_button_pressed.emit()

func _on_dismount_button_clicked() -> void:
	dismount_pressed.emit()

func _on_radio_button_clicked() -> void:
	radio_toggle_pressed.emit()

func _on_route_switch_button_clicked() -> void:
	action_button_pressed.emit()

func trigger_route_switch() -> void:
	_on_route_switch_button_clicked()

func trigger_dismount() -> void:
	_on_dismount_button_clicked()

func trigger_radio_toggle() -> void:
	_on_radio_button_clicked()

func trigger_action() -> void:
	_on_action_button_clicked()

func update_radio_button_state(is_enabled: bool, _station_id: String = "radio.yardline") -> void:
	if radio_button:
		if is_enabled:
			radio_button.text = "[ 88.3 FM ]"
			radio_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			radio_button.text = "[ RADIO: OFF ]"
			radio_button.modulate = Color(1.0, 1.0, 1.0, 0.6)

# ==============================================================================
# LIFECYCLE & INITIALIZATION
# ==============================================================================

func _configure_pointer_routing() -> void:
	# Passive full-screen containers must bubble touch events to this root Control.
	# Interactive Button children keep their default STOP behavior.
	for passive_control in [safe_area_root, left_touch_area, right_touch_area, driving_panel, gesture_panel, tension_panel, replay_panel]:
		if passive_control:
			passive_control.mouse_filter = Control.MOUSE_FILTER_PASS

	# Joystick artwork appears directly under the active thumb; it must never
	# steal ScreenDrag/ScreenTouch events from the routing controls behind it.
	for decorative_control in [joystick_base, joystick_handle, gesture_hint_label, alert_label, proximity_label]:
		if decorative_control:
			decorative_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_configure_pointer_routing()
	if joystick_handle and joystick_base:
		_joystick_handle_rest_pos = (joystick_base.size - joystick_handle.size) * 0.5
		joystick_handle.position = _joystick_handle_rest_pos

	if OS.has_feature("debug_ui") or OS.get_cmdline_user_args().has("--debug-ui"):
		debug_hud_enabled = true
		
	if action_button:
		action_button.pressed.connect(_on_action_button_clicked)
	if dismount_button:
		dismount_button.pressed.connect(_on_dismount_button_clicked)
	if radio_button:
		radio_button.pressed.connect(_on_radio_button_clicked)
	if route_switch_button:
		route_switch_button.pressed.connect(_on_route_switch_button_clicked)
	if core_tap_button:
		core_tap_button.pressed.connect(func(): core_tap_pressed.emit())
	if replay_button:
		replay_button.pressed.connect(func(): replay_pressed.emit())
	if retry_chase_button:
		retry_chase_button.pressed.connect(func(): retry_chase_pressed.emit())
		
	_apply_golden_slice_design_tokens()
	set_mode(UIMode.FOOT_TRAVERSAL)
	close_interaction_overlay()
	hide_tension_hud()
	set_route_switch_button_visible(false)
	update_radio_button_state(true)

	# Continuous driving controls use ScreenTouch directly. Avoid Button mouse
	# signals here so a desktop click cannot masquerade as held gas/brake input.
	if gas_button:
		gas_button.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch:
				var st := ev as InputEventScreenTouch
				if st.pressed:
					if _gas_touch_index == -1 and not is_pointer_index_claimed(st.index):
						_gas_touch_index = st.index
						_is_gas_pressed = true
						_emit_net_throttle()
				elif not st.pressed and st.index == _gas_touch_index:
					_is_gas_pressed = false
					_gas_touch_index = -1
					_emit_net_throttle()
		)
	if brake_button:
		brake_button.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch:
				var st := ev as InputEventScreenTouch
				if st.pressed:
					if _brake_touch_index == -1 and not is_pointer_index_claimed(st.index):
						_brake_touch_index = st.index
						_is_brake_pressed = true
						_emit_net_throttle()
				elif not st.pressed and st.index == _brake_touch_index:
					_is_brake_pressed = false
					_brake_touch_index = -1
					_emit_net_throttle()
		)
	if handbrake_button:
		handbrake_button.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch:
				var st := ev as InputEventScreenTouch
				if st.pressed:
					if _handbrake_touch_index == -1 and not is_pointer_index_claimed(st.index):
						_handbrake_touch_index = st.index
						_is_handbrake_pressed = true
						_emit_net_handbrake()
				elif not st.pressed and st.index == _handbrake_touch_index:
					_is_handbrake_pressed = false
					_handbrake_touch_index = -1
					_emit_net_handbrake()
		)

	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_update_safe_area_layout()

func _apply_golden_slice_design_tokens() -> void:
	if alert_label:
		alert_label.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25, 1.0))
	if proximity_label:
		proximity_label.visible = debug_hud_enabled
	if action_button:
		action_button.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0, 1.0))
	if route_switch_button:
		route_switch_button.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0, 1.0))
	if handbrake_button:
		handbrake_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))

func set_mode(mode: UIMode) -> void:
	current_mode = mode
	reset_driving_inputs()
	if mode == UIMode.FOOT_TRAVERSAL:
		if action_button: action_button.visible = true
		if driving_panel: driving_panel.visible = false
	elif mode == UIMode.VEHICLE_DRIVING:
		if action_button: action_button.visible = false
		if driving_panel: driving_panel.visible = true
		close_interaction_overlay()
		_sync_keyboard_driving_inputs_from_input()
		_emit_net_throttle()
		_emit_net_steer()
		_emit_net_handbrake()

var _is_rejection_flashing: bool = false
var _toast_timer_count: int = 0

func set_dismount_button_enabled(available: bool) -> void:
	if dismount_button:
		dismount_button.disabled = false # Keep button clickable so rejection events reach controller!
		if not _is_rejection_flashing:
			dismount_button.modulate = Color(1.0, 1.0, 1.0, 1.0) if available else Color(1.0, 1.0, 1.0, 0.6)

func show_dismount_rejection_warning(toast_text: String) -> void:
	_toast_timer_count += 1
	var current_timer_id := _toast_timer_count
	if dismount_button:
		_is_rejection_flashing = true
		dismount_button.modulate = Color(1.5, 0.3, 0.3, 1.0)
		get_tree().create_timer(0.2).timeout.connect(func():
			_is_rejection_flashing = false
			if dismount_button:
				dismount_button.modulate = Color(1.0, 1.0, 1.0, 0.6)
		)
	if alert_label:
		show_tension_hud(toast_text)
		get_tree().create_timer(1.2).timeout.connect(func():
			if _toast_timer_count == current_timer_id and current_mode == UIMode.VEHICLE_DRIVING and alert_label:
				hide_tension_hud()
		)

func set_route_switch_button_visible(visible_flag: bool) -> void:
	if route_switch_button:
		route_switch_button.visible = visible_flag

func show_tension_hud(alert_text: String) -> void:
	if tension_panel:
		tension_panel.visible = true
	if alert_label:
		alert_label.text = alert_text

func update_pursuer_proximity(distance: float) -> void:
	if proximity_label:
		proximity_label.visible = debug_hud_enabled
		proximity_label.text = "PURSUER: %.1fm" % distance

func update_tension_proximity(distance: float, in_danger: bool = false) -> void:
	if proximity_label:
		proximity_label.visible = true
		if in_danger:
			proximity_label.text = "PROXIMITY: CRITICAL (%.1fm)" % distance
		else:
			proximity_label.text = "PROXIMITY: %.1fm" % distance

func hide_tension_hud() -> void:
	if tension_panel:
		tension_panel.visible = false

func set_action_button_highlight(highlighted: bool) -> void:
	if action_button:
		action_button.modulate = Color(1.2, 1.2, 0.4, 1.0) if highlighted else Color(1.0, 1.0, 1.0, 0.7)

var _peel_accumulated_y: float = 0.0
var tuner_readout_label: Label = null

func _ensure_tuner_readout() -> void:
	if tuner_readout_label == null and gesture_panel:
		tuner_readout_label = Label.new()
		tuner_readout_label.name = "TunerReadoutLabel"
		tuner_readout_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tuner_readout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tuner_readout_label.position = Vector2(0, 36)
		tuner_readout_label.size = Vector2(480, 64)
		gesture_panel.add_child(tuner_readout_label)

func update_tuner_feedback(freq: float, accuracy: float, is_locked: bool = false) -> void:
	_ensure_tuner_readout()
	if tuner_readout_label == null:
		return
	tuner_readout_label.visible = gesture_panel != null and gesture_panel.visible and _current_gesture_type == "TUNE_SIGNAL"
	if not tuner_readout_label.visible:
		return
	var clamped_accuracy := clampf(accuracy, 0.0, 1.0)
	var filled := int(round(clamped_accuracy * 10.0))
	var bar := "█".repeat(filled) + "░".repeat(10 - filled)
	if is_locked:
		tuner_readout_label.text = "SIGNAL LOCKED · TUNE %.3f · [%s]" % [freq, bar]
	elif clamped_accuracy >= 0.90:
		tuner_readout_label.text = "TUNE %.3f · SIGNAL [%s] %.0f%% · LOCK ZONE — HOLD" % [freq, bar, clamped_accuracy * 100.0]
	else:
		tuner_readout_label.text = "TUNE %.3f · SIGNAL [%s] %.0f%%" % [freq, bar, clamped_accuracy * 100.0]

func show_gesture_overlay(gesture_type: String) -> void:
	_current_gesture_type = gesture_type
	_peel_accumulated_y = 0.0
	_tuning_accum_px = 0.0
	if gesture_panel:
		gesture_panel.visible = true
	if core_tap_button: core_tap_button.visible = (gesture_type == "EXPOSE_CORE")
	if gesture_hint_label:
		match gesture_type:
			"TUNE_SIGNAL": gesture_hint_label.text = "[ HOLD LEFT MOUSE · DRAG ← / → TO TUNE ]"
			"PEEL_PANEL": gesture_hint_label.text = "[ SWIPE DOWN TO PEEL PANEL ]"
			"EXPOSE_CORE": gesture_hint_label.text = "[ TAP CORE TO EXTRACT ]"
	if gesture_type == "TUNE_SIGNAL":
		_ensure_tuner_readout()
		update_tuner_feedback(0.15, 0.0)
	elif tuner_readout_label:
		tuner_readout_label.visible = false

func close_interaction_overlay() -> void:
	if gesture_panel:
		gesture_panel.visible = false
	if tuner_readout_label:
		tuner_readout_label.visible = false
	_is_peeling = false
	_is_tuning = false
	_is_mouse_interacting = false
	_interaction_touch_index = -1
	_current_gesture_type = ""
	_peel_accumulated_y = 0.0

func _is_key(event: InputEventKey, first: Key, second: Key = KEY_NONE) -> bool:
	return (
		event.keycode == first or event.physical_keycode == first or
		(second != KEY_NONE and (event.keycode == second or event.physical_keycode == second))
	)

func _update_keyboard_vehicle_state(event: InputEventKey) -> bool:
	if current_mode != UIMode.VEHICLE_DRIVING or event.echo:
		return false
	if _is_key(event, KEY_W, KEY_UP):
		_keyboard_forward_pressed = event.pressed
		_emit_net_throttle()
		return true
	if _is_key(event, KEY_S, KEY_DOWN):
		_keyboard_reverse_pressed = event.pressed
		_emit_net_throttle()
		return true
	if _is_key(event, KEY_A, KEY_LEFT):
		_keyboard_left_pressed = event.pressed
		_emit_net_steer()
		return true
	if _is_key(event, KEY_D, KEY_RIGHT):
		_keyboard_right_pressed = event.pressed
		_emit_net_steer()
		return true
	if _is_key(event, KEY_SPACE):
		_keyboard_handbrake_pressed = event.pressed
		_emit_net_handbrake()
		return true
	return false

func _input(event: InputEvent) -> void:
	# Global safety net: finger release anywhere on screen releases any owned pointer.
	if event is InputEventScreenTouch:
		var touch_ev := event as InputEventScreenTouch
		if not touch_ev.pressed:
			_handle_touch_up_anywhere(touch_ev.index)
	elif event is InputEventMouseButton:
		var mouse_ev := event as InputEventMouseButton
		# Browsers may synthesize a mouse companion for a real touch. It must never
		# clear touch ownership or progress the same interaction twice.
		if mouse_ev.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if not mouse_ev.pressed and _is_mouse_interacting:
			_is_mouse_interacting = false
			if _is_peeling:
				peel_gesture_released.emit()
				_is_peeling = false
			elif _is_tuning:
				tuner_interaction_released.emit()
				_is_tuning = false
	elif event is InputEventKey:
		var key_ev := event as InputEventKey
		_update_keyboard_vehicle_state(key_ev)
		if key_ev.pressed and not key_ev.echo:
			if _is_key(key_ev, KEY_ESCAPE) and gesture_panel and gesture_panel.visible:
				if _current_gesture_type == "TUNE_SIGNAL":
					tuner_interaction_released.emit()
				elif _current_gesture_type == "PEEL_PANEL":
					peel_gesture_released.emit()
				get_viewport().set_input_as_handled()
				return
			if _is_key(key_ev, KEY_E):
				if gesture_panel and gesture_panel.visible and _current_gesture_type == "EXPOSE_CORE":
					core_tap_pressed.emit()
				elif current_mode == UIMode.FOOT_TRAVERSAL:
					action_button_pressed.emit()
				elif current_mode == UIMode.VEHICLE_DRIVING:
					dismount_pressed.emit()
			elif _is_key(key_ev, KEY_SPACE) and current_mode == UIMode.FOOT_TRAVERSAL:
				if gesture_panel and gesture_panel.visible and _current_gesture_type == "EXPOSE_CORE":
					core_tap_pressed.emit()
			elif _is_key(key_ev, KEY_R) and current_mode == UIMode.VEHICLE_DRIVING:
				radio_toggle_pressed.emit()

func _handle_touch_up_anywhere(index: int) -> void:
	if index == _joystick_touch_index and _joystick_active:
		_stop_joystick()
	if index == _interaction_touch_index:
		if _is_peeling:
			peel_gesture_released.emit()
		elif _is_tuning:
			tuner_interaction_released.emit()
		_is_peeling = false
		_is_tuning = false
		_interaction_touch_index = -1
		_tuning_accum_px = 0.0
	if index == _gas_touch_index:
		_is_gas_pressed = false
		_gas_touch_index = -1
		_emit_net_throttle()
	if index == _brake_touch_index:
		_is_brake_pressed = false
		_brake_touch_index = -1
		_emit_net_throttle()
	if index == _handbrake_touch_index:
		_is_handbrake_pressed = false
		_handbrake_touch_index = -1
		_emit_net_handbrake()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_ev := event as InputEventScreenTouch
		if gesture_panel and gesture_panel.visible:
			if touch_ev.pressed:
				if _interaction_touch_index == -1 and not is_pointer_index_claimed(touch_ev.index):
					_interaction_touch_index = touch_ev.index
					if _current_gesture_type == "PEEL_PANEL":
						_is_peeling = true
						_peel_accumulated_y = 0.0
					elif _current_gesture_type == "TUNE_SIGNAL":
						_is_tuning = true
						_tuning_accum_px = 0.0
			elif not touch_ev.pressed and touch_ev.index == _interaction_touch_index:
				_handle_touch_up_anywhere(touch_ev.index)
		else:
			var safe_rect := get_resolved_safe_rect()
			var left_safe_bounds := Rect2(safe_rect.position.x, safe_rect.position.y, safe_rect.size.x * 0.5, safe_rect.size.y)
			if touch_ev.pressed:
				if not _joystick_active and not is_pointer_index_claimed(touch_ev.index) and left_safe_bounds.has_point(touch_ev.position):
					_start_joystick(touch_ev.index, touch_ev.position)
			elif not touch_ev.pressed and touch_ev.index == _joystick_touch_index:
				_stop_joystick()
				
	elif event is InputEventScreenDrag:
		var drag_ev := event as InputEventScreenDrag
		if drag_ev.index == _joystick_touch_index and _joystick_active:
			_update_joystick(drag_ev.position)
		elif drag_ev.index == _interaction_touch_index:
			if _is_peeling:
				_peel_accumulated_y = clampf(_peel_accumulated_y + drag_ev.relative.y, 0.0, 150.0)
				var progress: float = clampf(_peel_accumulated_y / 150.0, 0.0, 1.0)
				peel_gesture_dragged.emit(progress)
			elif _is_tuning and abs(drag_ev.relative.x) > 0:
				_tuning_accum_px += drag_ev.relative.x
				tuner_dragged.emit(_tuning_accum_px)

	elif event is InputEventMouseButton:
		var mouse_ev := event as InputEventMouseButton
		if mouse_ev.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if gesture_panel and gesture_panel.visible and mouse_ev.button_index == MOUSE_BUTTON_LEFT:
			if mouse_ev.pressed:
				_is_mouse_interacting = true
				if _current_gesture_type == "PEEL_PANEL":
					_is_peeling = true
					_peel_accumulated_y = 0.0
				elif _current_gesture_type == "TUNE_SIGNAL":
					_is_tuning = true
					_tuning_accum_px = 0.0
			else:
				if _is_mouse_interacting:
					_is_mouse_interacting = false
					if _is_peeling:
						peel_gesture_released.emit()
						_is_peeling = false
					elif _is_tuning:
						tuner_interaction_released.emit()
						_is_tuning = false

	elif event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if gesture_panel and gesture_panel.visible and _is_mouse_interacting:
			if _is_peeling:
				_peel_accumulated_y = clampf(_peel_accumulated_y + mouse_motion.relative.y, 0.0, 150.0)
				var progress: float = clampf(_peel_accumulated_y / 150.0, 0.0, 1.0)
				peel_gesture_dragged.emit(progress)
			elif _is_tuning and abs(mouse_motion.relative.x) > 0:
				_tuning_accum_px += mouse_motion.relative.x
				tuner_dragged.emit(_tuning_accum_px)

func _start_joystick(touch_idx: int, pos: Vector2) -> void:
	if is_pointer_index_claimed(touch_idx):
		return
	_joystick_active = true
	_joystick_touch_index = touch_idx
	
	var safe_rect := get_resolved_safe_rect()
	var base_half: Vector2 = (joystick_base.size * 0.5) if joystick_base else Vector2(60, 60)
	
	# Clamp initial spawn center so the entire 120x120 base is enclosed in safe-area
	var min_x := safe_rect.position.x + base_half.x
	var max_x := safe_rect.position.x + (safe_rect.size.x * 0.5) - base_half.x
	var min_y := safe_rect.position.y + base_half.y
	var max_y := safe_rect.position.y + safe_rect.size.y - base_half.y
	
	_joystick_center_pos = Vector2(
		clampf(pos.x, min_x, maxf(min_x, max_x)),
		clampf(pos.y, min_y, maxf(min_y, max_y))
	)
	
	if joystick_handle:
		joystick_handle.position = _joystick_handle_rest_pos
	if joystick_base:
		joystick_base.visible = true
		joystick_base.global_position = _joystick_center_pos - base_half

func _update_joystick(pos: Vector2) -> void:
	var delta_pos := pos - _joystick_center_pos
	var dist := delta_pos.length()
	if dist > max_joystick_radius:
		# Anchor-follow: slide center towards current touch position to remove reversal deadband!
		var excess := dist - max_joystick_radius
		_joystick_center_pos += delta_pos.normalized() * excess
		
		# Clamp dynamic anchor within safe bounds
		var safe_rect := get_resolved_safe_rect()
		var base_half: Vector2 = (joystick_base.size * 0.5) if joystick_base else Vector2(60, 60)
		var min_x := safe_rect.position.x + base_half.x
		var max_x := safe_rect.position.x + (safe_rect.size.x * 0.5) - base_half.x
		var min_y := safe_rect.position.y + base_half.y
		var max_y := safe_rect.position.y + safe_rect.size.y - base_half.y
		_joystick_center_pos = Vector2(
			clampf(_joystick_center_pos.x, min_x, maxf(min_x, max_x)),
			clampf(_joystick_center_pos.y, min_y, maxf(min_y, max_y))
		)
		
		if joystick_base:
			joystick_base.global_position = _joystick_center_pos - base_half
		delta_pos = delta_pos.normalized() * max_joystick_radius
	if joystick_handle:
		joystick_handle.position = _joystick_handle_rest_pos + delta_pos
	_current_joystick_vec = delta_pos / max_joystick_radius
	
	if current_mode == UIMode.FOOT_TRAVERSAL:
		joystick_vector_updated.emit(_current_joystick_vec)
	elif current_mode == UIMode.VEHICLE_DRIVING:
		_emit_net_steer()

func _stop_joystick() -> void:
	_joystick_active = false
	_joystick_touch_index = -1
	_current_joystick_vec = Vector2.ZERO
	if joystick_handle:
		joystick_handle.position = _joystick_handle_rest_pos
	if joystick_base:
		joystick_base.visible = false
		
	if current_mode == UIMode.FOOT_TRAVERSAL:
		joystick_vector_updated.emit(Vector2.ZERO)
	elif current_mode == UIMode.VEHICLE_DRIVING:
		_emit_net_steer()

func show_replay_overlay(can_retry_chase: bool = true) -> void:
	if replay_panel:
		replay_panel.visible = true
	if retry_chase_button:
		retry_chase_button.visible = can_retry_chase

func hide_replay_overlay() -> void:
	if replay_panel:
		replay_panel.visible = false