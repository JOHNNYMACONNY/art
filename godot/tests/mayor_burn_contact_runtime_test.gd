extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const STORE_SCRIPT_PATH := "res://scripts/progress/mayor_burn_contact_progress_store.gd"
const TEST_PATH := "user://tests/p10_mayor_burn_contact_runtime_test.json"
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup_test_progress() -> void:
	for path in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish(code: int) -> void:
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_cleanup_test_progress()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P10_BURN_CONTACT_RUNTIME] " + message)
	await _finish(1)

func _run() -> void:
	_cleanup_test_progress()
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("Wanted runtime is missing")
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

	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")

	var runtime = _scene.get_node_or_null("MayorBurnContactRuntime")
	var player = _scene.get_node_or_null("Runner")
	var civic = _scene.get_node_or_null("CivicRepossessionRuntime")
	var mission_one = _scene.get_node_or_null("MissionScrapJobRuntime")
	var district = _scene.get_node_or_null("GearsDistrictSlice01B")
	var repair_runtime = _scene.get_node_or_null("BurnGarageRepairRuntime")
	var hauler = _scene.get("scrap_hauler")
	if runtime == null or player == null or civic == null or mission_one == null or district == null or repair_runtime == null or hauler == null:
		await _fail("Production 10 retained fixture is incomplete")
		return
	for method_name in ["get_contact_state_name", "get_progress_store", "get_service_interactable", "get_affordance_text", "attempt_armor_restock"]:
		if not runtime.has_method(method_name):
			await _fail("MayorBurnContactRuntime missing " + method_name)
			return

	var store = runtime.call("get_progress_store")
	if store == null or String(runtime.call("get_contact_state_name")) != "UNESTABLISHED":
		await _fail("Fresh production runtime did not start UNESTABLISHED")
		return

	var socket := district.get_node_or_null("MissionDestinationSocket") as Marker3D
	if socket == null:
		await _fail("Burn Garage service socket is missing")
		return
	player.global_position = socket.global_position
	_scene.set("active_vehicle", null)
	player.set_vehicle_driving_posture(false)
	player.reset_vitals(73.0, 10.0)
	if bool(runtime.call("attempt_armor_restock")):
		await _fail("Unknown Contact received Burn armor privilege")
		return

	# Complete the retained Mission 02 path through its runtime once.
	mission_one.set_process(false)
	civic.set_process(false)
	mission_one.mission.phase = ScrapJobMissionScript.Phase.COMPLETE
	civic.mission.phase = CivicMissionScript.Phase.DELIVERY
	var return_zone = civic.get("_return_zone") as Node3D
	if return_zone == null:
		await _fail("Retained Civic Repossession return zone is missing")
		return
	hauler.global_position = return_zone.global_position
	civic.call("_process", 0.0)
	if civic.mission.phase != CivicMissionScript.Phase.COMPLETE:
		await _fail("Retained Mission 02 did not complete")
		return
	if int(civic.mission.reward_credits) != CivicMissionScript.PAYOFF_CREDITS:
		await _fail("Mission 02 payoff changed during Contact composition")
		return
	if String(runtime.call("get_contact_state_name")) != "KNOWN" or not bool(store.call("is_known")):
		await _fail("Mission 02 completion did not establish KNOWN Contact")
		return
	if int(store.call("get_write_count")) != 1:
		await _fail("Contact milestone did not persist exactly once")
		return
	civic.call("_process", 0.0)
	if int(store.call("get_write_count")) != 1:
		await _fail("Completed mission duplicated Contact persistence")
		return

	# Known + on foot + CLEAR + in radius must route through the retained
	# selector and Action signal, not only through a direct helper call.
	_wanted_runtime.call("reset_runtime")
	player.global_position = socket.global_position
	player.set_vehicle_driving_posture(false)
	_scene.set("active_vehicle", null)
	player.reset_vitals(73.0, 10.0)
	var health_before: float = player.current_health
	runtime.call("_process", 0.0)
	var service_interactable = runtime.call("get_service_interactable")
	var root_interactables = _scene.get("_interactables")
	if service_interactable == null or not (root_interactables is Array) or not root_interactables.has(service_interactable):
		await _fail("Burn Contact service is not registered in retained target arbitration")
		return
	if not bool(service_interactable.get("is_powered")) or String(runtime.call("get_affordance_text")) != "RESTOCK ARMOR // ACTION":
		await _fail("Eligible Burn Contact service did not expose its Action affordance")
		return
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != service_interactable:
		await _fail("Burn Contact service did not win retained target selection when eligible")
		return
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null:
		await _fail("Retained TouchControlsUI is missing")
		return
	touch_ui.action_button_pressed.emit()
	await process_frame
	if not is_equal_approx(player.current_armor, player.MAX_ARMOR):
		await _fail("Action-routed Armor restock did not reach MAX_ARMOR")
		return
	if not is_equal_approx(player.current_health, health_before):
		await _fail("Armor restock changed Health")
		return
	if bool(runtime.call("attempt_armor_restock")):
		await _fail("Full Armor restocked twice")
		return

	# Active Wanted must reject without mutating vitals or authority and must
	# expose the authored locked-treatment affordance.
	player.reset_vitals(73.0, 10.0)
	var authority = _wanted_runtime.get("wanted_authority")
	if authority == null or not bool(authority.call("submit_report", "p10_test", player.global_position, Vector3.FORWARD, "burn_test_observer")):
		await _fail("Could not establish CONTACT fixture")
		return
	var heat_before := int(_wanted_runtime.call("get_heat_level"))
	var state_before := String(_wanted_runtime.call("get_wanted_state_name"))
	runtime.call("_process", 0.0)
	if String(runtime.call("get_affordance_text")) != "WANTED // BURN WON'T OPEN" or bool(service_interactable.get("is_powered")):
		await _fail("Active Wanted did not visibly lock the Burn Contact service")
		return
	if bool(runtime.call("attempt_armor_restock")) or not is_equal_approx(player.current_armor, 10.0):
		await _fail("Burn service restocked during active Wanted")
		return
	if int(_wanted_runtime.call("get_heat_level")) != heat_before or String(_wanted_runtime.call("get_wanted_state_name")) != state_before:
		await _fail("Rejected Burn service mutated Wanted authority")
		return
	authority.call("reset")

	# Mounted use and out-of-radius use are rejected.
	player.reset_vitals(73.0, 10.0)
	player.set_vehicle_driving_posture(true, "bike")
	if bool(runtime.call("attempt_armor_restock")):
		await _fail("Mounted Runner used on-foot Burn service")
		return
	player.set_vehicle_driving_posture(false)
	player.global_position = socket.global_position + Vector3(10.0, 0.0, 0.0)
	if bool(runtime.call("attempt_armor_restock")):
		await _fail("Burn service worked outside Garage radius")
		return

	# Existing P07 repair runtime remains present and separately registered.
	if repair_runtime.call("get_repair_interactable") == runtime.call("get_service_interactable"):
		await _fail("P10 replaced P07 repair interaction authority")
		return

	# Full Replay must not erase the earned Contact.
	_scene.call("reset_slice")
	await process_frame
	if String(runtime.call("get_contact_state_name")) != "KNOWN" or not bool(store.call("is_known")):
		await _fail("Full Replay erased durable Burn Contact")
		return

	# A fresh store instance must reload the same durable milestone.
	var store_script = load(STORE_SCRIPT_PATH)
	var fresh = store_script.new()
	fresh.call("configure", String(store.call("get_storage_path")))
	if not bool(fresh.call("is_known")):
		await _fail("Fresh store instance did not reload KNOWN Contact")
		return

	print("[P10_BURN_CONTACT_RUNTIME] PASS")
	await _finish(0)
