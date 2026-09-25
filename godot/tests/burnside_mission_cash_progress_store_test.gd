extends SceneTree

const STORE_PATH := "res://scripts/progress/burnside_cash_progress_store.gd"
const TEST_PATH := "user://tests/p13_mission_cash_progress_store_test.json"

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
	push_error("[P13_MISSION_CASH_STORE] " + message)
	_finish(1)

func _write_raw(text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var ok := file.store_string(text)
	file.close()
	return ok

func _read_raw() -> String:
	return FileAccess.get_file_as_string(TEST_PATH)

func _require_api(store) -> bool:
	for method_name in [
		"credit_mission_01",
		"credit_mission_02",
		"has_mission_01_receipt",
		"has_mission_02_receipt",
	]:
		if not store.has_method(method_name):
			_fail("Cash store missing P13 API: " + method_name)
			return false
	return true

func _run() -> void:
	_cleanup()
	var script = load(STORE_PATH)
	if script == null:
		_fail("Cash store could not load")
		return

	# Clean v2.
	var store = script.new()
	store.configure(TEST_PATH)
	if not _require_api(store):
		return
	if int(store.get_balance()) != 0:
		_fail("Clean v2 store did not start at 0 Cash")
		return
	if store.has_vending_hack_receipt() or store.has_vending_breach_receipt():
		_fail("Clean v2 store began with vending receipts")
		return
	if bool(store.call("has_mission_01_receipt")) or bool(store.call("has_mission_02_receipt")):
		_fail("Clean v2 store began with mission receipts")
		return

	# Exact mission reward validation: bad values cannot mutate or consume.
	if int(store.call("credit_mission_01", 319)) != 0 or int(store.get_balance()) != 0 or bool(store.call("has_mission_01_receipt")):
		_fail("Invalid Mission 01 reward mutated Cash or consumed receipt")
		return
	if int(store.call("credit_mission_02", 451)) != 0 or int(store.get_balance()) != 0 or bool(store.call("has_mission_02_receipt")):
		_fail("Invalid Mission 02 reward mutated Cash or consumed receipt")
		return

	if int(store.call("credit_mission_01", 320)) != 320 or int(store.get_balance()) != 320:
		_fail("First Mission 01 payout was not exactly 320")
		return
	if int(store.call("credit_mission_01", 320)) != 0 or int(store.get_balance()) != 320:
		_fail("Mission 01 duplicate receipt paid twice")
		return
	if int(store.call("credit_mission_02", 450)) != 450 or int(store.get_balance()) != 770:
		_fail("First Mission 02 payout was not exactly 450")
		return
	if int(store.call("credit_mission_02", 450)) != 0 or int(store.get_balance()) != 770:
		_fail("Mission 02 duplicate receipt paid twice")
		return

	var reloaded = script.new()
	reloaded.configure(TEST_PATH)
	if not _require_api(reloaded):
		return
	if int(reloaded.get_balance()) != 770 \
	or not bool(reloaded.call("has_mission_01_receipt")) \
	or not bool(reloaded.call("has_mission_02_receipt")):
		_fail("Fresh store reconstruction lost mission Cash/receipts")
		return

	# Exact P12 v1 -> P13 v2 migration. Preserve Cash + vending receipts exactly.
	_cleanup()
	var v1 := "{\"version\":1,\"cash\":137,\"vending_hack_paid\":true,\"vending_breach_paid\":false}\n"
	if not _write_raw(v1):
		_fail("Could not write valid P12 v1 fixture")
		return
	var migrated = script.new()
	migrated.configure(TEST_PATH)
	if not _require_api(migrated):
		return
	if migrated.is_write_blocked():
		_fail("Valid P12 v1 fixture blocked migration")
		return
	if int(migrated.get_balance()) != 137:
		_fail("Migration changed existing P12 Cash")
		return
	if not migrated.has_vending_hack_receipt() or migrated.has_vending_breach_receipt():
		_fail("Migration changed existing vending receipts")
		return
	if bool(migrated.call("has_mission_01_receipt")) or bool(migrated.call("has_mission_02_receipt")):
		_fail("Migration did not initialize mission receipts false")
		return
	if int(migrated.get_write_count()) != 1:
		_fail("Migration did not persist atomically exactly once")
		return
	var migrated_document = JSON.parse_string(_read_raw())
	if typeof(migrated_document) != TYPE_DICTIONARY \
	or int(migrated_document.get("version", -1)) != 2 \
	or int(migrated_document.get("cash", -1)) != 137 \
	or migrated_document.get("vending_hack_paid", null) != true \
	or migrated_document.get("vending_breach_paid", null) != false \
	or migrated_document.get("mission_01_paid", null) != false \
	or migrated_document.get("mission_02_paid", null) != false:
		_fail("Migration did not persist the exact v2 document")
		return

	# Existing P12 Cash remains additive after migration.
	if int(migrated.call("credit_mission_01", 320)) != 320 or int(migrated.get_balance()) != 457:
		_fail("Mission 01 payout was not additive to migrated P12 Cash")
		return

	# Existing P12 vending contracts remain exact and one-time in schema v2.
	if int(migrated.credit_vending_hack(80)) != 0 or int(migrated.get_balance()) != 457:
		_fail("Migrated paid vending-hack receipt paid again")
		return
	if int(migrated.credit_vending_breach(120)) != 120 or int(migrated.get_balance()) != 577:
		_fail("Migrated unpaid vending-breach receipt did not pay exact 120")
		return

	# Unsupported newer schema fails closed and is never overwritten.
	_cleanup()
	var newer_raw := "{\"version\":999,\"cash\":50,\"vending_hack_paid\":true,\"vending_breach_paid\":true,\"mission_01_paid\":true,\"mission_02_paid\":true}\n"
	if not _write_raw(newer_raw):
		_fail("Could not write unsupported fixture")
		return
	var newer = script.new()
	newer.configure(TEST_PATH)
	if not newer.is_write_blocked() or newer.get_load_status() != "UNSUPPORTED_VERSION" or int(newer.get_balance()) != 0:
		_fail("Unsupported newer schema did not fail closed")
		return
	if _read_raw() != newer_raw:
		_fail("Unsupported newer document was overwritten")
		return

	# Malformed v1 must not be silently migrated or destroyed.
	_cleanup()
	var malformed_v1 := "{\"version\":1,\"cash\":-5,\"vending_hack_paid\":false,\"vending_breach_paid\":false}\n"
	if not _write_raw(malformed_v1):
		_fail("Could not write malformed v1 fixture")
		return
	var malformed = script.new()
	malformed.configure(TEST_PATH)
	if not malformed.is_write_blocked() or malformed.get_load_status() != "MALFORMED" or int(malformed.get_balance()) != 0:
		_fail("Malformed v1 did not fail closed")
		return
	if _read_raw() != malformed_v1:
		_fail("Malformed v1 document was overwritten")
		return

	print("[P13_MISSION_CASH_STORE] PASS")
	_finish(0)
