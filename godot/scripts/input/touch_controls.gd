class_name TouchControlsUI
extends Control

# Echos in the Scrap - Dual-Thumb Touch Controls UI (V4.1 Fix)
# Features Foot Traversal, Vehicle Driving, Tension HUD Panel, and Touch Tuner Dragging

signal joystick_vector_updated(vec: Vector2)
signal action_button_pressed
signal peel_gesture_dragged(progress: float)
signal tuner_dragged(delta_freq: float)
signal core_tap_pressed
signal driving_steer_updated(steer: float)
signal driving_throttle_updated(throttle: float)
signal dismount_pressed

enum UIMode {
	FOOT_TRAVERSAL,
	VEHICLE_DRIVING
}

@export var max_joystick_radius: float = 80.0
@export var debug_hud_enabled: bool = false

var current_mode: UIMode = UIMode.FOOT_TRAVERSAL

@onready var joystick_base: Control = $LeftTouchArea/JoystickBase
@onready var joystick_handle: Control = $LeftTouchArea/JoystickBase/JoystickKnob
@onready var action_button: Button = $RightTouchArea/ActionButton

@onready var driving_panel: Control = $DrivingOverlayPanel
@onready var gas_button: Button = $DrivingOverlayPanel/ThrottleButton
@onready var brake_button: Button = $DrivingOverlayPanel/BrakeButton
@onready var dismount_button: Button = $DrivingOverlayPanel/DismountButton

@onready var gesture_panel: Control = $GestureOverlayPanel
@onready var gesture_hint_label: Label = $GestureOverlayPanel/GestureLabel
@onready var core_tap_button: Button = $GestureOverlayPanel/CorePullButton

@onready var tension_panel: Control = $TensionHUDPanel
@onready var alert_label: Label = $TensionHUDPanel/AlertLabel
@onready var proximity_label: Label = $TensionHUDPanel/ProximityLabel

var _joystick_active: bool = false
var _joystick_touch_index: int = -1
var _joystick_center_pos: Vector2 = Vector2.ZERO
var _current_joystick_vec: Vector2 = Vector2.ZERO
var _is_peeling: bool = false
var _is_tuning: bool = false

func _ready() -> void:
	if action_button:
		action_button.pressed.connect(func(): action_button_pressed.emit())
	if dismount_button:
		dismount_button.pressed.connect(func(): dismount_pressed.emit())
	if core_tap_button:
		core_tap_button.pressed.connect(func(): core_tap_pressed.emit())
		
	if gas_button:
		gas_button.button_down.connect(func(): driving_throttle_updated.emit(1.0))
		gas_button.button_up.connect(func(): driving_throttle_updated.emit(0.0))
	if brake_button:
		brake_button.button_down.connect(func(): driving_throttle_updated.emit(-1.0))
		brake_button.button_up.connect(func(): driving_throttle_updated.emit(0.0))
		
	set_mode(UIMode.FOOT_TRAVERSAL)
	close_interaction_overlay()
	hide_tension_hud()

func set_mode(mode: UIMode) -> void:
	current_mode = mode
	if mode == UIMode.FOOT_TRAVERSAL:
		if action_button: action_button.visible = true
		if driving_panel: driving_panel.visible = false
	elif mode == UIMode.VEHICLE_DRIVING:
		if action_button: action_button.visible = false
		if driving_panel: driving_panel.visible = true
		close_interaction_overlay()

func set_dismount_button_enabled(enabled: bool) -> void:
	if dismount_button:
		dismount_button.disabled = not enabled
		dismount_button.modulate = Color(1, 1, 1, 1.0) if enabled else Color(1, 1, 1, 0.4)

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

func show_gesture_overlay(type: String) -> void:
	if gesture_panel:
		gesture_panel.visible = true
	if core_tap_button: core_tap_button.visible = (type == "EXPOSE_CORE")
	if gesture_hint_label:
		match type:
			"TUNE_SIGNAL": gesture_hint_label.text = "[ ROTATE DIAL TO LOCK FREQUENCY ]"
			"PEEL_PANEL": gesture_hint_label.text = "[ SWIPE DOWN TO PEEL PANEL ]"
			"EXPOSE_CORE": gesture_hint_label.text = "[ TAP CORE TO EXTRACT ]"

func close_interaction_overlay() -> void:
	if gesture_panel:
		gesture_panel.visible = false
	_is_peeling = false
	_is_tuning = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_ev := event as InputEventScreenTouch
		if touch_ev.position.x < get_viewport_rect().size.x * 0.5:
			if touch_ev.pressed and not _joystick_active:
				_start_joystick(touch_ev.index, touch_ev.position)
			elif not touch_ev.pressed and touch_ev.index == _joystick_touch_index:
				_stop_joystick()
		elif gesture_panel and gesture_panel.visible:
			if gesture_hint_label.text.contains("PEEL"):
				_is_peeling = touch_ev.pressed
			elif gesture_hint_label.text.contains("TUNE"):
				_is_tuning = touch_ev.pressed
				
	elif event is InputEventScreenDrag:
		var drag_ev := event as InputEventScreenDrag
		if drag_ev.index == _joystick_touch_index and _joystick_active:
			_update_joystick(drag_ev.position)
		elif _is_peeling and drag_ev.relative.y > 0:
			var progress: float = clampf(drag_ev.relative.y / 200.0, 0.0, 1.0)
			peel_gesture_dragged.emit(progress)
		elif _is_tuning and abs(drag_ev.relative.x) > 0:
			var delta_freq: float = drag_ev.relative.x / 300.0
			tuner_dragged.emit(delta_freq)

func _start_joystick(touch_idx: int, pos: Vector2) -> void:
	_joystick_active = true
	_joystick_touch_index = touch_idx
	_joystick_center_pos = pos
	if joystick_base:
		joystick_base.visible = true
		joystick_base.global_position = pos - (joystick_base.size * 0.5)

func _update_joystick(pos: Vector2) -> void:
	var delta_pos := pos - _joystick_center_pos
	if delta_pos.length() > max_joystick_radius:
		delta_pos = delta_pos.normalized() * max_joystick_radius
	if joystick_handle:
		joystick_handle.position = delta_pos
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
		joystick_handle.position = Vector2.ZERO
	if joystick_base:
		joystick_base.visible = false
		
	if current_mode == UIMode.FOOT_TRAVERSAL:
		joystick_vector_updated.emit(Vector2.ZERO)
	elif current_mode == UIMode.VEHICLE_DRIVING:
		driving_steer_updated.emit(0.0)
