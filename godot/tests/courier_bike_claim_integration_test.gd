extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const TEST_PATH := "user://tests/p11_courier_bike_claim_integration_test.json"
const CONTACT_TEST_PATH := "user://tests/p10_courier_bike_claim_integration_test.json"

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ".tmp", CONTACT_TEST_PATH, CONTACT_TEST_PATH + ".tmp"]:
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
	push_error("[P11_COURIER_CLAIM] " + message)
	await _finish(1)

func _run() -> void:
	_cleanup()
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return

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
	await process_frame

	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")

	var runtime := _scene.get_node_or_null("BurnGarageCourierBikeClaimRuntime")
	var contact_runtime := _scene.get_node_or_null("MayorBurnContactServiceRuntime")
	var repair_runtime := _scene.get_node_or_null("BurnGarageRepairRuntime")
	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	var player := _scene.get_node_or_null("Runner")
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var bike = _scene.get("courier_bike")
	var claim_socket := district.get_node_or_null("CourierBikeClaimSocket") as Marker3D if district != null else null
	if runtime == null or contact_runtime == null or repair_runtime == null or player == null or touch_ui == null or bike == null or claim_socket == null:
		await _fail("P11 production composition is incomplete")
		return

	for method_name in ["get_progress_store", "get_claim_interactable", "get_affordance_text", "attempt_claim", "attempt_recovery", "get_claim_socket_position", "restore_claimed_bike_after_replay"]:
		if not runtime.has_method(method_name):
			await _fail("Claim runtime missing " + method_name)
			return

	var store = runtime.call("get_progress_store")
	if store == null or String(store.call("get_storage_path")) != TEST_PATH:
		await _fail("Claim runtime did not use isolated deterministic test storage")
		return
	if bool(store.call("is_claimed")):
		await _fail("Clean fixture began CLAIMED")
		return

	var contact_store = contact_runtime.call("get_progress_store")
	if contact_store == null:
		await _fail("P10 Contact store is unavailable")
		return
	var authority = _wanted_runtime.get("wanted_authority")
	if authority == null:
		await _fail("WantedAuthority is unavailable")
		return

	player.global_position = claim_socket.global_position
	player.is_mounted = false
	_scene.set("active_vehicle", null)
	bike.global_position = claim_socket.global_position
	bike.current_speed = 0.0
	bike.velocity = Vector3.ZERO

	if bool(runtime.call("attempt_claim")):
		await _fail("UNESTABLISHED Burn Contact claimed the Bike")
		return

	if not bool(contact_store.call("mark_known")):
		await _fail("Could not establish Burn KNOWN fixture")
		return

	if not bool(authority.call("submit_report", "p11_test", player.global_position, Vector3.FORWARD, "p11_observer")):
		await _fail("Could not establish CONTACT fixture")
		return
	if bool(runtime.call("attempt_claim")):
		await _fail("CONTACT allowed claim")
		return
	if not bool(authority.call("lose_contact", player.global_position, Vector3.FORWARD, "p11_loss")):
		await _fail("Could not establish SEARCH fixture")
		return
	if bool(runtime.call("attempt_claim")):
		await _fail("SEARCH allowed claim")
		return
	authority.call("reset")

	player.is_mounted = true
	_scene.set("active_vehicle", bike)
	if bool(runtime.call("attempt_claim")):
		await _fail("Mounted Runner claimed the Bike")
		return
	player.is_mounted = false
	_scene.set("active_vehicle", null)

	bike.global_position = claim_socket.global_position + Vector3(8.0, 0.0, 0.0)
	if bool(runtime.call("attempt_claim")):
		await _fail("Bike outside claim bay was claimed")
		return
	bike.global_position = claim_socket.global_position
	bike.current_speed = 1.0
	if bool(runtime.call("attempt_claim")):
		await _fail("Moving Bike was claimed")
		return

	bike.current_speed = 0.0
	bike.call("reset_condition")
	bike.set("_condition_contact_cooldown", 0.0)
	if not bool(bike.call("apply_collision_condition", 1.0, 10.0)):
		await _fail("Could not establish BATTERED Bike fixture")
		return
	if String(bike.call("get_condition_name")) != "BATTERED":
		await _fail("Damage fixture did not reach BATTERED")
		return

	var health_before: float = float(player.current_health)
	var armor_before: float = float(player.current_armor)
	runtime.call("_process", 0.0)
	var claim_interactable = runtime.call("get_claim_interactable")
	if claim_interactable == null:
		await _fail("Claim interactable is missing")
		return
	claim_interactable.call("update_player_distance", player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != claim_interactable:
		await _fail("Claim bay lost retained Action target arbitration")
		return
	if String(runtime.call("get_affordance_text")) != "CLAIM COURIER BIKE // ACTION":
		await _fail("Eligible claim affordance is incorrect")
		return
	touch_ui.action_button_pressed.emit()
	await process_frame
	if not bool(store.call("is_claimed")):
		await _fail("Eligible claim did not complete through retained Action routing")
		return
	if not bool(store.call("is_claimed")) or int(store.call("get_write_count")) != 1:
		await _fail("Claim did not persist exactly once")
		return
	if String(bike.call("get_condition_name")) != "BATTERED":
		await _fail("Claim silently repaired P07 condition")
		return
	if not is_equal_approx(player.current_health, health_before) or not is_equal_approx(player.current_armor, armor_before):
		await _fail("Claim mutated player vitals")
		return
	if bool(runtime.call("attempt_claim")) or int(store.call("get_write_count")) != 1:
		await _fail("Duplicate claim duplicated persistence")
		return

	var bike_id: int = int(bike.get_instance_id())
	var far_position := claim_socket.global_position + Vector3(30.0, 0.0, 0.0)
	bike.global_position = far_position
	bike.current_speed = 0.0
	bike.velocity = Vector3.ZERO

	if not bool(authority.call("submit_report", "p11_recovery", player.global_position, Vector3.FORWARD, "p11_observer_2")):
		await _fail("Could not establish recovery CONTACT fixture")
		return
	if bool(runtime.call("attempt_recovery")):
		await _fail("CONTACT allowed recovery")
		return
	authority.call("reset")

	bike.occupant = player
	if bool(runtime.call("attempt_recovery")):
		await _fail("Occupied Bike was recovered")
		return
	bike.occupant = null

	runtime.set("_success_until_msec", 0)
	runtime.call("_process", 0.0)
	claim_interactable.call("update_player_distance", player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != claim_interactable:
		await _fail("Recovery bay lost retained Action target arbitration")
		return
	if String(runtime.call("get_affordance_text")) != "RECOVER COURIER BIKE // ACTION":
		await _fail("Eligible recovery affordance is incorrect")
		return
	touch_ui.action_button_pressed.emit()
	await process_frame
	if bike.global_position.distance_to(claim_socket.global_position) > 0.01:
		await _fail("Eligible claimed Bike recovery did not complete through retained Action routing")
		return
	if bike.get_instance_id() != bike_id:
		await _fail("Recovery replaced/duplicated the production Bike")
		return
	if bike.global_position.distance_to(claim_socket.global_position) > 0.01:
		await _fail("Recovery did not place Bike at authored claim socket")
		return
	if String(bike.call("get_condition_name")) != "ROADWORTHY" or abs(float(bike.current_speed)) > 0.001 or bike.velocity.length() > 0.001:
		await _fail("Recovery did not restore ROADWORTHY parked state")
		return
	if bool(runtime.call("attempt_recovery")):
		await _fail("Bike already at Garage recovered twice")
		return
	if not is_equal_approx(player.current_health, health_before) or not is_equal_approx(player.current_armor, armor_before):
		await _fail("Recovery mutated player vitals")
		return
	if not bool(contact_store.call("is_known")):
		await _fail("Recovery mutated Burn Contact")
		return

	var reloaded_script = load("res://scripts/progress/courier_bike_claim_progress_store.gd")
	var reloaded = reloaded_script.new()
	reloaded.configure(TEST_PATH)
	if not reloaded.is_claimed():
		await _fail("Fresh store instance did not reload claim")
		return

	# Full Replay retains ownership and restores the claimed Bike to the Garage.
	bike.global_position = far_position
	_scene.call("reset_slice")
	await process_frame
	await process_frame
	if not bool(store.call("is_claimed")):
		await _fail("Replay erased claimed ownership")
		return
	if bike.global_position.distance_to(claim_socket.global_position) > 0.01:
		await _fail("Replay did not restore claimed Bike to Garage")
		return

	# Soft Failure must not erase ownership or invoke Garage recovery by itself.
	bike.global_position = far_position
	player.current_health = 0.0
	_scene.call("_begin_soft_failure")
	await create_timer(0.9).timeout
	await process_frame
	if not bool(store.call("is_claimed")):
		await _fail("Soft Failure erased claim")
		return
	if bike.global_position.distance_to(far_position) > 0.01:
		await _fail("Soft Failure incorrectly summoned claimed Bike")
		return

	print("[P11_COURIER_CLAIM] PASS")
	await _finish(0)
