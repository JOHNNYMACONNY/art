extends SceneTree

var _scene_under_test: Node = null
var _runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[WANTED_HEAT1_SCENE] %s" % message)
	await _finish(1)

func _state(authority) -> String:
	return String(authority.call("get_wanted_state_name"))

func _heat(authority) -> int:
	return int(authority.call("get_heat_level"))

func _run() -> void:
	_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _runtime == null:
		await _fail("BurnsideWantedRuntime autoload is absent")
		return
	for method_name in ["bind_to_scene", "process_wanted", "has_direct_observation", "reset_runtime", "handle_action_pressed"]:
		if not _runtime.has_method(method_name):
			await _fail("BurnsideWantedRuntime missing seam: %s" % method_name)
			return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	_runtime.call("bind_to_scene", _scene_under_test)
	await process_frame

	var player := _scene_under_test.get_node_or_null("Runner") as Node3D
	var pursuer := _scene_under_test.get_node_or_null("PursuerPrototype") as Node3D
	var alarm := _scene_under_test.get_node_or_null("CivicServiceAlarm")
	var wanted_label := _scene_under_test.get_node_or_null("CanvasLayer/WantedStatusLabel") as Label
	var gears := _scene_under_test.get_node_or_null("GearsDistrictSlice01B")
	var authority = _runtime.get("wanted_authority")
	var search_anchor = _runtime.get("search_anchor")
	if player == null or pursuer == null or alarm == null or wanted_label == null or gears == null or authority == null or search_anchor == null:
		await _fail("Real production scene is missing Runner, Pursuer, CivicServiceAlarm, WantedStatusLabel, Gears, authority, or search anchor")
		return
	if not alarm.has_method("reset_alarm") or not "report_enabled" in alarm:
		await _fail("CivicServiceAlarm lacks bounded report/reset contract")
		return
	if not gears.has_method("get_production_contract"):
		await _fail("Gears production contract introspection is missing")
		return
	var gears_contract: Dictionary = gears.call("get_production_contract")
	if not bool(gears_contract.get("owns_no_gameplay_authority", false)):
		await _fail("Heat-1 tracer polluted the qualified Gears visual slice with gameplay authority")
		return
	if _heat(authority) != 0 or _state(authority) != "CLEAR" or wanted_label.visible:
		await _fail("Free roam did not begin CLEAR with quiet Wanted HUD")
		return

	# Incident without a working Report path must not create Wanted.
	alarm.set("report_enabled", false)
	alarm.call("reset_alarm")
	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	_scene_under_test.set("_active_target", alarm)
	_runtime.call("handle_action_pressed")
	if _heat(authority) != 0 or _state(authority) != "CLEAR" or bool(pursuer.get("is_active")):
		await _fail("Suppressed civic Report created an open-world response")
		return

	# The exact same bounded incident with its civic Report path live creates Heat 1.
	alarm.set("report_enabled", true)
	alarm.call("reset_alarm")
	alarm.call("update_player_distance", player.global_position)
	_scene_under_test.set("_active_target", alarm)
	_runtime.call("handle_action_pressed")
	if _heat(authority) != 1 or _state(authority) != "CONTACT":
		await _fail("Valid civic Report did not create Heat 1 + Contact")
		return
	if not bool(pursuer.get("is_active")):
		await _fail("Heat 1 did not activate the retained physical pursuer")
		return
	if pursuer.get("target_node") == player:
		await _fail("Fresh alarm Report immediately granted the pursuer omniscient live-player tracking")
		return
	if not wanted_label.visible or not wanted_label.text.contains("HEAT 1") or not wanted_label.text.contains("CONTACT"):
		await _fail("Wanted HUD did not clearly show Heat 1 + CONTACT")
		return

	# Real direct line of sight promotes the response asset to a live Contact source.
	pursuer.global_position = Vector3(-4.5, 0.6, -22.0)
	player.global_position = Vector3(-4.5, 0.1, -42.0)
	if not bool(_runtime.call("has_direct_observation", pursuer, player)):
		await _fail("Expected clear Gears primary-road observation fixture is occluded")
		return
	_runtime.call("process_wanted", 0.1)
	if _state(authority) != "CONTACT" or pursuer.get("target_node") != player:
		await _fail("Direct observation did not establish live Contact tracking")
		return
	var observed_pos: Vector3 = authority.call("get_last_known_position")
	if observed_pos.distance_to(player.global_position) > 0.05:
		await _fail("Direct observation did not refresh authority last-known position")
		return

	# Distance by itself is not Contact loss while the observer still has sight.
	_runtime.call("process_wanted", 1.0)
	_runtime.call("process_wanted", 1.0)
	if _state(authority) != "CONTACT":
		await _fail("Clear long-range observation incorrectly entered Search from distance alone")
		return

	# Commercial frontage physically breaks sight; after grace, Search owns stored knowledge.
	pursuer.global_position = Vector3(-4.5, 0.6, -35.0)
	player.global_position = Vector3(-17.0, 0.1, -35.0)
	if bool(_runtime.call("has_direct_observation", pursuer, player)):
		await _fail("Commercial frontage did not block the production observation ray")
		return
	for _i in range(3):
		_runtime.call("process_wanted", 0.4)
	if _state(authority) != "SEARCH" or _heat(authority) != 1:
		await _fail("Physical observation break did not become Heat-1 Search")
		return
	if not wanted_label.visible or not wanted_label.text.contains("SEARCH"):
		await _fail("Wanted HUD did not distinguish SEARCH from CONTACT")
		return
	if pursuer.get("target_node") != search_anchor:
		await _fail("Search did not retarget the response asset to a fixed last-known anchor")
		return
	var stored_search_position := (search_anchor as Node3D).global_position
	player.global_position = Vector3(22.0, 0.1, -18.0)
	_runtime.call("process_wanted", 0.2)
	if (search_anchor as Node3D).global_position.distance_to(stored_search_position) > 0.001:
		await _fail("Hidden player movement dragged Search knowledge with the live transform")
		return

	# Reappearing to the physical observer is a legitimate reacquisition path.
	pursuer.global_position = Vector3(-4.5, 0.6, -33.0)
	player.global_position = Vector3(-4.5, 0.1, -29.0)
	_runtime.call("process_wanted", 0.1)
	if _state(authority) != "CONTACT" or pursuer.get("target_node") != player:
		await _fail("Legitimate physical reacquisition did not restore Contact")
		return
	if not String(authority.call("get_last_reason")).begins_with("reacquire:"):
		await _fail("Reacquisition did not retain a concrete authority reason")
		return

	# Break sight again and remain unseen until ordinary Heat 1 evades.
	pursuer.global_position = Vector3(-4.5, 0.6, -35.0)
	player.global_position = Vector3(-17.0, 0.1, -35.0)
	for _i in range(3):
		_runtime.call("process_wanted", 0.4)
	if _state(authority) != "SEARCH":
		await _fail("Second observation break did not re-enter Search")
		return
	_runtime.call("process_wanted", 7.0)
	if _heat(authority) != 0 or _state(authority) != "CLEAR" or wanted_label.visible:
		await _fail("Search timeout did not restore unrestricted quiet free roam")
		return

	# A retained authored mission pursuit must not inherit stale free-roam Wanted state.
	alarm.call("reset_alarm")
	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	_scene_under_test.set("_active_target", alarm)
	_runtime.call("handle_action_pressed")
	if _heat(authority) != 1:
		await _fail("Mission compatibility setup could not create free-roam Heat 1")
		return
	var started := bool(_scene_under_test.call("_begin_disturbance_sequence", 0))
	if not started:
		await _fail("Retained mission disturbance could not take authority from free-roam Wanted")
		return
	_runtime.call("process_wanted", 0.01)
	if _heat(authority) != 0 or _state(authority) != "CLEAR":
		await _fail("Mission pursuit inherited stale free-roam Wanted state")
		return

	_scene_under_test.call("reset_slice")
	_runtime.call("reset_runtime")
	if _heat(authority) != 0 or _state(authority) != "CLEAR" or wanted_label.visible:
		await _fail("Full Replay reset left stale open-world Wanted state")
		return

	print("[WANTED_HEAT1_SCENE] PASS")
	await _finish(0)
