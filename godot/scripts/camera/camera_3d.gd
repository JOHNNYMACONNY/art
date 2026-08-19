class_name ChinatownCamera3D
extends Camera3D

# Chinatown Camera 3D: 3/4 Top-Down Dynamic Follow Camera
# Dynamic Speed FOV, Damped Velocity Look-Ahead, & Fixed 3/4 Perspective

@export var target_node: Node3D = null
@export var follow_speed: float = 5.0 # Focus point damping rate (s⁻¹)
@export var default_fov: float = 32.0
@export var max_speed_fov: float = 38.0
@export var max_speed_ref: float = 14.0

## Dynamic Yaw Follow & Polar Rig (#30 Candidate B)
@export var dynamic_yaw_enabled: bool = true
@export var vehicle_yaw_rate: float = 2.8 # s⁻¹
@export var foot_yaw_rate: float = 1.5 # s⁻¹
@export var max_yaw_speed: float = 2.5 # rad/s max slew

const RIG_GROUND_RADIUS: float = 16.9705627 # sqrt(12^2 + 12^2)
const RIG_ELEVATION_HEIGHT: float = 18.0

var _current_yaw_rad: float = PI / 4.0 # 45 degrees initial
var _interaction_target: Node3D = null
var _is_interaction_mode: bool = false
var _camera_offset: Vector3 = Vector3(12.0, 18.0, 12.0)
var _focus_height_offset: Vector3 = Vector3(0.0, 0.5, 0.0)

# Filtered state tracking
var _smoothed_focus_pos: Vector3 = Vector3.ZERO
var _smoothed_look_ahead: Vector3 = Vector3.ZERO
var _is_initialized: bool = false

# Telemetry
var last_follow_error: float = 0.0

func _ready() -> void:
	fov = default_fov
	if target_node:
		reset_camera_instant(target_node)

func set_target(new_target: Node3D) -> void:
	target_node = new_target
	if not _is_initialized and new_target != null:
		reset_camera_instant(new_target)

func set_interaction_mode(active: bool, focus_node: Node3D = null) -> void:
	_is_interaction_mode = active
	_interaction_target = focus_node

func reset_camera_instant(target: Node3D) -> void:
	target_node = target
	_is_interaction_mode = false
	_interaction_target = null
	_current_yaw_rad = PI / 4.0
	fov = default_fov
	if target:
		_smoothed_focus_pos = target.global_position
	else:
		_smoothed_focus_pos = Vector3.ZERO
	_smoothed_look_ahead = Vector3.ZERO
	_is_initialized = true
	var framing_center: Vector3 = _smoothed_focus_pos
	var offset_x: float = RIG_GROUND_RADIUS * sin(_current_yaw_rad)
	var offset_z: float = RIG_GROUND_RADIUS * cos(_current_yaw_rad)
	global_position = framing_center + Vector3(offset_x, RIG_ELEVATION_HEIGHT, offset_z)
	look_at(framing_center + _focus_height_offset)

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
		
	# -------------------------------------------------------------------------
	# STAGE 1: Determine Raw Target Position & Velocity
	# -------------------------------------------------------------------------
	var raw_target_pos: Vector3 = Vector3.ZERO
	var raw_velocity: Vector3 = Vector3.ZERO
	var speed: float = 0.0
	
	if _is_interaction_mode and _interaction_target:
		raw_target_pos = _interaction_target.global_position
		raw_velocity = Vector3.ZERO
		speed = 0.0
	elif target_node:
		raw_target_pos = target_node.global_position
		if target_node is CourierBike:
			var bike: CourierBike = target_node as CourierBike
			speed = abs(bike.current_speed)
			raw_velocity = bike.velocity
		elif target_node is CharacterBody3D:
			var body: CharacterBody3D = target_node as CharacterBody3D
			raw_velocity = body.velocity
			speed = raw_velocity.length()
	else:
		return

	if not _is_initialized:
		reset_camera_instant(target_node)
		return

	# -------------------------------------------------------------------------
	# STAGE 2: Focus Position Smoothing (Exact Exponential Damping)
	# -------------------------------------------------------------------------
	var focus_factor: float = 1.0 - exp(-follow_speed * delta)
	_smoothed_focus_pos = _smoothed_focus_pos.lerp(raw_target_pos, focus_factor)
	last_follow_error = (_smoothed_focus_pos - raw_target_pos).length()

	# -------------------------------------------------------------------------
	# STAGE 3: Dual-Rate Velocity Look-Ahead (Lead Damping)
	# -------------------------------------------------------------------------
	var target_look_ahead: Vector3 = Vector3.ZERO
	if raw_velocity.length() > 0.2:
		var lead_dist: float = clampf(speed * 0.18, 0.0, 3.0)
		target_look_ahead = raw_velocity.normalized() * lead_dist
	
	# Rate selection: 7.0 s⁻¹ on direction reversal / braking, 3.5 s⁻¹ on continuous acceleration
	var look_ahead_rate: float = 3.5
	if _smoothed_look_ahead.length() > 0.1 and target_look_ahead.dot(_smoothed_look_ahead) < 0.0:
		look_ahead_rate = 7.0
	var look_ahead_factor: float = 1.0 - exp(-look_ahead_rate * delta)
	_smoothed_look_ahead = _smoothed_look_ahead.lerp(target_look_ahead, look_ahead_factor)

	# -------------------------------------------------------------------------
	# STAGE 4: Dynamic Yaw Tracking & Combined Rig Transform
	# -------------------------------------------------------------------------
	if dynamic_yaw_enabled and not _is_interaction_mode:
		var target_yaw: float = _current_yaw_rad
		var yaw_rate: float = 0.0
		
		if target_node is CourierBike or target_node is ScrapHauler or (target_node != null and target_node.is_in_group("vehicles")):
			var veh_fwd: Vector3 = -target_node.global_transform.basis.z
			veh_fwd.y = 0.0
			if veh_fwd.length_squared() > 0.01:
				veh_fwd = veh_fwd.normalized()
				# Place camera behind vehicle travel direction
				target_yaw = atan2(veh_fwd.x, veh_fwd.z) + PI
				yaw_rate = vehicle_yaw_rate
		elif speed > 1.2 and raw_velocity.length() > 1.2:
			var move_fwd: Vector3 = raw_velocity.normalized()
			move_fwd.y = 0.0
			if move_fwd.length_squared() > 0.01:
				move_fwd = move_fwd.normalized()
				target_yaw = atan2(move_fwd.x, move_fwd.z) + PI
				yaw_rate = foot_yaw_rate
		
		if yaw_rate > 0.0:
			var angle_diff: float = wrapf(target_yaw - _current_yaw_rad, -PI, PI)
			var step: float = angle_diff * (1.0 - exp(-yaw_rate * delta))
			step = clampf(step, -max_yaw_speed * delta, max_yaw_speed * delta)
			_current_yaw_rad = wrapf(_current_yaw_rad + step, -PI, PI)

	var offset_x: float = RIG_GROUND_RADIUS * sin(_current_yaw_rad)
	var offset_z: float = RIG_GROUND_RADIUS * cos(_current_yaw_rad)
	var dynamic_offset := Vector3(offset_x, RIG_ELEVATION_HEIGHT, offset_z)

	var framing_center: Vector3 = _smoothed_focus_pos + _smoothed_look_ahead
	global_position = framing_center + dynamic_offset
	look_at(framing_center + _focus_height_offset)

	# -------------------------------------------------------------------------
	# FOV: Contextual & Speed Breathing
	# -------------------------------------------------------------------------
	var target_fov: float = default_fov
	var fov_rate: float = 3.0
	if _is_interaction_mode:
		target_fov = default_fov * 0.85 # 27.2°
		fov_rate = 4.0
	else:
		var speed_ratio: float = clampf(speed / max_speed_ref, 0.0, 1.0)
		target_fov = lerpf(default_fov, max_speed_fov, speed_ratio)
	
	var fov_factor: float = 1.0 - exp(-fov_rate * delta)
	fov = lerpf(fov, target_fov, fov_factor)
