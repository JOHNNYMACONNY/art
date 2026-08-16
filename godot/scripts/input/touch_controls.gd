class_name TouchControlsUI
extends Control

# Touch Controls & Multitouch Pointer Ownership Layer
# Tracks left_pointer_id for floating joystick and interaction_pointer_id for gesture drag.

signal joystick_vector_updated(vec: Vector2)
signal action_button_pressed
signal peel_gesture_dragged(progress: float)
signal core_tap_pressed

@onready var joystick_base: Control = $LeftTouchArea/JoystickBase
@onready var joystick_knob: Control = $LeftTouchArea/JoystickBase/JoystickKnob
@onready var action_button: Button = $RightTouchArea/ActionButton
@onready var gesture_panel: Panel = $GestureOverlayPanel
@onready var gesture_label: Label = $GestureOverlayPanel/GestureLabel
@onready var core_pull_button: Button = $GestureOverlayPanel/CorePullButton

# Pointer ownership IDs (-1 = unassigned)
var left_pointer_id: int = -1
var interaction_pointer_id: int = -1

var _joystick_origin := Vector2.ZERO
var _max_radius: float = 75.0

var _is_peeling: bool = false
var _peel_start_y: float = 0.0
var _peel_progress: float = 0.0

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
		if highlighted:
			action_button.text = "[ INTERACT ]"
			action_button.modulate = Color(1.0, 0.85, 0.2, 1.0)
		else:
			action_button.text = "ACTION"
			action_button.modulate = Color(0.6, 0.6, 0.6, 0.7)

func show_gesture_overlay(step_name: String) -> void:
	if gesture_panel:
		gesture_panel.visible = true
		if step_name == "PEEL_PANEL":
			gesture_label.text = "DRAG DOWN TO PEEL CORRODED COVER"
			core_pull_button.visible = false
			_is_peeling = true
			_peel_progress = 0.0
		elif step_name == "EXPOSE_CORE":
			gesture_label.text = "TAP GLOWING CORE TO EXTRACT!"
			core_pull_button.visible = true
			_is_peeling = false
		elif step_name == "EXTRACTED":
			gesture_label.text = "CORE EXTRACTED! [ SUCCESS ]"
			core_pull_button.visible = false
			_is_peeling = false
			await get_tree().create_timer(1.2).timeout
			gesture_panel.visible = false

func _input(event: InputEvent) -> void:
	var viewport_w := get_viewport_rect().size.x
	
	if event is InputEventScreenTouch:
		var touch_idx: int = event.index
		var is_down: bool = event.pressed
		var pos: Vector2 = event.position
		
		if is_down:
			# Left screen touch down claims locomotion joystick pointer
			if pos.x < (viewport_w * 0.5) and left_pointer_id == -1:
				left_pointer_id = touch_idx
				_joystick_origin = pos
				if joystick_base:
					joystick_base.visible = true
					joystick_base.global_position = pos - (joystick_base.size * 0.5)
			# Gesture drag touch down claims interaction pointer
			elif _is_peeling and interaction_pointer_id == -1:
				interaction_pointer_id = touch_idx
				_peel_start_y = pos.y
		else:
			# Touch release checks pointer ID ownership
			if touch_idx == left_pointer_id:
				_reset_joystick()
			elif touch_idx == interaction_pointer_id:
				interaction_pointer_id = -1
				
	elif event is InputEventScreenDrag:
		var drag_idx: int = event.index
		var pos: Vector2 = event.position
		
		if drag_idx == left_pointer_id:
			var offset: Vector2 = pos - _joystick_origin
			var clamped_offset := offset.limit_length(_max_radius)
			if joystick_knob:
				joystick_knob.position = (joystick_base.size * 0.5) + clamped_offset - (joystick_knob.size * 0.5)
			var norm_vec := clamped_offset / _max_radius
			emit_signal("joystick_vector_updated", norm_vec)
			
		elif drag_idx == interaction_pointer_id and _is_peeling:
			var dy: float = pos.y - _peel_start_y
			if dy > 5.0:
				_peel_progress = clamp(dy / 120.0, 0.0, 1.0)
				emit_signal("peel_gesture_dragged", _peel_progress)

	# Desktop mouse fallback
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
		emit_signal("joystick_vector_updated", norm_vec)

func _reset_joystick() -> void:
	left_pointer_id = -1
	if joystick_base:
		joystick_base.visible = false
	if joystick_knob:
		joystick_knob.position = (joystick_base.size * 0.5) - (joystick_knob.size * 0.5)
	emit_signal("joystick_vector_updated", Vector2.ZERO)

func _on_action_pressed() -> void:
	emit_signal("action_button_pressed")

func _on_core_pull_pressed() -> void:
	emit_signal("core_tap_pressed")
