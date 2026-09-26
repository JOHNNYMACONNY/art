extends SceneTree

const STORE_PATH := "res://scripts/progress/burnside_cash_progress_store.gd"
const TEST_PATH := "user://tests/p14_scrap_bash_bar_store_test.json"

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
	push_error("[P14_BASH_BAR_STORE] " + message)
	_finish(1)

func _write_raw(text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var ok := file.store_string(text)
	file.close()
	return ok

func _read_document() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _require_api(store) -> bool:
	for method_name in ["purchase_courier_bike_bash_bar", "has_courier_bike_bash_bar_receipt"]:
		if not store.has_method(method_name):
			_fail("Cash store missing P14 API: " + method_name)
			return false
	return true

func _run() -> void:
	_cleanup()
	var script = load(STORE_PATH)
	if script == null:
		_fail("Cash store could not load")
		return

	# Exact P13 v2 -> P14 v3 migration.
	var v2 := "{\"version\":2,\"cash\":770,\"vending_hack_paid\":true,\"vending_breach_paid\":true,\"mission_01_paid\":true,\"mission_02_paid\":true}\n"
	if not _write_raw(v2):
		_fail("Could not write valid v2 fixture")
		return
	var store = script.new()
	store.configure(TEST_PATH)
	if not _require_api(store):
		return
	if store.is_write_blocked():
		_fail("Valid v2 fixture blocked migration")
		return
	if int(store.get_balance()) != 770:
		_fail("v2 migration changed Cash")
		return
	if not store.has_mission_01_receipt() or not store.has_mission_02_receipt():
		_fail("v2 migration changed mission receipts")
		return
	if bool(store.call("has_courier_bike_bash_bar_receipt")):
		_fail("v2 migration invented bash-bar ownership")
		return
	var migrated := _read_document()
	if int(migrated.get("version", -1)) != 3 	or migrated.get("courier_bike_bash_bar_paid", null) != false:
		_fail("v2 migration did not persist exact v3 bash-bar field")
		return

	# Wrong price cannot mutate.
	if bool(store.call("purchase_courier_bike_bash_bar", 499)):
		_fail("Wrong 499 price purchased bash bar")
		return
	if int(store.get_balance()) != 770 or bool(store.call("has_courier_bike_bash_bar_receipt")):
		_fail("Wrong price mutated Cash or receipt")
		return

	# Exact purchase is one atomic Cash+receipt write.
	var writes_before := int(store.get_write_count())
	if not bool(store.call("purchase_courier_bike_bash_bar", 500)):
		_fail("Exact 500 purchase failed")
		return
	if int(store.get_balance()) != 270 or not bool(store.call("has_courier_bike_bash_bar_receipt")):
		_fail("Exact purchase did not atomically produce Cash 270 + receipt")
		return
	if int(store.get_write_count()) != writes_before + 1:
		_fail("Exact purchase did not persist exactly once")
		return

	# Duplicate cannot double-debit.
	if bool(store.call("purchase_courier_bike_bash_bar", 500)):
		_fail("Duplicate bash-bar purchase succeeded")
		return
	if int(store.get_balance()) != 270:
		_fail("Duplicate bash-bar purchase debited twice")
		return

	var reloaded = script.new()
	reloaded.configure(TEST_PATH)
	if not _require_api(reloaded):
		return
	if int(reloaded.get_balance()) != 270 or not bool(reloaded.call("has_courier_bike_bash_bar_receipt")):
		_fail("Fresh store reconstruction lost bash-bar transaction")
		return

	# Valid v3 insufficient balance rejects with zero mutation.
	_cleanup()
	var v3_insufficient := "{\"version\":3,\"cash\":499,\"vending_hack_paid\":false,\"vending_breach_paid\":false,\"mission_01_paid\":false,\"mission_02_paid\":false,\"courier_bike_bash_bar_paid\":false}\n"
	if not _write_raw(v3_insufficient):
		_fail("Could not write insufficient v3 fixture")
		return
	var poor = script.new()
	poor.configure(TEST_PATH)
	if not _require_api(poor):
		return
	if bool(poor.call("purchase_courier_bike_bash_bar", 500)):
		_fail("499 Cash purchased 500-Cash bash bar")
		return
	if int(poor.get_balance()) != 499 or bool(poor.call("has_courier_bike_bash_bar_receipt")):
		_fail("Insufficient purchase mutated state")
		return

	print("[P14_BASH_BAR_STORE] PASS")
	_finish(0)
