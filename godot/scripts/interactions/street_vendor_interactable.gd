class_name StreetVendorInteractable
extends InteractableBase

# Interaction Proxy for Street Vendor Smuggler Depot on Commercial Frontage
# Participates in player target arbitration, scrap trade, and vehicle tune-ups

@onready var vendor: Node = get_parent()
var _current_player: CharacterBody3D = null
var _current_vehicle: Node3D = null
var _cash_runtime: Node = null

func _ready() -> void:
	interaction_priority = 1.8
	interaction_radius = 2.8
	sensory_radius = 5.0
	is_powered = true

func set_player_reference(player: CharacterBody3D) -> void:
	_current_player = player

func set_vehicle_reference(vehicle: Node3D) -> void:
	_current_vehicle = vehicle

func set_cash_runtime(runtime: Node) -> void:
	_cash_runtime = runtime

func get_action_verb() -> String:
	if not vendor:
		return "TRADE"
	var state_val = vendor.get("current_state")
	# VendorState: READY=0, TUNED=1, DAMAGED=2, RAMMED=3
	if state_val == 3:
		return "WRECKED"
	if vendor.has_method("is_tune_up_active") and vendor.is_tune_up_active():
		return "TUNED"
	return "TUNE-UP"

func can_interact(_player_pos: Vector3) -> bool:
	if not vendor:
		return false
	if "is_rammed" in vendor and vendor.is_rammed:
		return false
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if not vendor:
		return false
	if "is_rammed" in vendor and vendor.is_rammed:
		return false

	if _cash_runtime != null and _cash_runtime.has_method("attempt_vendor_tune_up"):
		var success := bool(_cash_runtime.call("attempt_vendor_tune_up", vendor, _current_vehicle))
		if success:
			interaction_completed.emit()
		return success

	if vendor.has_method("purchase_tune_up"):
		var res: Dictionary = vendor.purchase_tune_up()
		interaction_completed.emit()
		return res.get("success", false)

	return false

func get_interaction_priority() -> float:
	return interaction_priority
