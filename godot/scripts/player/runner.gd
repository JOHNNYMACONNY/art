class_name PlayerRunner
extends CharacterBody3D

# Runner Locomotion & Hero Identity Script
# Screen-relative analog movement, floating left-thumb joystick support, 8-way visual facing,
# procedural run bob / limb swing, and mounted motorcycle riding posture.

@export var move_speed: float = 8.5
@export var acceleration: float = 40.0
@export var friction: float = 35.0

@onready var mesh_pivot: Node3D = $MeshPivot
@onready var torso_node: Node3D = $MeshPivot/Torso
@onready var head_node: Node3D = $MeshPivot/Head
@onready var left_arm: Node3D = $MeshPivot/LeftArm
@onready var right_arm: Node3D = $MeshPivot/RightArm
@onready var left_leg: Node3D = $MeshPivot/LeftLeg
@onready var right_leg: Node3D = $MeshPivot/RightLeg

var joystick_vector := Vector2.ZERO
var is_input_locked: bool = false
var is_mounted: bool = false

signal footstep_triggered

var _step_timer: float = 0.0
var _anim_time: float = 0.0

func _physics_process(delta: float) -> void:
	if is_mounted:
		# Posture handled via set_mounted_posture
		return

	if is_input_locked:
		velocity = Vector3.ZERO
		_reset_standing_pose()
		return

	# Touch joystick has authority while active; otherwise accept physical/logical desktop keys.
	var input_dir := joystick_vector
	if input_dir.length() < 0.05:
		var kb_x: float = 0.0
		var kb_y: float = 0.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
			kb_x += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
			kb_x -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
			kb_y += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up"):
			kb_y -= 1.0
		input_dir = Vector2(kb_x, kb_y)
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()

	if input_dir.length() > 0.05:
		# Preserve analog touch magnitude while deriving direction from the live camera basis.
		var input_strength: float = minf(input_dir.length(), 1.0)
		var normalized_input := input_dir.normalized()

		# Project the active camera's basis onto the horizontal plane. If no camera is
		# active yet, retain the historical 45-degree frame as a startup fallback.
		var camera_3d := get_viewport().get_camera_3d() if is_inside_tree() else null
		var forward_xz := Vector3(-0.707107, 0.0, -0.707107)
		var right_xz := Vector3(0.707107, 0.0, -0.707107)
		if camera_3d:
			var camera_basis := camera_3d.global_transform.basis
			var forward_candidate := Vector3(-camera_basis.z.x, 0.0, -camera_basis.z.z)
			if forward_candidate.length_squared() > 0.001:
				forward_xz = forward_candidate.normalized()
			var right_candidate := Vector3(camera_basis.x.x, 0.0, camera_basis.x.z)
			if right_candidate.length_squared() > 0.001:
				right_xz = right_candidate.normalized()

		# Screen space: Up = -Y, Down = +Y, Left = -X, Right = +X.
		var move_dir := (right_xz * normalized_input.x + forward_xz * (-normalized_input.y)).normalized()
		var target_vel := move_dir * (move_speed * input_strength)

		velocity = velocity.move_toward(target_vel, acceleration * delta)

		# 8-Way visual mesh facing direction
		if mesh_pivot:
			var target_angle := atan2(-move_dir.x, -move_dir.z)
			var snap_step: float = PI / 4.0
			var snapped_angle: float = round(target_angle / snap_step) * snap_step
			mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, snapped_angle, delta * 15.0)

		# Procedural running stride animation
		_anim_time += delta * velocity.length() * 2.2
		var leg_swing: float = sin(_anim_time) * 0.55
		var arm_swing: float = sin(_anim_time) * 0.45

		if left_leg: left_leg.rotation.x = leg_swing
		if right_leg: right_leg.rotation.x = -leg_swing
		if left_arm: left_arm.rotation.x = -arm_swing
		if right_arm: right_arm.rotation.x = arm_swing
		if torso_node: torso_node.position.y = 1.15 + abs(sin(_anim_time * 2.0)) * 0.04
		if head_node: head_node.position.y = 1.62 + abs(sin(_anim_time * 2.0)) * 0.03

		# Trigger footstep audio event periodically
		_step_timer += delta * velocity.length()
		if _step_timer > 3.0:
			_step_timer = 0.0
			emit_signal("footstep_triggered")
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		_step_timer = 0.0
		_reset_standing_pose()

	move_and_slide()

func set_joystick_input(vec: Vector2) -> void:
	joystick_vector = vec

func set_mounted_posture(mounted: bool) -> void:
	is_mounted = mounted
	if not mesh_pivot:
		return

	if mounted:
		# Riding motorcycle posture: seated, forward crouch, hands reaching forward to grips
		if torso_node:
			torso_node.position = Vector3(0, 0.48, 0.08)
			torso_node.rotation.x = deg_to_rad(-24.0)
		if head_node:
			head_node.position = Vector3(0, 0.88, -0.16)
			head_node.rotation.x = deg_to_rad(12.0)
		if left_arm:
			left_arm.position = Vector3(-0.30, 0.52, -0.05)
			left_arm.rotation.x = deg_to_rad(-65.0)
			left_arm.rotation.y = deg_to_rad(-15.0)
		if right_arm:
			right_arm.position = Vector3(0.30, 0.52, -0.05)
			right_arm.rotation.x = deg_to_rad(-65.0)
			right_arm.rotation.y = deg_to_rad(15.0)
		if left_leg:
			left_leg.position = Vector3(-0.24, 0.28, 0.12)
			left_leg.rotation.x = deg_to_rad(-70.0)
			left_leg.rotation.y = deg_to_rad(18.0)
		if right_leg:
			right_leg.position = Vector3(0.24, 0.28, 0.12)
			right_leg.rotation.x = deg_to_rad(-70.0)
			right_leg.rotation.y = deg_to_rad(-18.0)
		mesh_pivot.rotation.y = 0.0
	else:
		_reset_standing_pose()

func _reset_standing_pose() -> void:
	if torso_node:
		torso_node.position = Vector3(0, 1.15, 0)
		torso_node.rotation = Vector3.ZERO
	if head_node:
		head_node.position = Vector3(0, 1.62, 0)
		head_node.rotation = Vector3.ZERO
	if left_arm:
		left_arm.position = Vector3(-0.32, 1.18, 0)
		left_arm.rotation = Vector3.ZERO
	if right_arm:
		right_arm.position = Vector3(0.32, 1.18, 0)
		right_arm.rotation = Vector3.ZERO
	if left_leg:
		left_leg.position = Vector3(-0.14, 0.85, 0)
		left_leg.rotation = Vector3.ZERO
	if right_leg:
		right_leg.position = Vector3(0.14, 0.85, 0)
		right_leg.rotation = Vector3.ZERO
