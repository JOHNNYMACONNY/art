extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const ROUTE_ID := "gears.service_alley_north_connector"

var _scene: Node = null
var _wanted_runtime: Node = null
var _test_progress_path: String = ""

func _init() -> void:
	call_deferred("_run")

func _remove_test_progress() -> void:
	if not _test_progress_path.is_empty() and FileAccess.file_exists(_test_progress_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_progress_path))

func _finish(code: int) -> void:
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_remove_test_progress()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P07_MISSION02_COMPOSITION] %s" % message)
	await _finish(1)

func _set_critical(vehicle: Node) -> bool:
	if vehicle == null or not vehicle.has_method("apply_collision_condition"):
		return false
	vehicle.call("reset_condition")
	vehicle.set("_condition_contact_cooldown", 0.0)
	if not bool(vehicle.call("apply_collision_condition", 1.0, 10.0)):
		return false
	vehicle.set("_condition_contact_cooldown", 0.0)
	if not bool(vehicle.call("apply_collision_condition", 1.0, 10.0)):
		return false
	return String(vehicle.call("get_condition_name")) == "CRITICAL"

func _run() -> void:
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

	var repair_runtime := _scene.get_node_or_null("BurnGarageRepairRuntime")
	if repair_runtime == null:
		await _fail("Production-07 BurnGarageRepairRuntime is absent")
		return
	var civic := _scene.get_node_or_null("CivicRepossessionRuntime")
	var mission_one := _scene.get_node_or_null("MissionScrapJobRuntime")
	var hauler = _scene.get("scrap_hauler")
	var bike = _scene.get("courier_bike")
	var survey := _scene.get_node_or_null("GearsSurveyedServiceCutRuntime")
	if civic == null or mission_one == null or hauler == null or bike == null or survey == null:
		await _fail("Retained Mission/P06/vehicle fixture is incomplete")
		return
	if not hauler.has_method("apply_collision_condition") or not bike.has_method("reset_condition"):
		await _fail("Production-07 vehicle condition API is absent")
		return

	# Make the existing Mission-01 prerequisite truthfully complete for this deterministic composition fixture.
	var mission_one_state = mission_one.get("mission")
	if mission_one_state == null:
		await _fail("Mission 01 state is unavailable")
		return
	mission_one_state.set("phase", 9) # ScrapJobMission.Phase.COMPLETE

	civic.call("_try_bind_runtime")
	var mission = civic.get("mission")
	if mission == null:
		await _fail("Mission 02 state is unavailable")
		return
	if int(mission.get("phase")) == 0:
		if not bool(mission.call("unlock_after_scrap_job")):
			await _fail("Mission 02 could not unlock for composition fixture")
			return
	if not bool(mission.call("on_vehicle_mounted", "ScrapHauler")):
		await _fail("Mission 02 could not enter ESCAPE")
		return
	if not bool(mission.call("on_clean_take")):
		await _fail("Mission 02 could not enter legal DELIVERY")
		return
	if int(mission.get("phase")) != 3: # DELIVERY
		await _fail("Mission 02 fixture is not in DELIVERY")
		return

	if not _set_critical(hauler):
		await _fail("Could not establish CRITICAL Scrap Hauler")
		return
	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	var socket := district.get_node_or_null("MissionDestinationSocket") as Marker3D if district != null else null
	if socket == null:
		await _fail("Retained Burn Garage MissionDestinationSocket is missing")
		return
	hauler.global_position = socket.global_position
	hauler.set("current_speed", 0.0)

	# Existing Mission 02 process owns delivery and must ignore P07 vehicle condition.
	civic.call("_process", 0.0)
	if int(mission.get("phase")) != 5: # COMPLETE
		await _fail("CRITICAL Scrap Hauler could not complete legal Burn Garage delivery")
		return
	if int(mission.get("reward_credits")) != 450:
		await _fail("Mission 02 completion payoff changed during P07 composition")
		return
	if String(hauler.call("get_condition_name")) != "CRITICAL":
		await _fail("Mission delivery silently repaired or mutated Hauler condition")
		return

	# P07 repair owns condition only; completed mission remains completed and payoff is stable.
	_wanted_runtime.call("reset_runtime")
	_scene.set("active_vehicle", hauler)
	if not bool(repair_runtime.call("attempt_repair", hauler)):
		await _fail("Completed Mission-02 Hauler could not use legal Garage repair")
		return
	if String(hauler.call("get_condition_name")) != "ROADWORTHY":
		await _fail("Garage repair did not restore Mission-02 Hauler")
		return
	civic.call("_process", 0.0)
	if int(mission.get("phase")) != 5 or int(mission.get("reward_credits")) != 450:
		await _fail("Repair/delivery composition double-fired or corrupted Mission 02")
		return

	# Seed the retained narrow P06 test store, then prove full Replay separates durable map knowledge from P07 condition.
	var store = survey.call("get_progress_store")
	if store == null or not store.has_method("mark_surveyed"):
		await _fail("P06 progress store seam is unavailable")
		return
	_test_progress_path = String(store.call("get_storage_path"))
	_remove_test_progress()
	store.call("configure", _test_progress_path)
	if not bool(store.call("mark_surveyed", ROUTE_ID)) and not bool(store.call("is_surveyed", ROUTE_ID)):
		await _fail("Could not establish surveyed P06 route fixture")
		return
	if not _set_critical(bike) or not _set_critical(hauler):
		await _fail("Could not establish damaged Replay fixture")
		return

	_scene.call("reset_slice")
	await process_frame
	await physics_frame
	if String(bike.call("get_condition_name")) != "ROADWORTHY" or String(hauler.call("get_condition_name")) != "ROADWORTHY":
		await _fail("Full Replay did not restore both production vehicles ROADWORTHY")
		return
	if not bool(store.call("is_surveyed", ROUTE_ID)) or not bool(survey.call("is_route_surveyed")):
		await _fail("Full Replay erased retained P06 Durable Mapped Knowledge")
		return

	print("[P07_MISSION02_COMPOSITION] PASS")
	await _finish(0)