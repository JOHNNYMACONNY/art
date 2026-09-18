class_name MayorBurnContactProgressStore
extends RefCounted

const SCHEMA_VERSION := 1
const PRODUCTION_PATH := "user://burnside_contact_progress.json"
const TEST_DIRECTORY := "user://tests"
const STAGING_SUFFIX := ".tmp"

enum ContactState {
	UNESTABLISHED,
	KNOWN,
}

var _storage_path: String = ""
var _state: ContactState = ContactState.UNESTABLISHED
var _write_blocked: bool = false
var _write_count: int = 0
var _load_status: String = "UNCONFIGURED"

func configure(storage_path_override: String = "") -> void:
	_storage_path = storage_path_override if not storage_path_override.is_empty() else _resolve_default_storage_path()
	_state = ContactState.UNESTABLISHED
	_write_blocked = false
	_write_count = 0
	_load_status = "CLEAN"
	_load_from_disk()

func _resolve_default_storage_path() -> String:
	for arg in OS.get_cmdline_args():
		var text := String(arg)
		if text.contains("res://tests/") and text.ends_with(".gd"):
			var basename := text.get_file().get_basename()
			return "%s/p10_%s.json" % [TEST_DIRECTORY, basename]
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
	if not document.has("version"):
		_write_blocked = true
		_load_status = "MALFORMED"
		return
	var version_value = document["version"]
	if typeof(version_value) != TYPE_INT and typeof(version_value) != TYPE_FLOAT:
		_write_blocked = true
		_load_status = "MALFORMED"
		return
	if int(version_value) != SCHEMA_VERSION or float(version_value) != float(SCHEMA_VERSION):
		_write_blocked = true
		_load_status = "UNSUPPORTED_VERSION"
		return
	if not document.has("mayor_burn_contact") or typeof(document["mayor_burn_contact"]) != TYPE_STRING:
		_write_blocked = true
		_load_status = "MALFORMED"
		return
	var state_name := String(document["mayor_burn_contact"])
	if state_name == "UNESTABLISHED":
		_state = ContactState.UNESTABLISHED
	elif state_name == "KNOWN":
		_state = ContactState.KNOWN
	else:
		_write_blocked = true
		_load_status = "MALFORMED"
		return
	_load_status = "LOADED"

func _ensure_parent_directory() -> bool:
	var base_dir := _storage_path.get_base_dir()
	if base_dir.is_empty():
		return true
	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	var error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	return error == OK or error == ERR_ALREADY_EXISTS

func _cleanup_staging_file(staging_path: String) -> void:
	if staging_path.is_empty() or not FileAccess.file_exists(staging_path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(staging_path))

func _persist() -> bool:
	if _write_blocked or _storage_path.is_empty() or not _ensure_parent_directory():
		return false
	var payload := {
		"version": SCHEMA_VERSION,
		"mayor_burn_contact": get_state_name(),
	}
	var staging_path := _storage_path + STAGING_SUFFIX
	_cleanup_staging_file(staging_path)
	var file := FileAccess.open(staging_path, FileAccess.WRITE)
	if file == null:
		return false
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

func mark_known() -> bool:
	if _write_blocked or _state == ContactState.KNOWN:
		return false
	var previous := _state
	_state = ContactState.KNOWN
	if not _persist():
		_state = previous
		return false
	return true

func is_known() -> bool:
	return _state == ContactState.KNOWN

func get_state_name() -> String:
	return ContactState.keys()[_state]

func get_write_count() -> int:
	return _write_count

func get_load_status() -> String:
	return _load_status

func is_write_blocked() -> bool:
	return _write_blocked

func get_storage_path() -> String:
	return _storage_path
