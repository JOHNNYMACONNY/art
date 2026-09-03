extends Control

const ROUTE_ID := "gears.service_alley_north_connector"
const STORAGE_PATH := "user://p06_web_reload_probe.json"
const WRITE_OK := "P06_WRITE_OK"
const RELOAD_OK := "P06_RELOAD_OK"
const FAIL := "P06_FAIL"
const STORE_SCRIPT := preload("res://scripts/progress/surveyed_route_progress_store.gd")

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
			"route_id": ROUTE_ID,
			"storage_path": STORAGE_PATH,
		})
		return

	var store = STORE_SCRIPT.new()
	store.configure(STORAGE_PATH)

	if store.is_write_blocked():
		_publish(FAIL, store, "WRITE_BLOCKED")
		return

	if store.is_surveyed(ROUTE_ID):
		if store.get_load_status() != "LOADED":
			_publish(FAIL, store, "SURVEYED_WITHOUT_LOADED_STATUS")
			return
		_publish(RELOAD_OK, store, "")
		return

	if store.get_load_status() != "CLEAN":
		_publish(FAIL, store, "UNEXPECTED_INITIAL_LOAD_STATUS")
		return

	if not store.mark_surveyed(ROUTE_ID):
		_publish(FAIL, store, "MARK_SURVEYED_FAILED")
		return

	if not store.is_surveyed(ROUTE_ID) or store.get_write_count() != 1:
		_publish(FAIL, store, "WRITE_DID_NOT_COMMIT_EXPECTED_STATE")
		return

	JavaScriptBridge.force_fs_sync()
	await get_tree().create_timer(1.0).timeout
	_publish(WRITE_OK, store, "")

func _publish(status: String, store, reason: String) -> void:
	var payload := {
		"status": status,
		"reason": reason,
		"route_id": ROUTE_ID,
		"storage_path": store.get_storage_path(),
		"load_status": store.get_load_status(),
		"surveyed": store.is_surveyed(ROUTE_ID),
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
		var script := "window.P06_WEB_PROBE = %s; document.title = %s;" % [
			JSON.stringify(payload),
			JSON.stringify(status),
		]
		JavaScriptBridge.eval(script, true)
