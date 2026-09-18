extends Node

## Security Checkpoint Toll Standoff World Event
## Bounded authored event exploiting the 01F SecurityCheckpoint prop on the north arterial.
## Manages scanner proximity detection, toll payment bypass, or high-speed vehicle ramming.

signal standoff_triggered(payload: Dictionary)
signal checkpoint_resolved(payload: Dictionary)

enum State {
	ARMED,
	STANDOFF,
	TOLL_PAID,
	BREACHED,
	DISARMED
}

const DIRECTIVE := "checkpoint_toll_standoff"
const ACTOR := "CIVIC_SECURITY_BARRIER"
const ZONE := "gears_north_checkpoint"
const TOLL_AMOUNT := 150
const TRIGGER_RADIUS_M := 6.5
const REARM_RADIUS_M := 10.0
const COOLDOWN_SEC := 8.0
const MIN_RAM_SPEED := 5.0

const CHECKPOINT_PROP_PATH := "GearsDistrictSlice01B/StreetClutter/SecurityCheckpoint"

var current_state: State = State.ARMED
var last_event: Dictionary = {}
var trigger_count: int = 0

var _root_controller: Node = null
var _player: Node3D = null
var _audio: AudioManager = null
var _checkpoint_prop: StaticBody3D = null
var _barrier_collision: CollisionShape3D = null
var _cooldown_remaining: float = 0.0
var _barrier_collision_revision: int = 0

func _ready() -> void:
	_root_controller = get_parent()
	_resolve_dependencies()

func _resolve_dependencies() -> void:
	if _root_controller == null:
		_root_controller = get_parent()
	if _root_controller != null:
		_player = _root_controller.get_node_or_null("Runner") as Node3D
		_audio = _root_controller.get_node_or_null("AudioManager") as AudioManager
		_checkpoint_prop = _root_controller.get_node_or_null(CHECKPOINT_PROP_PATH) as StaticBody3D
		if _checkpoint_prop != null:
			_barrier_collision = _checkpoint_prop.get_node_or_null("CollisionShape3D") as CollisionShape3D

func _has_dependencies() -> bool:
	return is_instance_valid(_player) and is_instance_valid(_audio) and is_instance_valid(_checkpoint_prop)

func get_world_event_contract() -> Dictionary:
	return {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"toll_amount": TOLL_AMOUNT,
		"trigger_radius_m": TRIGGER_RADIUS_M,
		"rearm_radius_m": REARM_RADIUS_M,
		"cooldown_sec": COOLDOWN_SEC,
		"checkpoint_prop_path": CHECKPOINT_PROP_PATH,
	}

func _process(delta: float) -> void:
	if not _has_dependencies():
		_resolve_dependencies()
		if not _has_dependencies():
			return

	_cooldown_remaining = maxf(0.0, _cooldown_remaining - maxf(delta, 0.0))

	var active_entity: Node3D = _player
	if _root_controller != null and _root_controller.has_method("_get_active_vehicle"):
		var veh = _root_controller.call("_get_active_vehicle")
		if veh != null:
			active_entity = veh

	var distance: float = active_entity.global_position.distance_to(_checkpoint_prop.global_position)

	# Rearm when leaving beyond boundary and cooldown clear
	if distance >= REARM_RADIUS_M and _cooldown_remaining <= 0.0 and current_state != State.ARMED:
		reset_world_event()
		return

	if current_state == State.ARMED:
		if distance <= TRIGGER_RADIUS_M:
			_trigger_standoff()

func _trigger_standoff() -> void:
	current_state = State.STANDOFF
	trigger_count += 1
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "STANDOFF",
		"trigger_index": trigger_count,
	}
	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.SIREN_ALARM, _checkpoint_prop.global_position)
	standoff_triggered.emit(last_event.duplicate(true))

func pay_toll() -> bool:
	if current_state != State.STANDOFF:
		return false
	current_state = State.TOLL_PAID
	_cooldown_remaining = COOLDOWN_SEC
	if _barrier_collision != null:
		_barrier_collision.disabled = true
	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.COMPLETION, _checkpoint_prop.global_position)
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "TOLL_PAID",
		"resolution": "PAID",
		"toll_amount": TOLL_AMOUNT,
	}
	checkpoint_resolved.emit(last_event.duplicate(true))
	return true

func _defer_barrier_collision_disabled(disabled: bool) -> void:
	_barrier_collision_revision += 1
	var revision := _barrier_collision_revision
	call_deferred("_apply_barrier_collision_disabled", disabled, revision)

func _apply_barrier_collision_disabled(disabled: bool, revision: int) -> void:
	if revision != _barrier_collision_revision:
		return
	if is_instance_valid(_barrier_collision):
		_barrier_collision.disabled = disabled

func ram_breach(speed: float) -> bool:
	if current_state != State.STANDOFF and current_state != State.ARMED:
		return false
	if speed < MIN_RAM_SPEED:
		return false

	current_state = State.BREACHED
	_cooldown_remaining = COOLDOWN_SEC
	if _barrier_collision != null:
		# Vehicle collision callbacks can arrive while the physics server is flushing.
		# Revision-gated deferral also lets reset invalidate a queued breach write.
		_defer_barrier_collision_disabled(true)

	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.COLLISION_HEAD_ON, _checkpoint_prop.global_position)
		_audio.play_event(AudioManager.SoundEvent.GATE_SLAM, _checkpoint_prop.global_position)
		_audio.play_event(AudioManager.SoundEvent.SIREN_ALARM, _checkpoint_prop.global_position)

	# Breach alert triggers root pursuit authority
	if _root_controller != null and _root_controller.has_method("trigger_disturbance_alert"):
		_root_controller.call("trigger_disturbance_alert")

	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "BREACHED",
		"resolution": "RAMMED",
		"speed": speed,
	}
	checkpoint_resolved.emit(last_event.duplicate(true))
	return true

func reset_world_event() -> void:
	current_state = State.ARMED
	_cooldown_remaining = 0.0
	# Invalidate any breach disable that has been queued but not applied yet.
	_barrier_collision_revision += 1
	if _barrier_collision != null:
		_barrier_collision.disabled = false
