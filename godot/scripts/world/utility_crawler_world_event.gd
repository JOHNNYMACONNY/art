extends Node

## Municipal Utility Crawler Patrol World Event (World Event 04)
## Bounded authored world event managing the autonomous maintenance rover circuit,
## tactical scrap interception, 2-hit melee disabling, and high-speed vehicle ram breaches.

signal crawler_intercepted(payload: Dictionary)
signal crawler_disabled(payload: Dictionary)
signal crawler_rammed(payload: Dictionary)
signal world_event_resolved(payload: Dictionary)

enum EventState {
	ARMED,
	INTERCEPTED,
	DISABLED,
	WRECKED
}

const DIRECTIVE := "municipal_crawler_patrol"
const ACTOR := "MUNICIPAL_UTILITY_CRAWLER"
const ZONE := "gears_salvage_circuit"
const REWARD_SCRAP := 60
const MAX_DURABILITY := 2
const MIN_RAM_SPEED := 4.5
const CRAWLER_NODE_PATH := "UtilityCrawler"

var current_state: EventState = EventState.ARMED
var last_event: Dictionary = {}
var trigger_count: int = 0
var reward_granted: int = 0

var _root_controller: Node = null
var _player: Node3D = null
var _audio: AudioManager = null
var _crawler: UtilityCrawler = null

func _ready() -> void:
	_root_controller = get_parent()
	_resolve_dependencies()

func _resolve_dependencies() -> void:
	if _root_controller == null:
		_root_controller = get_parent()
	if _root_controller != null:
		_player = _root_controller.get_node_or_null("Runner") as Node3D
		_audio = _root_controller.get_node_or_null("AudioManager") as AudioManager
		_crawler = _root_controller.get_node_or_null(CRAWLER_NODE_PATH) as UtilityCrawler

func _has_dependencies() -> bool:
	return is_instance_valid(_player) and is_instance_valid(_audio) and is_instance_valid(_crawler)

func get_world_event_contract() -> Dictionary:
	return {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"reward_scrap": REWARD_SCRAP,
		"max_durability": MAX_DURABILITY,
		"min_ram_speed": MIN_RAM_SPEED,
		"crawler_node_path": CRAWLER_NODE_PATH,
	}

func intercept() -> bool:
	if not _has_dependencies():
		_resolve_dependencies()
	if not _has_dependencies():
		return false
	if current_state != EventState.ARMED:
		return false

	var reward := _crawler.intercept_crawler()
	if reward <= 0:
		return false

	current_state = EventState.INTERCEPTED
	reward_granted = reward
	trigger_count += 1
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "INTERCEPTED",
		"reward_scrap": reward_granted,
		"trigger_index": trigger_count,
	}
	crawler_intercepted.emit(last_event.duplicate(true))
	world_event_resolved.emit(last_event.duplicate(true))
	return true

func melee_strike(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> void:
	if not _has_dependencies():
		_resolve_dependencies()
	if not _has_dependencies():
		return
	_crawler.take_hit(damage, hit_pos, impulse_dir)
	if _crawler.current_durability <= 0 and current_state == EventState.ARMED:
		current_state = EventState.DISABLED
		reward_granted = _crawler.reward_granted
		trigger_count += 1
		last_event = {
			"directive": DIRECTIVE,
			"actor": ACTOR,
			"zone": ZONE,
			"state": "DISABLED",
			"reward_scrap": reward_granted,
			"trigger_index": trigger_count,
		}
		crawler_disabled.emit(last_event.duplicate(true))
		world_event_resolved.emit(last_event.duplicate(true))

func ram_breach(impact_speed: float, ram_dir: Vector3, vehicle: Node3D = null) -> bool:
	if not _has_dependencies():
		_resolve_dependencies()
	if not _has_dependencies():
		return false
	if current_state == EventState.WRECKED:
		return false

	var breached := _crawler.apply_vehicle_ram(impact_speed, ram_dir, vehicle)
	if not breached:
		return false

	current_state = EventState.WRECKED
	reward_granted = _crawler.reward_granted
	trigger_count += 1
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"state": "WRECKED",
		"reward_scrap": reward_granted,
		"impact_speed": impact_speed,
		"trigger_index": trigger_count,
	}
	crawler_rammed.emit(last_event.duplicate(true))
	world_event_resolved.emit(last_event.duplicate(true))
	return true

func reset_world_event() -> void:
	current_state = EventState.ARMED
	reward_granted = 0
	if is_instance_valid(_crawler):
		_crawler.reset_actor()
