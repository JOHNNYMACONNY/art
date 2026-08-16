class_name CourierBike
extends CharacterBody3D

# Courier Bike Vehicle Controller for Echos in the Scrap
# State machine: PARKED -> MOUNTING -> DRIVING -> DISMOUNTING

signal state_changed(new_state: String)
signal mounted(player: PlayerRunner)
signal dismounted

enum BikeState {
	PARKED,
	MOUNTING,
	DRIVING,
	DISMOUNTING
}

@export var max_speed: float = 14.0
@export var acceleration: float = 12.0
@export var braking_friction: float = 18.0
@export var steering_speed: float = 2.5
@export var dismount_speed_limit: float = 1.5

@onready var rider_socket: Node3D = $RiderSocket
@onready var mount_interactable: InteractableBase = $MountInteractable
@onready var bike_mesh: MeshInstance3D = $VisualRoot/BikeMesh
@onready var outline_mesh: MeshInstance3D = $VisualRoot/OutlineMesh

var current_state: BikeState = BikeState.PARKED
var occupant: PlayerRunner = null
var current_speed: float = 0.0
var steering_angle: float = 0.0

func _ready() -> void:
	if mount_interactable:
		mount_interactable.interaction_priority = 2.0 # High interaction priority
		mount_interactable.is_powered = true

func _physics_process(delta: float) -> void:
	if current_state == BikeState.DRIVING:
		# Arcade bike motion
		if abs(steering_angle) > 0.01:
			rotate_y(-steering_angle * steering_speed * delta)
			
		var forward_dir := -global_transform.basis.z
		velocity = forward_dir * current_speed
		move_and_slide()

func can_mount(player: PlayerRunner) -> bool:
	return current_state == BikeState.PARKED and occupant == null and mount_interactable.is_player_in_range

func request_mount(player: PlayerRunner) -> bool:
	if not can_mount(player):
		return false
		
	current_state = BikeState.MOUNTING
	occupant = player
	state_changed.emit("MOUNTING")
	
	player.is_input_locked = true
	player.global_position = rider_socket.global_position
	player.rotation = rotation
	
	if mount_interactable:
		mount_interactable.is_powered = false # Disable mount prompt while occupied
		
	get_tree().create_timer(0.25).timeout.connect(func():
		current_state = BikeState.DRIVING
		state_changed.emit("DRIVING")
		mounted.emit(player)
	)
	return true

func request_dismount() -> bool:
	if current_state != BikeState.DRIVING or current_speed > dismount_speed_limit:
		return false
		
	current_state = BikeState.DISMOUNTING
	state_changed.emit("DISMOUNTING")
	
	if occupant:
		var safe_offset := global_position + (global_transform.basis.x * 1.4)
		occupant.global_position = safe_offset
		occupant.is_input_locked = false
		var prev_player := occupant
		occupant = null
		
	if mount_interactable:
		mount_interactable.is_powered = true
		
	current_speed = 0.0
	velocity = Vector3.ZERO
	current_state = BikeState.PARKED
	state_changed.emit("PARKED")
	dismounted.emit()
	return true

func set_drive_inputs(throttle: float, steering: float, delta: float) -> void:
	if current_state != BikeState.DRIVING:
		return
		
	steering_angle = clamp(steering, -1.0, 1.0)
	
	if throttle > 0.0:
		current_speed = clamp(current_speed + acceleration * throttle * delta, 0.0, max_speed)
	elif throttle < 0.0:
		current_speed = clamp(current_speed + braking_friction * throttle * delta, 0.0, max_speed)
	else:
		current_speed = move_toward(current_speed, 0.0, braking_friction * 0.5 * delta)
