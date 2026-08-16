class_name ChinatownCamera3D
extends Camera3D

# Chinatown-Wars Camera with Traversal (32 deg) and Interaction (28 deg) Modes

enum CameraMode {
	TRAVERSAL,
	INTERACTION
}

@export var target_node: NodePath
@export var pitch_deg: float = -58.0
@export var yaw_deg: float = 45.0
@export var traversal_fov: float = 32.0
@export var interaction_fov: float = 28.0
@export var follow_speed: float = 6.0
@export var look_ahead_max: float = 2.5

var current_mode: CameraMode = CameraMode.TRAVERSAL
var _target: Node3D = null
var _interactable_target: Node3D = null

var _look_ahead_offset := Vector3.ZERO
var _target_fov: float = 32.0
var _current_distance: float = 24.0

func _ready() -> void:
	fov = traversal_fov
	_target_fov = traversal_fov
	if target_node:
		_target = get_node_or_null(target_node) as Node3D
	_setup_angles()

func _setup_angles() -> void:
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0.0)

func set_target(node: Node3D) -> void:
	_target = node

func set_interaction_mode(active: bool, interactable: Node3D = null) -> void:
	if active:
		current_mode = CameraMode.INTERACTION
		_interactable_target = interactable
		_target_fov = interaction_fov
		_current_distance = 20.0
	else:
		current_mode = CameraMode.TRAVERSAL
		_interactable_target = null
		_target_fov = traversal_fov
		_current_distance = 24.0

func _physics_process(delta: float) -> void:
	if not _target:
		return
		
	# Smoothly interpolate FOV
	fov = lerp(fov, _target_fov, delta * 5.0)
	
	var focus_point: Vector3 = _target.global_position
	
	if current_mode == CameraMode.TRAVERSAL:
		var velocity := Vector3.ZERO
		if _target is CharacterBody3D:
			velocity = (_target as CharacterBody3D).velocity
			
		var target_look_ahead := Vector3.ZERO
		if velocity.length() > 0.1:
			target_look_ahead = velocity.normalized() * min(velocity.length() * 0.3, look_ahead_max)
			
		_look_ahead_offset = _look_ahead_offset.lerp(target_look_ahead, delta * 4.0)
		focus_point += _look_ahead_offset
	elif current_mode == CameraMode.INTERACTION and _interactable_target != null:
		# Weighted midpoint between player and interactable terminal
		focus_point = _target.global_position.lerp(_interactable_target.global_position, 0.45)
		_look_ahead_offset = _look_ahead_offset.lerp(Vector3.ZERO, delta * 6.0)

	var rot_rad_pitch := deg_to_rad(pitch_deg)
	var rot_rad_yaw := deg_to_rad(yaw_deg)
	
	var offset_dir := Vector3(
		sin(rot_rad_yaw) * cos(rot_rad_pitch),
		-sin(rot_rad_pitch),
		cos(rot_rad_yaw) * cos(rot_rad_pitch)
	).normalized()
	
	var desired_pos: Vector3 = focus_point + (offset_dir * _current_distance)
	global_position = global_position.lerp(desired_pos, delta * follow_speed)
