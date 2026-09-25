extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const STORE_PATH := "res://scripts/progress/burnside_cash_progress_store.gd"
const CASH_TEST_PATH := "user://tests/p12_mission_cash_payout_integration_test.json"
const ScrapJobMissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for path in [CASH_TEST_PATH, CASH_TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish(code: int) -> void:
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_cleanup()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P13_MISSION_CASH_RUNTIME] " + message)
	await _finish(1)

func _complete_mission_one_production(runtime: Node) -> String:
	var player = _scene.get_node_or_null("Runner")
	var bike = _scene.get("courier_bike")
	var tuner = _scene.get("signal_tuner")
	var panel = _scene.get("corroded_panel")
	var pursuer = _scene.get("pursuer")
	if player == null or bike == null or tuner == null or panel == null or pursuer == null:
		return "Mission 01 retained production dependencies are missing"
	if int(runtime.mission.phase) != ScrapJobMissionScript.Phase.GET_BIKE:
		return "Mission 01 did not begin replay at GET_BIKE"

	bike.mounted.emit(player)
	if int(runtime.mission.phase) != ScrapJobMissionScript.Phase.TRAVERSE_TO_TUNER:
		return "Courier Bike production signal did not advance Mission 01"

	player.global_position = tuner.global_position
	runtime.call("_process", 0.0)
	if int(runtime.mission.phase) != ScrapJobMissionScript.Phase.SPOOF_SIGNAL:
		return "Production tuner arrival did not advance Mission 01"

	tuner.set("current_state", SignalTuner.TunerState.LOCKED)
	runtime.call("_process", 0.0)
	if int(runtime.mission.phase) != ScrapJobMissionScript.Phase.EXTRACT_CORE:
		return "Retained tuner state did not reconcile Mission 01"

	panel.set("current_step", CorrodedPanel.Step.EXTRACTED)
	runtime.call("_process", 0.0)
	if int(runtime.mission.phase) != ScrapJobMissionScript.Phase.PURSUIT_COMPLICATION:
		return "Retained core extraction did not advance Mission 01"

	_scene.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE)
	runtime.call("_process", 0.0)
	if int(runtime.mission.phase) != ScrapJobMissionScript.Phase.ROUTE_DECISION:
		return "Production pursuit state did not advance Mission 01"

	_scene.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.CALM)
	pursuer.de_escalation_completed.emit()
	if int(runtime.mission.phase) != ScrapJobMissionScript.Phase.COMPLETE:
		return "Production escape signal did not complete Mission 01"
	return ""

func _complete_mission_two_production(runtime: Node) -> String:
	runtime.call("_process", 0.0)
	var mission = runtime.get("mission")
	if mission == null:
		return "Mission 02 authored state is missing"
	if int(mission.phase) == CivicMissionScript.Phase.LOCKED:
		if not bool(mission.call("unlock_after_scrap_job")):
			return "Mission 02 could not unlock after Mission 01"
	if int(mission.phase) != CivicMissionScript.Phase.GET_HAULER:
		return "Mission 02 did not reach GET_HAULER"
	if not bool(mission.call("on_vehicle_mounted", "ScrapHauler")):
		return "Mission 02 authored mount transition failed"
	if not bool(mission.call("on_clean_take")):
		return "Mission 02 authored clean-take transition failed"
	if int(mission.phase) != CivicMissionScript.Phase.DELIVERY:
		return "Mission 02 did not reach DELIVERY"

	var hauler = _scene.get("scrap_hauler")
	var return_zone = runtime.get("_return_zone")
	if hauler == null or return_zone == null:
		return "Mission 02 production delivery dependencies are missing"
	hauler.global_position = return_zone.global_position
	runtime.call("_process", 0.0)
	if int(mission.phase) != CivicMissionScript.Phase.COMPLETE:
		return "Physical production delivery did not complete Mission 02"
	return ""

func _run() -> void:
	_cleanup()
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null or _wanted_runtime == null:
		await _fail("Production scene or Wanted runtime is unavailable")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame

	var cash_runtime := _scene.get_node_or_null("BurnsideCashEconomyRuntime")
	var mission_one := _scene.get_node_or_null("MissionScrapJobRuntime")
	var mission_two := _scene.get_node_or_null("CivicRepossessionRuntime")
	var cash_notice := _scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/CashNotice") as Label
	if cash_runtime == null or mission_one == null or mission_two == null or cash_notice == null:
		await _fail("P13 production composition is incomplete")
		return
	if String(cash_runtime.call("get_progress_store").call("get_storage_path")) != CASH_TEST_PATH:
		await _fail("Cash runtime did not use the isolated P13 test storage")
		return
	if not mission_one.has_signal("scrap_job_completed"):
		await _fail("Mission 01 production runtime is missing bounded completion signal")
		return
	for method_name in ["award_mission_01", "award_mission_02"]:
		if not cash_runtime.has_method(method_name):
			await _fail("Cash runtime missing P13 method " + method_name)
			return

	var completion_count := [0]
	mission_one.connect("scrap_job_completed", func(): completion_count[0] += 1)

	# Direct/test-only mutation is not a payout seam.
	mission_one.mission.set("phase", ScrapJobMissionScript.Phase.COMPLETE)
	mission_one.call("_process", 0.0)
	if completion_count[0] != 0 or int(cash_runtime.call("get_balance")) != 0:
		await _fail("Manual Mission 01 phase mutation emitted completion or credited Cash")
		return
	if int(mission_one.mission.phase) != ScrapJobMissionScript.Phase.GET_BIKE:
		await _fail("Clean-world manual mutation did not safely re-arm Mission 01")
		return

	# First legitimate production Mission 01 completion pays exactly 320 once.
	var error := _complete_mission_one_production(mission_one)
	if not error.is_empty():
		await _fail(error)
		return
	if completion_count[0] != 1:
		await _fail("Mission 01 production completion signal did not emit exactly once")
		return
	if int(cash_runtime.call("get_balance")) != 320:
		await _fail("Mission 01 completion did not credit exact 320 Cash")
		return
	if String(cash_notice.text) != "JOB PAID // +320 CASH // BALANCE 320":
		await _fail("Mission 01 first-payment notice is not truthful")
		return
	_scene.get("pursuer").de_escalation_completed.emit()
	if completion_count[0] != 1 or int(cash_runtime.call("get_balance")) != 320:
		await _fail("Duplicate Mission 01 completion signal/payment occurred")
		return

	# First Mission 02 production delivery pays exactly 450 and leaves Burn Contact independent.
	error = _complete_mission_two_production(mission_two)
	if not error.is_empty():
		await _fail(error)
		return
	if int(cash_runtime.call("get_balance")) != 770:
		await _fail("Mission 02 completion did not produce exact cumulative 770 Cash")
		return
	if String(cash_notice.text) != "BURN PAID // +450 CASH // BALANCE 770":
		await _fail("Mission 02 first-payment notice is not truthful")
		return

	var store = cash_runtime.call("get_progress_store")
	if not bool(store.call("has_mission_01_receipt")) or not bool(store.call("has_mission_02_receipt")):
		await _fail("Production payouts did not persist both durable receipts")
		return
	var reconstructed = load(STORE_PATH).new()
	reconstructed.configure(CASH_TEST_PATH)
	if int(reconstructed.get_balance()) != 770 \
	or not bool(reconstructed.call("has_mission_01_receipt")) \
	or not bool(reconstructed.call("has_mission_02_receipt")):
		await _fail("Fresh store reconstruction lost mission payout state")
		return

	# Full Replay resets missions but preserves durable Cash and receipts.
	_scene.call("reset_slice")
	await process_frame
	await process_frame
	mission_one.call("_process", 0.0)
	mission_two.call("_process", 0.0)
	if int(cash_runtime.call("get_balance")) != 770:
		await _fail("Full Replay changed durable Cash before replay completion")
		return

	error = _complete_mission_one_production(mission_one)
	if not error.is_empty():
		await _fail("Mission 01 replay: " + error)
		return
	if completion_count[0] != 2:
		await _fail("Mission 01 replay did not remain playable/re-arm its runtime signal")
		return
	if int(cash_runtime.call("get_balance")) != 770:
		await _fail("Mission 01 replay duplicated durable payout")
		return
	if String(cash_notice.text) != "PAYMENT ALREADY CLEARED // BALANCE 770" or String(cash_notice.text).contains("+320"):
		await _fail("Mission 01 replay falsely advertised a new Cash payment")
		return

	error = _complete_mission_two_production(mission_two)
	if not error.is_empty():
		await _fail("Mission 02 replay: " + error)
		return
	if int(cash_runtime.call("get_balance")) != 770:
		await _fail("Mission 02 replay duplicated durable payout")
		return
	if String(cash_notice.text) != "PAYMENT ALREADY CLEARED // BALANCE 770" or String(cash_notice.text).contains("+450"):
		await _fail("Mission 02 replay falsely advertised a new Cash payment")
		return

	print("[P13_MISSION_CASH_RUNTIME] PASS")
	await _finish(0)
