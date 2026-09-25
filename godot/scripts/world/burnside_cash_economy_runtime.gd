class_name BurnsideCashEconomyRuntime
extends Node

const CashStoreScript = preload("res://scripts/progress/burnside_cash_progress_store.gd")
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const CivicRepossessionMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const VENDOR_TUNE_UP_COST := 150

var _progress_store = CashStoreScript.new()
var _last_feedback: String = ""
var _mission_payouts_bound: bool = false

func _ready() -> void:
	call_deferred("_try_bind_mission_payouts")

func _process(_delta: float) -> void:
	if not _mission_payouts_bound:
		_try_bind_mission_payouts()

func configure(storage_path_override: String = "") -> void:
	_progress_store.configure(storage_path_override)

func get_progress_store():
	return _progress_store

func get_balance() -> int:
	return int(_progress_store.get_balance())

func get_last_feedback() -> String:
	return _last_feedback

func _try_bind_mission_payouts() -> void:
	if _mission_payouts_bound:
		return
	var root_controller := get_parent()
	if root_controller == null:
		return
	var mission_one := root_controller.get_node_or_null("MissionScrapJobRuntime")
	var mission_two := root_controller.get_node_or_null("CivicRepossessionRuntime")
	if mission_one == null or mission_two == null:
		return
	if not mission_one.has_signal("scrap_job_completed") or not mission_two.has_signal("civic_repossession_completed"):
		return

	var mission_one_callable := Callable(self, "_on_scrap_job_completed")
	var mission_two_callable := Callable(self, "_on_civic_repossession_completed")
	if not mission_one.is_connected("scrap_job_completed", mission_one_callable):
		mission_one.connect("scrap_job_completed", mission_one_callable)
	if not mission_two.is_connected("civic_repossession_completed", mission_two_callable):
		mission_two.connect("civic_repossession_completed", mission_two_callable)
	_mission_payouts_bound = true
	set_process(false)

func _publish_feedback() -> void:
	var root_controller := get_parent()
	if root_controller != null and root_controller.has_method("_show_cash_notice"):
		root_controller.call("_show_cash_notice", _last_feedback)

func _on_scrap_job_completed() -> void:
	award_mission_01(ScrapJobMissionScript.PAYOFF_CREDITS)
	_publish_feedback()

func _on_civic_repossession_completed() -> void:
	award_mission_02(CivicRepossessionMissionScript.PAYOFF_CREDITS)
	_publish_feedback()

func award_mission_01(reward: int) -> int:
	if reward != ScrapJobMissionScript.PAYOFF_CREDITS:
		_last_feedback = "PAYMENT REJECTED // BALANCE %d" % get_balance()
		return 0
	var already_paid := bool(_progress_store.has_mission_01_receipt())
	var credited := int(_progress_store.credit_mission_01(reward))
	if credited > 0:
		_last_feedback = "JOB PAID // +%d CASH // BALANCE %d" % [credited, get_balance()]
	elif already_paid or bool(_progress_store.has_mission_01_receipt()):
		_last_feedback = "PAYMENT ALREADY CLEARED // BALANCE %d" % get_balance()
	else:
		_last_feedback = "PAYMENT FAILED // BALANCE %d" % get_balance()
	return credited

func award_mission_02(reward: int) -> int:
	if reward != CivicRepossessionMissionScript.PAYOFF_CREDITS:
		_last_feedback = "PAYMENT REJECTED // BALANCE %d" % get_balance()
		return 0
	var already_paid := bool(_progress_store.has_mission_02_receipt())
	var credited := int(_progress_store.credit_mission_02(reward))
	if credited > 0:
		_last_feedback = "BURN PAID // +%d CASH // BALANCE %d" % [credited, get_balance()]
	elif already_paid or bool(_progress_store.has_mission_02_receipt()):
		_last_feedback = "PAYMENT ALREADY CLEARED // BALANCE %d" % get_balance()
	else:
		_last_feedback = "PAYMENT FAILED // BALANCE %d" % get_balance()
	return credited

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
