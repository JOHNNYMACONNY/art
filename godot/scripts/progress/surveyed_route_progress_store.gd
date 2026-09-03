class_name SurveyedRouteProgressStore
extends RefCounted

const SCHEMA_VERSION := 1
const PRODUCTION_PATH := "user://burnside_mapped_knowledge.json"
const TEST_DIRECTORY := "user://tests"

var _storage_path: String = ""
var _surveyed_routes: Dictionary = {}
var _write_blocked: bool = false
var _write_count: int = 0
var _load_status: String = "UNCONFIGURED"

func configure(storage_path_override: String = "") -> void:
	_storage_path = storage_path_override if not storage_path_override.is_empty() else _resolve_default_storage_path()
	_surveyed_routes.clear()
	_write_blocked = false
	_write_count = 0
	_load_status = "CLEAN"
	_load_from_disk()

func _resolve_default_storage_path() -> String:
	for arg in OS.get_cmdline_args():
		var text := String(arg)
		if text.contains("res://tests/") and text.ends_with(".gd"):
			var basename := text.get_file().get_basename()
			return "%s/p06_%s.json" % [TEST_DIRECTORY, basename]
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

	if not document.has("surveyed_routes") or typeof(document["surveyed_routes"]) != TYPE_ARRAY:
		_write_blocked = true
		_load_status = "MALFORMED"
		return
	var routes: Array = document["surveyed_routes"]
	for route_value in routes:
		if typeof(route_value) != TYPE_STRING or String(route_value).is_empty():
			_write_blocked = true
			_surveyed_routes.clear()
			_load_status = "MALFORMED"
			return
		_surveyed_routes[String(route_value)] = true
	_load_status = "LOADED"

func _ensure_parent_directory() -> bool:
	var base_dir := _storage_path.get_base_dir()
	if base_dir.is_empty():
		return true
	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	var error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	return error == OK or error == ERR_ALREADY_EXISTS

func _persist_supported_document() -> bool:
	if _write_blocked or _storage_path.is_empty() or not _ensure_parent_directory():
		return false
	var file := FileAccess.open(_storage_path, FileAccess.WRITE)
	if file == null:
		return false
	var payload := {
		"version": SCHEMA_VERSION,
		"surveyed_routes": Array(get_surveyed_routes()),
	}
	file.store_string(JSON.stringify(payload) + "\n")
	file.close()
	_write_count += 1
	return true

func is_surveyed(route_id: String) -> bool:
	return not route_id.is_empty() and _surveyed_routes.has(route_id)

func mark_surveyed(route_id: String) -> bool:
	if route_id.is_empty() or _write_blocked or is_surveyed(route_id):
		return false
	_surveyed_routes[route_id] = true
	if not _persist_supported_document():
		_surveyed_routes.erase(route_id)
		return false
	return true

func get_surveyed_routes() -> PackedStringArray:
	var routes := PackedStringArray()
	for route_id in _surveyed_routes.keys():
		routes.append(String(route_id))
	routes.sort()
	return routes

func get_write_count() -> int:
	return _write_count

func get_load_status() -> String:
	return _load_status

func is_write_blocked() -> bool:
	return _write_blocked

func get_storage_path() -> String:
	return _storage_path
