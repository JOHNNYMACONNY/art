class_name PursuerPrototype
extends CharacterBody3D

# Pursuer Prototype Threat Entity for Echos in the Scrap (V8 M03)
# Direct vector pursuit steering toward active target with detour waypoint rerouting,
# graceful de-escalation retreat, and deterministic lifecycle reset.

signal intercepted_target
signal de_escalation_started
signal de_escalation_completed

enum PursuerState {
	INACTIVE,
	CHASING,
	DETOURING,
	DE_ESCALATING,
	EVADED_DISENGAGED
}

@export var max_speed: float = 15.5
@export var acceleration: float = 14.0
@export var steering_speed: float = 4.0
@export var intercept_distance: float = 1.5

@onready var visual_root: Node3D = $VisualRoot
@onready var siren_mesh: MeshInstance3D = $VisualRoot/SirenMesh
@onready var siren_light: OmniLight3D = $VisualRoot/SirenLight

var is_active: bool = false
var current_state: PursuerState = PursuerState.INACTIVE
var target_node: Node3D = null
var current_speed: float = 0.0
var _intercept_timer: float = 0.0
var _de_escalate_timer: float = 0.0
var _de_escalate_turn_target: Vector3 = Vector3.ZERO

var detour_waypoints: Array[Vector3] = []
var current_detour_index: int = -1

func _ready() -> void:
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
	target_node = null
	detour_waypoints.clear()
	current_detour_index = -1
	_intercept_timer = 0.0
	
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
	global_position = spawn_pos
	set_physics_process(false)
	if siren_light:
		siren_light.visible = false
		siren_light.light_color = Color(1.0, 0.2, 0.2)
		siren_light.light_energy = 1.0

func set_detour_path(waypoints: Array[Vector3]) -> void:
	if current_state == PursuerState.DE_ESCALATING or current_state == PursuerState.EVADED_DISENGAGED:
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

func _physics_process(delta: float) -> void:
	if not is_active:
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
		
	var destination: Vector3 = target_node.global_position
	if current_detour_index >= 0 and current_detour_index < detour_waypoints.size():
		destination = detour_waypoints[current_detour_index]
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
