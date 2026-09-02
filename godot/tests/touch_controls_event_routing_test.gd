extends SceneTree

# Exercises actual Viewport -> Control GUI routing, not direct method calls.
const TouchSteeringConditioningContract = preload("res://tests/touch_steering_conditioning_contract_test.gd")
const MissionScrapJobContract = preload("res://tests/mission_scrap_job_contract_test.gd")
const CivicRepossessionContract = preload("res://tests/civic_repossession_mission_contract_test.gd")
const CityThatForgotContract = preload("res://tests/city_that_forgot_mission_contract_test.gd")
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const CityMissionScript = preload("res://scripts/missions/city_that_forgot_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")

var _last_joystick_vector := Vector2.ZERO
var _scene_under_test: Node = null
var _stage: String = "init"

func _init() -> void:
	call_deferred("_watchdog")
	call_deferred("_run")

func _watchdog() -> void:
	await create_timer(12.0).timeout
	push_error("[MOBILE_TOUCH_ROUTING] WATCHDOG TIMEOUT stage=%s" % _stage)
	quit(1)

func _finish(exit_code: int) -> void:
	_stage = "finish"
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[MOBILE_TOUCH_ROUTING] %s (stage=%s)" % [message, _stage])
	await _finish(1)

func _run() -> void:
	_stage = "contracts"
	var steering_error: String = TouchSteeringConditioningContract.verify()
	if not steering_error.is_empty():
		await _fail("CTW Feel 02: %s" % steering_error)
		return

	var mission_error: String = MissionScrapJobContract.verify()
	if not mission_error.is_empty():
		await _fail("Mission/Narrative 01: %s" % mission_error)
		return

	var civic_error: String = CivicRepossessionContract.verify()
	if not civic_error.is_empty():
		await _fail("Mission/Narrative 02: %s" % civic_error)
		return

	var city_error: String = CityThatForgotContract.verify()
	if not city_error.is_empty():
		await _fail("Mission/Narrative 03: %s" % city_error)
		return

	_stage = "scene_instantiation"
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	await process_frame

	_stage = "runtime_bindings"
	var touch_ui := _scene_under_test.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := _scene_under_test.get_node_or_null("Runner")
	if touch_ui == null or player == null:
		await _fail("Main scene is missing TouchControlsUI or Runner")
		return

	var wanted_runtime := root.get_node_or_null("BurnsideWantedRuntime")
	if wanted_runtime == null \
	or not wanted_runtime.has_method("bind_to_scene") \
	or not wanted_runtime.has_method("get_heat_level") \
	or not wanted_runtime.has_method("get_wanted_state_name"):
		await _fail("BurnsideWantedRuntime Mission 02 composition seam is unavailable")
		return
	if not bool(wanted_runtime.call("bind_to_scene", _scene_under_test)):
		await _fail("BurnsideWantedRuntime did not bind to the retained production scene")
		return

	var runtime := _scene_under_test.get_node_or_null("MissionScrapJobRuntime")
	if runtime == null or not bool(runtime.get("_bound")):
		await _fail("Mission/Narrative 01 runtime did not bind to retained gameplay systems")
		return

	var civic_runtime := _scene_under_test.get_node_or_null("CivicRepossessionRuntime")
	if civic_runtime == null:
		await _fail("Mission/Narrative 02 production runtime is missing")
		return
	if civic_runtime.get("_bound") != true:
		await _fail("Mission/Narrative 02 runtime did not bind to retained gameplay systems")
		return
	if civic_runtime.mission.phase != CivicMissionScript.Phase.LOCKED:
		await _fail("Mission/Narrative 02 did not remain LOCKED before Mission 01 completion")
		return

	var city_runtime := _scene_under_test.get_node_or_null("CityThatForgotRuntime")
	if city_runtime == null:
		await _fail("Mission/Narrative 03 production runtime is missing")
		return
	if city_runtime.get("_bound") != true:
		await _fail("Mission/Narrative 03 runtime did not bind to retained gameplay systems")
		return
	if city_runtime.mission.phase != CityMissionScript.Phase.LOCKED:
		await _fail("Mission/Narrative 03 did not remain LOCKED before Civic Repossession completion")
		return
	var silent_core := _scene_under_test.get_node_or_null("SilentCore")
	if silent_core == null:
		await _fail("Mission/Narrative 03 Silent Core is missing from the production slice")
		return
	if bool(silent_core.get("is_powered")):
		await _fail("Silent Core is powered before Mission 03 unlock")
		return
	if silent_core.begin_interaction(player.global_position):
		await _fail("Silent Core accepted interaction before Mission 03 unlock")
		return

	var safe_root := touch_ui.get_node_or_null("SafeAreaRoot")
	var mission_hud := safe_root.get_node_or_null("MissionHUD") if safe_root != null else null
	if mission_hud == null:
		await _fail("Mission/Narrative 01 HUD is not rooted inside the established safe area")
		return
	var margin := mission_hud.find_child("MissionMargin", true, false) as Control
	var stack := mission_hud.find_child("MissionStack", true, false) as Control
	var title := mission_hud.find_child("MissionTitle", true, false) as Label
	var objective := mission_hud.find_child("ObjectiveLabel", true, false) as Label
	var contact := mission_hud.find_child("ContactLabel", true, false) as Label
	if margin == null or stack == null or title == null or objective == null or contact == null:
		await _fail("Mission/Narrative 01 HUD is missing required authored controls")
		return
	for hud_control in [mission_hud, margin, stack, title, objective, contact]:
		if hud_control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			await _fail("Mission HUD contains a control that can steal gameplay touch input")
			return
	if safe_root.find_children("MissionHUD", "PanelContainer", true, false).size() != 1:
		await _fail("Mission chain created a parallel mission HUD instead of reusing Mission 01 UI")
		return
	if "COURIER BIKE" not in objective.text or not contact.text.begins_with("LIRA //"):
		await _fail("Mission/Narrative 01 cold-start briefing is not visible in the production scene")
		return
	var bike = _scene_under_test.get("courier_bike")
	if bike == null or not bike.mounted.is_connected(Callable(runtime, "_on_courier_bike_mounted")):
		await _fail("Retained Courier Bike mounted signal is not connected to the authored mission runtime")
		return
	var hauler = _scene_under_test.get("scrap_hauler")
	if hauler == null:
		await _fail("Retained Scrap Hauler runtime reference is absent")
		return
	if not hauler.mounted.is_connected(Callable(civic_runtime, "_on_hauler_mounted")):
		await _fail("Retained Scrap Hauler mounted signal is not connected to Civic Repossession")
		return
	var signal_gate = _scene_under_test.get("signal_gate")
	if signal_gate == null or not signal_gate.gate_triggered.is_connected(Callable(civic_runtime, "_on_signal_gate_triggered")):
		await _fail("Retained Signal Gate is not connected to Civic Repossession")
		return
	var return_zone := _scene_under_test.get_node_or_null("CivicRepossessionReturnZone")
	if return_zone == null:
		await _fail("Civic Repossession return-zone marker is missing from the production scene")
		return
	if return_zone.visible:
		await _fail("Civic Repossession return zone is visible before delivery phase")
		return

	_stage = "touch_routing"
	touch_ui.joystick_vector_updated.connect(func(vec: Vector2): _last_joystick_vector = vec)
	var start_position: Vector3 = player.global_position

	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 7
	touch_down.pressed = true
	touch_down.position = Vector2(140, 390)
	root.push_input(touch_down, true)
	await process_frame

	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 7
	touch_drag.position = Vector2(180, 390)
	touch_drag.relative = Vector2(40, 0)
	root.push_input(touch_drag, true)
	await process_frame
	for _frame in range(4):
		await physics_frame

	if _last_joystick_vector.length() <= 0.05:
		await _fail("A left-half touch drag did not reach the floating joystick through the real Viewport GUI route")
		return
	if player.joystick_vector.length() <= 0.05:
		await _fail("Joystick signal did not reach PlayerRunner")
		return

	var horizontal_displacement := Vector2(
		player.global_position.x - start_position.x,
		player.global_position.z - start_position.z
	).length()
	if horizontal_displacement <= 0.01:
		await _fail("Touch joystick reached PlayerRunner but did not move the character in world space")
		return

	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 7
	touch_up.pressed = false
	touch_up.position = Vector2(180, 390)
	root.push_input(touch_up, true)
	await process_frame

	if player.joystick_vector.length() > 0.001:
		await _fail("Joystick release did not clear PlayerRunner input")
		return

	_stage = "mission1_tuner"
	runtime.call("_on_courier_bike_mounted", player)
	if bike.get("occupant") != null:
		await _fail("Mission early-park test unexpectedly mounted the retained bike")
		return
	var tuner = _scene_under_test.get("signal_tuner")
	if tuner == null:
		await _fail("Retained Signal Tuner runtime reference is absent")
		return
	player.global_position = tuner.global_position
	await process_frame
	if "SPOOF THE YARD SIGNAL" not in objective.text:
		await _fail("Walking the final meters to the tuner did not advance the authored objective")
		return

	_stage = "mission1_reconcile"
	var panel = _scene_under_test.get("corroded_panel")
	if panel == null:
		await _fail("Retained Corroded Panel runtime reference is absent")
		return
	tuner.set("current_state", SignalTuner.TunerState.LOCKED)
	panel.set("current_step", CorrodedPanel.Step.EXTRACTED)
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE)
	await process_frame
	if "SIGNAL GATE OR LONG ROAD" not in objective.text:
		await _fail("Consumed tuner/panel state did not reconcile into the live route decision")
		return

	_stage = "mission1_retry"
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.INTERCEPTED)
	await process_frame
	if "JOB BURNED" not in objective.text or "RETRY PURSUIT" not in objective.text:
		await _fail("Controller-authoritative INTERCEPTED state did not fail the authored job")
		return
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE)
	await process_frame
	if "SIGNAL GATE OR LONG ROAD" not in objective.text:
		await _fail("Controller-authoritative retry pursuit did not resume the route decision")
		return

	_stage = "mission2_unlock"
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.CALM)
	if not runtime.mission.on_escape_complete():
		await _fail("Mission 01 fixture could not reach COMPLETE before Civic Repossession")
		return
	runtime.call("_refresh_hud")
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.GET_HAULER:
		await _fail("Mission 01 completion did not unlock Civic Repossession in production")
		return
	if title.text != "CIVIC REPOSSESSION // MAYOR BURN":
		await _fail("Civic Repossession did not take ownership of the shared mission title")
		return
	if "SCRAP HAULER" not in objective.text or not contact.text.begins_with("MAYOR BURN //"):
		await _fail("Mayor Burn handoff is not visible on the shared mission HUD")
		return
	if city_runtime.mission.phase != CityMissionScript.Phase.LOCKED:
		await _fail("Mission 03 unlocked before Civic Repossession completion")
		return

	_stage = "mission2_mount"
	hauler.mounted.emit(player)
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.ESCAPE:
		await _fail("Real Scrap Hauler mounted signal did not start Civic Repossession escape")
		return
	if int(_scene_under_test.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.CALM):
		await _fail("Mission 02 Hauler theft started the retired legacy pursuit path")
		return
	if int(wanted_runtime.call("get_heat_level")) != 1 \
	or String(wanted_runtime.call("get_wanted_state_name")) != "CONTACT":
		await _fail("Live Civic Repossession theft did not produce Heat 1 + CONTACT")
		return

	_stage = "mission2_evasion"
	var wanted_authority = wanted_runtime.get("wanted_authority")
	if wanted_authority == null:
		await _fail("Civic Repossession could not read the retained Wanted authority fixture")
		return
	if not bool(wanted_authority.call(
		"lose_contact",
		wanted_authority.call("get_last_known_position"),
		wanted_authority.call("get_last_known_direction"),
		"mobile_touch_mission2_contact_break"
	)):
		await _fail("Mission 02 live-report path could not enter Search through legitimate Contact loss")
		return
	if String(wanted_runtime.call("get_wanted_state_name")) != "SEARCH":
		await _fail("Mission 02 Contact loss did not enter Search")
		return
	var search_seconds := float(wanted_authority.get("search_evasion_seconds"))
	if not bool(wanted_authority.call("advance_search", search_seconds + 0.1)):
		await _fail("Mission 02 Search did not produce legitimate Evasion")
		return
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.DELIVERY:
		await _fail("Open-world Wanted Evasion did not advance Civic Repossession to delivery")
		return
	if not return_zone.visible:
		await _fail("Civic Repossession return zone did not become visible for delivery")
		return

	_stage = "mission2_delivery"
	hauler.global_position = return_zone.global_position
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.COMPLETE:
		await _fail("Delivering the real Scrap Hauler did not complete Civic Repossession")
		return
	if str(CivicMissionScript.PAYOFF_CREDITS) not in objective.text:
		await _fail("Civic Repossession payoff is not visible after delivery")
		return

	_stage = "mission3_unlock"
	await process_frame
	if city_runtime.mission.phase != CityMissionScript.Phase.REACH_SILENT_CORE:
		await _fail("Civic Repossession completion did not unlock The City That Forgot")
		return
	if title.text != "THE CITY THAT FORGOT // SISTER KAEL":
		await _fail("Mission 03 did not take ownership of the existing shared MissionHUD")
		return
	if "SILENT CORE" not in objective.text or not contact.text.begins_with("SISTER KAEL //"):
		await _fail("Sister Kael / Silent Core handoff is not visible on the shared HUD")
		return
	if not bool(silent_core.get("is_powered")):
		await _fail("Silent Core did not power on for the Mission 03 objective")
		return
	if safe_root.find_children("MissionHUD", "PanelContainer", true, false).size() != 1:
		await _fail("Mission 03 created a parallel MissionHUD")
		return

	_stage = "mission3_action"
	player.global_position = silent_core.global_position
	silent_core.update_player_distance(player.global_position)
	_scene_under_test.call("_evaluate_target_selection")
	if _scene_under_test.get("_active_target") != silent_core:
		await _fail("Retained target arbitration did not select the Silent Core")
		return
	touch_ui.action_button_pressed.emit()
	await process_frame
	if city_runtime.mission.phase != CityMissionScript.Phase.ECHO_ACTIVE:
		await _fail("Retained Action route did not activate the Silent Core")
		return
	if int(silent_core.get("activation_count")) != 1:
		await _fail("Silent Core activation was not exactly once")
		return
	var echo_controller = _scene_under_test.get("echo_controller")
	if echo_controller == null:
		await _fail("Mission 03 did not reuse the retained Memory Echo controller")
		return
	if echo_controller.get_trigger_count() != 1:
		await _fail("Mission 03 authored Echo did not trigger exactly once")
		return
	var echo_data = echo_controller.get("_echo_data")
	if echo_data == null or echo_data.mission_ref != "mission_03_city_that_forgot":
		await _fail("Mission 03 Echo did not carry the authored HS-7 mission payload")
		return
	touch_ui.action_button_pressed.emit()
	await process_frame
	if echo_controller.get_trigger_count() != 1 or int(silent_core.get("activation_count")) != 1:
		await _fail("Repeated Action input duplicated the Mission 03 Echo")
		return

	_stage = "mission3_echo_complete"
	echo_controller.call("_process", 1.0)
	echo_controller.call("_process", 2.0)
	echo_controller.call("_process", 1.0)
	await process_frame
	if city_runtime.mission.phase != CityMissionScript.Phase.ESCAPE:
		await _fail("Authored HS-7 Echo completion did not start Mission 03 escape")
		return
	if int(_scene_under_test.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.DISTURBANCE_ALERT):
		await _fail("Mission 03 did not start its retained pursuit from the post-Mission-02 CALM authority")
		return

	_stage = "mission3_intercept"
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.INTERCEPTED)
	await process_frame
	if city_runtime.mission.phase != CityMissionScript.Phase.FAILED or "RETRY PURSUIT" not in objective.text:
		await _fail("Retained interception did not fail Mission 03")
		return
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE)
	await process_frame
	if city_runtime.mission.phase != CityMissionScript.Phase.ESCAPE:
		await _fail("Retained fast retry did not resume Mission 03 escape")
		return

	_stage = "mission3_evasion"
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.EVADED)
	await process_frame
	if city_runtime.mission.phase != CityMissionScript.Phase.COMPLETE:
		await _fail("Retained evasion did not complete Mission 03")
		return
	if "CITY THAT FORGOT" not in objective.text or not contact.text.begins_with("SISTER KAEL //"):
		await _fail("Mission 03 narrative aftermath is not visible on the shared HUD")
		return
	if city_runtime.mission.reward_credits != 0:
		await _fail("Mission 03 production runtime introduced an out-of-scope economy reward")
		return

	_stage = "full_replay"
	wanted_runtime.call("reset_runtime")
	_scene_under_test.call("reset_slice")
	await process_frame
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.LOCKED:
		await _fail("Full replay did not relock Civic Repossession behind Mission 01")
		return
	if city_runtime.mission.phase != CityMissionScript.Phase.LOCKED:
		await _fail("Full replay did not relock Mission 03 behind Civic Repossession")
		return
	if bool(silent_core.get("is_powered")) or int(silent_core.get("activation_count")) != 0:
		await _fail("Full replay leaked Silent Core power or activation state")
		return
	if return_zone.visible:
		await _fail("Full replay left the Civic Repossession return zone visible")
		return
	if int(wanted_runtime.call("get_heat_level")) != 0 \
	or String(wanted_runtime.call("get_wanted_state_name")) != "CLEAR":
		await _fail("Full replay did not restore the open-world Wanted baseline")
		return
	if title.text != "SCRAP JOB 01 // CITY PROPERTY" or "COURIER BIKE" not in objective.text:
		await _fail("Full replay did not restore Mission 01 shared HUD ownership")
		return

	_stage = "premounted_hauler_reconcile"
	if not runtime.mission.on_courier_bike_mounted():
		await _fail("Pre-mounted Hauler fixture could not pass Mission 01 bike prerequisite")
		return
	if not runtime.mission.on_tuner_arrived():
		await _fail("Pre-mounted Hauler fixture could not reach tuner objective")
		return
	if not runtime.mission.on_signal_locked():
		await _fail("Pre-mounted Hauler fixture could not solve signal")
		return
	if not runtime.mission.on_core_extracted():
		await _fail("Pre-mounted Hauler fixture could not extract core")
		return
	if not runtime.mission.on_pursuit_active():
		await _fail("Pre-mounted Hauler fixture could not reach escape")
		return
	tuner.set("current_state", SignalTuner.TunerState.LOCKED)
	panel.set("current_step", CorrodedPanel.Step.EXTRACTED)
	hauler.set("occupant", player)
	hauler.mounted.emit(player)
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.LOCKED:
		await _fail("Hauler use before Mission 01 completion incorrectly unlocked Civic Repossession")
		return
	_scene_under_test.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.CALM)
	if not runtime.mission.on_escape_complete():
		await _fail("Pre-mounted Hauler fixture could not complete Mission 01")
		return
	runtime.call("_refresh_hud")
	await process_frame
	if civic_runtime.mission.phase != CivicMissionScript.Phase.ESCAPE:
		await _fail("Civic Repossession stranded after Mission 01 completed with the Hauler already occupied")
		return
	if int(_scene_under_test.get("current_pursuit_state")) != int(ScrapTestBlockScript.PursuitState.CALM):
		await _fail("Pre-mounted Hauler reconciliation incorrectly started the retired legacy pursuit")
		return
	if int(wanted_runtime.call("get_heat_level")) != 1 \
	or String(wanted_runtime.call("get_wanted_state_name")) != "CONTACT":
		await _fail("Pre-mounted Hauler reconciliation did not create the civic Heat 1 + CONTACT report")
		return
	if city_runtime.mission.phase != CityMissionScript.Phase.LOCKED:
		await _fail("Mission 03 unlocked during Civic Repossession pre-mounted recovery")
		return

	print("[MISSION_NARRATIVE_01] CONTRACT + RUNTIME WIRING PASS")
	print("[MISSION_NARRATIVE_02] CONTRACT + RUNTIME WIRING PASS")
	print("[MISSION_NARRATIVE_03] CONTRACT + RUNTIME WIRING PASS")
	print("[MOBILE_TOUCH_ROUTING] PASS")
	await _finish(0)