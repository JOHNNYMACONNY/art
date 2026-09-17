class_name VendingMachineInteractable
extends InteractableBase

## Interaction Proxy for Commercial Storefront Vending Machine Contraband Terminal
## Participates in player target arbitration, frequency alignment, and contraband payout

@onready var machine: Node = get_parent()
var _current_player: CharacterBody3D = null

func _ready() -> void:
	interaction_priority = 1.85
	interaction_radius = 2.6
	sensory_radius = 5.0
	is_powered = true

func set_player_reference(player: CharacterBody3D) -> void:
	_current_player = player

func get_action_verb() -> String:
	if not machine:
		return "HACK"
	var state_val = machine.get("current_state")
	# VendingState: READY=0, HACKED=1, BREACHED=2, EMPTY=3
	if state_val == 2:
		return "BREACHED"
	if state_val == 1:
		return "DISPENSED"
	return "HACK TERMINAL"

func can_interact(_player_pos: Vector3) -> bool:
	if not machine:
		return false
	if "is_rammed" in machine and machine.is_rammed:
		return false
	var state_val = machine.get("current_state")
	if state_val == 2 or state_val == 1:
		return false
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if not can_interact(_player_pos):
		return false

	if machine.has_method("hack_terminal"):
		var res: Dictionary = machine.hack_terminal(_current_player)
		interaction_completed.emit()
		return res.get("success", false)

	return false

func get_interaction_priority() -> float:
	return interaction_priority
