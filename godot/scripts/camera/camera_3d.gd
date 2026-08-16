class_name ChinatownCamera3D
extends Camera3D

# Chinatown Wars-Inspired Low-FOV 3/4 Perspective Camera
# FOV ~32 deg, pitch ~58 deg downward, yaw ~45 deg, velocity look-ahead ~12% max.

@export var target_node: NodePath
@export var pitch_deg: float = -58.0
@export var yaw_deg: float = 45.0
@export var camera_fov: float = 32.0
@export var distance: float = 24.0
@export var follow_speed: float = 6.0
@export var look_ahead_max: float = 2.5 # ~12% of typical viewport width in 3D units

var _target: Node3D = null
var _look_ahead_offset := Vector3.ZERO

func _ready() -> void:
	fov = camera_fov
	if target_node:
		_target = get_node_or_null(target_node) as Node3D
	_setup_angles()

func _setup_angles() -> void:
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0.0)

func set_target(node: Node3D) -> void:
	_target = node

func _physics_process(delta: float) -> void:
	if not _target:
		return
		
	# Calculate target velocity for look-ahead
	var velocity := Vector3.ZERO
	if _target is CharacterBody3D:
		velocity = (_target as CharacterBody3D).velocity
		
	var target_look_ahead := Vector3.ZERO
	if velocity.length() > 0.1:
		target_look_ahead = velocity.normalized() * min(velocity.length() * 0.3, look_ahead_max)
		
	_look_ahead_offset = _look_ahead_offset.lerp(target_look_ahead, delta * 4.0)
	
	# Compute camera target position based on 3/4 offset vector
	var rot_rad_pitch := deg_to_rad(pitch_deg)
	var rot_rad_yaw := deg_to_rad(yaw_deg)
	
	var offset_dir := Vector3(
		sin(rot_rad_yaw) * cos(rot_rad_pitch),
		-sin(rot_rad_pitch),
		cos(rot_rad_yaw) * cos(rot_rad_pitch)
	).normalized()
	
	var desired_pos: Vector3 = _target.global_position + _look_ahead_offset + (offset_dir * distance)
	global_position = global_position.lerp(desired_pos, delta * follow_speed)
