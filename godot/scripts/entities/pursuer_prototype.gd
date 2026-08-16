class_name PursuerPrototype
extends CharacterBody3D

# Pursuer Prototype Threat Entity for Echos in the Scrap (V4)
# Direct vector pursuit steering toward active target at 11 m/s

signal intercepted_target

@export var max_speed: float = 11.0
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

func _ready() -> void:
	visible = false
	set_physics_process(false)

func activate_pursuit(target: Node3D) -> void:
	target_node = target
	is_active = true
	visible = true
	current_speed = 0.0
	_intercept_timer = 0.0
	set_physics_process(true)
	if siren_light:
		siren_light.visible = true

func deactivate_pursuit() -> void:
	is_active = false
	visible = false
	target_node = null
	current_speed = 0.0
	velocity = Vector3.ZERO
	set_physics_process(false)
	if siren_light:
		siren_light.visible = false

func _physics_process(delta: float) -> void:
	if not is_active or not target_node:
		return
		
	var target_pos := target_node.global_position
	var to_target := target_pos - global_position
	to_target.y = 0.0 # Maintain ground plane
	var dist := to_target.length()
	
	if dist > 0.1:
		var desired_dir := to_target.normalized()
		var current_forward := -global_transform.basis.z
		var new_forward := current_forward.slerp(desired_dir, steering_speed * delta).normalized()
		look_at(global_position + new_forward, Vector3.UP)
		
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)
		velocity = -global_transform.basis.z * current_speed
		move_and_slide()
		
	# Intercept check (~1.5m for 0.35s)
	if dist <= intercept_distance:
		_intercept_timer += delta
		if _intercept_timer >= 0.35:
			_intercept_timer = 0.0
			intercepted_target.emit()
	else:
		_intercept_timer = move_toward(_intercept_timer, 0.0, delta * 2.0)
