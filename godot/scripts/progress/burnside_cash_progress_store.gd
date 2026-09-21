class_name BurnsideCashProgressStore
extends RefCounted

const SCHEMA_VERSION := 1
const PRODUCTION_PATH := "user://burnside_cash_progress.json"
const TEST_DIRECTORY := "user://tests"
const STAGING_SUFFIX := ".tmp"
const MAX_CASH := 2000000000
const VENDING_HACK_REWARD := 80
const VENDING_BREACH_REWARD := 120

var _storage_path: String = ""
var _cash: int = 0
var _vending_hack_paid: bool = false
var _vending_breach_paid: bool = false
var _write_blocked: bool = false
var _write_count: int = 0
var _load_status: String = "UNCONFIGURED"

func configure(storage_path_override: String = "") -> void:
	_storage_path = storage_path_override if not storage_path_override.is_empty() else _resolve_default_storage_path()
	_cash = 0
	_vending_hack_paid = false
	_vending_breach_paid = false
	_write_blocked = false
	_write_count = 0
	_load_status = "CLEAN"
	_load_from_disk()

func _resolve_default_storage_path() -> String:
	for arg in OS.get_cmdline_args():
		var text := String(arg)
		if text.contains("res://tests/") and text.ends_with(".gd"):
			var base := text.get_file().get_basename()
			if base.begins_with("burnside_"):
				base = base.trim_prefix("burnside_")
			return "%s/p12_%s.json" % [TEST_DIRECTORY, base]
	return PRODUCTION_PATH

func _load_from_disk() -> void:
	if _storage_path.is_empty() or not FileAccess.file_exists(_storage_path):
		_load_status = "CLEAN"
		return
	var file := FileAccess.open(_storage_path, FileAccess.READ)
	if file == null:
		_write_blocked = true
		_load_status = "READ_ERROR"
		return
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail_load("MALFORMED")
		return
	var document: Dictionary = parsed
	for key in ["version", "cash", "vending_hack_paid", "vending_breach_paid"]:
		if not document.has(key):
			_fail_load("MALFORMED")
			return
	var version_value = document["version"]
	if typeof(version_value) != TYPE_INT and typeof(version_value) != TYPE_FLOAT:
		_fail_load("MALFORMED")
		return
	if int(version_value) != SCHEMA_VERSION or float(version_value) != float(SCHEMA_VERSION):
		_fail_load("UNSUPPORTED_VERSION")
		return
	var cash_value = document["cash"]
	if typeof(cash_value) != TYPE_INT and typeof(cash_value) != TYPE_FLOAT:
		_fail_load("MALFORMED")
		return
	if float(cash_value) != float(int(cash_value)):
		_fail_load("MALFORMED")
		return
	var loaded_cash := int(cash_value)
	if loaded_cash < 0 or loaded_cash > MAX_CASH:
		_fail_load("MALFORMED")
		return
	if typeof(document["vending_hack_paid"]) != TYPE_BOOL or typeof(document["vending_breach_paid"]) != TYPE_BOOL:
		_fail_load("MALFORMED")
		return
	_cash = loaded_cash
	_vending_hack_paid = bool(document["vending_hack_paid"])
	_vending_breach_paid = bool(document["vending_breach_paid"])
	_load_status = "LOADED"

func _fail_load(status: String) -> void:
	_cash = 0
	_vending_hack_paid = false
	_vending_breach_paid = false
	_write_blocked = true
	_load_status = status

func _ensure_parent_directory() -> bool:
	var base_dir := _storage_path.get_base_dir()
	if base_dir.is_empty():
		return true
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir))
	return error == OK or error == ERR_ALREADY_EXISTS

func _cleanup_staging(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _persist() -> bool:
	if _write_blocked or _storage_path.is_empty() or not _ensure_parent_directory():
		return false
	var staging_path := _storage_path + STAGING_SUFFIX
	_cleanup_staging(staging_path)
	var file := FileAccess.open(staging_path, FileAccess.WRITE)
	if file == null:
		return false
	var payload := {
		"version": SCHEMA_VERSION,
		"cash": _cash,
		"vending_hack_paid": _vending_hack_paid,
		"vending_breach_paid": _vending_breach_paid,
	}
	var wrote := file.store_string(JSON.stringify(payload) + "\n")
	file.flush()
	var write_error := file.get_error()
	file.close()
	if not wrote or write_error != OK:
		_cleanup_staging(staging_path)
		return false
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(staging_path),
		ProjectSettings.globalize_path(_storage_path)
	)
	if rename_error != OK:
		_cleanup_staging(staging_path)
		return false
	_write_count += 1
	return true

func _credit_receipt(amount: int, is_hack: bool) -> int:
	if _write_blocked or amount <= 0:
		return 0
	if (is_hack and _vending_hack_paid) or (not is_hack and _vending_breach_paid):
		return 0
	if _cash > MAX_CASH - amount:
		return 0
	var old_cash := _cash
	var old_hack := _vending_hack_paid
	var old_breach := _vending_breach_paid
	_cash += amount
	if is_hack:
		_vending_hack_paid = true
	else:
		_vending_breach_paid = true
	if not _persist():
		_cash = old_cash
		_vending_hack_paid = old_hack
		_vending_breach_paid = old_breach
		return 0
	return amount

func credit_vending_hack(amount: int) -> int:
	if amount != VENDING_HACK_REWARD:
		return 0
	return _credit_receipt(amount, true)

func credit_vending_breach(amount: int) -> int:
	if amount != VENDING_BREACH_REWARD:
		return 0
	return _credit_receipt(amount, false)

func can_afford(amount: int) -> bool:
	return amount >= 0 and _cash >= amount

func try_spend(amount: int) -> bool:
	if _write_blocked or amount <= 0 or _cash < amount:
		return false
	var old_cash := _cash
	_cash -= amount
	if not _persist():
		_cash = old_cash
		return false
	return true

func get_balance() -> int:
	return _cash

func has_vending_hack_receipt() -> bool:
	return _vending_hack_paid

func has_vending_breach_receipt() -> bool:
	return _vending_breach_paid

func get_storage_path() -> String:
	return _storage_path

func get_load_status() -> String:
	return _load_status

func is_write_blocked() -> bool:
	return _write_blocked

func get_write_count() -> int:
	return _write_count
