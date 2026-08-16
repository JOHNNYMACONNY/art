class_name ChinatownCamera3D
extends Camera3D

# Chinatown Camera 3D: 3/4 Top-Down Dynamic Follow Camera
# Dynamic Speed FOV & Velocity Look-Ahead

@export var target_node: Node3D = null
@export var follow_speed: float = 6.0
@export var default_fov: float = 32.0
@export var max_speed_fov: float = 38.0
@export var max_speed_ref: float = 14.0

var _interaction_target: Node3D = null
var _is_interaction_mode: bool = false
var _camera_offset: Vector3 = Vector3(12, 18, 12)

func _ready() -> void:
	fov = default_fov

func set_target(new_target: Node3D) -> void:
	target_node = new_target

func set_interaction_mode(active: bool, focus_node: Node3D = null) -> void:
	_is_interaction_mode = active
	_interaction_target = focus_node

func _process(delta: float) -> void:
	var target_pos: Vector3 = Vector3.ZERO
	var speed: float = 0.0
	var target_velocity: Vector3 = Vector3.ZERO
	
	if _is_interaction_mode and _interaction_target:
		target_pos = _interaction_target.global_position
		fov = lerp(fov, default_fov * 0.85, delta * 4.0)
	elif target_node:
		target_pos = target_node.global_position
		
		if target_node is CourierBike:
			speed = (target_node as CourierBike).current_speed
			target_velocity = (target_node as CourierBike).velocity
		elif target_node is CharacterBody3D:
			target_velocity = (target_node as CharacterBody3D).velocity
			speed = target_velocity.length()
			
		if target_velocity.length() > 0.01:
			var look_ahead: Vector3 = target_velocity.normalized() * clampf(speed * 0.15, 0.0, 3.0)
			target_pos += look_ahead
			
		var speed_ratio: float = clampf(speed / max_speed_ref, 0.0, 1.0)
		var target_fov: float = lerp(default_fov, max_speed_fov, speed_ratio)
		fov = lerp(fov, target_fov, delta * 6.0)
		
	var desired_pos: Vector3 = target_pos + _camera_offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	look_at(target_pos + Vector3(0, 0.5, 0))
