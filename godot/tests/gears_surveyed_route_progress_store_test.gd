extends SceneTree

const STORE_SCRIPT_PATH := "res://scripts/progress/surveyed_route_progress_store.gd"
const ROUTE_ID := "gears.service_alley_north_connector"
const TEST_PATH := "user://tests/p06_progress_store_contract.json"
const MALFORMED_PATH := "user://tests/p06_progress_store_malformed.json"
const NEWER_PATH := "user://tests/p06_progress_store_newer.json"
const ATOMIC_DIR := "user://tests/p06_progress_store_atomic_guard"
const ATOMIC_PATH := ATOMIC_DIR + "/mapped.json"
const OWNER_RWX := 448
const OWNER_RX := 320

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[GEARS_SURVEYED_ROUTE_PROGRESS] %s" % message)
	_cleanup()
	quit(1)

func _cleanup() -> void:
	var atomic_dir_abs := ProjectSettings.globalize_path(ATOMIC_DIR)
	if DirAccess.dir_exists_absolute(atomic_dir_abs):
		FileAccess.set_unix_permissions(atomic_dir_abs, OWNER_RWX)
		for atomic_file in [ATOMIC_PATH, ATOMIC_PATH + ".tmp"]:
			if FileAccess.file_exists(atomic_file):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(atomic_file))
		DirAccess.remove_absolute(atomic_dir_abs)
	for path in [TEST_PATH, MALFORMED_PATH, NEWER_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _write_raw(path: String, text: String) -> bool:
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var wrote := file.store_string(text)
	file.close()
	return wrote

func _read_raw(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text

func _run() -> void:
	_cleanup()
	var store_script := load(STORE_SCRIPT_PATH)
	if store_script == null:
		_fail("Production 06 SurveyedRouteProgressStore is absent")
		return

	var store = store_script.new()
	if not store.has_method("configure") or not store.has_method("mark_surveyed") or not store.has_method("is_surveyed"):
		_fail("SurveyedRouteProgressStore contract is incomplete")
		return
	store.call("configure", TEST_PATH)
	if bool(store.call("is_surveyed", ROUTE_ID)):
		_fail("Clean progress started with the route already surveyed")
		return
	if String(store.call("get_load_status")) != "CLEAN":
		_fail("Clean progress did not report CLEAN load status")
		return
	if not bool(store.call("mark_surveyed", ROUTE_ID)):
		_fail("First valid survey did not persist")
		return
	if not bool(store.call("is_surveyed", ROUTE_ID)) or int(store.call("get_write_count")) != 1:
		_fail("First valid survey did not become known with exactly one write")
		return
	if bool(store.call("mark_surveyed", ROUTE_ID)) or int(store.call("get_write_count")) != 1:
		_fail("Repeated survey duplicated durable progress")
		return

	var reloaded = store_script.new()
	reloaded.call("configure", TEST_PATH)
	if not bool(reloaded.call("is_surveyed", ROUTE_ID)):
		_fail("Fresh store instance did not reload surveyed knowledge")
		return
	if String(reloaded.call("get_load_status")) != "LOADED":
		_fail("Fresh store instance did not report LOADED status")
		return

	var default_store = store_script.new()
	default_store.call("configure")
	var default_path := String(default_store.call("get_storage_path"))
	if default_path == "user://burnside_mapped_knowledge.json" or not default_path.begins_with("user://tests/"):
		_fail("Automated test execution was not isolated from owner mapped knowledge")
		return

	var malformed_raw := "{ this is not valid JSON :: P06 }"
	if not _write_raw(MALFORMED_PATH, malformed_raw):
		_fail("Could not create malformed persistence fixture")
		return
	var malformed = store_script.new()
	malformed.call("configure", MALFORMED_PATH)
	if not bool(malformed.call("is_write_blocked")) or String(malformed.call("get_load_status")) != "MALFORMED":
		_fail("Malformed progress did not enter fail-safe write-blocked mode")
		return
	if bool(malformed.call("mark_surveyed", ROUTE_ID)):
		_fail("Malformed progress accepted a destructive write")
		return
	if _read_raw(MALFORMED_PATH) != malformed_raw:
		_fail("Malformed progress bytes were silently destroyed")
		return

	var newer_raw := "{\"version\":99,\"surveyed_routes\":[\"future.route\"],\"future_field\":true}"
	if not _write_raw(NEWER_PATH, newer_raw):
		_fail("Could not create newer-version persistence fixture")
		return
	var newer = store_script.new()
	newer.call("configure", NEWER_PATH)
	if not bool(newer.call("is_write_blocked")) or String(newer.call("get_load_status")) != "UNSUPPORTED_VERSION":
		_fail("Newer progress version did not enter fail-safe write-blocked mode")
		return
	if bool(newer.call("mark_surveyed", ROUTE_ID)):
		_fail("Unsupported newer progress accepted a destructive write")
		return
	if _read_raw(NEWER_PATH) != newer_raw:
		_fail("Unsupported newer progress bytes were silently destroyed")
		return

	# Linux CI can make the parent directory non-writable while keeping the existing
	# progress file writable. Direct in-place truncation would still succeed there;
	# a durable staging+replace write must fail without touching the known-good bytes.
	if OS.get_name() == "Linux":
		var original_atomic_raw := "{\"version\":1,\"surveyed_routes\":[]}\n"
		if not _write_raw(ATOMIC_PATH, original_atomic_raw):
			_fail("Could not create atomic-write preservation fixture")
			return
		var atomic_store = store_script.new()
		atomic_store.call("configure", ATOMIC_PATH)
		if String(atomic_store.call("get_load_status")) != "LOADED":
			_fail("Atomic-write fixture did not load as supported progress")
			return
		var atomic_dir_abs := ProjectSettings.globalize_path(ATOMIC_DIR)
		if FileAccess.set_unix_permissions(atomic_dir_abs, OWNER_RX) != OK:
			_fail("Could not make atomic-write fixture directory non-writable")
			return
		var accepted_failed_replace := bool(atomic_store.call("mark_surveyed", ROUTE_ID))
		FileAccess.set_unix_permissions(atomic_dir_abs, OWNER_RWX)
		if accepted_failed_replace:
			_fail("Progress write mutated the live file instead of failing safely when atomic replacement was unavailable")
			return
		if bool(atomic_store.call("is_surveyed", ROUTE_ID)) or int(atomic_store.call("get_write_count")) != 0:
			_fail("Failed durable write leaked surveyed state or write accounting")
			return
		if _read_raw(ATOMIC_PATH) != original_atomic_raw:
			_fail("Failed durable write changed previously valid progress bytes")
			return

	print("[GEARS_SURVEYED_ROUTE_PROGRESS] PASS")
	_cleanup()
	quit(0)
