class_name MuscleCoupe
extends CharacterBody3D

# Muscle Coupe Vehicle Controller (High-Performance Scavenged V8 Muscle Class)
# Responsive acceleration, power oversteer drift, Dan Houser tire screech,
# authentic skeletal driving posture, and GTA-standard mount/dismount/collision contracts.

enum DismountRejectReason {
	TOO_FAST,
	NO_SAFE_POSITION
}

enum GearState {
	FORWARD,
	REVERSE
}

signal state_changed(new_state: String)
signal mounted(player: PlayerRunner)
signal dismounted
signal brake_screech_triggered(pos: Vector3)
signal dismount_rejected(reason: DismountRejectReason, current_speed: float, speed_limit: float)
signal collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3)

enum VehicleState {
	PARKED,
	MOUNTING,
	DRIVING,
	DISMOUNTING
}

@export var max_speed: float = 21.0
@export var max_reverse_speed: float = -5.0
@export var acceleration: float = 14.5
@export var braking_friction: float = 14.0
@export var steering_speed: float = 2.4
@export var dismount_speed_limit: float = 1.5
@export var drift_slip_rate: float = 3.2

@onready var rider_socket: Node3D = $RiderSocket
@onready var mount_interactable: InteractableBase = $MountInteractable
@onready var visual_root: Node3D = $VisualRoot

var current_state: VehicleState = VehicleState.PARKED
var current_gear: GearState = GearState.FORWARD
var occupant: PlayerRunner = null
var current_speed: float = 0.0
var steering_angle: float = 0.0
var is_handbrake_active: bool = false
var _brake_screech_cooldown: float = 0.0
var _gear_settle_timer: float = 0.0
const GEAR_SETTLE_DURATION: float = 0.12

var _mount_blend_time: float = 0.0
var _mount_start_pos: Vector3 = Vector3.ZERO
var _mount_start_basis: Basis = Basis.IDENTITY
var _dismount_blend_time: float = 0.0
var _dismount_start_pos: Vector3 = Vector3.ZERO
var _dismount_start_basis: Basis = Basis.IDENTITY
var _dismount_target_pos: Vector3 = Vector3.ZERO
const MOUNT_BLEND_DURATION: float = 0.20
const DISMOUNT_BLEND_DURATION: float = 0.20

func _ready() -> void:
	if mount_interactable:
		mount_interactable.interaction_priority = 2.0
		mount_interactable.is_powered = true
	var seat = find_child("Seat_Driver", true, false)
	if seat and rider_socket:
		rider_socket.position = seat.position + Vector3(0.0, -0.80, 0.08)

func _process(delta: float) -> void:
	if not occupant:
		return
	var socket_pos := to_global(rider_socket.position)
	if current_state == VehicleState.MOUNTING:
		_mount_blend_time += delta
		var t: float = clampf(_mount_blend_time / MOUNT_BLEND_DURATION, 0.0, 1.0)
		var smooth_t: float = 0.5 - 0.5 * cos(t * PI)
		occupant.global_position = _mount_start_pos.lerp(socket_pos, smooth_t)
		occupant.global_basis = _mount_start_basis.slerp(global_basis, smooth_t)
	elif current_state == VehicleState.DISMOUNTING:
		_dismount_blend_time += delta
		var t: float = clampf(_dismount_blend_time / DISMOUNT_BLEND_DURATION, 0.0, 1.0)
		var smooth_t: float = 0.5 - 0.5 * cos(t * PI)
		occupant.global_position = _dismount_start_pos.lerp(_dismount_target_pos, smooth_t)
		occupant.global_basis = _dismount_start_basis.slerp(Basis.IDENTITY, smooth_t)
	elif current_state == VehicleState.DRIVING:
		occupant.global_position = socket_pos
		occupant.global_basis = global_basis

func _physics_process(delta: float) -> void:
	if _brake_screech_cooldown > 0.0:
		_brake_screech_cooldown -= delta

	if current_state != VehicleState.DRIVING and current_state != VehicleState.MOUNTING:
		if not is_on_floor():
			velocity.y -= 9.8 * delta
			move_and_slide()
		return

	if current_state == VehicleState.DRIVING:
		# 1. Speed-sensitive steering yaw rate (sharp response at mid speed, stable at max speed)
		var speed_ratio: float = clampf(abs(current_speed) / max_speed, 0.0, 1.0)
		var steer_rate: float = lerp(steering_speed, 1.3, speed_ratio * 0.7)
		if is_handbrake_active:
			steer_rate *= 1.4

		if abs(steering_angle) > 0.01 and abs(current_speed) > 0.1:
			var steer_sign: float = 1.0 if current_speed >= -0.05 else -1.0
			rotate_y(-steering_angle * steer_rate * steer_sign * delta)

		# Chassis body roll into corners
		if visual_root:
			var target_roll := -steering_angle * clampf(abs(current_speed) / 8.0, 0.0, 1.0) * deg_to_rad(5.0)
			visual_root.rotation.z = lerpf(visual_root.rotation.z, target_roll, delta * 8.0)

		# 2. V8 Oversteer Lateral Grip & Drift Slip Model
		var forward_dir: Vector3 = -global_transform.basis.z
		var right_dir: Vector3 = global_transform.basis.x

		var current_lateral_vel: float = velocity.dot(right_dir)
		var grip_rate: float = drift_slip_rate if is_handbrake_active else 12.0
		var decay_factor: float = 1.0 - exp(-grip_rate * delta)
		var new_lateral_vel: float = lerpf(current_lateral_vel, 0.0, decay_factor)
		var new_forward_vel: float = current_speed

		velocity = (forward_dir * new_forward_vel) + (right_dir * new_lateral_vel)
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed
		move_and_slide()

		# 3. Glance Collision Response
		if get_slide_collision_count() > 0:
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				var normal := col.get_normal()
				if abs(normal.y) < 0.5:
					var head_on_ratio: float = abs(forward_dir.dot(normal))
					var pre_impact_speed: float = abs(current_speed)
					var impact_decay: float = lerpf(1.5, 30.0, head_on_ratio * head_on_ratio)
					var collider = col.get_collider()
					if collider and collider.has_method("apply_vehicle_ram"):
						impact_decay = lerpf(1.0, 7.5, head_on_ratio * head_on_ratio)
					current_speed = move_toward(current_speed, 0.0, impact_decay * delta)
					collision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())

	if occupant:
		if current_state == VehicleState.DRIVING:
			occupant.global_position = to_global(rider_socket.position)
			occupant.global_basis = global_basis
		occupant.velocity = Vector3.ZERO
		occupant.is_input_locked = true

func can_mount(player: PlayerRunner) -> bool:
	return current_state == VehicleState.PARKED and occupant == null and (mount_interactable == null or mount_interactable.is_player_in_range)

func request_mount(player: PlayerRunner) -> bool:
	if not can_mount(player):
		return false

	current_state = VehicleState.MOUNTING
	occupant = player
	state_changed.emit("MOUNTING")

	_mount_blend_time = 0.0
	_mount_start_pos = player.global_position
	_mount_start_basis = player.global_basis

	player.is_input_locked = true
	player.velocity = Vector3.ZERO
	player.set_vehicle_driving_posture(true, "car")

	var p_col := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if p_col: p_col.set_deferred("disabled", true)

	if mount_interactable:
		mount_interactable.is_powered = false

	get_tree().create_timer(0.20).timeout.connect(func():
		if current_state == VehicleState.MOUNTING:
			current_state = VehicleState.DRIVING
			state_changed.emit("DRIVING")
			mounted.emit(player)
	)
	return true

func request_dismount() -> bool:
	if current_state != VehicleState.DRIVING:
		return false

	if abs(current_speed) > dismount_speed_limit:
		dismount_rejected.emit(DismountRejectReason.TOO_FAST, current_speed, dismount_speed_limit)
		return false

	var safe_pos := _find_safe_dismount_position()
	if safe_pos == Vector3.INF:
		print("[COUPE] Dismount rejected: No volume-cleared dismount offset found!")
		dismount_rejected.emit(DismountRejectReason.NO_SAFE_POSITION, current_speed, dismount_speed_limit)
		return false

	current_state = VehicleState.DISMOUNTING
	state_changed.emit("DISMOUNTING")

	_dismount_blend_time = 0.0
	_dismount_start_pos = occupant.global_position
	_dismount_start_basis = occupant.global_basis
	_dismount_target_pos = safe_pos

	if mount_interactable:
		mount_interactable.is_powered = false

	get_tree().create_timer(0.20).timeout.connect(func():
		if occupant:
			var p_col := occupant.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if p_col: p_col.set_deferred("disabled", false)
			occupant.set_mounted_posture(false)
			occupant.global_position = safe_pos
			occupant.global_basis = Basis()
			occupant.is_input_locked = false
			occupant.velocity = Vector3.ZERO
			occupant = null

		if mount_interactable:
			mount_interactable.is_powered = true

		current_speed = 0.0
		velocity = Vector3.ZERO
		if visual_root: visual_root.rotation = Vector3.ZERO
		current_state = VehicleState.PARKED
		state_changed.emit("PARKED")
		dismounted.emit()
	)
	return true

func force_dismount() -> void:
	_mount_blend_time = 0.0
	_dismount_blend_time = 0.0
	if occupant:
		var p_col := occupant.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if p_col: p_col.set_deferred("disabled", false)
		occupant.set_mounted_posture(false)
		occupant.global_basis = Basis()
		occupant.is_input_locked = false
		occupant.velocity = Vector3.ZERO
		occupant = null
	if mount_interactable:
		mount_interactable.is_powered = true
	current_speed = 0.0
	velocity = Vector3.ZERO
	current_gear = GearState.FORWARD
	is_handbrake_active = false
	_gear_settle_timer = 0.0
	if visual_root: visual_root.rotation = Vector3.ZERO
	current_state = VehicleState.PARKED
	state_changed.emit("PARKED")
	dismounted.emit()

func _find_safe_dismount_position() -> Vector3:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return global_position + (global_transform.basis.x * 1.8)

	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.4

	var candidates: Array[Vector3] = [
		global_position + (global_transform.basis.x * 1.8),   # Left door
		global_position - (global_transform.basis.x * 1.8),  # Right door
		global_position + (global_transform.basis.z * 2.4),   # Rear bumper
		global_position - (global_transform.basis.z * 2.4)    # Front bumper
	]

	for cand in candidates:
		var ray_query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.5, 0), cand + Vector3(0, 0.5, 0))
		ray_query.exclude = [get_rid()]
		if occupant:
			ray_query.exclude.append(occupant.get_rid())
		var ray_res := space_state.intersect_ray(ray_query)
		if not ray_res.is_empty():
			var r_col = ray_res.get("collider")
			if r_col and r_col.name != "Floor" and not ("floor" in r_col.name.to_lower()):
				continue

		var shape_query := PhysicsShapeQueryParameters3D.new()
		shape_query.shape = shape
		shape_query.transform = Transform3D(Basis.IDENTITY, cand + Vector3(0, 0.95, 0))
		shape_query.exclude = [get_rid()]
		if occupant:
			shape_query.exclude.append(occupant.get_rid())
		var shape_res := space_state.intersect_shape(shape_query, 4)

		var is_blocked := false
		for hit in shape_res:
			var collider = hit.get("collider")
			if collider and collider.name != "Floor" and not ("floor" in collider.name.to_lower()):
				is_blocked = true
				break

		if not is_blocked:
			return cand

	return Vector3.INF

func set_drive_inputs(throttle: float, steer: float, delta: float, handbrake: bool = false) -> void:
	if current_state != VehicleState.DRIVING:
		return

	steering_angle = steer
	is_handbrake_active = handbrake
	if occupant and occupant.has_method("set_vehicle_steering"):
		occupant.set_vehicle_steering(steer)

	if handbrake:
		var pre_brake_speed := current_speed
		current_speed = move_toward(current_speed, 0.0, braking_friction * 1.6 * delta)
		if abs(pre_brake_speed) > 4.0 and _brake_screech_cooldown <= 0.0:
			_brake_screech_cooldown = 0.4
			brake_screech_triggered.emit(global_position)
		return

	if _gear_settle_timer > 0.0:
		_gear_settle_timer -= delta
		current_speed = move_toward(current_speed, 0.0, braking_friction * delta)
		return

	if current_gear == GearState.FORWARD:
		if throttle > 0.01:
			current_speed = move_toward(current_speed, max_speed, acceleration * throttle * delta)
		elif throttle < -0.01:
			current_speed = move_toward(current_speed, 0.0, braking_friction * abs(throttle) * delta)
			if abs(current_speed) < 0.1:
				current_speed = 0.0
				current_gear = GearState.REVERSE
				_gear_settle_timer = GEAR_SETTLE_DURATION
		else:
			current_speed = move_toward(current_speed, 0.0, (braking_friction * 0.35) * delta)
	elif current_gear == GearState.REVERSE:
		if throttle < -0.01:
			current_speed = move_toward(current_speed, max_reverse_speed, (acceleration * 0.75) * abs(throttle) * delta)
		elif throttle > 0.01:
			current_speed = move_toward(current_speed, 0.0, braking_friction * throttle * delta)
			if abs(current_speed) < 0.1:
				current_speed = 0.0
				current_gear = GearState.FORWARD
				_gear_settle_timer = GEAR_SETTLE_DURATION
		else:
			current_speed = move_toward(current_speed, 0.0, (braking_friction * 0.35) * delta)

