class_name CourierBike
extends CharacterBody3D

# Courier Bike Vehicle Controller for Echos in the Scrap
# Features rider binding, volume-cleared dismount query, arcade reverse mechanics, and brake screech SFX

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

enum BikeState {
	PARKED,
	MOUNTING,
	DRIVING,
	DISMOUNTING
}

@export var max_speed: float = 14.0
@export var max_reverse_speed: float = -4.0
@export var acceleration: float = 12.0
@export var braking_friction: float = 18.0
@export var steering_speed: float = 2.5
@export var dismount_speed_limit: float = 1.5

@onready var rider_socket: Node3D = $RiderSocket
@onready var mount_interactable: InteractableBase = $MountInteractable
@onready var bike_mesh: MeshInstance3D = $VisualRoot/BikeMesh
@onready var outline_mesh: MeshInstance3D = $VisualRoot/OutlineMesh

var current_state: BikeState = BikeState.PARKED
var current_gear: GearState = GearState.FORWARD
var occupant: PlayerRunner = null
var current_speed: float = 0.0
var steering_angle: float = 0.0
var is_handbrake_active: bool = false
var _brake_screech_cooldown: float = 0.0
var _gear_settle_timer: float = 0.0
const GEAR_SETTLE_DURATION: float = 0.12

func _ready() -> void:
	if mount_interactable:
		mount_interactable.interaction_priority = 2.0
		mount_interactable.is_powered = true

func _physics_process(delta: float) -> void:
	if _brake_screech_cooldown > 0.0:
		_brake_screech_cooldown -= delta
		
	if current_state == BikeState.DRIVING or current_state == BikeState.MOUNTING:
		if current_state == BikeState.DRIVING:
			# 1. Speed-sensitive steering yaw rate (high agility at low speed, stability at top speed)
			var speed_ratio: float = clampf(abs(current_speed) / max_speed, 0.0, 1.0)
			var steer_rate: float = lerp(3.6, 1.35, speed_ratio)
			if is_handbrake_active:
				steer_rate *= 1.75 # Powerslide yaw agility
				
			if abs(steering_angle) > 0.01 and abs(current_speed) > 0.1:
				var steer_sign: float = 1.0 if current_speed >= -0.05 else -1.0
				rotate_y(-steering_angle * steer_rate * steer_sign * delta)
				
			# 2. Arcade Lateral Grip & Drift Slip Model (Decoupled Heading & Velocity)
			var forward_dir: Vector3 = -global_transform.basis.z
			var right_dir: Vector3 = global_transform.basis.x
			
			var current_lateral_vel: float = velocity.dot(right_dir)
			var grip_rate: float = 1.8 if is_handbrake_active else 10.0
			var decay_factor: float = 1.0 - exp(-grip_rate * delta)
			var new_lateral_vel: float = lerpf(current_lateral_vel, 0.0, decay_factor)
			var new_forward_vel: float = current_speed
			
			velocity = (forward_dir * new_forward_vel) + (right_dir * new_lateral_vel)
			if velocity.length() > max_speed:
				velocity = velocity.normalized() * max_speed
			move_and_slide()
			
			# 3. GTA-style Glance Collision Response (Glancing impacts slide along tangent; head-on sheds speed)
			if get_slide_collision_count() > 0:
				for i in range(get_slide_collision_count()):
					var col := get_slide_collision(i)
					var normal := col.get_normal()
					if abs(normal.y) < 0.5: # Vertical wall/obstacle
						var head_on_ratio: float = abs(forward_dir.dot(normal))
						var impact_decay: float = lerpf(2.0, 32.0, head_on_ratio * head_on_ratio)
						current_speed = move_toward(current_speed, 0.0, impact_decay * delta)
						
		if occupant:
			occupant.global_position = rider_socket.global_position
			occupant.global_transform = rider_socket.global_transform
			occupant.velocity = Vector3.ZERO
			occupant.is_input_locked = true

func can_mount(player: PlayerRunner) -> bool:
	return current_state == BikeState.PARKED and occupant == null and mount_interactable.is_player_in_range

func request_mount(player: PlayerRunner) -> bool:
	if not can_mount(player):
		return false
		
	current_state = BikeState.MOUNTING
	occupant = player
	state_changed.emit("MOUNTING")
	
	player.is_input_locked = true
	player.velocity = Vector3.ZERO
	player.global_position = rider_socket.global_position
	player.global_transform = rider_socket.global_transform
	var p_col := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if p_col: p_col.disabled = true
	
	if mount_interactable:
		mount_interactable.is_powered = false
		
	get_tree().create_timer(0.25).timeout.connect(func():
		if current_state == BikeState.MOUNTING:
			current_state = BikeState.DRIVING
			state_changed.emit("DRIVING")
			mounted.emit(player)
	)
	return true

func request_dismount() -> bool:
	if current_state != BikeState.DRIVING:
		return false

	if abs(current_speed) > dismount_speed_limit:
		dismount_rejected.emit(DismountRejectReason.TOO_FAST, current_speed, dismount_speed_limit)
		return false
		
	var safe_pos := _find_safe_dismount_position()
	if safe_pos == Vector3.INF:
		print("[BIKE] Dismount rejected: No volume-cleared dismount offset found!")
		dismount_rejected.emit(DismountRejectReason.NO_SAFE_POSITION, current_speed, dismount_speed_limit)
		return false
		
	current_state = BikeState.DISMOUNTING
	state_changed.emit("DISMOUNTING")
	
	if mount_interactable:
		mount_interactable.is_powered = false
		
	get_tree().create_timer(0.2).timeout.connect(func():
		if occupant:
			var p_col := occupant.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if p_col: p_col.disabled = false
			occupant.global_position = safe_pos
			occupant.is_input_locked = false
			occupant.velocity = Vector3.ZERO
			occupant = null
			
		if mount_interactable:
			mount_interactable.is_powered = true
			
		current_speed = 0.0
		velocity = Vector3.ZERO
		current_state = BikeState.PARKED
		state_changed.emit("PARKED")
		dismounted.emit()
	)
	return true

func force_dismount() -> void:
	if occupant:
		var p_col := occupant.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if p_col: p_col.disabled = false
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
	current_state = BikeState.PARKED
	state_changed.emit("PARKED")
	dismounted.emit()

func _find_safe_dismount_position() -> Vector3:
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return global_position + (global_transform.basis.x * 1.4)
		
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.4
	
	var candidates: Array[Vector3] = [
		global_position + (global_transform.basis.x * 1.4),
		global_position - (global_transform.basis.x * 1.4),
		global_position + (global_transform.basis.z * 1.4)
	]
	
	for cand in candidates:
		var ray_query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.5, 0), cand + Vector3(0, 0.5, 0))
		ray_query.exclude = [get_rid()]
		if occupant:
			ray_query.exclude.append(occupant.get_rid())
		var ray_res := space_state.intersect_ray(ray_query)
		if not ray_res.is_empty():
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
			if collider and collider.name != "Floor":
				is_blocked = true
				break
				
		if not is_blocked:
			return cand
			
	return Vector3.INF

func set_drive_inputs(throttle: float, steering: float, delta: float, handbrake: bool = false) -> void:
	if current_state != BikeState.DRIVING:
		return
		
	steering_angle = clampf(steering, -1.0, 1.0)
	is_handbrake_active = handbrake
	
	if current_gear == GearState.FORWARD:
		if throttle > 0.0:
			_gear_settle_timer = 0.0
			current_speed = clampf(current_speed + acceleration * throttle * delta, 0.0, max_speed)
		elif throttle < 0.0:
			if current_speed > 0.05:
				if current_speed > 6.0 and _brake_screech_cooldown <= 0.0:
					_brake_screech_cooldown = 1.0
					brake_screech_triggered.emit(global_position)
				current_speed = move_toward(current_speed, 0.0, braking_friction * delta)
				_gear_settle_timer = 0.0
			else:
				current_speed = 0.0
				_gear_settle_timer += delta
				if _gear_settle_timer >= GEAR_SETTLE_DURATION:
					current_gear = GearState.REVERSE
					_gear_settle_timer = 0.0
		else:
			_gear_settle_timer = 0.0
			var coast_friction := braking_friction * (1.0 if is_handbrake_active else 0.4)
			current_speed = move_toward(current_speed, 0.0, coast_friction * delta)
	elif current_gear == GearState.REVERSE:
		if throttle < 0.0:
			_gear_settle_timer = 0.0
			current_speed = clampf(current_speed - acceleration * 0.5 * delta, max_reverse_speed, 0.0)
		elif throttle > 0.0:
			if current_speed < -0.05:
				current_speed = move_toward(current_speed, 0.0, braking_friction * delta)
				_gear_settle_timer = 0.0
			else:
				current_speed = 0.0
				_gear_settle_timer += delta
				if _gear_settle_timer >= GEAR_SETTLE_DURATION:
					current_gear = GearState.FORWARD
					_gear_settle_timer = 0.0
		else:
			_gear_settle_timer = 0.0
			var coast_friction := braking_friction * (1.0 if is_handbrake_active else 0.5)
			current_speed = move_toward(current_speed, 0.0, coast_friction * delta)
			if is_zero_approx(current_speed):
				current_gear = GearState.FORWARD
