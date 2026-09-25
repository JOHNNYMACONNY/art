extends Control

const STORAGE_PATH := "user://p13_web_cash_probe.json"
const WRITE_OK := "P13_WRITE_OK"
const RELOAD_OK := "P13_RELOAD_OK"
const FAIL := "P13_FAIL"
const STORE_SCRIPT := preload("res://scripts/progress/burnside_cash_progress_store.gd")

var _status_label: Label

func _ready() -> void:
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_status_label)
	await _run_probe()

func _run_probe() -> void:
	if not OS.has_feature("web"):
		_publish_raw(FAIL, {
			"status": FAIL,
			"reason": "NOT_WEB",
			"storage_path": STORAGE_PATH,
		})
		return

	var store = STORE_SCRIPT.new()
	store.configure(STORAGE_PATH)
	for method_name in ["credit_mission_01", "credit_mission_02", "has_mission_01_receipt", "has_mission_02_receipt"]:
		if not store.has_method(method_name):
			_publish(FAIL, store, "MISSING_API_" + method_name.to_upper())
			return

	if store.is_write_blocked():
		_publish(FAIL, store, "WRITE_BLOCKED")
		return

	var mission_01_paid := bool(store.call("has_mission_01_receipt"))
	var mission_02_paid := bool(store.call("has_mission_02_receipt"))
	if mission_01_paid or mission_02_paid:
		if store.get_load_status() != "LOADED":
			_publish(FAIL, store, "PAID_WITHOUT_LOADED_STATUS")
			return
		if int(store.get_balance()) != 770 or not mission_01_paid or not mission_02_paid:
			_publish(FAIL, store, "RELOADED_STATE_MISMATCH")
			return
		if int(store.get_write_count()) != 0:
			_publish(FAIL, store, "RELOAD_PERFORMED_WRITE")
			return
		_publish(RELOAD_OK, store, "")
		return

	if store.get_load_status() != "CLEAN" or int(store.get_balance()) != 0:
		_publish(FAIL, store, "UNEXPECTED_INITIAL_STATE")
		return
	if int(store.call("credit_mission_01", 320)) != 320:
		_publish(FAIL, store, "MISSION_01_WRITE_FAILED")
		return
	if int(store.call("credit_mission_02", 450)) != 450:
		_publish(FAIL, store, "MISSION_02_WRITE_FAILED")
		return
	if int(store.get_balance()) != 770 \
	or not bool(store.call("has_mission_01_receipt")) \
	or not bool(store.call("has_mission_02_receipt")) \
	or int(store.get_write_count()) != 2:
		_publish(FAIL, store, "WRITE_STATE_MISMATCH")
		return

	JavaScriptBridge.force_fs_sync()
	await get_tree().create_timer(1.0).timeout
	_publish(WRITE_OK, store, "")

func _publish(status: String, store, reason: String) -> void:
	var payload := {
		"status": status,
		"reason": reason,
		"storage_path": store.get_storage_path(),
		"load_status": store.get_load_status(),
		"cash": store.get_balance(),
		"mission_01_paid": bool(store.call("has_mission_01_receipt")) if store.has_method("has_mission_01_receipt") else false,
		"mission_02_paid": bool(store.call("has_mission_02_receipt")) if store.has_method("has_mission_02_receipt") else false,
		"write_count": store.get_write_count(),
		"write_blocked": store.is_write_blocked(),
		"userfs_persistent_hint": OS.is_userfs_persistent(),
		"engine_version": String(Engine.get_version_info().get("string", "")),
	}
	_publish_raw(status, payload)

func _publish_raw(status: String, payload: Dictionary) -> void:
	_status_label.text = "%s\n%s" % [status, JSON.stringify(payload)]
	DisplayServer.window_set_title(status)
	if OS.has_feature("web"):
		var script := "window.P13_WEB_PROBE = %s; document.title = %s;" % [
			JSON.stringify(payload),
			JSON.stringify(status),
		]
		JavaScriptBridge.eval(script, true)
