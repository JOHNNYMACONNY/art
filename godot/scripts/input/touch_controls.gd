class_name TouchControlsUI
extends Control

# TouchControlsUI: Multitouch Pointer Ownership & Gesture Overlay Manager

signal joystick_vector_updated(vec: Vector2)
signal action_button_pressed
signal peel_gesture_dragged(progress: float)
signal tuner_dragged(delta_freq: float)
signal core_tap_pressed

@onready var joystick_base: Control = $LeftTouchArea/JoystickBase
@onready var joystick_knob: Control = $LeftTouchArea/JoystickBase/JoystickKnob
@onready var action_button: Button = $RightTouchArea/ActionButton
@onready var gesture_panel: Panel = $GestureOverlayPanel
@onready var gesture_label: Label = $GestureOverlayPanel/GestureLabel
@onready var core_pull_button: Button = $GestureOverlayPanel/CorePullButton

var left_pointer_id: int = -1
var interaction_pointer_id: int = -1

var _joystick_origin: Vector2 = Vector2.ZERO
var _max_radius: float = 75.0

var _is_peeling: bool = false
var _is_tuning: bool = false
var _peel_start_y: float = 0.0
var _peel_progress: float = 0.0
var _last_drag_x: float = 0.0

func _ready() -> void:
	if joystick_base:
		joystick_base.visible = false
	if gesture_panel:
		gesture_panel.visible = false
	if action_button:
		action_button.pressed.connect(_on_action_pressed)
	if core_pull_button:
		core_pull_button.pressed.connect(_on_core_pull_pressed)

func set_action_button_highlight(highlighted: bool) -> void:
	if action_button:
		action_button.modulate = Color(1.2, 1.2, 1.0) if highlighted else Color(1, 1, 1)

func show_gesture_overlay(step_name: String) -> void:
	if gesture_panel and gesture_label:
		gesture_panel.visible = true
		match step_name:
			"TUNE_SIGNAL":
				gesture_label.text = "SWIPE HORIZONTALLY TO TUNE FREQUENCY"
				core_pull_button.visible = false
				_is_peeling = false
				_is_tuning = true
			"PEEL_PANEL":
				gesture_label.text = "DRAG DOWN TO PEEL CORRODED COVER"
				core_pull_button.visible = false
				_is_peeling = true
				_is_tuning = false
				_peel_progress = 0.0
			"EXPOSE_CORE":
				gesture_label.text = "TAP GLOWING CORE TO EXTRACT!"
				core_pull_button.visible = true
				_is_peeling = false
				_is_tuning = false
			"EXTRACTED":
				gesture_label.text = "CORE EXTRACTED! [ SUCCESS ]"
				core_pull_button.visible = false
				_is_peeling = false
				_is_tuning = false
				await get_tree().create_timer(1.2).timeout
				close_interaction_overlay()
			_:
				close_interaction_overlay()

func close_interaction_overlay() -> void:
	_is_peeling = false
	_is_tuning = false
	_peel_progress = 0.0
	interaction_pointer_id = -1
	if gesture_panel:
		gesture_panel.visible = false

func _input(event: InputEvent) -> void:
	var viewport_w := get_viewport_rect().size.x
	
	if event is InputEventScreenTouch:
		var touch_idx: int = event.index
		var is_down: bool = event.pressed
		var pos: Vector2 = event.position
		
		if is_down:
			if (_is_peeling or _is_tuning) and interaction_pointer_id == -1:
				interaction_pointer_id = touch_idx
				_peel_start_y = pos.y
				_last_drag_x = pos.x
			elif pos.x < (viewport_w * 0.5) and left_pointer_id == -1:
				left_pointer_id = touch_idx
				_joystick_origin = pos
				if joystick_base:
					joystick_base.visible = true
					joystick_base.global_position = pos - (joystick_base.size * 0.5)
		else:
			if touch_idx == left_pointer_id:
				_reset_joystick()
			elif touch_idx == interaction_pointer_id:
				interaction_pointer_id = -1
				
	elif event is InputEventScreenDrag:
		var drag_idx: int = event.index
		var pos: Vector2 = event.position
		
		if drag_idx == interaction_pointer_id:
			if _is_peeling:
				var dy: float = pos.y - _peel_start_y
				if dy > 5.0:
					_peel_progress = clamp(dy / 120.0, 0.0, 1.0)
					peel_gesture_dragged.emit(_peel_progress)
			elif _is_tuning:
				var dx: float = pos.x - _last_drag_x
				_last_drag_x = pos.x
				var delta_freq: float = dx / 250.0
				tuner_dragged.emit(delta_freq)
				
		elif drag_idx == left_pointer_id:
			var offset: Vector2 = pos - _joystick_origin
			var clamped_offset := offset.limit_length(_max_radius)
			if joystick_knob:
				joystick_knob.position = (joystick_base.size * 0.5) + clamped_offset - (joystick_knob.size * 0.5)
			var norm_vec := clamped_offset / _max_radius
			joystick_vector_updated.emit(norm_vec)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and event.position.x < (viewport_w * 0.5) and left_pointer_id == -1:
			left_pointer_id = 99
			_joystick_origin = event.position
			if joystick_base:
				joystick_base.visible = true
				joystick_base.global_position = event.position - (joystick_base.size * 0.5)
		elif not event.is_pressed() and left_pointer_id == 99:
			_reset_joystick()
			
	elif event is InputEventMouseMotion and left_pointer_id == 99:
		var offset: Vector2 = event.position - _joystick_origin
		var clamped_offset := offset.limit_length(_max_radius)
		if joystick_knob:
			joystick_knob.position = (joystick_base.size * 0.5) + clamped_offset - (joystick_knob.size * 0.5)
		var norm_vec := clamped_offset / _max_radius
		joystick_vector_updated.emit(norm_vec)

func _reset_joystick() -> void:
	left_pointer_id = -1
	if joystick_base:
		joystick_base.visible = false
	if joystick_knob:
		joystick_knob.position = (joystick_base.size * 0.5) - (joystick_knob.size * 0.5)
	joystick_vector_updated.emit(Vector2.ZERO)

func _on_action_pressed() -> void:
	action_button_pressed.emit()

func _on_core_pull_pressed() -> void:
	core_tap_pressed.emit()
