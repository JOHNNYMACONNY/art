class_name CourierBikeClaimProgressStore
extends RefCounted

const SCHEMA_VERSION := 1
const PRODUCTION_PATH := "user://burnside_courier_bike_claim.json"
const TEST_DIRECTORY := "user://tests"
const STAGING_SUFFIX := ".tmp"

enum ClaimState {
	UNCLAIMED,
	CLAIMED,
}

var _storage_path: String = ""
var _state: ClaimState = ClaimState.UNCLAIMED
var _write_blocked: bool = false
var _write_count: int = 0
var _load_status: String = "UNCONFIGURED"

func configure(storage_path_override: String = "") -> void:
	_storage_path = storage_path_override if not storage_path_override.is_empty() else _resolve_default_storage_path()
	_state = ClaimState.UNCLAIMED
	_write_blocked = false
	_write_count = 0
	_load_status = "CLEAN"
	_load_from_disk()

func _resolve_default_storage_path() -> String:
	for arg in OS.get_cmdline_args():
		var text := String(arg)
		if text.contains("res://tests/") and text.ends_with(".gd"):
			return "%s/p11_%s.json" % [TEST_DIRECTORY, text.get_file().get_basename()]
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
		_write_blocked = true
		_load_status = "MALFORMED"
		return
	var document: Dictionary = parsed
	if not document.has("version") or not document.has("courier_bike_state"):
		_write_blocked = true
		_load_status = "MALFORMED"
		return

	var version_value = document["version"]
	if (typeof(version_value) != TYPE_INT and typeof(version_value) != TYPE_FLOAT) \
	or int(version_value) != SCHEMA_VERSION \
	or float(version_value) != float(SCHEMA_VERSION):
		_write_blocked = true
		_load_status = "UNSUPPORTED_VERSION" if (typeof(version_value) == TYPE_INT or typeof(version_value) == TYPE_FLOAT) else "MALFORMED"
		return

	if typeof(document["courier_bike_state"]) != TYPE_STRING:
		_write_blocked = true
		_load_status = "MALFORMED"
		return
	match String(document["courier_bike_state"]):
		"UNCLAIMED":
			_state = ClaimState.UNCLAIMED
		"CLAIMED":
			_state = ClaimState.CLAIMED
		_:
			_write_blocked = true
			_load_status = "MALFORMED"
			return
	_load_status = "LOADED"

func _ensure_parent_directory() -> bool:
	var base_dir := _storage_path.get_base_dir()
	if base_dir.is_empty():
		return true
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir))
	return error == OK or error == ERR_ALREADY_EXISTS

func _cleanup_staging_file(path: String) -> void:
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _persist() -> bool:
	if _write_blocked or _storage_path.is_empty() or not _ensure_parent_directory():
		return false
	var staging_path := _storage_path + STAGING_SUFFIX
	_cleanup_staging_file(staging_path)
	var file := FileAccess.open(staging_path, FileAccess.WRITE)
	if file == null:
		return false
	var payload := {
		"version": SCHEMA_VERSION,
		"courier_bike_state": get_state_name(),
	}
	var wrote := file.store_string(JSON.stringify(payload) + "\n")
	file.flush()
	var write_error := file.get_error()
	file.close()
	if not wrote or write_error != OK:
		_cleanup_staging_file(staging_path)
		return false
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(staging_path),
		ProjectSettings.globalize_path(_storage_path)
	)
	if rename_error != OK:
		_cleanup_staging_file(staging_path)
		return false
	_write_count += 1
	return true

func is_claimed() -> bool:
	return _state == ClaimState.CLAIMED

func mark_claimed() -> bool:
	if _write_blocked or is_claimed():
		return false
	var previous := _state
	_state = ClaimState.CLAIMED
	if not _persist():
		_state = previous
		return false
	return true

func get_state_name() -> String:
	return ClaimState.keys()[_state]

func get_write_count() -> int:
	return _write_count

func get_load_status() -> String:
	return _load_status

func is_write_blocked() -> bool:
	return _write_blocked

func get_storage_path() -> String:
	return _storage_path
