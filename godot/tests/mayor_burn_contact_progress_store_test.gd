extends SceneTree

const StoreScript = preload("res://scripts/progress/mayor_burn_contact_progress_store.gd")
const TEST_PATH := "user://tests/p10_mayor_burn_contact_progress_store_test.json"

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _ensure_test_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))

func _write_raw(text: String) -> bool:
	_ensure_test_dir()
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var ok := file.store_string(text)
	file.close()
	return ok

func _finish(code: int) -> void:
	_cleanup()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P10_CONTACT_STORE] " + message)
	_finish(1)

func _run() -> void:
	_cleanup()

	var store = StoreScript.new()
	store.configure(TEST_PATH)
	if store.get_state_name() != "UNESTABLISHED" or store.is_known():
		_fail("Clean store did not start UNESTABLISHED")
		return
	if not store.mark_known():
		_fail("First KNOWN transition did not persist")
		return
	if not store.is_known() or store.get_state_name() != "KNOWN":
		_fail("Persisted state is not KNOWN")
		return
	if store.get_write_count() != 1:
		_fail("First transition must write exactly once")
		return
	if store.mark_known() or store.get_write_count() != 1:
		_fail("Duplicate KNOWN transition duplicated persistence")
		return

	var reloaded = StoreScript.new()
	reloaded.configure(TEST_PATH)
	if not reloaded.is_known() or reloaded.get_load_status() != "LOADED":
		_fail("Fresh store instance did not reload KNOWN")
		return

	_cleanup()
	var unsupported := "{\"version\":999,\"mayor_burn_state\":\"KNOWN\"}\n"
	if not _write_raw(unsupported):
		_fail("Could not create unsupported-version fixture")
		return
	var newer = StoreScript.new()
	newer.configure(TEST_PATH)
	if newer.is_known() or not newer.is_write_blocked() or newer.get_load_status() != "UNSUPPORTED_VERSION":
		_fail("Unsupported version did not fail safe")
		return
	if newer.mark_known():
		_fail("Unsupported version was overwritten")
		return
	var untouched := FileAccess.get_file_as_string(TEST_PATH)
	if untouched != unsupported:
		_fail("Unsupported document was mutated")
		return

	_cleanup()
	if not _write_raw("{\"version\":1,\"mayor_burn_state\":\"MYSTERY\"}\n"):
		_fail("Could not create malformed-state fixture")
		return
	var malformed = StoreScript.new()
	malformed.configure(TEST_PATH)
	if malformed.is_known() or not malformed.is_write_blocked() or malformed.get_load_status() != "MALFORMED":
		_fail("Malformed relationship state did not fail safe")
		return

	print("[P10_CONTACT_STORE] PASS")
	_finish(0)
