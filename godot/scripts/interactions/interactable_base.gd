class_name InteractableBase
extends Area3D

# Minimal Base Interactable3D Contract for Echos in the Scrap

signal proximity_changed(in_range: bool, target: Area3D)
signal state_changed(new_state_name: String)
signal interaction_completed
signal audio_event_triggered(event_name: String, source_pos: Vector3)

@export var sensory_radius: float = 6.0
@export var interaction_radius: float = 2.5
@export var is_powered: bool = true
@export var interaction_priority: float = 1.0

var is_player_in_range: bool = false

func can_interact(_player_pos: Vector3) -> bool:
	return is_powered and is_player_in_range

func begin_interaction(_player_pos: Vector3) -> bool:
	return can_interact(_player_pos)

func cancel_interaction() -> void:
	pass

func get_focus_point() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)

func get_interaction_priority() -> float:
	return interaction_priority

func update_player_distance(player_pos: Vector3) -> void:
	if not is_powered:
		return
	var dist := global_position.distance_to(player_pos)
	var was_in_range := is_player_in_range
	is_player_in_range = (dist <= interaction_radius)
	if is_player_in_range != was_in_range:
		proximity_changed.emit(is_player_in_range, self)
