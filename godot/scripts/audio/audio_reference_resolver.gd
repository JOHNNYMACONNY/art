class_name AudioReferenceResolver
extends RefCounted

## Sandboxed Local Reference Audio Resolver for ECHOES
## Loads dev-opt-in replacement audio streams from a sandboxed relative directory.
## Strictly fail-closed: requires OS.is_debug_build() and developer opt-in.
## Uses AudioStreamWAV.load_from_file() with bounded diagnostic reason codes.

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")

const ENV_ALLOW_REFERENCE := "ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO"
const ENV_MANIFEST_PATH := "ECHOES_REFERENCE_AUDIO_MANIFEST"
const CMDLINE_ALLOW_FLAG := "--allow-local-reference-audio"
const CMDLINE_MANIFEST_ARG := "--reference-audio-manifest="
const ALLOWED_EXTENSION := "wav"

# Reason Codes for Diagnostics
const REASON_MANIFEST_MALFORMED := "REFERENCE_MANIFEST_MALFORMED"
const REASON_MANIFEST_INVALID_SCHEMA := "REFERENCE_MANIFEST_INVALID_SCHEMA"
const REASON_MANIFEST_VERSION_UNSUPPORTED := "REFERENCE_MANIFEST_VERSION_UNSUPPORTED"
const REASON_SLOT_UNKNOWN := "REFERENCE_SLOT_UNKNOWN"
const REASON_PATH_ABSOLUTE := "REFERENCE_PATH_ABSOLUTE"
const REASON_PATH_TRAVERSAL := "REFERENCE_PATH_TRAVERSAL"
const REASON_PATH_OUTSIDE_ROOT := "REFERENCE_PATH_OUTSIDE_ROOT"
const REASON_PATH_INVALID_EXTENSION := "REFERENCE_PATH_INVALID_EXTENSION"
const REASON_FILE_MISSING := "REFERENCE_FILE_MISSING"
const REASON_WAV_INVALID := "REFERENCE_WAV_INVALID"
const REASON_STATUS_FINAL := "REFERENCE_STATUS_FINAL"

static var _cached_manifest: Dictionary = {}
static var _manifest_loaded: bool = false
static var _sandbox_root: String = ""
static var _cached_streams: Dictionary = {}

static func _has_semantic_slot(slot_id: String) -> bool:
	return AudioRegistryScript.has_slot(slot_id) or UIAudioSemanticRegistryScript.has_slot(slot_id)

static func _get_semantic_slot(slot_id: String) -> Dictionary:
	if AudioRegistryScript.has_slot(slot_id):
		return AudioRegistryScript.get_slot(slot_id)
	return UIAudioSemanticRegistryScript.get_slot(slot_id)

static func is_reference_enabled() -> bool:
	if not OS.is_debug_build():
		return false
	if OS.get_environment(ENV_ALLOW_REFERENCE) == "1":
		return true
	if OS.get_cmdline_user_args().has(CMDLINE_ALLOW_FLAG):
		return true
	return false

static func get_manifest_path() -> String:
	var env_path := OS.get_environment(ENV_MANIFEST_PATH)
	if not env_path.is_empty():
		return env_path
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(CMDLINE_MANIFEST_ARG):
			return arg.substr(CMDLINE_MANIFEST_ARG.length())
	return ""

static func is_valid_relative_path(path: String) -> bool:
	if path.is_empty():
		return false
	if path.begins_with("/") or path.begins_with("\\") or path.contains(":"):
		return false
	if path.contains(".."):
		return false
	if path.get_extension().to_lower() != ALLOWED_EXTENSION:
		return false
	return true

static func _normalize_dir_path(path: String) -> String:
	var norm := path.replace("\\", "/").simplify_path()
	if not norm.ends_with("/"):
		norm += "/"
	return norm

static func is_contained_in_sandbox(full_path: String, sandbox_dir: String) -> bool:
	var norm_sandbox := _normalize_dir_path(sandbox_dir)
	var norm_full := full_path.replace("\\", "/").simplify_path()
	if not norm_full.begins_with(norm_sandbox):
		return false
	return true

static func load_manifest(manifest_path: String = "") -> Dictionary:
	var path := manifest_path if not manifest_path.is_empty() else get_manifest_path()
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_str := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		push_warning("[AudioReferenceResolver] %s" % REASON_MANIFEST_MALFORMED)
		return {}

	var data = json.get_data()
	if not (data is Dictionary):
		push_warning("[AudioReferenceResolver] %s" % REASON_MANIFEST_INVALID_SCHEMA)
		return {}

	if not data.has("version") or not (data["version"] is int or data["version"] is float):
		push_warning("[AudioReferenceResolver] %s" % REASON_MANIFEST_INVALID_SCHEMA)
		return {}
	if data["version"] is String or floor(data["version"]) != data["version"] or int(data["version"]) != 1:
		push_warning("[AudioReferenceResolver] %s" % REASON_MANIFEST_INVALID_SCHEMA)
		return {}

	if not data.has("slots") or not (data["slots"] is Dictionary):
		push_warning("[AudioReferenceResolver] %s" % REASON_MANIFEST_INVALID_SCHEMA)
		return {}

	var raw_slots: Dictionary = data["slots"]
	for k in raw_slots.keys():
		if not (k is String) or not (raw_slots[k] is String):
			push_warning("[AudioReferenceResolver] %s" % REASON_MANIFEST_INVALID_SCHEMA)
			return {}

	var base_dir := path.get_base_dir()
	if base_dir.is_empty():
		base_dir = "."
	_sandbox_root = _normalize_dir_path(base_dir)

	var valid_slots: Dictionary = {}
	for slot_id in raw_slots.keys():
		var rel_path: String = raw_slots[slot_id]
		if not _has_semantic_slot(slot_id):
			push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_SLOT_UNKNOWN])
			continue

		if rel_path.begins_with("/") or rel_path.begins_with("\\") or rel_path.contains(":"):
			push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_PATH_ABSOLUTE])
			continue

		if rel_path.contains(".."):
			push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_PATH_TRAVERSAL])
			continue

		if rel_path.get_extension().to_lower() != ALLOWED_EXTENSION:
			push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_PATH_INVALID_EXTENSION])
			continue

		var full_path := _sandbox_root + rel_path
		if not is_contained_in_sandbox(full_path, _sandbox_root):
			push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_PATH_OUTSIDE_ROOT])
			continue

		valid_slots[slot_id] = rel_path

	return valid_slots

static func resolve_stream(slot_id: String, override_manifest_path: String = "") -> AudioStreamWAV:
	if not is_reference_enabled():
		return null

	if _cached_streams.has(slot_id):
		return _cached_streams[slot_id]

	if not _manifest_loaded or not override_manifest_path.is_empty():
		_cached_manifest = load_manifest(override_manifest_path)
		_manifest_loaded = true

	if not _cached_manifest.has(slot_id):
		return null

	var slot_def: Dictionary = _get_semantic_slot(slot_id)
	if not slot_def.is_empty():
		var status: int = slot_def.get("asset_status", -1)
		if not AudioRegistryScript.is_reference_allowed_for_status(status):
			push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_STATUS_FINAL])
			return null

	var rel_path: String = _cached_manifest[slot_id]
	var full_path := _sandbox_root + rel_path

	if not is_contained_in_sandbox(full_path, _sandbox_root):
		push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_PATH_OUTSIDE_ROOT])
		return null

	if not FileAccess.file_exists(full_path):
		push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_FILE_MISSING])
		return null

	var stream := AudioStreamWAV.load_from_file(full_path)
	if stream == null or stream.data == null or stream.data.is_empty():
		push_warning("[AudioReferenceResolver] %s: %s" % [slot_id, REASON_WAV_INVALID])
		return null

	_cached_streams[slot_id] = stream
	return stream

static func reset() -> void:
	_cached_manifest.clear()
	_manifest_loaded = false
	_sandbox_root = ""
	_cached_streams.clear()
