class_name PursuerPrototype
extends CharacterBody3D

# Pursuer Prototype Threat Entity for Echos in the Scrap (V8 M03)
# Physical pursuit steering with authored Signal Gate detours, bounded observable
# target-velocity interception, graceful de-escalation, and deterministic reset.

signal intercepted_target
signal de_escalation_started
signal de_escalation_completed
signal pursuer_rammed(ram_speed: float, impact_pos: Vector3)
signal stun_recovered

enum PursuerState {
	INACTIVE,
	CHASING,
	DETOURING,
	DE_ESCALATING,
	EVADED_DISENGAGED,
	STUNNED
}

@export var max_speed: float = 15.5
@export var acceleration: float = 14.0
@export var steering_speed: float = 4.0
@export var intercept_distance: float = 1.5
@export var stun_recovery_time: float = 3.5
@export var ram_threshold_speed: float = 4.5

# CTW Feel 06 — destination-only A/B. These values never retune motion authority.
# The lead uses current observable velocity only and collapses toward the direct
# chase baseline at low target speed / close range.
@export var bounded_intercept_enabled: bool = true
@export var intercept_lead_horizon_min: float = 0.15
@export var intercept_lead_horizon_max: float = 0.45
@export var intercept_lead_distance_cap: float = 4.0
@export var intercept_prediction_close_range: float = 3.0
@export var intercept_prediction_full_range: float = 15.0
@export var intercept_prediction_min_target_speed: float = 0.75
@export var intercept_prediction_full_target_speed: float = 10.0

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var siren_mesh: MeshInstance3D = get_node_or_null("VisualRoot/SirenMesh")
@onready var siren_light: OmniLight3D = get_node_or_null("VisualRoot/SirenLight")

var is_active: bool = false
var current_state: PursuerState = PursuerState.INACTIVE
var target_node: Node3D = null
var current_speed: float = 0.0
var _intercept_timer: float = 0.0
var _de_escalate_timer: float = 0.0
var _de_escalate_turn_target: Vector3 = Vector3.ZERO
var _stun_timer: float = 0.0
var _stun_spin_rate: float = 0.0
var is_stunned: bool:
	get:
		return current_state == PursuerState.STUNNED

var detour_waypoints: Array[Vector3] = []
var current_detour_index: int = -1

func _ready() -> void:
	add_to_group("pursuers")
	visible = false
	current_state = PursuerState.INACTIVE
	set_physics_process(false)

func activate_pursuit(target: Node3D) -> void:
	target_node = target
	is_active = true
	current_state = PursuerState.CHASING
	visible = true
	current_speed = 0.0
	_intercept_timer = 0.0
	_de_escalate_timer = 0.0
	_stun_timer = 0.0
	_stun_spin_rate = 0.0
	if visual_root:
		visual_root.rotation = Vector3.ZERO
	detour_waypoints.clear()
	current_detour_index = -1
	set_physics_process(true)
	if siren_light:
		siren_light.visible = true
		siren_light.light_color = Color(1.0, 0.2, 0.2)
		siren_light.light_energy = 1.0

func start_de_escalation() -> void:
	if not is_active or current_state == PursuerState.INACTIVE:
		return
		
	current_state = PursuerState.DE_ESCALATING
	_de_escalate_timer = 0.0
	_stun_timer = 0.0
	_stun_spin_rate = 0.0
	target_node = null
	detour_waypoints.clear()
	current_detour_index = -1
	_intercept_timer = 0.0
	if visual_root:
		visual_root.rotation = Vector3.ZERO
	
	# Compute retreat vector (continue moving forward-diagonal while slowing down)
	_de_escalate_turn_target = global_position - global_transform.basis.z * 12.0 + Vector3(2.5, 0.0, 0.0)
	
	if siren_light:
		siren_light.light_color = Color(1.0, 0.65, 0.2) # Transition to amber search
		
	de_escalation_started.emit()
	print("[PURSUER] De-escalation started. Transitioning to non-hostile retreat/search...")

func deactivate_pursuit() -> void:
	reset_pursuer()

func reset_pursuer(spawn_pos: Vector3 = Vector3(0, 0.6, -10.0)) -> void:
	is_active = false
	current_state = PursuerState.INACTIVE
	visible = false
	target_node = null
	current_speed = 0.0
	velocity = Vector3.ZERO
	detour_waypoints.clear()
	current_detour_index = -1
	_intercept_timer = 0.0
	_de_escalate_timer = 0.0
	_stun_timer = 0.0
	_stun_spin_rate = 0.0
	if visual_root:
		visual_root.rotation = Vector3.ZERO
	global_position = spawn_pos
	set_physics_process(false)
	if siren_light:
		siren_light.visible = false
		siren_light.light_color = Color(1.0, 0.2, 0.2)
		siren_light.light_energy = 1.0

func apply_vehicle_ram(impact_speed: float, ram_direction: Vector3, _vehicle_source: Node3D = null) -> bool:
	if not is_active or current_state == PursuerState.INACTIVE or current_state == PursuerState.EVADED_DISENGAGED:
		return false
	if impact_speed < ram_threshold_speed:
		return false

	current_state = PursuerState.STUNNED
	_stun_timer = stun_recovery_time
	_intercept_timer = 0.0

	var flat_dir := ram_direction
	flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.001:
		flat_dir = -global_transform.basis.z
	else:
		flat_dir = flat_dir.normalized()

	velocity = flat_dir * (impact_speed * 1.1) + Vector3(0.0, 2.2, 0.0)
	current_speed = flat_dir.dot(velocity)
	_stun_spin_rate = randf_range(8.0, 14.0) * (1.0 if randf() > 0.5 else -1.0)

	if siren_light:
		siren_light.visible = true
		siren_light.light_color = Color(1.0, 0.7, 0.1)
		siren_light.light_energy = 0.4
	if visual_root:
		var tween := create_tween()
		tween.tween_property(visual_root, "rotation:z", deg_to_rad(20.0), 0.1)
		tween.tween_property(visual_root, "rotation:z", deg_to_rad(-12.0), 0.15)
		tween.tween_property(visual_root, "rotation:z", 0.0, 0.25)

	pursuer_rammed.emit(impact_speed, global_position)
	print("[PURSUER] VEHICLE RAM IMPACT! Speed: %.1f m/s. Pursuer STUNNED for %.1fs!" % [impact_speed, stun_recovery_time])
	return true

func apply_emp_stun(duration: float = 4.0) -> bool:
	if not is_active or current_state == PursuerState.INACTIVE or current_state == PursuerState.EVADED_DISENGAGED:
		return false

	current_state = PursuerState.STUNNED
	_stun_timer = duration
	_intercept_timer = 0.0
	velocity = Vector3.ZERO
	current_speed = 0.0
	_stun_spin_rate = 0.0

	if siren_light:
		siren_light.visible = true
		siren_light.light_color = Color(0.1, 0.8, 1.0)
		siren_light.light_energy = 0.6
	if visual_root:
		var tween := create_tween()
		tween.tween_property(visual_root, "rotation:z", deg_to_rad(10.0), 0.08)
		tween.tween_property(visual_root, "rotation:z", deg_to_rad(-10.0), 0.08)
		tween.tween_property(visual_root, "rotation:z", 0.0, 0.12)

	print("[PURSUER] EMP OVERLOAD STUN! Pursuer disabled for %.1fs!" % duration)
	return true

func set_detour_path(waypoints: Array[Vector3]) -> void:
	if current_state == PursuerState.DE_ESCALATING or current_state == PursuerState.EVADED_DISENGAGED or current_state == PursuerState.STUNNED:
		return
		
	detour_waypoints.clear()
	# Filter out any waypoints behind pursuer Z position to prevent 180 deg U-turns
	for wp in waypoints:
		if wp.z > global_position.z:
			detour_waypoints.append(wp)
			
	if detour_waypoints.size() > 0:
		current_state = PursuerState.DETOURING
		current_detour_index = 0
	else:
		current_detour_index = -1
		current_state = PursuerState.CHASING
		
	print("[PURSUER] Detour reroute path set (%d forward waypoints)..." % detour_waypoints.size())

## CTW Feel 06 — pure destination candidate. It has no target input history and
## therefore cannot preserve stale steering intent after a sharp reversal.
func get_bounded_chase_destination(target_position: Vector3, target_velocity: Vector3) -> Vector3:
	var flat_to_target := target_position - global_position
	flat_to_target.y = 0.0
	var target_distance: float = flat_to_target.length()

	var flat_velocity := target_velocity
	flat_velocity.y = 0.0
	var target_speed: float = flat_velocity.length()

	if target_distance <= intercept_prediction_close_range or target_speed <= intercept_prediction_min_target_speed:
		return target_position

	var distance_span: float = maxf(intercept_prediction_full_range - intercept_prediction_close_range, 0.001)
	var speed_span: float = maxf(intercept_prediction_full_target_speed - intercept_prediction_min_target_speed, 0.001)
	var distance_factor: float = clampf((target_distance - intercept_prediction_close_range) / distance_span, 0.0, 1.0)
	var speed_factor: float = clampf((target_speed - intercept_prediction_min_target_speed) / speed_span, 0.0, 1.0)
	var qualification: float = minf(distance_factor, speed_factor)
	if qualification <= 0.0:
		return target_position

	var horizon: float = lerpf(intercept_lead_horizon_min, intercept_lead_horizon_max, qualification)
	# Scaling by qualification lets lead distance approach zero smoothly while the
	# actual horizon remains inside the specified 0.15–0.45 s experiment range.
	var lead_vector: Vector3 = flat_velocity * horizon * qualification
	if lead_vector.length() > intercept_lead_distance_cap:
		lead_vector = lead_vector.normalized() * intercept_lead_distance_cap
	return target_position + lead_vector

## Single destination authority for the active chase. Authored DETOURING waypoints
## always win; prediction only participates in direct CHASING.
func get_navigation_destination() -> Vector3:
	if current_detour_index >= 0 and current_detour_index < detour_waypoints.size():
		return detour_waypoints[current_detour_index]
	if target_node == null:
		return global_position

	var direct_destination: Vector3 = target_node.global_position
	if not bounded_intercept_enabled:
		return direct_destination

	var target_velocity := Vector3.ZERO
	if target_node is CharacterBody3D:
		target_velocity = (target_node as CharacterBody3D).velocity
	return get_bounded_chase_destination(direct_destination, target_velocity)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	# -------------------------------------------------------------------------
	# STATE: STUNNED (Temporarily disabled by weaponized vehicle ram)
	# -------------------------------------------------------------------------
	if current_state == PursuerState.STUNNED:
		_stun_timer -= delta

		# Decelerate knockback horizontally and apply gravity
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if not is_on_floor():
			velocity.y -= 19.6 * delta
		else:
			velocity.y = 0.0

		# Spin out on yaw during initial impact deceleration
		if abs(velocity.x) > 0.5 or abs(velocity.z) > 0.5:
			rotate_y(_stun_spin_rate * delta)
			_stun_spin_rate = move_toward(_stun_spin_rate, 0.0, 4.0 * delta)

		move_and_slide()

		# Glitch strobe on siren light
		if siren_light:
			siren_light.light_energy = 0.8 if int(_stun_timer * 12.0) % 2 == 0 else 0.1

		if _stun_timer <= 0.0:
			_stun_timer = 0.0
			_stun_spin_rate = 0.0
			if siren_light:
				siren_light.light_color = Color(1.0, 0.2, 0.2)
				siren_light.light_energy = 1.0
			if visual_root:
				visual_root.rotation = Vector3.ZERO
			if target_node:
				current_state = PursuerState.CHASING
				print("[PURSUER] Reboot sequence complete. Resuming chase...")
			else:
				current_state = PursuerState.DE_ESCALATING
				start_de_escalation()
			stun_recovered.emit()
		return

	# -------------------------------------------------------------------------
	# STATE: DE-ESCALATING (Non-hostile retreat / search deceleration)
	# -------------------------------------------------------------------------
	if current_state == PursuerState.DE_ESCALATING:
		_de_escalate_timer += delta
		
		# Smoothly decelerate toward search speed (2.5 m/s)
		current_speed = move_toward(current_speed, 2.5, 6.0 * delta)
		
		var to_retreat := _de_escalate_turn_target - global_position
		to_retreat.y = 0.0
		if to_retreat.length() > 0.5:
			var desired_dir := to_retreat.normalized()
			var current_forward := -global_transform.basis.z
			var new_forward := current_forward.slerp(desired_dir, 1.8 * delta).normalized()
			look_at(global_position + new_forward, Vector3.UP)
			
		velocity = -global_transform.basis.z * current_speed
		move_and_slide()
		
		if siren_light:
			siren_light.light_energy = maxf(0.0, 1.0 - (_de_escalate_timer / 2.5))
			
		if _de_escalate_timer >= 2.5:
			current_state = PursuerState.EVADED_DISENGAGED
			current_speed = 0.0
			velocity = Vector3.ZERO
			is_active = false
			visible = false
			set_physics_process(false)
			if siren_light:
				siren_light.visible = false
			de_escalation_completed.emit()
			print("[PURSUER] De-escalation completed. Pursuer safely disengaged.")
		return
		
	# -------------------------------------------------------------------------
	# STATE: CHASING / DETOURING (Active hostile pursuit)
	# -------------------------------------------------------------------------
	if not target_node:
		return
		
	var destination: Vector3 = get_navigation_destination()
	if current_detour_index >= 0 and current_detour_index < detour_waypoints.size():
		if global_position.distance_to(destination) < 3.0:
			current_detour_index += 1
			print("[PURSUER] Detour waypoint reached. Advancing to index %d..." % current_detour_index)
			if current_detour_index >= detour_waypoints.size():
				current_detour_index = -1
				current_state = PursuerState.CHASING
				print("[PURSUER] Detour completed. Resuming direct pursuit...")
				
	var to_target := destination - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	
	if dist > 0.1:
		var desired_dir := to_target.normalized()
		var current_forward := -global_transform.basis.z
		var new_forward := current_forward.slerp(desired_dir, steering_speed * delta).normalized()
		look_at(global_position + new_forward, Vector3.UP)
		
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)
		velocity = -global_transform.basis.z * current_speed
		move_and_slide()
		
	# Hostile interception only possible during active CHASING / DETOURING
	if (current_state == PursuerState.CHASING or current_state == PursuerState.DETOURING) and target_node:
		if global_position.distance_to(target_node.global_position) <= intercept_distance:
			_intercept_timer += delta
			if _intercept_timer >= 0.35:
				_intercept_timer = 0.0
				intercepted_target.emit()
		else:
			_intercept_timer = move_toward(_intercept_timer, 0.0, delta * 2.0)
