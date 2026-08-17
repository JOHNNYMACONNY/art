class_name UtilityCrawler
extends CharacterBody3D

## UtilityCrawler: Low industrial autonomous salvage rover for living scrap yard
## Implements deterministic AMBIENT / YIELDING / ALARMED / RECOVERING lifecycle

enum CrawlerState {
	AMBIENT,
	YIELDING,
	ALARMED,
	RECOVERING
}

@export var crawler_name: String = "UtilityCrawler"
@export var patrol_waypoints: Array = [
	Vector3(1.0, 0.05, -2.0),
	Vector3(1.0, 0.05, 4.0)
]
@export var safe_anchor: Vector3 = Vector3(1.0, 0.05, -4.5)
@export var move_speed: float = 2.0
@export var awareness_radius: float = 4.0

var current_state: CrawlerState = CrawlerState.AMBIENT
var current_waypoint_idx: int = 0
var _initial_position: Vector3 = Vector3.ZERO
var _initial_rotation_y: float = 0.0
var _anim_time: float = 0.0
var _yield_timer: float = 0.0
var _station_timer: float = 0.0
var _servo_cooldown: float = 0.0
var _audio_mgr: AudioManager = null

@onready var beacon_light: OmniLight3D = $BeaconLight
@onready var beacon_mesh: MeshInstance3D = $Chassis/BeaconMesh

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
		patrol_waypoints.append(_initial_position + Vector3(0, 0, 4.0))

func reset_actor() -> void:
	current_state = CrawlerState.AMBIENT
	current_waypoint_idx = 0
	global_position = _initial_position
	global_position.y = 0.05
	rotation.y = _initial_rotation_y
	velocity = Vector3.ZERO
	_yield_timer = 0.0
	_station_timer = 0.0
	_servo_cooldown = 1.5
	_anim_time = 0.0
	visible = true
	if beacon_light:
		beacon_light.light_energy = 1.4
		beacon_light.light_color = Color(1.0, 0.72, 0.12)

func _physics_process(delta: float) -> void:
	_anim_time += delta * 4.0
	_servo_cooldown = maxf(0.0, _servo_cooldown - delta)
	
	# Amber beacon rotation / pulse
	if beacon_light:
		if current_state == CrawlerState.ALARMED:
			# Fast red/amber warning strobe
			beacon_light.light_energy = 2.0 if fmod(_anim_time * 2.0, 1.0) > 0.5 else 0.2
			beacon_light.light_color = Color(1.0, 0.35, 0.1)
		else:
			# Slow rotating work pulse
			beacon_light.light_energy = 1.0 + sin(_anim_time * 2.0) * 0.4
			beacon_light.light_color = Color(1.0, 0.72, 0.12)
			
	match current_state:
		CrawlerState.AMBIENT:
			_process_ambient(delta)
		CrawlerState.YIELDING:
			_process_yielding(delta)
		CrawlerState.ALARMED:
			_process_alarmed(delta)
		CrawlerState.RECOVERING:
			_process_recovering(delta)
			
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.05

func check_proximity_threat(threat_pos: Vector3, threat_vel: Vector3) -> void:
	if current_state == CrawlerState.ALARMED:
		return
		
	var dist: float = global_position.distance_to(threat_pos)
	if dist < awareness_radius and threat_vel.length() > 1.5:
		_enter_yielding(dist)

func _enter_yielding(dist: float) -> void:
	current_state = CrawlerState.YIELDING
	_yield_timer = 1.5
	velocity = Vector3.ZERO
	state_changed.emit("YIELDING")
	yield_triggered.emit(dist)

func _process_yielding(delta: float) -> void:
	_yield_timer -= delta
	velocity = Vector3.ZERO
	if _yield_timer <= 0.0:
		current_state = CrawlerState.AMBIENT
		state_changed.emit("AMBIENT")

func trigger_alarm() -> void:
	current_state = CrawlerState.ALARMED
	state_changed.emit("ALARMED")
	alarm_triggered.emit()

func _process_alarmed(delta: float) -> void:
	var target_pos: Vector3 = safe_anchor
	var dist: float = global_position.distance_to(target_pos)
	if dist > 0.4:
		var dir: Vector3 = (target_pos - global_position).normalized()
		velocity = dir * 3.0
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
	else:
		velocity = Vector3.ZERO

func _process_ambient(delta: float) -> void:
	if _station_timer > 0.0:
		_station_timer -= delta
		velocity = Vector3.ZERO
		return
		
	var target: Vector3 = patrol_waypoints[current_waypoint_idx]
	var dist: float = global_position.distance_to(target)
	if dist < 0.5:
		_station_timer = 2.0 # Wait at salvage station for 2.0s
		current_waypoint_idx = (current_waypoint_idx + 1) % patrol_waypoints.size()
		velocity = Vector3.ZERO
		return
		
	var dir: Vector3 = (target - global_position).normalized()
	velocity = dir * move_speed
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)
	
	if _servo_cooldown <= 0.0:
		_servo_cooldown = 1.8
		if _audio_mgr:
			_audio_mgr.play_event(AudioManager.SoundEvent.AMBIENT_SERVO_HUM, global_position)

func _process_recovering(delta: float) -> void:
	current_state = CrawlerState.AMBIENT
	state_changed.emit("AMBIENT")
