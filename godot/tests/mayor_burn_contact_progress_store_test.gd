extends SceneTree

const STORE_SCRIPT_PATH := "res://scripts/progress/mayor_burn_contact_progress_store.gd"
const TEST_PATH := "user://tests/p10_mayor_burn_contact_progress_store_test.json"

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
	push_error("[P10_BURN_CONTACT_STORE] " + message)
	_finish(1)

func _run() -> void:
	_cleanup()
	var script = load(STORE_SCRIPT_PATH)
	if script == null:
		_fail("Progress store script is missing")
		return

	var store = script.new()
	store.call("configure", TEST_PATH)
	if String(store.call("get_state_name")) != "UNESTABLISHED" or bool(store.call("is_known")):
		_fail("Clean store did not start UNESTABLISHED")
		return
	if not bool(store.call("mark_known")):
		_fail("First KNOWN milestone did not persist")
		return
	if String(store.call("get_state_name")) != "KNOWN" or not bool(store.call("is_known")):
		_fail("Known state was not exposed after milestone")
		return
	if int(store.call("get_write_count")) != 1:
		_fail("First milestone did not write exactly once")
		return
	if bool(store.call("mark_known")) or int(store.call("get_write_count")) != 1:
		_fail("Duplicate milestone was not idempotent")
		return

	var reloaded = script.new()
	reloaded.call("configure", TEST_PATH)
	if not bool(reloaded.call("is_known")) or String(reloaded.call("get_state_name")) != "KNOWN":
		_fail("Fresh store instance did not reload KNOWN")
		return

	# Unsupported data must become read-only/fail-safe and never be overwritten.
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 999, "mayor_burn_contact": "KNOWN"}) + "\n")
	file.close()
	var unsupported = script.new()
	unsupported.call("configure", TEST_PATH)
	if not bool(unsupported.call("is_write_blocked")) or String(unsupported.call("get_load_status")) != "UNSUPPORTED_VERSION":
		_fail("Newer schema did not enter fail-safe mode")
		return
	if bool(unsupported.call("mark_known")):
		_fail("Fail-safe store accepted a write")
		return
	var verify := FileAccess.open(TEST_PATH, FileAccess.READ)
	var raw := verify.get_as_text()
	verify.close()
	if not raw.replace(" ", "").contains('"version":999'):
		_fail("Unsupported data was silently overwritten")
		return

	print("[P10_BURN_CONTACT_STORE] PASS")
	_finish(0)
