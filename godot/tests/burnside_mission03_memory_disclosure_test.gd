extends SceneTree

const MISSION_PATH := "res://scripts/missions/city_that_forgot_mission.gd"
const RELAY_PATH := "res://scripts/interactions/memory_disclosure_relay.gd"
const PRODUCTION_SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")

var _scene_under_test: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[P16_MEMORY_DISCLOSURE] %s" % message)
	await _finish(1)

func _drive_city_to_complete(city_runtime: Node, civic_runtime: Node) -> bool:
	# This focused P16 tracer does not replay Mission 01/02. Freeze only the
	# synthetic Mission-02 prerequisite so its own live reconciler cannot relock it.
	civic_runtime.set_process(false)
	civic_runtime.mission.phase = CivicMissionScript.Phase.COMPLETE
	var mission = city_runtime.mission
	return mission.unlock_after_civic_repossession() \
	and mission.on_silent_core_activated() \
	and mission.on_echo_completed() \
	and mission.on_escape_complete()

func _make_scene() -> Dictionary:
	if _wanted_runtime != null:
		_wanted_runtime.call("reset_runtime")
	var packed := load(PRODUCTION_SCENE_PATH) as PackedScene
	if packed == null:
		return {}
	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	_wanted_runtime.call("bind_to_scene", _scene_under_test)
	await process_frame
	var city_runtime := _scene_under_test.get_node_or_null("CityThatForgotRuntime")
	var civic_runtime := _scene_under_test.get_node_or_null("CivicRepossessionRuntime")
	var player := _scene_under_test.get_node_or_null("Runner") as Node3D
	var touch_ui := _scene_under_test.get_node_or_null("CanvasLayer/TouchControlsUI")
	var release_relay := _scene_under_test.get_node_or_null("MemoryReleaseRelay")
	var seal_relay := _scene_under_test.get_node_or_null("MemorySealRelay")
	if city_runtime == null or civic_runtime == null or player == null or touch_ui == null \
	or release_relay == null or seal_relay == null:
		return {}
	return {
		"scene": _scene_under_test,
		"city": city_runtime,
		"civic": civic_runtime,
		"player": player,
		"touch_ui": touch_ui,
		"release": release_relay,
		"seal": seal_relay,
	}

func _select_relay(fixture: Dictionary, relay: Node) -> bool:
	var player: Node3D = fixture["player"]
	var other: Node = fixture["seal"] if relay == fixture["release"] else fixture["release"]
	player.global_position = relay.global_position
	relay.call("update_player_distance", player.global_position)
	other.call("update_player_distance", player.global_position)
	fixture["scene"].call("_evaluate_target_selection")
	if fixture["scene"].get("_active_target") != relay:
		return false
	fixture["touch_ui"].action_button_pressed.emit()
	await process_frame
	return true

func _run() -> void:
	# Pure authored-state contract.
	var mission_script = load(MISSION_PATH)
	if mission_script == null:
		await _fail("Mission 03 script missing")
		return
	var mission = mission_script.new()
	if not mission.unlock_after_civic_repossession() \
	or not mission.on_silent_core_activated() \
	or not mission.on_echo_completed() \
	or not mission.on_escape_complete():
		await _fail("Retained Mission 03 path could not reach COMPLETE")
		return
	if not mission.has_method("get_aftermath_state_name") \
	or String(mission.call("get_aftermath_state_name")) != "UNDECIDED":
		await _fail("Fresh Mission 03 aftermath is not UNDECIDED")
		return
	if "RETURN TO CORE" not in mission.objective:
		await _fail("Mission 03 completion does not direct the player back to the Core")
		return
	if not mission.has_method("choose_memory_release") or not mission.has_method("choose_memory_seal"):
		await _fail("Mission 03 lacks RELEASE / SEAL choice API")
		return
	if not bool(mission.call("choose_memory_release")) \
	or String(mission.call("get_aftermath_state_name")) != "RELEASED":
		await _fail("RELEASE did not become RELEASED")
		return
	if bool(mission.call("choose_memory_release")) or bool(mission.call("choose_memory_seal")):
		await _fail("Aftermath choice was not exactly-once")
		return
	var sealed = mission_script.new()
	sealed.unlock_after_civic_repossession()
	sealed.on_silent_core_activated()
	sealed.on_echo_completed()
	sealed.on_escape_complete()
	if not bool(sealed.call("choose_memory_seal")) \
	or String(sealed.call("get_aftermath_state_name")) != "SEALED":
		await _fail("SEAL did not become SEALED")
		return
	var relay_script = load(RELAY_PATH)
	if relay_script == null:
		await _fail("Memory disclosure relay implementation missing")
		return

	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload missing")
		return

	# Production RELEASE path through retained target arbitration + Action.
	var live := await _make_scene()
	if live.is_empty():
		await _fail("Production RELEASE fixture could not bind P16 relays")
		return
	if bool(live["release"].get("is_powered")) or bool(live["seal"].get("is_powered")):
		await _fail("P16 relays were active before Mission 03 COMPLETE")
		return
	if not _drive_city_to_complete(live["city"], live["civic"]):
		await _fail("Production RELEASE fixture could not reach Mission 03 COMPLETE")
		return
	live["city"].call("_arm_aftermath_choice")
	if not bool(live["release"].get("is_powered")) or not bool(live["seal"].get("is_powered")):
		await _fail("Mission 03 COMPLETE did not arm both physical relays")
		return
	if not await _select_relay(live, live["release"]):
		await _fail("Retained target arbitration / Action did not select RELEASE relay")
		return
	var release_snapshot: Dictionary = live["city"].call("get_aftermath_snapshot")
	if release_snapshot["state"] != "RELEASED" \
	or int(release_snapshot["release_report_attempt_count"]) != 1:
		await _fail("Production RELEASE did not resolve exactly once")
		return
	if release_snapshot["release_relay"]["resolution"] != "RELEASED" \
	or release_snapshot["seal_relay"]["resolution"] != "LOCKED":
		await _fail("RELEASE did not resolve chosen/unchosen relay presentation")
		return
	var authority = _wanted_runtime.get("wanted_authority")
	if int(authority.call("get_heat_level")) != 1 \
	or String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("Live RELEASE did not compose with retained Heat 1 civic Report authority")
		return
	live["touch_ui"].action_button_pressed.emit()
	await process_frame
	if int(live["city"].call("get_aftermath_snapshot")["release_report_attempt_count"]) != 1:
		await _fail("Repeated Action duplicated the RELEASE civic Report attempt")
		return

	# Full Replay clears the session-local choice and relay state.
	_wanted_runtime.call("reset_runtime")
	live["civic"].set_process(true)
	live["scene"].call("reset_slice")
	await process_frame
	await process_frame
	var reset_snapshot: Dictionary = live["city"].call("get_aftermath_snapshot")
	if reset_snapshot["state"] != "UNDECIDED" \
	or int(reset_snapshot["release_report_attempt_count"]) != 0 \
	or reset_snapshot["release_relay"]["resolution"] != "DORMANT" \
	or reset_snapshot["seal_relay"]["resolution"] != "DORMANT":
		await _fail("Full Replay leaked P16 aftermath choice or relay state")
		return

	live["scene"].queue_free()
	await process_frame
	await process_frame
	_scene_under_test = null

	# Production SEAL path creates no civic Report.
	var seal_fixture := await _make_scene()
	if seal_fixture.is_empty() or not _drive_city_to_complete(seal_fixture["city"], seal_fixture["civic"]):
		await _fail("Production SEAL fixture could not reach Mission 03 COMPLETE")
		return
	seal_fixture["city"].call("_arm_aftermath_choice")
	if not await _select_relay(seal_fixture, seal_fixture["seal"]):
		await _fail("Retained target arbitration / Action did not select SEAL relay")
		return
	var seal_snapshot: Dictionary = seal_fixture["city"].call("get_aftermath_snapshot")
	authority = _wanted_runtime.get("wanted_authority")
	if seal_snapshot["state"] != "SEALED" \
	or int(seal_snapshot["release_report_attempt_count"]) != 0:
		await _fail("Production SEAL resolved incorrectly")
		return
	if int(authority.call("get_heat_level")) != 0 \
	or String(authority.call("get_wanted_state_name")) != "CLEAR":
		await _fail("SEAL incorrectly created Wanted state")
		return

	seal_fixture["scene"].queue_free()
	await process_frame
	await process_frame
	_scene_under_test = null

	# P02 composition: jammed reporting still records RELEASED but creates no Heat.
	var jammed := await _make_scene()
	if jammed.is_empty():
		await _fail("Jammed RELEASE fixture could not bind")
		return
	var access: Node = jammed["scene"].get_node_or_null("CivicReportAccess")
	var alarm: Node = jammed["scene"].get_node_or_null("CivicServiceAlarm")
	if access == null or alarm == null:
		await _fail("P02 civic report access/alarm missing from production fixture")
		return
	jammed["player"].global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", jammed["player"].global_position)
	jammed["scene"].set("_active_target", access)
	if not bool(_wanted_runtime.call("handle_action_pressed")) or bool(alarm.get("report_enabled")):
		await _fail("P02 Field Hacking did not suppress reporting before RELEASE")
		return
	if not _drive_city_to_complete(jammed["city"], jammed["civic"]):
		await _fail("Jammed RELEASE fixture could not reach Mission 03 COMPLETE")
		return
	jammed["city"].call("_arm_aftermath_choice")
	if not await _select_relay(jammed, jammed["release"]):
		await _fail("Jammed RELEASE relay was not selectable")
		return
	var jam_snapshot: Dictionary = jammed["city"].call("get_aftermath_snapshot")
	authority = _wanted_runtime.get("wanted_authority")
	if jam_snapshot["state"] != "RELEASED" \
	or int(jam_snapshot["release_report_attempt_count"]) != 1:
		await _fail("Jammed RELEASE did not retain the authored choice")
		return
	if int(authority.call("get_heat_level")) != 0 \
	or String(authority.call("get_wanted_state_name")) != "CLEAR":
		await _fail("Suppressed RELEASE incorrectly created Wanted state")
		return
	if "CIVIC REPORT SUPPRESSED" not in String(jammed["city"].mission.objective):
		await _fail("Suppressed RELEASE does not tell the player the civic Report was blocked")
		return

	print("[P16_MEMORY_DISCLOSURE] PASS")
	await _finish(0)
