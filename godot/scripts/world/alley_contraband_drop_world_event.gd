extends Node

## Alley Contraband Drop World Event (Side Beat 03)
## Authored side event exploiting ServiceAlleyEntrySocket, CardboardBoxStack stash,
## and ServiceAlleyExitSocket in GearsDistrictSlice01B.

signal drop_discovered(payload: Dictionary)
signal drop_collected(payload: Dictionary)
signal drop_delivered(payload: Dictionary)

enum State {
	ARMED,
	DISCOVERED,
	COLLECTED,
	DELIVERED,
	COMPLETED
}

const DIRECTIVE := "contraband_alley_drop"
const ACTOR := "MAYOR_BURN_DROP"
const ZONE := "gears_service_alley"
const REWARD_CREDITS := 250

const ENTRY_SOCKET_PATH := "GearsDistrictSlice01B/ServiceAlleyEntrySocket"
const STASH_PROP_PATH := "GearsDistrictSlice01B/StreetClutter/CardboardBoxStack"
const EXIT_SOCKET_PATH := "GearsDistrictSlice01B/ServiceAlleyExitSocket"

const ENTRY_RADIUS_M := 4.5
const STASH_RADIUS_M := 3.0
const EXIT_RADIUS_M := 3.5
const REARM_RADIUS_M := 16.0
const COOLDOWN_SEC := 8.0

var current_state: State = State.ARMED
var last_event: Dictionary = {}
var trigger_count: int = 0
var reward_granted: int = 0

var _root_controller: Node = null
var _player: Node3D = null
var _audio: AudioManager = null
var _entry_socket: Marker3D = null
var _stash_prop: Node3D = null
var _exit_socket: Marker3D = null
var _cooldown_remaining: float = 0.0

func _ready() -> void:
	_root_controller = get_parent()
	_resolve_dependencies()

func _resolve_dependencies() -> void:
	if _root_controller == null:
		_root_controller = get_parent()
	if _root_controller != null:
		_player = _root_controller.get_node_or_null("Runner") as Node3D
		_audio = _root_controller.get_node_or_null("AudioManager") as AudioManager
		_entry_socket = _root_controller.get_node_or_null(ENTRY_SOCKET_PATH) as Marker3D
		_stash_prop = _root_controller.get_node_or_null(STASH_PROP_PATH) as Node3D
		_exit_socket = _root_controller.get_node_or_null(EXIT_SOCKET_PATH) as Marker3D

func _has_dependencies() -> bool:
	return is_instance_valid(_player) and is_instance_valid(_audio) \
		and is_instance_valid(_entry_socket) and is_instance_valid(_stash_prop) \
		and is_instance_valid(_exit_socket)

func get_world_event_contract() -> Dictionary:
	return {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"reward_credits": REWARD_CREDITS,
		"entry_socket_path": ENTRY_SOCKET_PATH,
		"stash_prop_path": STASH_PROP_PATH,
		"exit_socket_path": EXIT_SOCKET_PATH,
		"entry_radius_m": ENTRY_RADIUS_M,
		"stash_radius_m": STASH_RADIUS_M,
		"exit_radius_m": EXIT_RADIUS_M,
		"rearm_radius_m": REARM_RADIUS_M,
		"cooldown_sec": COOLDOWN_SEC,
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

	var dist_entry: float = active_entity.global_position.distance_to(_entry_socket.global_position)
	var dist_stash: float = active_entity.global_position.distance_to(_stash_prop.global_position)
	var dist_exit: float = active_entity.global_position.distance_to(_exit_socket.global_position)

	# Rearm when leaving beyond boundary and cooldown clear
	if dist_entry >= REARM_RADIUS_M and dist_stash >= REARM_RADIUS_M and dist_exit >= REARM_RADIUS_M:
		if _cooldown_remaining <= 0.0 and current_state != State.ARMED:
			reset_world_event()
			return

	if current_state == State.ARMED:
		if dist_entry <= ENTRY_RADIUS_M or dist_stash <= STASH_RADIUS_M:
			_trigger_discovered()

func _trigger_discovered() -> void:
	current_state = State.DISCOVERED
	trigger_count += 1
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "DISCOVERED",
		"trigger_index": trigger_count,
	}
	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.SIGNAL_LOCK, _stash_prop.global_position)
	drop_discovered.emit(last_event.duplicate(true))

func collect_stash() -> bool:
	if current_state != State.DISCOVERED and current_state != State.ARMED:
		return false

	current_state = State.COLLECTED
	reward_granted = REWARD_CREDITS
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "COLLECTED",
		"reward_credits": reward_granted,
	}
	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.SIGNAL_LOCK, _stash_prop.global_position)
	drop_collected.emit(last_event.duplicate(true))
	return true

func deliver_drop() -> bool:
	if current_state != State.COLLECTED:
		return false

	current_state = State.DELIVERED
	_cooldown_remaining = COOLDOWN_SEC
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "DELIVERED",
		"reward_credits": reward_granted,
	}
	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.COMPLETION, _exit_socket.global_position)

	# Delivery triggers root pursuit alert
	if _root_controller != null and _root_controller.has_method("trigger_disturbance_alert"):
		_root_controller.call("trigger_disturbance_alert")

	drop_delivered.emit(last_event.duplicate(true))
	return true

func reset_world_event() -> void:
	current_state = State.ARMED
	reward_granted = 0
	_cooldown_remaining = 0.0
