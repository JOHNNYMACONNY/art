class_name InteractableBase
extends Area3D

# Base Interactable3D Contract for Echos in the Scrap (SignalTuner & CorrodedPanel)

signal proximity_changed(in_range: bool, target: Area3D)
signal state_changed(new_state_name: String)
signal interaction_completed
signal audio_event_triggered(event_name: String)

enum InteractionState {
	DORMANT,
	ATTRACTING,
	READY,
	TUNING,
	LOCKED,
	SPENT
}

@export var sensory_radius: float = 6.0
@export var interaction_radius: float = 2.5
@export var is_powered: bool = true
@export var priority: float = 1.0

var current_state: InteractionState = InteractionState.DORMANT
var is_player_in_range: bool = false

func update_player_distance(player_pos: Vector3) -> void:
	if current_state == InteractionState.SPENT or current_state == InteractionState.LOCKED or not is_powered:
		return
		
	var dist := global_position.distance_to(player_pos)
	var was_in_range := is_player_in_range
	is_player_in_range = (dist <= interaction_radius)
	
	if is_player_in_range != was_in_range:
		proximity_changed.emit(is_player_in_range, self)
		
	if current_state != InteractionState.TUNING:
		if is_player_in_range:
			_set_state(InteractionState.READY)
		elif dist <= sensory_radius:
			_set_state(InteractionState.ATTRACTING)
		else:
			_set_state(InteractionState.DORMANT)

func can_interact(_player_pos: Vector3) -> bool:
	return is_powered and current_state == InteractionState.READY

func begin_interaction(_player_pos: Vector3) -> bool:
	if not can_interact(_player_pos):
		return false
	_set_state(InteractionState.TUNING)
	return true

func cancel_interaction() -> void:
	if current_state == InteractionState.TUNING:
		_set_state(InteractionState.READY if is_player_in_range else InteractionState.ATTRACTING)

func complete_interaction_sequence() -> void:
	_set_state(InteractionState.LOCKED)
	interaction_completed.emit()

func get_focus_point() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)

func get_interaction_priority() -> float:
	return priority

func _set_state(new_state: InteractionState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(InteractionState.keys()[new_state])
