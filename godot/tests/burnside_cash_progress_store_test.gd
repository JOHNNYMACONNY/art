extends SceneTree

const STORE_PATH := "res://scripts/progress/burnside_cash_progress_store.gd"
const TEST_PATH := "user://tests/p12_cash_progress_store_test.json"

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
	push_error("[P12_CASH_STORE] " + message)
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
		_fail("BurnsideCashProgressStore does not exist yet")
		return
	var script = load(STORE_PATH)
	if script == null:
		_fail("Cash store could not load")
		return

	var store = script.new()
	store.configure(TEST_PATH)
	if int(store.get_balance()) != 0:
		_fail("Clean Cash store did not start at 0")
		return
	if store.has_vending_hack_receipt() or store.has_vending_breach_receipt():
		_fail("Clean Cash store began with paid receipts")
		return

	if int(store.credit_vending_hack(81)) != 0 or int(store.get_balance()) != 0 or store.has_vending_hack_receipt():
		_fail("Invalid hack reward mutated Cash or consumed receipt")
		return
	if int(store.credit_vending_breach(119)) != 0 or int(store.get_balance()) != 0 or store.has_vending_breach_receipt():
		_fail("Invalid breach reward mutated Cash or consumed receipt")
		return

	if int(store.credit_vending_hack(80)) != 80 or int(store.get_balance()) != 80:
		_fail("First hack did not credit exactly 80")
		return
	if int(store.credit_vending_hack(80)) != 0 or int(store.get_balance()) != 80:
		_fail("Duplicate hack paid twice")
		return
	if int(store.credit_vending_breach(120)) != 120 or int(store.get_balance()) != 200:
		_fail("First breach did not credit exactly 120")
		return
	if int(store.credit_vending_breach(120)) != 0 or int(store.get_balance()) != 200:
		_fail("Duplicate breach paid twice")
		return
	if not store.can_afford(150):
		_fail("Balance 200 did not afford 150")
		return
	if not store.try_spend(150) or int(store.get_balance()) != 50:
		_fail("150 debit from 200 did not leave 50")
		return
	if store.try_spend(150) or int(store.get_balance()) != 50:
		_fail("Insufficient spend mutated Cash")
		return

	var reloaded = script.new()
	reloaded.configure(TEST_PATH)
	if int(reloaded.get_balance()) != 50 or not reloaded.has_vending_hack_receipt() or not reloaded.has_vending_breach_receipt():
		_fail("Fresh store reconstruction lost Cash/receipts")
		return

	_cleanup()
	var unsupported := "{\"version\":999,\"cash\":50,\"vending_hack_paid\":true,\"vending_breach_paid\":true}\n"
	if not _write_raw(unsupported):
		_fail("Could not write unsupported fixture")
		return
	var newer = script.new()
	newer.configure(TEST_PATH)
	if not newer.is_write_blocked() or newer.get_load_status() != "UNSUPPORTED_VERSION" or int(newer.get_balance()) != 0:
		_fail("Unsupported version did not fail safe")
		return
	if int(newer.credit_vending_hack(80)) != 0 or newer.try_spend(1):
		_fail("Unsupported version accepted a write")
		return
	if FileAccess.get_file_as_string(TEST_PATH) != unsupported:
		_fail("Unsupported document was overwritten")
		return

	_cleanup()
	if not _write_raw("{\"version\":1,\"cash\":-5,\"vending_hack_paid\":false,\"vending_breach_paid\":false}\n"):
		_fail("Could not write malformed fixture")
		return
	var malformed = script.new()
	malformed.configure(TEST_PATH)
	if not malformed.is_write_blocked() or malformed.get_load_status() != "MALFORMED" or int(malformed.get_balance()) != 0:
		_fail("Malformed negative balance did not fail safe")
		return

	print("[P12_CASH_STORE] PASS")
	_finish(0)
