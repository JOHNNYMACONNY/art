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
signal vehicle_feedback_updated(telemetry: Dictionary, vehicle_pos: Vector3)

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
@onready var visual_root: Node3D = $VisualRoot
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
var _feedback_throttle: float = 0.0
var _feedback_audio_manager: Node = null
var _feedback_active: bool = false
var _slip_dust: GPUParticles3D = null
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
	_ensure_slip_dust()
	_ensure_condition_presentation()
	_refresh_condition_presentation()

func _physics_process(delta: float) -> void:
	if _brake_screech_cooldown > 0.0:
		_brake_screech_cooldown -= delta
	if _condition_contact_cooldown > 0.0:
		_condition_contact_cooldown = maxf(_condition_contact_cooldown - delta, 0.0)
		
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
				
			# Subtle arcade lean into turn when steering (up to 12 degrees)
			if visual_root:
				var target_lean := -steering_angle * clampf(abs(current_speed) / 5.0, 0.0, 1.0) * deg_to_rad(12.0)
				visual_root.rotation.z = lerpf(visual_root.rotation.z, target_lean, delta * 10.0)
				
			# 2. Arcade Lateral Grip & Drift Slip Model (Decoupled Heading & Velocity)
			var forward_dir: Vector3 = -global_transform.basis.z
			var right_dir: Vector3 = global_transform.basis.x
			
			var current_lateral_vel: float = velocity.dot(right_dir)
			var grip_rate: float = 1.8 if is_handbrake_active else 10.0
			var decay_factor: float = 1.0 - exp(-grip_rate * delta)
			var new_lateral_vel: float = lerpf(current_lateral_vel, 0.0, decay_factor)
			if current_speed > get_usable_max_speed():
				current_speed = get_usable_max_speed()
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
						var pre_impact_speed: float = abs(current_speed)
						var impact_decay: float = lerpf(2.0, 32.0, head_on_ratio * head_on_ratio)
						current_speed = move_toward(current_speed, 0.0, impact_decay * delta)
						apply_collision_condition(head_on_ratio, pre_impact_speed)
						collision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())
						
		_update_vehicle_feedback_presentation()
		
		if occupant:
			occupant.global_position = to_global(rider_socket.position)
			occupant.global_basis = global_basis
			occupant.velocity = Vector3.ZERO
			occupant.is_input_locked = true
	else:
		_clear_vehicle_feedback_presentation()

func _process(_delta: float) -> void:
	if occupant:
		occupant.global_position = to_global(rider_socket.position)
		occupant.global_basis = global_basis

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
	player.set_mounted_posture(true)
	player.global_position = to_global(rider_socket.position)
	player.global_basis = global_basis
	var p_col := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if p_col: p_col.set_deferred("disabled", true)
	
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
	_clear_vehicle_feedback_presentation()
	
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
		current_state = BikeState.PARKED
		state_changed.emit("PARKED")
		dismounted.emit()
	)
	return true

func force_dismount() -> void:
	_clear_vehicle_feedback_presentation()
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
	_feedback_throttle = 0.0
	_gear_settle_timer = 0.0
	if visual_root: visual_root.rotation = Vector3.ZERO
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
	_feedback_throttle = clampf(throttle, -1.0, 1.0)
	
	if current_gear == GearState.FORWARD:
		if throttle > 0.0:
			_gear_settle_timer = 0.0
			current_speed = clampf(current_speed + acceleration * throttle * delta, 0.0, get_usable_max_speed())
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

## CTW Feel 04 — observation-only presentation telemetry. This reads the state
## already produced by the handling model and never mutates physics values.
func get_vehicle_feedback_telemetry(throttle: float = _feedback_throttle) -> Dictionary:
	var speed_abs: float = abs(current_speed)
	var speed_ratio: float = clampf(speed_abs / maxf(max_speed, 0.001), 0.0, 1.0)
	var right_dir: Vector3 = global_transform.basis.x.normalized()
	var lateral_speed: float = abs(velocity.dot(right_dir))
	var slip_ratio: float = clampf(lateral_speed / maxf(speed_abs, 2.0), 0.0, 1.0)
	var load_ratio: float = clampf(abs(throttle), 0.0, 1.0)
	var braking: bool = (
		(current_gear == GearState.FORWARD and throttle < -0.05 and current_speed > 0.05)
		or (current_gear == GearState.REVERSE and throttle > 0.05 and current_speed < -0.05)
	)
	var traction_state := "STABLE"
	if is_handbrake_active and speed_abs >= 2.0 and slip_ratio >= 0.24:
		traction_state = "FULL_SLIP"
	elif slip_ratio >= 0.12:
		traction_state = "NEAR_SLIP"
	var slip_intensity: float = clampf((slip_ratio - 0.08) / 0.35, 0.0, 1.0)
	if braking and slip_ratio > 0.05:
		slip_intensity = clampf(slip_intensity + 0.14, 0.0, 1.0)
	if traction_state == "FULL_SLIP":
		slip_intensity = maxf(slip_intensity, 0.78)
	return {
		"speed_ratio": speed_ratio,
		"load_ratio": load_ratio,
		"lateral_speed": lateral_speed,
		"slip_ratio": slip_ratio,
		"slip_intensity": slip_intensity,
		"traction_state": traction_state,
		"handbrake": is_handbrake_active,
		"braking": braking,
	}

func get_vehicle_feedback_visual_snapshot() -> Dictionary:
	return {
		"dust_available": _slip_dust != null,
		"dust_emitting": _slip_dust.emitting if _slip_dust else false,
		"dust_amount": _slip_dust.amount if _slip_dust else 0,
		"dust_position": _slip_dust.position if _slip_dust else Vector3.ZERO,
	}

func _update_vehicle_feedback_presentation() -> void:
	var telemetry := get_vehicle_feedback_telemetry()
	vehicle_feedback_updated.emit(telemetry, global_position)
	_feedback_active = true
	_update_slip_dust(telemetry)

	if not is_instance_valid(_feedback_audio_manager):
		_feedback_audio_manager = get_tree().get_first_node_in_group("audio_manager")
	if _feedback_audio_manager and _feedback_audio_manager.has_method("update_vehicle_feedback"):
		_feedback_audio_manager.call("update_vehicle_feedback", telemetry, global_position)

func _clear_vehicle_feedback_presentation() -> void:
	if _slip_dust:
		_slip_dust.emitting = false
	if not _feedback_active:
		return
	_feedback_active = false
	_feedback_throttle = 0.0
	if is_instance_valid(_feedback_audio_manager) and _feedback_audio_manager.has_method("clear_vehicle_feedback"):
		_feedback_audio_manager.call("clear_vehicle_feedback")

func _ensure_slip_dust() -> void:
	if _slip_dust:
		return
	_slip_dust = GPUParticles3D.new()
	_slip_dust.name = "SlipDustParticles"
	_slip_dust.position = Vector3(0.0, -0.34, 0.72)
	_slip_dust.amount = 12
	_slip_dust.lifetime = 0.48
	_slip_dust.randomness = 0.35
	_slip_dust.emitting = false
	_slip_dust.visibility_aabb = AABB(Vector3(-2.5, -1.0, -2.5), Vector3(5.0, 3.0, 5.0))

	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.0, 0.25, 1.0)
	process_material.spread = 32.0
	process_material.initial_velocity_min = 1.2
	process_material.initial_velocity_max = 2.6
	process_material.gravity = Vector3(0.0, -0.7, 0.0)
	process_material.scale_min = 0.10
	process_material.scale_max = 0.24
	process_material.color = Color(0.48, 0.41, 0.31, 0.48)
	_slip_dust.process_material = process_material

	var quad := QuadMesh.new()
	quad.size = Vector2(0.24, 0.24)
	var dust_material := StandardMaterial3D.new()
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_material.albedo_color = Color(0.52, 0.45, 0.34, 0.42)
	quad.material = dust_material
	_slip_dust.draw_pass_1 = quad
	add_child(_slip_dust)

func _update_slip_dust(telemetry: Dictionary) -> void:
	if not _slip_dust:
		return
	var traction_state: String = String(telemetry.get("traction_state", "STABLE"))
	var slip_intensity: float = clampf(float(telemetry.get("slip_intensity", 0.0)), 0.0, 1.0)
	var should_emit: bool = traction_state == "NEAR_SLIP" or traction_state == "FULL_SLIP"
	_slip_dust.emitting = should_emit
	if should_emit:
		_slip_dust.amount = 18 if traction_state == "FULL_SLIP" else 10
		_slip_dust.speed_scale = lerpf(0.85, 1.25, slip_intensity)


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
		_condition_tag.position = Vector3(0.0, 1.35, 0.15)
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
		_condition_smoke.position = Vector3(0.0, 0.30, -0.12)
		_condition_smoke.amount = 6
		_condition_smoke.lifetime = 0.85
		_condition_smoke.randomness = 0.45
		_condition_smoke.emitting = false
		_condition_smoke.visibility_aabb = AABB(Vector3(-2.5, -1.0, -2.5), Vector3(5.0, 4.0, 5.0))
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
