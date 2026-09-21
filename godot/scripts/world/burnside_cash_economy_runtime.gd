class_name BurnsideCashEconomyRuntime
extends Node

const CashStoreScript = preload("res://scripts/progress/burnside_cash_progress_store.gd")
const VENDOR_TUNE_UP_COST := 150

var _progress_store = CashStoreScript.new()
var _last_feedback: String = ""

func configure(storage_path_override: String = "") -> void:
	_progress_store.configure(storage_path_override)

func get_progress_store():
	return _progress_store

func get_balance() -> int:
	return int(_progress_store.get_balance())

func get_last_feedback() -> String:
	return _last_feedback

func award_vending_hack(reward: int) -> int:
	var credited := int(_progress_store.credit_vending_hack(reward))
	if credited > 0:
		_last_feedback = "+%d CASH // BALANCE %d" % [credited, get_balance()]
	else:
		_last_feedback = "CASH CACHE EMPTY // BALANCE %d" % get_balance()
	return credited

func award_vending_breach(reward: int) -> int:
	var credited := int(_progress_store.credit_vending_breach(reward))
	if credited > 0:
		_last_feedback = "+%d CASH // BALANCE %d" % [credited, get_balance()]
	else:
		_last_feedback = "CASH CACHE EMPTY // BALANCE %d" % get_balance()
	return credited

func attempt_vendor_tune_up(vendor: Node, vehicle: Node3D) -> bool:
	if vendor == null or not vendor.has_method("can_trade") or not vendor.has_method("is_tune_up_active"):
		_last_feedback = "VENDOR UNAVAILABLE // CASH %d" % get_balance()
		return false
	if not bool(vendor.call("can_trade")):
		_last_feedback = "VENDOR UNAVAILABLE // CASH %d" % get_balance()
		return false
	if bool(vendor.call("is_tune_up_active")):
		_last_feedback = "TUNE-UP ACTIVE // CASH %d" % get_balance()
		return false
	if vehicle == null or not vehicle.has_method("apply_tune_up"):
		_last_feedback = "TUNE-UP REQUIRES VEHICLE // CASH %d" % get_balance()
		return false
	if get_balance() < VENDOR_TUNE_UP_COST:
		_last_feedback = "NEED %d // CASH %d" % [VENDOR_TUNE_UP_COST, get_balance()]
		return false
	if not vendor.has_method("complete_authorized_tune_up"):
		_last_feedback = "VENDOR UNAVAILABLE // CASH %d" % get_balance()
		return false
	if not _progress_store.try_spend(VENDOR_TUNE_UP_COST):
		_last_feedback = "PAYMENT FAILED // CASH %d" % get_balance()
		return false
	_last_feedback = "TUNE-UP ACQUIRED // -%d // CASH %d" % [VENDOR_TUNE_UP_COST, get_balance()]
	vendor.call("complete_authorized_tune_up", VENDOR_TUNE_UP_COST, vehicle)
	return true
