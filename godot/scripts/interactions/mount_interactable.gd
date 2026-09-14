class_name MountInteractable
extends InteractableBase

# Interaction Proxy for CourierBike Mount
# Participates in player target arbitration

@onready var vehicle: Node = get_parent()
var bike: CourierBike:
	get: return vehicle as CourierBike
var _current_player: PlayerRunner = null

func update_player_distance(player_pos: Vector3) -> void:
	super.update_player_distance(player_pos)

func set_player_reference(player: PlayerRunner) -> void:
	_current_player = player

func can_interact(_player_pos: Vector3) -> bool:
	if not vehicle:
		return false
	if "current_state" in vehicle and int(vehicle.current_state) != 0:
		return false
	if "occupant" in vehicle and vehicle.occupant != null:
		return false
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if vehicle and _current_player and vehicle.has_method("request_mount"):
		return vehicle.request_mount(_current_player)
	return false

func get_interaction_priority() -> float:
	return interaction_priority
