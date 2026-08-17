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
signal replay_pressed
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
var _current_gesture_type: String = ""
var _tuning_accum_px: float = 0.0
var _is_gas_pressed: bool = false
var _is_brake_pressed: bool = false
var _is_handbrake_pressed: bool = false

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
	if _is_brake_pressed:
		throttle = -1.0
	elif _is_gas_pressed:
		throttle = 1.0
	driving_throttle_updated.emit(throttle)

func reset_driving_inputs() -> void:
	_is_gas_pressed = false
	_gas_touch_index = -1
	_is_brake_pressed = false
	_brake_touch_index = -1
	_is_handbrake_pressed = false
	_handbrake_touch_index = -1
	_emit_net_throttle()
	driving_handbrake_updated.emit(false)

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

func _on_route_switch_button_clicked() -> void:
	action_button_pressed.emit()

func trigger_route_switch() -> void:
	_on_route_switch_button_clicked()

func trigger_dismount() -> void:
	_on_dismount_button_clicked()

func trigger_action() -> void:
	_on_action_button_clicked()

# ==============================================================================
# LIFECYCLE & INITIALIZATION
# ==============================================================================

func _ready() -> void:
	if joystick_handle and joystick_base:
		_joystick_handle_rest_pos = (joystick_base.size - joystick_handle.size) * 0.5
		joystick_handle.position = _joystick_handle_rest_pos

	if OS.has_feature("debug_ui") or OS.get_cmdline_user_args().has("--debug-ui"):
		debug_hud_enabled = true
		
	if action_button:
		action_button.pressed.connect(_on_action_button_clicked)
	if dismount_button:
		dismount_button.pressed.connect(_on_dismount_button_clicked)
	if route_switch_button:
		route_switch_button.pressed.connect(_on_route_switch_button_clicked)
	if core_tap_button:
		core_tap_button.pressed.connect(func(): core_tap_pressed.emit())
	if replay_button:
		replay_button.pressed.connect(func(): replay_pressed.emit())
		
	_apply_golden_slice_design_tokens()
	set_mode(UIMode.FOOT_TRAVERSAL)
	close_interaction_overlay()
	hide_tension_hud()
	set_route_switch_button_visible(false)

	# Continuous driving controls use single, deterministic pointer ownership
	if gas_button:
		gas_button.button_down.connect(func():
			if _gas_touch_index == -1:
				_gas_touch_index = 0
				_is_gas_pressed = true
				_emit_net_throttle()
		)
		gas_button.button_up.connect(func():
			if _gas_touch_index == 0:
				_is_gas_pressed = false
				_gas_touch_index = -1
				_emit_net_throttle()
		)
		gas_button.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch:
				var st := ev as InputEventScreenTouch
				if st.pressed and _gas_touch_index == -1:
					_gas_touch_index = st.index
					_is_gas_pressed = true
					_emit_net_throttle()
				elif not st.pressed and st.index == _gas_touch_index:
					_is_gas_pressed = false
					_gas_touch_index = -1
					_emit_net_throttle()
		)
	if brake_button:
		brake_button.button_down.connect(func():
			if _brake_touch_index == -1:
				_brake_touch_index = 0
				_is_brake_pressed = true
				_emit_net_throttle()
		)
		brake_button.button_up.connect(func():
			if _brake_touch_index == 0:
				_is_brake_pressed = false
				_brake_touch_index = -1
				_emit_net_throttle()
		)
		brake_button.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch:
				var st := ev as InputEventScreenTouch
				if st.pressed and _brake_touch_index == -1:
					_brake_touch_index = st.index
					_is_brake_pressed = true
					_emit_net_throttle()
				elif not st.pressed and st.index == _brake_touch_index:
					_is_brake_pressed = false
					_brake_touch_index = -1
					_emit_net_throttle()
		)
	if handbrake_button:
		handbrake_button.button_down.connect(func():
			if _handbrake_touch_index == -1:
				_handbrake_touch_index = 0
				_is_handbrake_pressed = true
				driving_handbrake_updated.emit(true)
		)
		handbrake_button.button_up.connect(func():
			if _handbrake_touch_index == 0:
				_is_handbrake_pressed = false
				_handbrake_touch_index = -1
				driving_handbrake_updated.emit(false)
		)
		handbrake_button.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventScreenTouch:
				var st := ev as InputEventScreenTouch
				if st.pressed and _handbrake_touch_index == -1:
					_handbrake_touch_index = st.index
					_is_handbrake_pressed = true
					driving_handbrake_updated.emit(true)
				elif not st.pressed and st.index == _handbrake_touch_index:
					_is_handbrake_pressed = false
					_handbrake_touch_index = -1
					driving_handbrake_updated.emit(false)
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

func hide_tension_hud() -> void:
	if tension_panel:
		tension_panel.visible = false

func set_action_button_highlight(highlighted: bool) -> void:
	if action_button:
		action_button.modulate = Color(1.2, 1.2, 0.4, 1.0) if highlighted else Color(1.0, 1.0, 1.0, 0.7)

var _peel_accumulated_y: float = 0.0

func show_gesture_overlay(gesture_type: String) -> void:
	_current_gesture_type = gesture_type
	_peel_accumulated_y = 0.0
	_tuning_accum_px = 0.0
	if gesture_panel:
		gesture_panel.visible = true
	if core_tap_button: core_tap_button.visible = (gesture_type == "EXPOSE_CORE")
	if gesture_hint_label:
		match gesture_type:
			"TUNE_SIGNAL": gesture_hint_label.text = "[ SWIPE ↔ TO TUNE FREQUENCY ]"
			"PEEL_PANEL": gesture_hint_label.text = "[ SWIPE DOWN TO PEEL PANEL ]"
			"EXPOSE_CORE": gesture_hint_label.text = "[ TAP CORE TO EXTRACT ]"

func close_interaction_overlay() -> void:
	if gesture_panel:
		gesture_panel.visible = false
	_is_peeling = false
	_is_tuning = false
	_interaction_touch_index = -1
	_current_gesture_type = ""
	_peel_accumulated_y = 0.0

func _input(event: InputEvent) -> void:
	# Global safety net: finger release anywhere on screen releases any owned pointer
	if event is InputEventScreenTouch:
		var touch_ev := event as InputEventScreenTouch
		if not touch_ev.pressed:
			_handle_touch_up_anywhere(touch_ev.index)
	elif event is InputEventMouseButton:
		var mouse_ev := event as InputEventMouseButton
		if not mouse_ev.pressed:
			# If mouse released, clear all active states
			_handle_touch_up_anywhere(_joystick_touch_index)
			_handle_touch_up_anywhere(_gas_touch_index)
			_handle_touch_up_anywhere(_brake_touch_index)
			_handle_touch_up_anywhere(_handbrake_touch_index)
			_handle_touch_up_anywhere(_interaction_touch_index)

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
		driving_handbrake_updated.emit(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_ev := event as InputEventScreenTouch
		if gesture_panel and gesture_panel.visible:
			if touch_ev.pressed:
				if _interaction_touch_index == -1:
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
				if not _joystick_active and left_safe_bounds.has_point(touch_ev.position):
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

func _start_joystick(touch_idx: int, pos: Vector2) -> void:
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
		driving_steer_updated.emit(_current_joystick_vec.x)

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
		driving_steer_updated.emit(0.0)

func show_replay_overlay() -> void:
	if replay_panel:
		replay_panel.visible = true

func hide_replay_overlay() -> void:
	if replay_panel:
		replay_panel.visible = false
