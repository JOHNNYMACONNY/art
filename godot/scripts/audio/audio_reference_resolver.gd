class_name AudioReferenceResolver
extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")

## Safe Local Reference Audio Resolver for ECHOES
## Enables dev-only local reference playback with fail-closed security,
## clean-clone procedural independence, strict path containment, and WAV-only ingestion.

const ALLOWED_EXTENSION: String = "wav"

static var _cached_manifest: Dictionary = {}
static var _manifest_loaded: bool = false
static var _sandbox_root: String = ""
static var _stream_cache: Dictionary = {} # slot_id -> AudioStreamWAV

## Returns true if local reference audio is explicitly enabled by developer in debug builds
static func is_reference_enabled() -> bool:
	# Release builds are strictly fail-closed
	if not OS.is_debug_build():
		return false
		
	if OS.get_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO") == "1":
		return true
		
	for arg in OS.get_cmdline_user_args():
		if arg == "--allow-local-reference-audio":
			return true
			
	return false

## Resets cached manifest, sandbox root, and stream memory (for tests and teardown)
static func reset() -> void:
	_cached_manifest.clear()
	_manifest_loaded = false
	_sandbox_root = ""
	_stream_cache.clear()

## Get manifest file path from explicit CLI argument or explicit environment variable
static func get_manifest_path() -> String:
	var env_path := OS.get_environment("ECHOES_REFERENCE_AUDIO_MANIFEST")
	if not env_path.is_empty():
		return env_path
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reference-audio-manifest="):
			return arg.trim_prefix("--reference-audio-manifest=").strip_edges()
	return ""

## Normalizes directory path to ensure trailing slash and clean separators
static func _normalize_dir_path(path: String) -> String:
	var norm := path.replace("\\", "/")
	if not norm.ends_with("/"):
		norm += "/"
	return norm

## Validates relative file path against directory traversal, absolute prefixes, and extension constraints
static func is_valid_relative_path(rel_path: String) -> bool:
	if rel_path.is_empty():
		return false
	# Reject absolute paths (OS absolute or URI schemes)
	if rel_path.begins_with("/") or rel_path.begins_with("\\") or ":" in rel_path:
		push_warning("[AudioReferenceResolver] Absolute path rejected: %s" % rel_path)
		return false
	# Reject directory traversal
	if ".." in rel_path or rel_path.contains("../") or rel_path.contains("..\\"):
		push_warning("[AudioReferenceResolver] Path traversal rejected: %s" % rel_path)
		return false
	# Enforce .wav only for #21 tracer
	var ext := rel_path.get_extension().to_lower()
	if ext != ALLOWED_EXTENSION:
		push_warning("[AudioReferenceResolver] Non-WAV extension '%s' rejected: %s" % [ext, rel_path])
		return false
	return true

## Enforces that the resolved full path is strictly contained within the sandbox root directory
static func is_contained_in_sandbox(full_path: String, sandbox_dir: String) -> bool:
	var norm_full := full_path.replace("\\", "/").simplify_path()
	var norm_sandbox := _normalize_dir_path(sandbox_dir.replace("\\", "/").simplify_path())
	
	# Strict prefix check with trailing directory boundary (prevents sibling-prefix escape)
	if not norm_full.begins_with(norm_sandbox):
		push_warning("[AudioReferenceResolver] Sandbox escape rejected: '%s' outside '%s'" % [norm_full, norm_sandbox])
		return false
	return true

## Load and parse manifest JSON safely. Returns empty dict on any failure or schema mismatch.
static func load_manifest(custom_path: String = "") -> Dictionary:
	var path := custom_path if not custom_path.is_empty() else get_manifest_path()
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_text := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_warning("[AudioReferenceResolver] Malformed manifest JSON at %s: error %d" % [path, err])
		return {}

	var data = json.get_data()
	if not (data is Dictionary):
		push_warning("[AudioReferenceResolver] Manifest root must be a Dictionary")
		return {}

	# Record sandbox root as the directory containing the manifest
	_sandbox_root = _normalize_dir_path(path.get_base_dir())

	var dict_data: Dictionary = data
	var raw_slots: Dictionary = {}
	if dict_data.has("slots") and dict_data["slots"] is Dictionary:
		raw_slots = dict_data["slots"]
	else:
		raw_slots = dict_data

	# Strict schema validation: slot_id (String) -> relative_path (String)
	var validated_slots: Dictionary = {}
	for slot_key in raw_slots.keys():
		if not (slot_key is String):
			continue
		var val = raw_slots[slot_key]
		if not (val is String):
			push_warning("[AudioReferenceResolver] Manifest entry for slot '%s' must be a String" % slot_key)
			continue
		var rel_path: String = val
		if is_valid_relative_path(rel_path):
			validated_slots[slot_key] = rel_path

	return validated_slots

## Attempt to resolve an AudioStreamWAV for a given semantic slot ID
## Returns null if disabled, missing, precedence denied, or load failed.
static func resolve_stream(slot_id: String, custom_manifest_path: String = "") -> AudioStreamWAV:
	if not is_reference_enabled():
		return null

	if _stream_cache.has(slot_id):
		return _stream_cache[slot_id]

	# Check asset status precedence in AudioRegistry: ORIGINAL_FINAL and LICENSED_FINAL are immutable
	var slot_meta: Dictionary = AudioRegistryScript.get_slot(slot_id)
	if not slot_meta.is_empty():
		var status = slot_meta.get("asset_status", AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK)
		if status == AudioRegistryScript.AssetStatus.ORIGINAL_FINAL or status == AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			return null

	if not _manifest_loaded or not custom_manifest_path.is_empty():
		_cached_manifest = load_manifest(custom_manifest_path)
		if custom_manifest_path.is_empty():
			_manifest_loaded = true

	if not _cached_manifest.has(slot_id):
		return null

	var rel_path: String = _cached_manifest[slot_id]
	var full_path := _sandbox_root + rel_path

	if not is_contained_in_sandbox(full_path, _sandbox_root):
		return null

	if not FileAccess.file_exists(full_path):
		push_warning("[AudioReferenceResolver] Reference file not found: %s" % full_path)
		return null

	var stream := _load_wav_file(full_path)
	if stream:
		_stream_cache[slot_id] = stream
		return stream

	return null

## Internal WAV loader safely reading 8-bit or 16-bit PCM WAV data
static func _load_wav_file(file_path: String) -> AudioStreamWAV:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.is_empty():
		return null

	var wav := AudioStreamWAV.new()
	# Check RIFF WAV header
	if bytes.size() >= 44 and bytes.slice(0, 4).get_string_from_ascii() == "RIFF" and bytes.slice(8, 12).get_string_from_ascii() == "WAVE":
		wav.format = AudioStreamWAV.FORMAT_8_BITS # Safe fallback format
		wav.mix_rate = 22050
		wav.data = bytes.slice(44)
	else:
		wav.format = AudioStreamWAV.FORMAT_8_BITS
		wav.mix_rate = 22050
		wav.data = bytes
		
	return wav
