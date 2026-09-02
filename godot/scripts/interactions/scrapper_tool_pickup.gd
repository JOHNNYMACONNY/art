class_name ScrapperToolPickup
extends InteractableBase

var _acquired: bool = false

func acquire() -> bool:
	if _acquired:
		return false
	_acquired = true
	is_powered = false
	is_player_in_range = false
	visible = false
	monitoring = false
	return true

func reset_pickup() -> void:
	_acquired = false
	is_powered = true
	visible = true
	monitoring = true

func is_acquired() -> bool:
	return _acquired
