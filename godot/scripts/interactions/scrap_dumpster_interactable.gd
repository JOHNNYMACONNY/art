class_name ScrapDumpsterInteractable
extends InteractableBase

# Interaction Proxy for Municipal Scrap Dumpster in Service Alley
# Participates in player target arbitration, scavenging, and stealth hiding evasion

@onready var dumpster: Node = get_parent()
var _current_player: CharacterBody3D = null
var is_pursuit_active: bool = false

func _ready() -> void:
	interaction_priority = 1.7
	interaction_radius = 2.4
	sensory_radius = 5.0
	is_powered = true

func set_player_reference(player: CharacterBody3D) -> void:
	_current_player = player

func set_pursuit_active(active: bool) -> void:
	is_pursuit_active = active

func get_action_verb() -> String:
	if not dumpster:
		return "SEARCH"
	var state_val = dumpster.get("current_state")
	# DumpsterState.OCCUPIED_HIDING is state 2
	if state_val == 2:
		return "EXIT"
	if is_pursuit_active and dumpster.has_method("can_hide") and dumpster.can_hide():
		return "HIDE"
	if dumpster.has_method("is_scavenged") and dumpster.is_scavenged():
		return "EMPTY"
	return "SEARCH"

func can_interact(_player_pos: Vector3) -> bool:
	if not dumpster:
		return false
	if "is_rammed" in dumpster and dumpster.is_rammed:
		return false
	var state_val = dumpster.get("current_state")
	if state_val == 2: # OCCUPIED_HIDING: always can interact to exit
		return true
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if not dumpster:
		return false
	
	var state_val = dumpster.get("current_state")
	if state_val == 2: # OCCUPIED_HIDING
		var success: bool = dumpster.exit_hiding(_current_player)
		interaction_completed.emit()
		return success
	
	if is_pursuit_active and dumpster.has_method("can_hide") and dumpster.can_hide():
		var success: bool = dumpster.enter_hiding(_current_player)
		interaction_completed.emit()
		return success
	
	if dumpster.has_method("scavenge_scrap"):
		var reward: int = dumpster.scavenge_scrap()
		interaction_completed.emit()
		return reward > 0

	return false

func get_interaction_priority() -> float:
	return interaction_priority
