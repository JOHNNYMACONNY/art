class_name ScrapHauler
extends CharacterBody3D

# Scrap Hauler Vehicle Controller (Full-Size 4-Wheel Escape Class)
# Heavier inertia, slower rotation rate, planted high-speed stability, wider drift arc,
# and GTA-family responsive reverse & glance collision mechanics.

enum DismountRejectReason {
	TOO_FAST,
	NO_SAFE_POSITION
}

enum GearState {
	FORWARD,
	REVERSE
}

enum VehicleCondition {
	ROADWORTHY,
	BATTERED,
	CRITICAL
}

signal state_changed(new_state: String)
signal mounted(player: PlayerRunner)
signal dismounted
signal brake_screech_triggered(pos: Vector3)
signal dismount_rejected(reason: DismountRejectReason, current_speed: float, speed_limit: float)
signal collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3)
signal condition_changed(condition_name: String)

enum VehicleState {
	PARKED,
	MOUNTING,
	DRIVING,
	DISMOUNTING
}

@export var max_speed: float = 15.5
@export var max_reverse_speed: float = -3.5
@export var acceleration: float = 8.5
@export var braking_friction: float = 12.0
@export var steering_speed: float = 1.8
@export var dismount_speed_limit: float = 1.5

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
var _condition: VehicleCondition = VehicleCondition.ROADWORTHY
var _condition_load: float = 0.0
var _condition_contact_cooldown: float = 0.0
var _condition_smoke: GPUParticles3D = null
var _condition_tag: Label3D = null
const GEAR_SETTLE_DURATION: float = 0.12
const CONDITION_MIN_IMPACT_SPEED: float = 4.0
const CONDITION_CONTACT_COOLDOWN_SECONDS: float = 0.50
const CONDITION_BATTERED_LOAD: float = 0.75
const CONDITION_CRITICAL_LOAD: float = 1.50
const CONDITION_MAX_LOAD: float = 1.50
const CRITICAL_SPEED_MULTIPLIER: float = 0.52

func _ready() -> void:
	if mount_interactable:
		mount_interactable.interaction_priority = 2.0
		mount_interactable.is_powered = true
	_ensure_condition_presentation()
	_refresh_condition_presentation()

func _process(_delta: float) -> void:
	if occupant:
		occupant.global_position = to_global(rider_socket.position)
		occupant.global_basis = global_basis

func _physics_process(delta: float) -> void:
	if _brake_screech_cooldown > 0.0:
		_brake_screech_cooldown -= delta
	if _condition_contact_cooldown > 0.0:
		_condition_contact_cooldown = maxf(_condition_contact_cooldown - delta, 0.0)
		
	if current_state == VehicleState.DRIVING or current_state == VehicleState.MOUNTING:
		if current_state == VehicleState.DRIVING:
			# 1. Car-scale Speed-sensitive steering yaw rate (heavier, slower yaw rotation)
			var speed_ratio: float = clampf(abs(current_speed) / max_speed, 0.0, 1.0)
			var steer_rate: float = lerp(2.2, 0.9, speed_ratio)
			if is_handbrake_active:
				steer_rate *= 1.5
				
			if abs(steering_angle) > 0.01 and abs(current_speed) > 0.1:
				var steer_sign: float = 1.0 if current_speed >= -0.05 else -1.0
				rotate_y(-steering_angle * steer_rate * steer_sign * delta)
				
			# Subtle chassis body roll into corners
			if visual_root:
				var target_roll := -steering_angle * clampf(abs(current_speed) / 6.0, 0.0, 1.0) * deg_to_rad(6.0)
				visual_root.rotation.z = lerpf(visual_root.rotation.z, target_roll, delta * 8.0)
				
			# 2. Heavy Lateral Grip & Drift Slip Model (Decoupled Heading & Velocity)
			var forward_dir: Vector3 = -global_transform.basis.z
			var right_dir: Vector3 = global_transform.basis.x
			
			var current_lateral_vel: float = velocity.dot(right_dir)
			var grip_rate: float = 3.5 if is_handbrake_active else 14.0
			var decay_factor: float = 1.0 - exp(-grip_rate * delta)
			var new_lateral_vel: float = lerpf(current_lateral_vel, 0.0, decay_factor)
			if current_speed > get_usable_max_speed():
				current_speed = get_usable_max_speed()
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
						var impact_decay: float = lerpf(1.5, 28.0, head_on_ratio * head_on_ratio)
						current_speed = move_toward(current_speed, 0.0, impact_decay * delta)
						apply_collision_condition(head_on_ratio, pre_impact_speed)
						collision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())
						
		if occupant:
			occupant.global_position = to_global(rider_socket.position)
			occupant.global_basis = global_basis
			occupant.velocity = Vector3.ZERO
			occupant.is_input_locked = true

func can_mount(player: PlayerRunner) -> bool:
	return current_state == VehicleState.PARKED and occupant == null and mount_interactable.is_player_in_range

func request_mount(player: PlayerRunner) -> bool:
	if not can_mount(player):
		return false
		
	current_state = VehicleState.MOUNTING
	occupant = player
	state_changed.emit("MOUNTING")
	
	player.is_input_locked = true
	player.velocity = Vector3.ZERO
	player.set_mounted_posture(true)
	player.global_position = to_global(rider_socket.position)
	player.global_basis = global_basis
	var p_col := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if p_col: p_col.set_deferred("disabled", true)
	
	if mount_interactable:
		mount_interactable.is_powered = false
		
	get_tree().create_timer(0.25).timeout.connect(func():
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
		print("[HAULER] Dismount rejected: No volume-cleared dismount offset found!")
		dismount_rejected.emit(DismountRejectReason.NO_SAFE_POSITION, current_speed, dismount_speed_limit)
		return false
		
	current_state = VehicleState.DISMOUNTING
	state_changed.emit("DISMOUNTING")
	
	if mount_interactable:
		mount_interactable.is_powered = false
		
	get_tree().create_timer(0.2).timeout.connect(func():
		if occupant:
			var p_col := occupant.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if p_col: p_col.set_deferred("disabled", false)
			occupant.set_mounted_posture(false)
			occupant.global_position = safe_pos
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
	if occupant:
		var p_col := occupant.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if p_col: p_col.set_deferred("disabled", false)
		occupant.set_mounted_posture(false)
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
		return global_position + (global_transform.basis.x * 2.0)
		
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	
	var offsets := [
		global_transform.basis.x * 1.8,   # Left side door
		-global_transform.basis.x * 1.8,  # Right side door
		global_transform.basis.z * 2.4,   # Rear tailgate
		-global_transform.basis.z * 2.4   # Front hood
	]
	
	for offset in offsets:
		var test_pos: Vector3 = global_position + offset + Vector3(0, 0.8, 0)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, test_pos)
		query.exclude = [get_rid()]
		
		var hits := space_state.intersect_shape(query, 1)
		if hits.is_empty():
			return test_pos - Vector3(0, 0.8, 0)
			
	return Vector3.INF

func set_drive_inputs(throttle: float, steer: float, delta: float, handbrake: bool = false) -> void:
	if current_state != VehicleState.DRIVING:
		return
		
	steering_angle = steer
	is_handbrake_active = handbrake
	
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
			current_speed = move_toward(current_speed, get_usable_max_speed(), acceleration * throttle * delta)
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
			current_speed = move_toward(current_speed, max_reverse_speed, (acceleration * 0.7) * abs(throttle) * delta)
		elif throttle > 0.01:
			current_speed = move_toward(current_speed, 0.0, braking_friction * throttle * delta)
			if abs(current_speed) < 0.1:
				current_speed = 0.0
				current_gear = GearState.FORWARD
				_gear_settle_timer = GEAR_SETTLE_DURATION
		else:
			current_speed = move_toward(current_speed, 0.0, (braking_friction * 0.35) * delta)


## Burnside Production 07 — coarse, local vehicle consequence. The internal load
## is diagnostic/accumulation state only; the player-facing model remains the
## three-state ROADWORTHY/BATTERED/CRITICAL contract.
func get_condition_name() -> String:
	return VehicleCondition.keys()[_condition]

func get_condition_load() -> float:
	return _condition_load

func get_usable_max_speed() -> float:
	return max_speed * CRITICAL_SPEED_MULTIPLIER if _condition == VehicleCondition.CRITICAL else max_speed

func apply_collision_condition(head_on_ratio: float, impact_speed: float) -> bool:
	if impact_speed < CONDITION_MIN_IMPACT_SPEED or _condition_contact_cooldown > 0.0:
		return false
	var speed_severity := clampf((impact_speed - 3.5) / 7.5, 0.0, 1.0)
	var direction_weight := lerpf(0.50, 1.0, clampf(head_on_ratio, 0.0, 1.0))
	var load_delta := speed_severity * direction_weight
	if load_delta <= 0.0:
		return false
	_condition_load = minf(_condition_load + load_delta, CONDITION_MAX_LOAD)
	_condition_contact_cooldown = CONDITION_CONTACT_COOLDOWN_SECONDS
	_refresh_condition_state()
	return true

func repair_condition() -> bool:
	if _condition == VehicleCondition.ROADWORTHY:
		return false
	_condition_load = 0.0
	_condition_contact_cooldown = 0.0
	_set_condition(VehicleCondition.ROADWORTHY)
	return true

func reset_condition() -> void:
	_condition_load = 0.0
	_condition_contact_cooldown = 0.0
	_set_condition(VehicleCondition.ROADWORTHY)

func get_condition_presentation_snapshot() -> Dictionary:
	return {
		"condition": get_condition_name(),
		"damage_tag_visible": _condition_tag.visible if _condition_tag else false,
		"damage_tag_text": _condition_tag.text if _condition_tag else "",
		"smoke_emitting": _condition_smoke.emitting if _condition_smoke else false,
		"smoke_amount": _condition_smoke.amount if _condition_smoke else 0,
	}

func _refresh_condition_state() -> void:
	var next_condition := VehicleCondition.ROADWORTHY
	if _condition_load >= CONDITION_CRITICAL_LOAD:
		next_condition = VehicleCondition.CRITICAL
	elif _condition_load >= CONDITION_BATTERED_LOAD:
		next_condition = VehicleCondition.BATTERED
	_set_condition(next_condition)

func _set_condition(next_condition: VehicleCondition) -> void:
	var changed := next_condition != _condition
	_condition = next_condition
	if _condition == VehicleCondition.CRITICAL and current_speed > get_usable_max_speed():
		current_speed = get_usable_max_speed()
	_refresh_condition_presentation()
	if changed:
		condition_changed.emit(get_condition_name())

func _ensure_condition_presentation() -> void:
	if _condition_tag == null:
		_condition_tag = Label3D.new()
		_condition_tag.name = "VehicleConditionTag"
		_condition_tag.position = Vector3(0.0, 1.85, 0.15)
		_condition_tag.font_size = 22
		_condition_tag.outline_size = 7
		_condition_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_condition_tag.modulate = Color(0.92, 0.78, 0.38, 0.95)
		_condition_tag.outline_modulate = Color(0.08, 0.08, 0.07, 0.95)
		_condition_tag.visible = false
		add_child(_condition_tag)

	if _condition_smoke == null:
		_condition_smoke = GPUParticles3D.new()
		_condition_smoke.name = "VehicleConditionSmoke"
		_condition_smoke.position = Vector3(0.0, 0.75, -0.35)
		_condition_smoke.amount = 6
		_condition_smoke.lifetime = 0.85
		_condition_smoke.randomness = 0.45
		_condition_smoke.emitting = false
		_condition_smoke.visibility_aabb = AABB(Vector3(-3.5, -1.0, -4.0), Vector3(7.0, 5.0, 8.0))
		var process_material := ParticleProcessMaterial.new()
		process_material.direction = Vector3(0.0, 1.0, 0.1)
		process_material.spread = 28.0
		process_material.initial_velocity_min = 0.35
		process_material.initial_velocity_max = 0.95
		process_material.gravity = Vector3(0.0, 0.18, 0.0)
		process_material.scale_min = 0.14
		process_material.scale_max = 0.34
		process_material.color = Color(0.14, 0.13, 0.12, 0.42)
		_condition_smoke.process_material = process_material
		var quad := QuadMesh.new()
		quad.size = Vector2(0.32, 0.32)
		var smoke_material := StandardMaterial3D.new()
		smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		smoke_material.albedo_color = Color(0.13, 0.12, 0.11, 0.34)
		quad.material = smoke_material
		_condition_smoke.draw_pass_1 = quad
		add_child(_condition_smoke)

func _refresh_condition_presentation() -> void:
	_ensure_condition_presentation()
	match _condition:
		VehicleCondition.ROADWORTHY:
			_condition_tag.visible = false
			_condition_smoke.emitting = false
		VehicleCondition.BATTERED:
			_condition_tag.text = "BATTERED"
			_condition_tag.visible = true
			_condition_smoke.amount = 6
			_condition_smoke.speed_scale = 0.8
			_condition_smoke.emitting = true
		VehicleCondition.CRITICAL:
			_condition_tag.text = "CRITICAL // LIMP"
			_condition_tag.visible = true
			_condition_smoke.amount = 12
			_condition_smoke.speed_scale = 1.15
			_condition_smoke.emitting = true
