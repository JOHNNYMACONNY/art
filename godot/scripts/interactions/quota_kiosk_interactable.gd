class_name QuotaKioskInteractable
extends InteractableBase

# Interaction Proxy for Municipal Quota Kiosk
# Participates in player target arbitration and biometric proximity detection

@onready var kiosk: Node = get_parent()
var _current_player: CharacterBody3D = null

func _ready() -> void:
	interaction_priority = 1.8
	interaction_radius = 2.4
	sensory_radius = 6.0
	is_powered = true

func set_player_reference(player: CharacterBody3D) -> void:
	_current_player = player

func can_interact(_player_pos: Vector3) -> bool:
	if not kiosk:
		return false
	if "is_breached" in kiosk and kiosk.is_breached:
		return false
	if "is_quota_fulfilled" in kiosk and kiosk.is_quota_fulfilled:
		return false
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if kiosk and kiosk.has_method("deposit_scrap"):
		var deposit_amount: int = 150
		var res: Dictionary = kiosk.deposit_scrap(deposit_amount)
		interaction_completed.emit()
		return res.get("success", false)
	return false

func get_interaction_priority() -> float:
	return interaction_priority
