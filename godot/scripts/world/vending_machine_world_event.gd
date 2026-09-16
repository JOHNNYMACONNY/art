extends Node

## Commercial Vending Machine Contraband Hack World Event
## Bounded authored world event managing the storefront contraband vending terminal,
## tactical frequency hacking, 3-hit melee tamper breach, and vehicle ram breach.

signal terminal_hacked(payload: Dictionary)
signal terminal_breached(payload: Dictionary)
signal vending_machine_rammed(payload: Dictionary)
signal world_event_resolved(payload: Dictionary)

enum EventState {
	ARMED,
	HACKED,
	BREACHED
}

const DIRECTIVE := "vending_machine_contraband_hack"
const ACTOR := "COMMERCIAL_VENDING_MACHINE"
const ZONE := "commercial_frontage"
const REWARD_SCRAP := 80
const BREACH_SCRAP := 120
const MAX_DURABILITY := 3
const MIN_RAM_SPEED := 4.5
const VENDING_NODE_PATH := "PropVendingMachine"
const PropVendingMachineScript = preload("res://scripts/props/prop_vending_machine.gd")

var current_state: EventState = EventState.ARMED
var last_event: Dictionary = {}
var trigger_count: int = 0
var reward_granted: int = 0

var _root_controller: Node = null
var _player: Node3D = null
var _audio: AudioManager = null
var _machine: StaticBody3D = null

func _ready() -> void:
	_root_controller = get_parent()
	_resolve_dependencies()

func _resolve_dependencies() -> void:
	if _root_controller == null:
		_root_controller = get_parent()
	if _root_controller != null:
		_player = _root_controller.get_node_or_null("Runner") as Node3D
		_audio = _root_controller.get_node_or_null("AudioManager") as AudioManager
		_machine = _root_controller.get_node_or_null(VENDING_NODE_PATH) as StaticBody3D

func _has_dependencies() -> bool:
	return is_instance_valid(_player) and is_instance_valid(_audio) and is_instance_valid(_machine)

func get_world_event_contract() -> Dictionary:
	return {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"reward_scrap": REWARD_SCRAP,
		"breach_scrap": BREACH_SCRAP,
		"max_durability": MAX_DURABILITY,
		"min_ram_speed": MIN_RAM_SPEED,
		"vending_node_path": VENDING_NODE_PATH,
		"state": EventState.keys()[current_state]
	}

func notify_hacked(scrap_reward: int, pos: Vector3) -> void:
	if current_state != EventState.ARMED:
		return
	current_state = EventState.HACKED
	trigger_count += 1
	reward_granted = scrap_reward
	last_event = {
		"event": "terminal_hacked",
		"reward_scrap": scrap_reward,
		"position": pos,
		"trigger_count": trigger_count
	}
	terminal_hacked.emit(last_event)
	world_event_resolved.emit(last_event)

func notify_breached(loot_reward: int, pos: Vector3) -> void:
	current_state = EventState.BREACHED
	trigger_count += 1
	last_event = {
		"event": "terminal_breached",
		"loot_reward": loot_reward,
		"position": pos,
		"trigger_count": trigger_count
	}
	terminal_breached.emit(last_event)
	world_event_resolved.emit(last_event)

func notify_rammed(impact_speed: float, ram_dir: Vector3) -> void:
	last_event = {
		"event": "vending_machine_rammed",
		"impact_speed": impact_speed,
		"ram_direction": ram_dir,
		"trigger_count": trigger_count
	}
	vending_machine_rammed.emit(last_event)

func reset_world_event() -> void:
	current_state = EventState.ARMED
	last_event.clear()
	trigger_count = 0
	reward_granted = 0
	_resolve_dependencies()
	if is_instance_valid(_machine) and _machine.has_method("reset_vending_machine"):
		_machine.reset_vending_machine()
