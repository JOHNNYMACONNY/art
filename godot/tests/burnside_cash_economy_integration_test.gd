extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CASH_TEST_PATH := "user://tests/p12_cash_economy_integration_test.json"

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for path in [CASH_TEST_PATH, CASH_TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_cleanup()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P12_CASH_ECONOMY] " + message)
	await _finish(1)

func _run() -> void:
	_cleanup()
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame

	var runtime := _scene.get_node_or_null("BurnsideCashEconomyRuntime")
	var player = _scene.get("player")
	var vendor = _scene.get("street_vendor")
	var vending = _scene.get("vending_machine")
	var bike = _scene.get("courier_bike")
	var coupe = _scene.get("muscle_coupe")
	var cash_notice := _scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/CashNotice") as Label
	if runtime == null or player == null or vendor == null or vending == null or bike == null or coupe == null or cash_notice == null:
		await _fail("P12 production composition is incomplete")
		return

	for method_name in ["get_progress_store", "award_vending_hack", "award_vending_breach", "attempt_vendor_tune_up", "get_balance"]:
		if not runtime.has_method(method_name):
			await _fail("Cash runtime missing " + method_name)
			return

	var store = runtime.call("get_progress_store")
	if store == null or String(store.call("get_storage_path")) != CASH_TEST_PATH:
		await _fail("Cash runtime did not use isolated deterministic test storage")
		return

	# Breach-first path: +120 is real but insufficient for the 150 vendor price.
	vending.call("breach_terminal", Vector3.BACK)
	await process_frame
	if int(runtime.call("get_balance")) != 120:
		await _fail("First physical vending breach did not credit 120 Cash")
		return
	if not cash_notice.visible or not String(cash_notice.text).contains("120"):
		await _fail("Breach Cash notice did not expose real balance")
		return

	vendor.call("reset_vendor")
	bike.tune_up_time_remaining = 0.0
	coupe.tune_up_time_remaining = 0.0
	var bike_speed_before: float = float(bike.get_effective_max_speed())
	var coupe_speed_before: float = float(coupe.get_effective_max_speed())
	if bool(runtime.call("attempt_vendor_tune_up", vendor, bike)):
		await _fail("Vendor purchase succeeded with only 120 Cash")
		return
	if int(runtime.call("get_balance")) != 120 or bike.is_tuned_up or coupe.is_tuned_up:
		await _fail("Insufficient vendor purchase mutated balance or vehicle")
		return

	# Reset the physical terminal; durable breach receipt remains. First hack pays +80.
	vending.call("reset_vending_machine")
	await process_frame
	var vend_interactable = vending.get_node_or_null("VendingMachineInteractable")
	if vend_interactable == null:
		await _fail("Vending interactable missing")
		return
	player.global_position = vending.global_position + Vector3(1.0, 0.0, 0.0)
	vend_interactable.call("set_player_reference", player)
	vend_interactable.call("update_player_distance", player.global_position)
	if not bool(vend_interactable.call("begin_interaction", player.global_position)):
		await _fail("Physical vending hack interaction failed")
		return
	await process_frame
	if int(runtime.call("get_balance")) != 200:
		await _fail("First physical vending hack did not bring durable Cash to 200")
		return
	if not cash_notice.visible or not String(cash_notice.text).contains("200"):
		await _fail("Hack Cash notice did not expose Cash 200")
		return

	# Replayed/reset terminal cannot pay hack receipt again.
	vending.call("reset_vending_machine")
	await process_frame
	player.global_position = vending.global_position + Vector3(1.0, 0.0, 0.0)
	vend_interactable.call("update_player_distance", player.global_position)
	if not bool(vend_interactable.call("begin_interaction", player.global_position)):
		await _fail("Repeated physical terminal interaction failed")
		return
	await process_frame
	if int(runtime.call("get_balance")) != 200:
		await _fail("Repeated terminal hack duplicated durable Cash")
		return
	if String(cash_notice.text).contains("+80"):
		await _fail("Paid receipt replay falsely advertised +80 Cash")
		return

	# Actual retained Action route purchases the tune-up for the active vehicle only.
	vendor.call("reset_vendor")
	bike.tune_up_time_remaining = 0.0
	coupe.tune_up_time_remaining = 0.0
	bike.global_position = vendor.global_position + Vector3(1.0, 0.05, 0.0)
	player.global_position = bike.global_position
	player.is_mounted = true
	bike.occupant = player
	_scene.set("active_vehicle", bike)
	var vendor_interactable = vendor.get_node_or_null("StreetVendorInteractable")
	if vendor_interactable == null:
		await _fail("Street Vendor interactable missing")
		return
	vendor_interactable.call("update_player_distance", bike.global_position)
	_scene.set("_active_target", vendor_interactable)
	_scene.call("_on_action_pressed")
	await process_frame
	if int(runtime.call("get_balance")) != 50:
		await _fail("Successful 150-Cash vendor purchase did not leave 50")
		return
	if not bike.is_tuned_up or float(bike.get_effective_max_speed()) <= bike_speed_before:
		await _fail("Active Courier Bike did not receive retained tune-up")
		return
	if coupe.is_tuned_up or not is_equal_approx(float(coupe.get_effective_max_speed()), coupe_speed_before):
		await _fail("Inactive Muscle Coupe was incorrectly tuned")
		return
	if not cash_notice.visible or not String(cash_notice.text).contains("50"):
		await _fail("Successful vendor Cash notice did not expose Cash 50")
		return

	# Already-active tune-up cannot double-debit.
	_scene.call("_on_action_pressed")
	await process_frame
	if int(runtime.call("get_balance")) != 50:
		await _fail("Repeat active tune-up debited twice")
		return

	# Replay resets physical props/vehicle tune-up but preserves Cash + receipts.
	player.is_mounted = false
	bike.occupant = null
	_scene.set("active_vehicle", null)
	_scene.call("reset_slice")
	await process_frame
	await process_frame
	if int(runtime.call("get_balance")) != 50:
		await _fail("Replay erased durable Cash")
		return
	if not bool(store.call("has_vending_hack_receipt")) or not bool(store.call("has_vending_breach_receipt")):
		await _fail("Replay erased durable payout receipts")
		return
	if bike.is_tuned_up or coupe.is_tuned_up:
		await _fail("Replay failed to clear transient tune-up state")
		return

	print("[P12_CASH_ECONOMY] PASS")
	await _finish(0)
