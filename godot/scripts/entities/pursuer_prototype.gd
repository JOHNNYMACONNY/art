class_name PursuerPrototype
extends CharacterBody3D

# Pursuer Prototype Threat Entity for Echos in the Scrap (V5.1)
# Direct vector pursuit steering toward active target with detour waypoint rerouting

signal intercepted_target

@export var max_speed: float = 15.5
@export var acceleration: float = 14.0
@export var steering_speed: float = 4.0
@export var intercept_distance: float = 1.5

@onready var visual_root: Node3D = $VisualRoot
@onready var siren_mesh: MeshInstance3D = $VisualRoot/SirenMesh
@onready var siren_light: OmniLight3D = $VisualRoot/SirenLight

var is_active: bool = false
var target_node: Node3D = null
var current_speed: float = 0.0
var _intercept_timer: float = 0.0

var detour_waypoints: Array[Vector3] = []
var current_detour_index: int = -1

func _ready() -> void:
	visible = false
	set_physics_process(false)

func activate_pursuit(target: Node3D) -> void:
	target_node = target
	is_active = true
	visible = true
	current_speed = 0.0
	_intercept_timer = 0.0
	detour_waypoints.clear()
	current_detour_index = -1
	set_physics_process(true)
	if siren_light:
		siren_light.visible = true

func deactivate_pursuit() -> void:
	is_active = false
	visible = false
	target_node = null
	current_speed = 0.0
	velocity = Vector3.ZERO
	detour_waypoints.clear()
	current_detour_index = -1
	set_physics_process(false)
	if siren_light:
		siren_light.visible = false

func set_detour_path(waypoints: Array[Vector3]) -> void:
	detour_waypoints.clear()
	# Filter out any waypoints behind pursuer Z position to prevent 180 deg U-turns
	for wp in waypoints:
		if wp.z > global_position.z:
			detour_waypoints.append(wp)
			
	current_detour_index = 0 if detour_waypoints.size() > 0 else -1
	print("[PURSUER] Detour reroute path set (%d forward waypoints)..." % detour_waypoints.size())

func _physics_process(delta: float) -> void:
	if not is_active or not target_node:
		return
		
	var destination: Vector3 = target_node.global_position
	if current_detour_index >= 0 and current_detour_index < detour_waypoints.size():
		destination = detour_waypoints[current_detour_index]
		if global_position.distance_to(destination) < 3.0:
			current_detour_index += 1
			print("[PURSUER] Detour waypoint reached. Advancing to index %d..." % current_detour_index)
			if current_detour_index >= detour_waypoints.size():
				current_detour_index = -1
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
		
	if target_node and global_position.distance_to(target_node.global_position) <= intercept_distance:
		_intercept_timer += delta
		if _intercept_timer >= 0.35:
			_intercept_timer = 0.0
			intercepted_target.emit()
	else:
		_intercept_timer = move_toward(_intercept_timer, 0.0, delta * 2.0)
