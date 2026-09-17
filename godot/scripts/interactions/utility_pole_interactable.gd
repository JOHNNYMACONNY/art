class_name UtilityPoleInteractable
extends InteractableBase

# Interaction Proxy for Surveillance Utility Pole on Sidewalk Curb
# Participates in player target arbitration, tactical grid tapping, and EMP overload detonation

@onready var pole: Node = get_parent()
var _current_player: CharacterBody3D = null

func _ready() -> void:
	interaction_priority = 1.9
	interaction_radius = 2.8
	sensory_radius = 6.0
	is_powered = true

func set_player_reference(player: CharacterBody3D) -> void:
	_current_player = player

func get_action_verb() -> String:
	if not pole:
		return "TAP GRID"
	if "is_rammed" in pole and pole.is_rammed:
		return "WRECKED"
	if "is_overloaded" in pole and pole.is_overloaded:
		return "OVERLOADED"
	if "current_durability" in pole and pole.current_durability <= 0:
		return "BLOWN"
	return "TAP GRID"

func can_interact(_player_pos: Vector3) -> bool:
	if not pole:
		return false
	if "is_rammed" in pole and pole.is_rammed:
		return false
	if "is_overloaded" in pole and pole.is_overloaded:
		return false
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if not can_interact(_player_pos):
		return false
	if pole.has_method("overload_grid"):
		var res: bool = pole.overload_grid()
		interaction_completed.emit()
		return res
	return false

func get_interaction_priority() -> float:
	return interaction_priority
