class_name ScrapWorker
extends CharacterBody3D

## ScrapWorker: Human-scale industrial neutral actor for living scrap yard
## Implements deterministic AMBIENT / YIELDING / ALARMED / RECOVERING lifecycle

enum WorkerState {
	AMBIENT,
	YIELDING,
	ALARMED,
	RECOVERING
}

@export var worker_name: String = "Worker"
@export var patrol_waypoints: Array = [
	Vector3(-5.5, 0.05, 1.0),
	Vector3(-6.0, 0.05, -3.0)
]
@export var safe_anchor: Vector3 = Vector3(-6.0, 0.05, 2.5)
@export var move_speed: float = 2.2
@export var alarm_speed: float = 5.0
@export var awareness_radius: float = 3.8

var current_state: WorkerState = WorkerState.AMBIENT
var current_waypoint_idx: int = 0
var _initial_position: Vector3 = Vector3.ZERO
var _initial_rotation_y: float = 0.0
var _anim_time: float = 0.0
var _inspect_timer: float = 0.0
var _yield_timer: float = 0.0
var _clink_cooldown: float = 0.0
var _audio_mgr: AudioManager = null

@onready var mesh_pivot: Node3D = $MeshPivot
@onready var torso_mesh: MeshInstance3D = $MeshPivot/Torso
@onready var helmet_mesh: MeshInstance3D = $MeshPivot/Helmet
@onready var left_arm: Node3D = $MeshPivot/LeftArm
@onready var right_arm: Node3D = $MeshPivot/RightArm
@onready var left_leg: Node3D = $MeshPivot/LeftLeg
@onready var right_leg: Node3D = $MeshPivot/RightLeg
@onready var torch_light: OmniLight3D = $MeshPivot/TorchLight

signal state_changed(new_state: String)
signal yield_triggered(distance: float)
signal alarm_triggered()

func setup_audio(mgr: AudioManager) -> void:
	_audio_mgr = mgr

func _ready() -> void:
	_initial_position = global_position
	_initial_rotation_y = rotation.y
	if patrol_waypoints.is_empty():
		patrol_waypoints.append(_initial_position)
		patrol_waypoints.append(_initial_position + Vector3(0, 0, -3.0))

func reset_actor() -> void:
	current_state = WorkerState.AMBIENT
	current_waypoint_idx = 0
	global_position = _initial_position
	global_position.y = 0.05
	rotation.y = _initial_rotation_y
	velocity = Vector3.ZERO
	_inspect_timer = 0.0
	_yield_timer = 0.0
	_clink_cooldown = 1.2
	_anim_time = 0.0
	visible = true
	_reset_pose()
	if torch_light:
		torch_light.visible = true

func _physics_process(delta: float) -> void:
	_anim_time += delta * 6.0
	_clink_cooldown = maxf(0.0, _clink_cooldown - delta)
	
	match current_state:
		WorkerState.AMBIENT:
			_process_ambient(delta)
		WorkerState.YIELDING:
			_process_yielding(delta)
		WorkerState.ALARMED:
			_process_alarmed(delta)
		WorkerState.RECOVERING:
			_process_recovering(delta)
			
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.05

func check_proximity_threat(threat_pos: Vector3, threat_vel: Vector3) -> void:
	if current_state == WorkerState.ALARMED:
		return
		
	var dist: float = global_position.distance_to(threat_pos)
	if dist < awareness_radius:
		var is_approaching: bool = threat_vel.length() > 1.5
		if is_approaching:
			var to_self: Vector3 = (global_position - threat_pos).normalized()
			var approach_dot: float = threat_vel.normalized().dot(to_self)
			if approach_dot > 0.2 or dist < 2.5:
				_enter_yielding(threat_pos, threat_vel, dist)

func _enter_yielding(threat_pos: Vector3, threat_vel: Vector3, dist: float) -> void:
	current_state = WorkerState.YIELDING
	_yield_timer = 1.2
	state_changed.emit("YIELDING")
	yield_triggered.emit(dist)
	
	# Step perpendicularly away from threat velocity
	var side_dir: Vector3 = threat_vel.normalized().cross(Vector3.UP).normalized()
	var to_self: Vector3 = (global_position - threat_pos).normalized()
	if side_dir.dot(to_self) < 0.0:
		side_dir = -side_dir
		
	velocity = side_dir * 3.0
	if mesh_pivot:
		mesh_pivot.rotation.y = atan2(velocity.x, velocity.z)

func _process_yielding(delta: float) -> void:
	_yield_timer -= delta
	velocity = velocity.move_toward(Vector3.ZERO, 5.0 * delta)
	_animate_walk(0.5)
	if _yield_timer <= 0.0:
		current_state = WorkerState.AMBIENT
		state_changed.emit("AMBIENT")

func trigger_alarm() -> void:
	current_state = WorkerState.ALARMED
	state_changed.emit("ALARMED")
	alarm_triggered.emit()
	if torch_light:
		torch_light.visible = false

func _process_alarmed(delta: float) -> void:
	var target_pos: Vector3 = safe_anchor
	var dist: float = global_position.distance_to(target_pos)
	if dist > 0.5:
		var dir: Vector3 = (target_pos - global_position).normalized()
		velocity = dir * alarm_speed
		if mesh_pivot:
			mesh_pivot.rotation.y = atan2(dir.x, dir.z)
		_animate_walk(1.5)
	else:
		velocity = Vector3.ZERO
		_crouch_pose()

func _process_ambient(delta: float) -> void:
	if _inspect_timer > 0.0:
		_inspect_timer -= delta
		velocity = Vector3.ZERO
		_inspect_pose(delta)
		if _clink_cooldown <= 0.0:
			_clink_cooldown = 1.2
			if _audio_mgr:
				_audio_mgr.play_event(AudioManager.SoundEvent.AMBIENT_WORK_CLINK, global_position)
		return
		
	var target: Vector3 = patrol_waypoints[current_waypoint_idx]
	var dist: float = global_position.distance_to(target)
	if dist < 0.6:
		_inspect_timer = 2.5 # Inspect scrap pile for 2.5s
		current_waypoint_idx = (current_waypoint_idx + 1) % patrol_waypoints.size()
		velocity = Vector3.ZERO
		if _clink_cooldown <= 0.0:
			_clink_cooldown = 1.2
			if _audio_mgr:
				_audio_mgr.play_event(AudioManager.SoundEvent.AMBIENT_WORK_CLINK, global_position)
		return
		
	var dir: Vector3 = (target - global_position).normalized()
	velocity = dir * move_speed
	if mesh_pivot:
		mesh_pivot.rotation.y = atan2(dir.x, dir.z)
	_animate_walk(1.0)

func _process_recovering(delta: float) -> void:
	current_state = WorkerState.AMBIENT
	state_changed.emit("AMBIENT")

func _animate_walk(speed_scale: float) -> void:
	if left_leg and right_leg and left_arm and right_arm:
		var swing: float = sin(_anim_time * speed_scale) * 0.4
		left_leg.rotation.x = swing
		right_leg.rotation.x = -swing
		left_arm.rotation.x = -swing * 0.8
		right_arm.rotation.x = swing * 0.8

func _inspect_pose(delta: float) -> void:
	if left_arm and right_arm and torch_light:
		left_arm.rotation.x = deg_to_rad(-45.0)
		right_arm.rotation.x = deg_to_rad(-60.0)
		# Flickering torch light pulse
		torch_light.light_energy = 1.2 + sin(_anim_time * 3.0) * 0.5

func _crouch_pose() -> void:
	if mesh_pivot:
		mesh_pivot.position.y = -0.25
	if left_arm and right_arm:
		left_arm.rotation.x = deg_to_rad(-30.0)
		right_arm.rotation.x = deg_to_rad(-30.0)

func _reset_pose() -> void:
	if mesh_pivot:
		mesh_pivot.position.y = 0.0
	if left_leg: left_leg.rotation = Vector3.ZERO
	if right_leg: right_leg.rotation = Vector3.ZERO
	if left_arm: left_arm.rotation = Vector3.ZERO
	if right_arm: right_arm.rotation = Vector3.ZERO
