class_name CivicReportAccess
extends InteractableBase

## Burnside Production 02 / #122
## One authored physical service tap for bounded Field Hacking interference.
## This is intentionally not a generalized hacking target or network framework.

signal report_interference_requested

var is_compromised: bool = false

@onready var status_label: Label3D = get_node_or_null("StatusLabel") as Label3D

func _ready() -> void:
	interaction_radius = 1.5
	interaction_priority = 1.25
	_update_label()

func can_interact(player_pos: Vector3) -> bool:
	return super.can_interact(player_pos) and not is_compromised

func begin_interaction(player_pos: Vector3) -> bool:
	if not can_interact(player_pos):
		return false

	is_compromised = true
	_update_label()
	state_changed.emit("REPORT_LINK_JAMMED")
	report_interference_requested.emit()
	interaction_completed.emit()
	return true

func reset_access() -> void:
	is_compromised = false
	_update_label()
	state_changed.emit("SERVICE_READY")

func _update_label() -> void:
	if status_label == null:
		return
	status_label.text = "REPORT LINK JAMMED" if is_compromised else "SERVICE TAP"
