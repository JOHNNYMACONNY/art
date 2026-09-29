extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const BIKE_SCENE_PATH := "res://scenes/vehicles/courier_bike.tscn"
const CASH_TEST_PATH := "user://tests/p12_courier_bike_scrap_bash_bar_integration_test.json"
const CLAIM_TEST_PATH := "user://tests/p11_burnside_courier_bike_scrap_bash_bar_integration_test.json"
const CONTACT_TEST_PATH := "user://tests/p10_burnside_courier_bike_scrap_bash_bar_integration_test.json"

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for base in [CASH_TEST_PATH, CLAIM_TEST_PATH, CONTACT_TEST_PATH]:
		for path in [base, base + ".tmp"]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish(code: int) -> void:
	if _wanted_runtime != null:
		if _wanted_runtime.has_method("reset_runtime"):
			_wanted_runtime.call("reset_runtime")
		_wanted_runtime.set_process(true)
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_cleanup()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P14_BASH_BAR_INTEGRATION] " + message)
	await _finish(1)

func _spawn_production_scene() -> Node:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame
	await process_frame
	return scene

func _run() -> void:
	_cleanup()
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload missing")
		return

	_scene = await _spawn_production_scene()
	if _scene == null:
		await _fail("Production scene could not load")
		return
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")

	var mod_runtime := _scene.get_node_or_null("BurnGarageCourierBikeScrapperModRuntime")
	var claim_runtime := _scene.get_node_or_null("BurnGarageCourierBikeClaimRuntime")
	var contact_runtime := _scene.get_node_or_null("MayorBurnContactServiceRuntime")
	var repair_runtime := _scene.get_node_or_null("BurnGarageRepairRuntime")
	var cash_runtime := _scene.get_node_or_null("BurnsideCashEconomyRuntime")
	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	var player = _scene.get("player")
	var bike = _scene.get("courier_bike")
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var claim_socket := district.get_node_or_null("CourierBikeClaimSocket") as Marker3D if district != null else null
	var repair_socket := district.get_node_or_null("MissionDestinationSocket") as Marker3D if district != null else null
	if mod_runtime == null or claim_runtime == null or contact_runtime == null or repair_runtime == null or cash_runtime == null 	or player == null or bike == null or touch_ui == null or claim_socket == null or repair_socket == null:
		await _fail("P14 production composition is incomplete")
		return

	for method_name in ["get_mod_interactable", "get_affordance_text", "attempt_purchase", "get_price", "restore_mod_from_receipt"]:
		if not mod_runtime.has_method(method_name):
			await _fail("P14 runtime missing " + method_name)
			return
	if not bike.has_method("has_scrap_bash_bar") or not bike.has_method("set_scrap_bash_bar_installed"):
		await _fail("Courier Bike missing bash-bar API")
		return

	var cash_store = cash_runtime.call("get_progress_store")
	var claim_store = claim_runtime.call("get_progress_store")
	var contact_store = contact_runtime.call("get_progress_store")
	if cash_store == null or claim_store == null or contact_store == null:
		await _fail("Required durable stores are unavailable")
		return
	if String(cash_store.call("get_storage_path")) != CASH_TEST_PATH:
		await _fail("Cash runtime did not use deterministic P14 test storage")
		return
	if int(mod_runtime.call("get_price")) != 500:
		await _fail("P14 price is not locked to 500")
		return
	if bool(bike.call("has_scrap_bash_bar")):
		await _fail("Clean production Bike began modified")
		return

	player.global_position = claim_socket.global_position
	player.is_mounted = false
	_scene.set("active_vehicle", null)
	bike.global_position = claim_socket.global_position
	bike.current_speed = 0.0
	bike.velocity = Vector3.ZERO

	if bool(mod_runtime.call("attempt_purchase")):
		await _fail("Unclaimed Bike purchased bash bar")
		return

	if not bool(contact_store.call("mark_known")):
		await _fail("Could not establish Burn KNOWN fixture")
		return
	if not bool(claim_runtime.call("attempt_claim")):
		await _fail("Retained claim path could not establish CLAIMED Bike")
		return

	# One mission payout is insufficient.
	if int(cash_runtime.call("award_mission_01", 320)) != 320:
		await _fail("Could not establish 320-Cash authored fixture")
		return
	if bool(mod_runtime.call("attempt_purchase")):
		await _fail("320 Cash purchased 500-Cash bash bar")
		return
	if int(cash_runtime.call("get_balance")) != 320 or bool(cash_store.call("has_courier_bike_bash_bar_receipt")):
		await _fail("Insufficient purchase mutated durable state")
		return

	# Wanted blocks the Garage even when all other conditions are legal.
	var authority = _wanted_runtime.get("wanted_authority")
	if authority == null or not bool(authority.call("submit_report", "p14_test", player.global_position, Vector3.FORWARD, "p14_observer")):
		await _fail("Could not establish Wanted CONTACT fixture")
		return
	mod_runtime.call("_process", 0.0)
	if bool(mod_runtime.call("attempt_purchase")):
		await _fail("Wanted-active Garage purchased bash bar")
		return
	if int(cash_runtime.call("get_balance")) != 320:
		await _fail("Wanted rejection mutated Cash")
		return
	authority.call("reset")

	# Second authored payout makes the durable choice affordable.
	if int(cash_runtime.call("award_mission_02", 450)) != 450 or int(cash_runtime.call("get_balance")) != 770:
		await _fail("Could not establish 770-Cash authored fixture")
		return

	mod_runtime.call("_process", 0.0)
	var mod_interactable = mod_runtime.call("get_mod_interactable")
	if mod_interactable == null:
		await _fail("P14 interactable missing")
		return
	mod_interactable.call("update_player_distance", player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != mod_interactable:
		await _fail("Legal P14 state did not win retained Action arbitration")
		return
	if String(mod_runtime.call("get_affordance_text")) != "FIT SCRAP BASH BAR // 500 CASH // ACTION":
		await _fail("Eligible P14 affordance is incorrect")
		return

	touch_ui.action_button_pressed.emit()
	await process_frame
	if int(cash_runtime.call("get_balance")) != 270:
		await _fail("Successful bash-bar purchase did not debit exactly 500")
		return
	if not bool(cash_store.call("has_courier_bike_bash_bar_receipt")) or not bool(bike.call("has_scrap_bash_bar")):
		await _fail("Successful purchase did not produce durable receipt + Bike capability")
		return
	var bash_visual := bike.get_node_or_null("VisualRoot/ScrapBashBar") as Node3D
	if bash_visual == null or not bash_visual.visible:
		await _fail("Purchased bash bar is not visibly present on production Bike")
		return

	# Duplicate cannot charge again.
	if bool(mod_runtime.call("attempt_purchase")) or int(cash_runtime.call("get_balance")) != 270:
		await _fail("Duplicate P14 purchase charged twice")
		return

	# Capability proof against an otherwise stock Bike.
	var bike_packed := load(BIKE_SCENE_PATH) as PackedScene
	var stock_bike = bike_packed.instantiate()
	root.add_child(stock_bike)
	await process_frame
	stock_bike.call("reset_condition")
	stock_bike.set("_condition_contact_cooldown", 0.0)
	if not bool(stock_bike.call("apply_collision_condition", 1.0, 10.0)):
		await _fail("Stock reference impact was not accepted")
		return
	if String(stock_bike.call("get_condition_name")) != "BATTERED":
		await _fail("Stock reference did not reach BATTERED")
		return

	bike.call("reset_condition")
	bike.set("_condition_contact_cooldown", 0.0)
	if not bool(bike.call("apply_collision_condition", 1.0, 10.0)):
		await _fail("Fitted reference impact was not accepted")
		return
	if String(bike.call("get_condition_name")) != "ROADWORTHY":
		await _fail("Fitted Bike did not resist one hard frontal impact")
		return

	# Side/glancing damage is intentionally unchanged.
	bike.call("reset_condition")
	for _i in range(2):
		bike.set("_condition_contact_cooldown", 0.0)
		bike.call("apply_collision_condition", 0.0, 10.0)
	if String(bike.call("get_condition_name")) != "BATTERED":
		await _fail("Bash bar incorrectly protected side/glancing damage")
		return
	stock_bike.queue_free()

	# Existing free repair is independent and retains the mod.
	player.is_mounted = true
	bike.occupant = player
	_scene.set("active_vehicle", bike)
	bike.global_position = repair_socket.global_position
	bike.current_speed = 0.0
	if not bool(repair_runtime.call("attempt_repair", bike)):
		await _fail("Retained P07 repair could not repair fitted Bike")
		return
	if String(bike.call("get_condition_name")) != "ROADWORTHY" or not bool(bike.call("has_scrap_bash_bar")):
		await _fail("P07 repair removed or corrupted bash bar")
		return
	player.is_mounted = false
	bike.occupant = null
	_scene.set("active_vehicle", null)
	player.global_position = claim_socket.global_position

	# Retained recovery returns the same modified Bike.
	var bike_id := int(bike.get_instance_id())
	bike.global_position = claim_socket.global_position + Vector3(30.0, 0.0, 0.0)
	if not bool(claim_runtime.call("attempt_recovery")):
		await _fail("Retained P11 recovery failed for fitted Bike")
		return
	if int(bike.get_instance_id()) != bike_id or not bool(bike.call("has_scrap_bash_bar")):
		await _fail("Recovery replaced Bike or lost bash bar")
		return

	# Replay retains receipt/mod while keeping retained transient reset semantics.
	bike.global_position = claim_socket.global_position + Vector3(30.0, 0.0, 0.0)
	_scene.call("reset_slice")
	await process_frame
	await process_frame
	if int(cash_runtime.call("get_balance")) != 270 	or not bool(cash_store.call("has_courier_bike_bash_bar_receipt")) 	or not bool(bike.call("has_scrap_bash_bar")):
		await _fail("Replay lost P14 durable state")
		return

	# Fresh runtime reconstruction proves reload, not merely in-memory replay.
	_scene.queue_free()
	await process_frame
	await process_frame
	_scene = await _spawn_production_scene()
	if _scene == null:
		await _fail("Fresh production scene reconstruction failed")
		return
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not rebind after fresh scene")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")
	var fresh_cash := _scene.get_node_or_null("BurnsideCashEconomyRuntime")
	var fresh_mod := _scene.get_node_or_null("BurnGarageCourierBikeScrapperModRuntime")
	var fresh_claim := _scene.get_node_or_null("BurnGarageCourierBikeClaimRuntime")
	var fresh_bike = _scene.get("courier_bike")
	if fresh_cash == null or fresh_mod == null or fresh_claim == null or fresh_bike == null:
		await _fail("Fresh P14 runtime composition incomplete")
		return
	var fresh_store = fresh_cash.call("get_progress_store")
	var fresh_claim_store = fresh_claim.call("get_progress_store")
	if int(fresh_cash.call("get_balance")) != 270 	or not bool(fresh_store.call("has_courier_bike_bash_bar_receipt")) 	or not bool(fresh_claim_store.call("is_claimed")) 	or not bool(fresh_bike.call("has_scrap_bash_bar")):
		await _fail("Fresh relaunch did not reload CLAIMED + Cash + bash-bar entitlement")
		return
	var fresh_visual := fresh_bike.get_node_or_null("VisualRoot/ScrapBashBar") as Node3D
	if fresh_visual == null or not fresh_visual.visible:
		await _fail("Fresh relaunch did not restore bash-bar visual")
		return

	print("[P14_BASH_BAR_INTEGRATION] PASS")
	await _finish(0)
