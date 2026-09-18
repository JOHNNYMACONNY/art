extends SceneTree

const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const StoreScript = preload("res://scripts/progress/mayor_burn_contact_progress_store.gd")

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const TEST_PATH := "user://tests/p10_mayor_burn_contact_integration_test.json"

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ".tmp"]:
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
	push_error("[P10_MAYOR_BURN_CONTACT] " + message)
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

	var contact_runtime := _scene.get_node_or_null("MayorBurnContactServiceRuntime")
	var repair_runtime := _scene.get_node_or_null("BurnGarageRepairRuntime")
	var civic := _scene.get_node_or_null("CivicRepossessionRuntime")
	var mission_one := _scene.get_node_or_null("MissionScrapJobRuntime")
	var player := _scene.get_node_or_null("Runner")
	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var socket := district.get_node_or_null("MissionDestinationSocket") as Marker3D if district != null else null
	if contact_runtime == null or repair_runtime == null or civic == null or mission_one == null or player == null or socket == null or touch_ui == null:
		await _fail("P10 retained composition fixture is incomplete")
		return

	for method_name in ["get_progress_store", "get_contact_interactable", "get_affordance_text", "attempt_armor_restock", "get_service_socket_position"]:
		if not contact_runtime.has_method(method_name):
			await _fail("MayorBurnContactServiceRuntime missing " + method_name)
			return

	var store = contact_runtime.call("get_progress_store")
	if store == null or String(store.call("get_storage_path")) != TEST_PATH:
		await _fail("Contact runtime did not use isolated deterministic test storage")
		return
	if bool(store.call("is_known")):
		await _fail("Clean production scene began with Burn already KNOWN")
		return

	# Unknown contact cannot grant Armor even with every spatial/safety condition met.
	player.global_position = socket.global_position
	player.reset_vitals(83.0, 5.0)
	_scene.set("active_vehicle", null)
	player.is_mounted = false
	contact_runtime.call("_process", 0.0)
	if bool(contact_runtime.call("attempt_armor_restock", player)):
		await _fail("UNESTABLISHED contact granted Armor")
		return
	if not is_equal_approx(player.current_armor, 5.0):
		await _fail("Rejected unknown-contact restock mutated Armor")
		return

	# Complete the real Mission-02 delivery transition through CivicRepossessionRuntime.
	mission_one.mission.phase = ScrapJobMissionScript.Phase.COMPLETE
	civic.mission.phase = CivicMissionScript.Phase.DELIVERY
	var completion_count := [0]
	civic.civic_repossession_completed.connect(func(): completion_count[0] += 1)
	var hauler = _scene.get("scrap_hauler")
	hauler.global_position = socket.global_position
	civic.call("_process", 0.0)
	await process_frame
	if civic.mission.phase != CivicMissionScript.Phase.COMPLETE or civic.mission.reward_credits != CivicMissionScript.PAYOFF_CREDITS:
		await _fail("Mission 02 completion/payoff changed while establishing Contact")
		return
	if completion_count[0] != 1 or not bool(store.call("is_known")) or int(store.call("get_write_count")) != 1:
		await _fail("Mission 02 completion did not record KNOWN exactly once")
		return
	civic.call("_process", 0.0)
	await process_frame
	if completion_count[0] != 1 or int(store.call("get_write_count")) != 1:
		await _fail("Duplicate completed mission processing duplicated Contact write")
		return

	# Full Replay may reset current vitals/missions, but it cannot erase earned relationship knowledge.
	_scene.call("reset_slice")
	await process_frame
	await process_frame
	if not bool(store.call("is_known")):
		await _fail("Full Replay erased Burn KNOWN relationship")
		return
	var reloaded = StoreScript.new()
	reloaded.configure(TEST_PATH)
	if not reloaded.is_known():
		await _fail("Fresh Contact store instance did not reload KNOWN")
		return

	# Eligible restock: on foot, CLEAR, in radius, Armor damaged.
	var authority = _wanted_runtime.get("wanted_authority")
	if authority == null:
		await _fail("WantedAuthority unavailable")
		return
	authority.call("reset")
	player.global_position = socket.global_position
	player.is_mounted = false
	_scene.set("active_vehicle", null)
	player.reset_vitals(83.0, 5.0)
	var health_before := player.current_health
	contact_runtime.call("_process", 0.0)
	if not bool(contact_runtime.call("attempt_armor_restock", player)):
		await _fail("Eligible known/CLEAR/on-foot Armor restock failed")
		return
	if not is_equal_approx(player.current_armor, player.MAX_ARMOR):
		await _fail("Restock did not set Armor exactly to MAX_ARMOR")
		return
	if not is_equal_approx(player.current_health, health_before):
		await _fail("Armor restock changed Health")
		return
	if bool(contact_runtime.call("attempt_armor_restock", player)):
		await _fail("Full Armor restocked more than once")
		return

	# CONTACT and SEARCH visibly lock and cannot mutate Armor.
	player.reset_vitals(83.0, 5.0)
	if not bool(authority.call("submit_report", "p10_test", player.global_position, Vector3.FORWARD, "p10_contact_observer")):
		await _fail("Could not establish CONTACT fixture")
		return
	contact_runtime.call("_process", 0.0)
	if String(_wanted_runtime.call("get_wanted_state_name")) != "CONTACT":
		await _fail("Wanted fixture did not enter CONTACT")
		return
	if String(contact_runtime.call("get_affordance_text")) != "WANTED // BURN WON'T OPEN":
		await _fail("CONTACT did not expose Burn locked affordance")
		return
	if bool(contact_runtime.call("attempt_armor_restock", player)) or not is_equal_approx(player.current_armor, 5.0):
		await _fail("CONTACT allowed Armor restock")
		return
	if not bool(authority.call("lose_contact", player.global_position, Vector3.FORWARD, "p10_loss")):
		await _fail("Could not establish SEARCH fixture")
		return
	contact_runtime.call("_process", 0.0)
	if String(_wanted_runtime.call("get_wanted_state_name")) != "SEARCH":
		await _fail("Wanted fixture did not enter SEARCH")
		return
	if bool(contact_runtime.call("attempt_armor_restock", player)):
		await _fail("SEARCH allowed Armor restock")
		return

	# Mounted state rejects the on-foot relationship service.
	authority.call("reset")
	player.reset_vitals(83.0, 5.0)
	player.is_mounted = true
	_scene.set("active_vehicle", _scene.get("courier_bike"))
	if bool(contact_runtime.call("attempt_armor_restock", player)):
		await _fail("Mounted player used Burn Armor stash")
		return
	player.is_mounted = false
	_scene.set("active_vehicle", null)

	# Retained Action routing selects the P10 interactable on foot and triggers the service.
	player.global_position = socket.global_position
	player.reset_vitals(83.0, 5.0)
	contact_runtime.call("_process", 0.0)
	var interactable = contact_runtime.call("get_contact_interactable")
	if interactable == null:
		await _fail("Contact interactable is missing")
		return
	interactable.call("update_player_distance", player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != interactable:
		await _fail("Burn Armor stash lost retained on-foot target arbitration")
		return
	if String(contact_runtime.call("get_affordance_text")) != "RESTOCK ARMOR // ACTION":
		await _fail("Eligible Burn Armor stash affordance is incorrect")
		return
	touch_ui.action_button_pressed.emit()
	await process_frame
	if not is_equal_approx(player.current_armor, player.MAX_ARMOR):
		await _fail("Retained Action routing did not restock Armor")
		return

	print("[P10_MAYOR_BURN_CONTACT] PASS")
	await _finish(0)
