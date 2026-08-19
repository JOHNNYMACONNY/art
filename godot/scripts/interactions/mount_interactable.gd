class_name MountInteractable
extends InteractableBase

# Interaction Proxy for CourierBike Mount
# Participates in player target arbitration

@onready var bike: CourierBike = get_parent() as CourierBike
var _current_player: PlayerRunner = null

func update_player_distance(player_pos: Vector3) -> void:
	super.update_player_distance(player_pos)

func set_player_reference(player: PlayerRunner) -> void:
	_current_player = player

func can_interact(_player_pos: Vector3) -> bool:
	if not bike:
		bike = get_parent() as CourierBike
	if not bike or bike.current_state != CourierBike.BikeState.PARKED or bike.occupant != null:
		return false
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if not bike:
		bike = get_parent() as CourierBike
	if bike and _current_player:
		return bike.request_mount(_current_player)
	return false

func get_interaction_priority() -> float:
	return interaction_priority
