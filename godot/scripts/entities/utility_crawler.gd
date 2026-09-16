class_name UtilityCrawler
extends CharacterBody3D

## UtilityCrawler: Low industrial autonomous salvage rover for living scrap yard
## Implements deterministic AMBIENT / YIELDING / ALARMED / RECOVERING / DISABLED / WRECKED lifecycle
## Supports tactical scrap interception ([E] INTERCEPT), 2-hit melee disable, and vehicle ram wreck.

enum CrawlerState {
	AMBIENT = 0,
	YIELDING = 1,
	ALARMED = 2,
	RECOVERING = 3,
	DISABLED = 4,
	WRECKED = 5
}

const MAX_DURABILITY: int = 2
const HARVEST_REWARD: int = 60
const MIN_RAM_SPEED: float = 4.5
const DEBRIS_COUNT: int = 4

@export var crawler_name: String = "UtilityCrawler"
@export var patrol_waypoints: Array = [
	Vector3(1.0, 0.05, -2.0),
	Vector3(1.0, 0.05, 4.0)
]
@export var safe_anchor: Vector3 = Vector3(1.0, 0.05, -4.5)
@export var move_speed: float = 2.0
@export var awareness_radius: float = 4.0

@export var material_main: Material
@export var material_optic: Material

var current_state: CrawlerState = CrawlerState.AMBIENT
var current_durability: int = MAX_DURABILITY
var current_waypoint_idx: int = 0
var is_harvested: bool = false
var is_rammed: bool = false
var reward_granted: int = 0
var debris_instances: Array[Node3D] = []

var _initial_position: Vector3 = Vector3.ZERO
var _initial_rotation_y: float = 0.0
var _anim_time: float = 0.0
var _yield_timer: float = 0.0
var _station_timer: float = 0.0
var _servo_cooldown: float = 0.0
var _audio_mgr: AudioManager = null
var _shake_tween: Tween = null
var _launch_tween: Tween = null

@onready var beacon_light: OmniLight3D = $BeaconLight
@onready var beacon_mesh: MeshInstance3D = $Chassis/BeaconMesh
@onready var visual_root: Node3D = $Chassis if has_node("Chassis") else self
@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D
@onready var interactable: Area3D = find_child("UtilityCrawlerInteractable", true, false) as Area3D

signal state_changed(new_state: String)
signal yield_triggered(distance: float)
signal alarm_triggered()
signal hit_received(remaining_durability: int, hit_pos: Vector3, impulse_dir: Vector3)
signal crawler_intercepted(reward: int, source_pos: Vector3)
signal crawler_disabled(reward: int, source_pos: Vector3)
signal crawler_rammed(impact_speed: float, ram_dir: Vector3)
signal crawler_reset()

func setup_audio(mgr: AudioManager) -> void:
	_audio_mgr = mgr

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("utility_crawlers")
	_setup_mesh_materials()
	_initial_position = global_position
	_initial_rotation_y = rotation.y
	if patrol_waypoints.is_empty():
		patrol_waypoints.append(_initial_position)
		patrol_waypoints.append(_initial_position + Vector3(0, 0, 4.0))
	if interactable:
		interactable.set("crawler", self)

func _setup_mesh_materials() -> void:
	var crawler_mesh := find_child("UtilityCrawler_Mesh", true, false) as MeshInstance3D
	if crawler_mesh:
		if material_main:
			crawler_mesh.set_surface_override_material(0, material_main.duplicate())
		if material_optic:
			crawler_mesh.set_surface_override_material(1, material_optic.duplicate())

func reset_actor() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	if is_instance_valid(_launch_tween) and _launch_tween.is_running():
		_launch_tween.kill()

	for shard in debris_instances:
		if is_instance_valid(shard):
			shard.queue_free()
	debris_instances.clear()

	current_state = CrawlerState.AMBIENT
	current_durability = MAX_DURABILITY
	is_harvested = false
	is_rammed = false
	reward_granted = 0
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

	if visual_root and visual_root != self:
		visual_root.position = Vector3.ZERO
		visual_root.rotation = Vector3.ZERO
		visual_root.scale = Vector3.ONE

	if beacon_light:
		beacon_light.light_energy = 1.4
		beacon_light.light_color = Color(1.0, 0.72, 0.12)

	if collision_shape:
		collision_shape.set_deferred("disabled", false)
		collision_shape.disabled = false

	if interactable:
		interactable.set("is_powered", true)

	crawler_reset.emit()

func _physics_process(delta: float) -> void:
	if current_state == CrawlerState.DISABLED or current_state == CrawlerState.WRECKED:
		velocity = Vector3.ZERO
		if beacon_light:
			beacon_light.light_energy = 0.0
		return

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
	if current_state == CrawlerState.ALARMED or current_state == CrawlerState.DISABLED or current_state == CrawlerState.WRECKED:
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
	if current_state == CrawlerState.DISABLED or current_state == CrawlerState.WRECKED:
		return
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

func _process_recovering(_delta: float) -> void:
	current_state = CrawlerState.AMBIENT
	state_changed.emit("AMBIENT")

# ==============================================================================
# COMBAT & TACTICAL INTERACTION CONTRACTS
# ==============================================================================

func intercept_crawler() -> int:
	if is_rammed or is_harvested or current_durability <= 0 or current_state == CrawlerState.WRECKED:
		return 0

	is_harvested = true
	current_state = CrawlerState.DISABLED
	reward_granted = HARVEST_REWARD
	velocity = Vector3.ZERO

	if beacon_light:
		beacon_light.light_energy = 0.0

	state_changed.emit("DISABLED")
	crawler_intercepted.emit(reward_granted, global_position)

	if _audio_mgr:
		_audio_mgr.play_event(AudioManager.SoundEvent.COMPLETION, global_position)
		_audio_mgr.play_event(AudioManager.SoundEvent.AMBIENT_WORK_CLINK, global_position)

	return reward_granted

func take_hit(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> void:
	if is_rammed or current_state == CrawlerState.WRECKED or current_durability <= 0:
		return

	current_durability = maxi(0, current_durability - damage)
	_trigger_impact_shake(impulse_dir)
	hit_received.emit(current_durability, hit_pos, impulse_dir)

	if _audio_mgr:
		_audio_mgr.play_event(AudioManager.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
		_audio_mgr.play_event(AudioManager.SoundEvent.SPARK, hit_pos)

	if current_durability <= 0:
		current_state = CrawlerState.DISABLED
		velocity = Vector3.ZERO
		if beacon_light:
			beacon_light.light_energy = 0.0

		state_changed.emit("DISABLED")

		var reward: int = 0
		if not is_harvested:
			is_harvested = true
			reward = HARVEST_REWARD
			reward_granted = reward

		_spawn_scrap_debris(impulse_dir, 3)
		crawler_disabled.emit(reward, global_position)

		if _audio_mgr and reward > 0:
			_audio_mgr.play_event(AudioManager.SoundEvent.COMPLETION, global_position)

func apply_vehicle_ram(impact_speed: float, ram_direction: Vector3, _vehicle: Node3D = null) -> bool:
	if is_rammed or current_state == CrawlerState.WRECKED:
		return false

	if impact_speed < MIN_RAM_SPEED:
		_trigger_impact_shake(ram_direction * 0.4)
		return false

	is_rammed = true
	current_state = CrawlerState.WRECKED
	current_durability = 0
	velocity = Vector3.ZERO

	if beacon_light:
		beacon_light.light_energy = 0.0

	state_changed.emit("WRECKED")

	var reward: int = 0
	if not is_harvested:
		is_harvested = true
		reward = HARVEST_REWARD
		reward_granted = reward

	_spawn_scrap_debris(ram_direction, DEBRIS_COUNT)
	_launch_chassis(ram_direction, impact_speed)
	crawler_rammed.emit(impact_speed, ram_direction)

	if _audio_mgr:
		_audio_mgr.play_event(AudioManager.SoundEvent.COLLISION_HEAD_ON, global_position)
		_audio_mgr.play_event(AudioManager.SoundEvent.SPARK, global_position)
		_audio_mgr.play_event(AudioManager.SoundEvent.SIREN_ALARM, global_position)

	var root_node := get_parent()
	if root_node and root_node.has_method("trigger_disturbance_alert"):
		root_node.call("trigger_disturbance_alert")

	return true

func _trigger_impact_shake(impulse_dir: Vector3) -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()

	if not visual_root or visual_root == self:
		return

	var punch_offset := impulse_dir.normalized() * 0.08
	punch_offset.y = 0.03

	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(visual_root, "position", punch_offset, 0.06)
	_shake_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.2)

func _launch_chassis(ram_direction: Vector3, impact_speed: float) -> void:
	if not visual_root or visual_root == self:
		return
	if is_instance_valid(_launch_tween) and _launch_tween.is_running():
		_launch_tween.kill()

	var flat_dir := Vector3(ram_direction.x, 0.0, ram_direction.z).normalized()
	if flat_dir.length_squared() < 0.001:
		flat_dir = Vector3.FORWARD

	var slide_dist := minf(impact_speed * 0.4, 3.0)
	var end_pos := global_position + flat_dir * slide_dist

	_launch_tween = create_tween()
	_launch_tween.set_parallel(true)
	_launch_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_launch_tween.tween_property(self, "global_position", end_pos, 0.35)
	_launch_tween.tween_property(visual_root, "rotation", Vector3(deg_to_rad(35.0), deg_to_rad(45.0), deg_to_rad(15.0)), 0.35)

func _spawn_scrap_debris(ram_direction: Vector3, count: int) -> void:
	var flat_dir := Vector3(ram_direction.x, 0.0, ram_direction.z).normalized()
	if flat_dir.length_squared() < 0.001:
		flat_dir = Vector3.FORWARD

	for i in range(count):
		var shard := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(randf_range(0.12, 0.22), randf_range(0.08, 0.16), randf_range(0.10, 0.18))
		shard.mesh = box_mesh
		if material_main:
			shard.material_override = material_main

		shard.position = Vector3(randf_range(-0.3, 0.3), 0.2, randf_range(-0.3, 0.3))
		add_child(shard)
		debris_instances.append(shard)

		var angle: float = randf_range(-PI * 0.4, PI * 0.4)
		var scatter_dir: Vector3 = flat_dir.rotated(Vector3.UP, angle).normalized()
		var scatter_dist: float = randf_range(1.2, 2.8)
		var end_pos: Vector3 = shard.position + scatter_dir * scatter_dist
		end_pos.y = 0.05

		var shard_tween := create_tween()
		shard_tween.set_parallel(true)
		shard_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shard_tween.tween_property(shard, "position", end_pos, 0.35 + i * 0.05)
		shard_tween.tween_property(shard, "rotation", Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)), 0.35 + i * 0.05)
		shard_tween.chain().tween_property(shard, "scale", Vector3.ZERO, 0.5)
