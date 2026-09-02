class_name CivicServiceAlarm
extends InteractableBase

## Burnside Production 01 / #119
## One authored Gears civic-service tamper box used to prove the Report path.
## This is intentionally not a generalized crime or witness system.

signal report_requested(report_source: String, observed_position: Vector3, contact_source: String)

@export var report_enabled: bool = true
@export var report_source: String = "gears_civic_alarm"
@export var contact_source: String = "civic_alarm_direct_observation"

var is_triggered: bool = false

@onready var status_label: Label3D = get_node_or_null("StatusLabel") as Label3D

func _ready() -> void:
	interaction_radius = 2.4
	interaction_priority = 1.35
	_update_label()

func can_interact(player_pos: Vector3) -> bool:
	return super.can_interact(player_pos) and not is_triggered

func begin_interaction(player_pos: Vector3) -> bool:
	if not can_interact(player_pos):
		return false
	return trigger_report(player_pos)

func trigger_report(observed_position: Vector3) -> bool:
	if is_triggered:
		return false
	is_triggered = true
	_update_label()
	state_changed.emit("TRIGGERED")
	if report_enabled:
		report_requested.emit(report_source, observed_position, contact_source)
	interaction_completed.emit()
	return true

func reset_alarm() -> void:
	is_triggered = false
	_update_label()
	state_changed.emit("READY")

func _update_label() -> void:
	if status_label == null:
		return
	status_label.text = "REPORT SENT" if is_triggered and report_enabled else ("ALARM FAULT" if is_triggered else "SERVICE ALARM")
