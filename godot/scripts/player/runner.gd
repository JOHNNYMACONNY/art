class_name PlayerRunner
extends CharacterBody3D

# Runner Placeholder Locomotion Script
# Screen-relative analog movement, floating left-thumb joystick support, 8-way visual facing.

@export var move_speed: float = 8.5
@export var acceleration: float = 40.0
@export var friction: float = 35.0

@onready var mesh_pivot: Node3D = $MeshPivot

var joystick_vector := Vector2.ZERO
var is_input_locked: bool = false

# Screen-to-World direction relative to 45 deg yaw camera
var _camera_yaw_deg: float = 45.0

signal footstep_triggered

var _step_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if is_input_locked:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		move_and_slide()
		return
		
	# Fallback keyboard input if joystick vector is zero
	var input_dir := joystick_vector
	if input_dir.length() < 0.05:
		var kb_x := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		var kb_y := Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		input_dir = Vector2(kb_x, kb_y)
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()
			
	if input_dir.length() > 0.05:
		# Convert screen-relative 2D input (Up = -Y screen) to 3D world direction
		# Camera yaw = 45 degrees, so screen UP (-Y) maps to (-X, -Z) in world 3D space
		var yaw_rad := deg_to_rad(_camera_yaw_deg)
		var forward := Vector3(-sin(yaw_rad), 0.0, -cos(yaw_rad)).normalized()
		var right := Vector3(cos(yaw_rad), 0.0, -sin(yaw_rad)).normalized()
		
		var move_dir := (right * input_dir.x + forward * input_dir.y).normalized()
		var target_vel := move_dir * (move_speed * input_dir.length())
		
		velocity = velocity.move_toward(target_vel, acceleration * delta)
		
		# 8-Way visual mesh facing direction
		if mesh_pivot:
			var target_angle := atan2(-move_dir.x, -move_dir.z)
			# Snap visual mesh angle to 8 cardinal/intercardinal directions
			var snap_step: float = PI / 4.0
			var snapped_angle: float = round(target_angle / snap_step) * snap_step
			mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, snapped_angle, delta * 15.0)
			
		# Trigger footstep audio event periodically
		_step_timer += delta * velocity.length()
		if _step_timer > 3.0:
			_step_timer = 0.0
			emit_signal("footstep_triggered")
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		_step_timer = 0.0
		
	move_and_slide()

func set_joystick_input(vec: Vector2) -> void:
	joystick_vector = vec
