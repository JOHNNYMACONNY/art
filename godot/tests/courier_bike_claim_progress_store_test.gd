extends SceneTree

const STORE_PATH := "res://scripts/progress/courier_bike_claim_progress_store.gd"
const TEST_PATH := "user://tests/p11_courier_bike_claim_progress_store_test.json"

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish(code: int) -> void:
	_cleanup()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P11_COURIER_CLAIM_STORE] " + message)
	_finish(1)

func _write_raw(text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var ok := file.store_string(text)
	file.close()
	return ok

func _run() -> void:
	_cleanup()
	if not ResourceLoader.exists(STORE_PATH):
		_fail("CourierBikeClaimProgressStore does not exist yet")
		return
	var script = load(STORE_PATH)
	if script == null:
		_fail("CourierBikeClaimProgressStore could not load")
		return

	var store = script.new()
	store.configure(TEST_PATH)
	if store.get_state_name() != "UNCLAIMED" or store.is_claimed():
		_fail("Clean store did not start UNCLAIMED")
		return
	if not store.mark_claimed():
		_fail("First CLAIMED transition did not persist")
		return
	if not store.is_claimed() or store.get_state_name() != "CLAIMED":
		_fail("Persisted state is not CLAIMED")
		return
	if int(store.get_write_count()) != 1:
		_fail("First claim must write exactly once")
		return
	if store.mark_claimed() or int(store.get_write_count()) != 1:
		_fail("Duplicate claim duplicated persistence")
		return

	var reloaded = script.new()
	reloaded.configure(TEST_PATH)
	if not reloaded.is_claimed() or reloaded.get_load_status() != "LOADED":
		_fail("Fresh store instance did not reload CLAIMED")
		return

	_cleanup()
	var unsupported := "{\"version\":999,\"courier_bike_state\":\"CLAIMED\"}\n"
	if not _write_raw(unsupported):
		_fail("Could not create unsupported-version fixture")
		return
	var newer = script.new()
	newer.configure(TEST_PATH)
	if newer.is_claimed() or not newer.is_write_blocked() or newer.get_load_status() != "UNSUPPORTED_VERSION":
		_fail("Unsupported version did not fail safe")
		return
	if newer.mark_claimed():
		_fail("Unsupported version was overwritten")
		return
	if FileAccess.get_file_as_string(TEST_PATH) != unsupported:
		_fail("Unsupported document was mutated")
		return

	_cleanup()
	if not _write_raw("{\"version\":1,\"courier_bike_state\":\"MYSTERY\"}\n"):
		_fail("Could not create malformed-state fixture")
		return
	var malformed = script.new()
	malformed.configure(TEST_PATH)
	if malformed.is_claimed() or not malformed.is_write_blocked() or malformed.get_load_status() != "MALFORMED":
		_fail("Malformed claim state did not fail safe")
		return

	print("[P11_COURIER_CLAIM_STORE] PASS")
	_finish(0)
