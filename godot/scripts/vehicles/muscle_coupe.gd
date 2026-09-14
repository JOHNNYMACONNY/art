class_name MuscleCoupe
extends CharacterBody3D

# Muscle Coupe Vehicle Controller (High-Performance Scavenged V8 Muscle Class)
# Responsive acceleration, power oversteer drift, Dan Houser tire screech

signal state_changed(new_state: String)
signal mounted(player: Node3D)
signal dismounted

enum VehicleState {
	PARKED,
	MOUNTING,
	DRIVING,
	DISMOUNTING
}

@export var max_speed: float = 19.5
@export var max_reverse_speed: float = -4.5
@export var acceleration: float = 14.0
@export var braking_friction: float = 14.0
@export var steering_speed: float = 2.4

@onready var visual_root: Node3D = $VisualRoot

var current_state: VehicleState = VehicleState.PARKED
var occupant: Node3D = null
var current_speed: float = 0.0
var steering_angle: float = 0.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if current_state != VehicleState.DRIVING:
		if not is_on_floor():
			velocity.y -= 9.8 * delta
			move_and_slide()
		return

	var throttle: float = Input.get_action_raw_strength("move_up") - Input.get_action_raw_strength("move_down")
	var steer: float = Input.get_action_raw_strength("move_right") - Input.get_action_raw_strength("move_left")

	if occupant and occupant.has_method("set_vehicle_steering"):
		occupant.set_vehicle_steering(steer)

	if throttle > 0.0:
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)
	elif throttle < 0.0:
		current_speed = move_toward(current_speed, max_reverse_speed, braking_friction * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, 6.0 * delta)

	if abs(current_speed) > 0.1:
		rotate_y(-steer * steering_speed * delta * sign(current_speed))

	var forward_dir: Vector3 = -transform.basis.z
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
