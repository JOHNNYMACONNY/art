extends Node

## Security Checkpoint Toll Standoff World Event
## Bounded authored event exploiting the 01F SecurityCheckpoint prop on the north arterial.
## P15 adds one session-local claimed-Courier recognition consequence while keeping
## Wanted/Report authority in BurnsideWantedRuntime.

signal standoff_triggered(payload: Dictionary)
signal checkpoint_resolved(payload: Dictionary)

enum State {
	ARMED,
	STANDOFF,
	TOLL_PAID,
	BREACHED,
	DISARMED,
	WATCHLISTED
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
const WATCHLIST_HOLD_TEXT := "VEHICLE FLAGGED // HOLD"
const WATCHLIST_LINK_FAULT_TEXT := "VEHICLE FLAGGED // LINK FAULT"

var current_state: State = State.ARMED
var last_event: Dictionary = {}
var trigger_count: int = 0

var _root_controller: Node = null
var _player: Node3D = null
var _audio: AudioManager = null
var _wanted_runtime: Node = null
var _checkpoint_prop: StaticBody3D = null
var _barrier_collision: CollisionShape3D = null
var _watchlist_label: Label3D = null
var _cooldown_remaining: float = 0.0
var _barrier_collision_revision: int = 0
var _courier_bike_watchlisted: bool = false
var _watchlist_report_attempted: bool = false
var _watchlist_report_attempt_count: int = 0

func _ready() -> void:
	_root_controller = get_parent()
	_resolve_dependencies()

func _resolve_dependencies() -> void:
	if _root_controller == null:
		_root_controller = get_parent()
	if _root_controller != null:
		_player = _root_controller.get_node_or_null("Runner") as Node3D
		_audio = _root_controller.get_node_or_null("AudioManager") as AudioManager
		_wanted_runtime = _root_controller.get_node_or_null("/root/BurnsideWantedRuntime")
		_checkpoint_prop = _root_controller.get_node_or_null(CHECKPOINT_PROP_PATH) as StaticBody3D
		if _checkpoint_prop != null:
			_barrier_collision = _checkpoint_prop.get_node_or_null("CollisionShape3D") as CollisionShape3D
			_ensure_watchlist_label()

func _has_dependencies() -> bool:
	return is_instance_valid(_player) 		and is_instance_valid(_audio) 		and is_instance_valid(_wanted_runtime) 		and is_instance_valid(_checkpoint_prop)

func _ensure_watchlist_label() -> void:
	if _checkpoint_prop == null or is_instance_valid(_watchlist_label):
		return
	_watchlist_label = Label3D.new()
	_watchlist_label.name = "CourierRecognitionStatus"
	_watchlist_label.font_size = 28
	_watchlist_label.pixel_size = 0.009
	_watchlist_label.outline_size = 6
	_watchlist_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_watchlist_label.no_depth_test = true
	_watchlist_label.modulate = Color(0.95, 0.72, 0.24, 0.98)
	_watchlist_label.outline_modulate = Color(0.05, 0.05, 0.04, 0.96)
	_watchlist_label.position = Vector3(0.0, 3.15, 0.0)
	_watchlist_label.visible = false
	_checkpoint_prop.add_child(_watchlist_label)

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
		"watchlisted_state": int(State.WATCHLISTED),
	}

func _get_active_entity() -> Node3D:
	var active_entity: Node3D = _player
	if _root_controller != null and _root_controller.has_method("_get_active_vehicle"):
		var veh = _root_controller.call("_get_active_vehicle")
		if veh is Node3D:
			active_entity = veh as Node3D
	return active_entity

func _is_active_claimed_courier_bike(active_entity: Node3D) -> bool:
	if _root_controller == null or active_entity == null:
		return false
	var production_bike = _root_controller.get("courier_bike")
	if production_bike == null or active_entity != production_bike:
		return false
	return _root_controller.has_method("_is_courier_bike_claimed") 		and bool(_root_controller.call("_is_courier_bike_claimed"))

func _process(delta: float) -> void:
	if not _has_dependencies():
		_resolve_dependencies()
		if not _has_dependencies():
			return

	_cooldown_remaining = maxf(0.0, _cooldown_remaining - maxf(delta, 0.0))

	var active_entity := _get_active_entity()
	if active_entity == null:
		return
	var distance: float = active_entity.global_position.distance_to(_checkpoint_prop.global_position)

	# Ordinary recovery preserves the P15 session-local watchlist.
	if distance >= REARM_RADIUS_M and _cooldown_remaining <= 0.0 and current_state != State.ARMED:
		reset_world_event()
		return

	if current_state == State.ARMED and distance <= TRIGGER_RADIUS_M:
		if _courier_bike_watchlisted and _is_active_claimed_courier_bike(active_entity):
			_trigger_watchlisted_scan()
		else:
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

func _trigger_watchlisted_scan() -> void:
	current_state = State.WATCHLISTED
	_watchlist_report_attempted = false
	_set_watchlist_label(WATCHLIST_HOLD_TEXT, true)
	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.SIREN_ALARM, _checkpoint_prop.global_position)

	var report_result := "ALREADY_WANTED"
	if _wanted_runtime != null 	and _wanted_runtime.has_method("get_heat_level") 	and int(_wanted_runtime.call("get_heat_level")) <= 0:
		_watchlist_report_attempted = true
		_watchlist_report_attempt_count += 1
		var requested := _wanted_runtime.has_method("request_civic_report") 			and bool(_wanted_runtime.call("request_civic_report", _checkpoint_prop.global_position))
		var report_created_wanted := requested 			and int(_wanted_runtime.call("get_heat_level")) > 0
		if report_created_wanted:
			report_result = "SENT"
			_set_watchlist_label(WATCHLIST_HOLD_TEXT, true)
		else:
			report_result = "SUPPRESSED"
			_set_watchlist_label(WATCHLIST_LINK_FAULT_TEXT, true)

	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "WATCHLISTED",
		"resolution": "CLAIMED_COURIER_RECOGNIZED",
		"report_result": report_result,
	}
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

func _request_breach_report() -> void:
	if _wanted_runtime == null 	or not _wanted_runtime.has_method("get_heat_level") 	or not _wanted_runtime.has_method("request_civic_report"):
		return
	if int(_wanted_runtime.call("get_heat_level")) > 0:
		return
	_wanted_runtime.call("request_civic_report", _checkpoint_prop.global_position)

func ram_breach(speed: float) -> bool:
	if current_state != State.STANDOFF 	and current_state != State.ARMED 	and current_state != State.WATCHLISTED:
		return false
	if speed < MIN_RAM_SPEED:
		return false

	var active_entity := _get_active_entity()
	if _is_active_claimed_courier_bike(active_entity):
		_courier_bike_watchlisted = true

	current_state = State.BREACHED
	_cooldown_remaining = COOLDOWN_SEC
	_set_watchlist_label("", false)
	if _barrier_collision != null:
		# Vehicle collision callbacks can arrive while the physics server is flushing.
		# Revision-gated deferral also lets reset invalidate a queued breach write.
		_defer_barrier_collision_disabled(true)

	if _audio != null:
		_audio.play_event(AudioManager.SoundEvent.COLLISION_HEAD_ON, _checkpoint_prop.global_position)
		_audio.play_event(AudioManager.SoundEvent.GATE_SLAM, _checkpoint_prop.global_position)
		_audio.play_event(AudioManager.SoundEvent.SIREN_ALARM, _checkpoint_prop.global_position)

	# P15 converges this checkpoint-only legacy seam on the retained P01/P02
	# civic Report authority. Local breach still occurs when the Report link is jammed.
	_request_breach_report()

	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "BREACHED",
		"resolution": "RAMMED",
		"speed": speed,
		"claimed_courier_watchlisted": _courier_bike_watchlisted,
	}
	checkpoint_resolved.emit(last_event.duplicate(true))
	return true

func reset_world_event(clear_memory: bool = false) -> void:
	current_state = State.ARMED
	_cooldown_remaining = 0.0
	_watchlist_report_attempted = false
	_watchlist_report_attempt_count = 0
	if clear_memory:
		_courier_bike_watchlisted = false
	_set_watchlist_label("", false)
	# Invalidate any breach disable that has been queued but not applied yet.
	_barrier_collision_revision += 1
	if _barrier_collision != null:
		_barrier_collision.disabled = false

func _set_watchlist_label(text: String, visible_value: bool) -> void:
	if not is_instance_valid(_watchlist_label):
		_ensure_watchlist_label()
	if _watchlist_label == null:
		return
	_watchlist_label.text = text
	_watchlist_label.visible = visible_value

func is_courier_bike_watchlisted() -> bool:
	return _courier_bike_watchlisted

func get_watchlist_report_attempt_count() -> int:
	return _watchlist_report_attempt_count

func get_watchlist_label_text() -> String:
	return _watchlist_label.text if is_instance_valid(_watchlist_label) and _watchlist_label.visible else ""
