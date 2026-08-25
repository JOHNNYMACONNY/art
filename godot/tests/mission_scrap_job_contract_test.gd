extends SceneTree

const MissionScript = preload("res://scripts/missions/scrap_job_mission.gd")

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[MISSION_NARRATIVE_01] %s" % message)
	quit(1)

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true

func _advance_to_route_decision(mission) -> bool:
	if not _expect(mission.start(), "Mission did not start from briefing state"):
		return false
	if not _expect(mission.on_courier_bike_mounted(), "Courier Bike mount did not advance traversal"):
		return false
	if not _expect(mission.on_tuner_arrived(), "Tuner arrival did not advance spoof objective"):
		return false
	if not _expect(mission.on_signal_locked(), "Signal lock did not advance core theft objective"):
		return false
	if not _expect(mission.on_core_extracted(), "Core extraction did not enter pursuit complication"):
		return false
	if not _expect(mission.on_pursuit_active(), "Pursuit activation did not expose route decision"):
		return false
	return true

func _run() -> void:
	var mission = MissionScript.new()
	if not _expect(mission.phase == MissionScript.Phase.BRIEFING, "Fresh mission did not begin in BRIEFING"):
		return
	if not _expect(mission.start(), "Mission start was rejected"):
		return
	if not _expect(mission.phase == MissionScript.Phase.GET_BIKE, "Briefing did not resolve to GET_BIKE"):
		return
	if not _expect("COURIER BIKE" in mission.objective, "Cold-start objective does not identify the Courier Bike"):
		return
	if not _expect(mission.contact_line.begins_with("LIRA //"), "Cold-start contact line is not authored as Lira briefing"):
		return

	var phase_before_wrong_order = mission.phase
	if not _expect(not mission.on_signal_locked(), "Out-of-order signal lock mutated the mission"):
		return
	if not _expect(mission.phase == phase_before_wrong_order, "Wrong-order event changed mission phase"):
		return

	if not _expect(mission.on_courier_bike_mounted(), "Courier Bike mount did not advance mission"):
		return
	if not _expect(mission.phase == MissionScript.Phase.TRAVERSE_TO_TUNER, "Bike mount did not enter traversal phase"):
		return
	if not _expect("TUNER MAST" in mission.objective, "Traversal objective does not name the tuner mast"):
		return
	if not _expect(mission.on_tuner_arrived(), "Tuner arrival did not advance mission"):
		return
	if not _expect(mission.phase == MissionScript.Phase.SPOOF_SIGNAL, "Tuner arrival did not enter spoof phase"):
		return
	if not _expect(mission.on_signal_locked(), "Signal lock did not advance mission"):
		return
	if not _expect(mission.phase == MissionScript.Phase.EXTRACT_CORE, "Signal lock did not enter extraction phase"):
		return
	if not _expect("CUSTOMS CORE" in mission.objective, "Extraction objective does not identify the customs core"):
		return
	if not _expect(mission.on_core_extracted(), "Core extraction did not advance mission"):
		return
	if not _expect(mission.phase == MissionScript.Phase.PURSUIT_COMPLICATION, "Core extraction bypassed pursuit complication phase"):
		return
	if not _expect(mission.on_pursuit_active(), "Pursuit activation did not advance mission"):
		return
	if not _expect(mission.phase == MissionScript.Phase.ROUTE_DECISION, "Pursuit did not expose route decision"):
		return
	if not _expect("SIGNAL GATE" in mission.objective and "LONG ROAD" in mission.objective, "Route objective does not expose both authored choices"):
		return
	if not _expect(mission.on_gate_triggered(), "Signal Gate event did not advance escape"):
		return
	if not _expect(mission.route_choice == MissionScript.RouteChoice.SIGNAL_GATE, "Signal Gate route was not recorded"):
		return
	if not _expect(mission.phase == MissionScript.Phase.ESCAPE, "Signal Gate did not enter ESCAPE"):
		return
	if not _expect(mission.on_escape_complete(), "Successful shortcut escape did not complete mission"):
		return
	if not _expect(mission.phase == MissionScript.Phase.COMPLETE, "Shortcut run did not reach COMPLETE"):
		return
	if not _expect(mission.reward_credits == MissionScript.PAYOFF_CREDITS, "Completed job did not award configured payoff"):
		return
	if not _expect(str(MissionScript.PAYOFF_CREDITS) in mission.objective, "Payoff amount is not visible in completion objective"):
		return
	if not _expect("Municipal" in mission.contact_line, "Completion aftermath does not carry authored crime-satire consequence"):
		return

	var long_road = MissionScript.new()
	if not _advance_to_route_decision(long_road):
		return
	if not _expect(long_road.on_escape_complete(), "Long-road evasion did not complete from route decision"):
		return
	if not _expect(long_road.route_choice == MissionScript.RouteChoice.LONG_ROAD, "Ungated escape did not record LONG_ROAD"):
		return
	if not _expect(long_road.phase == MissionScript.Phase.COMPLETE, "Long-road run did not reach COMPLETE"):
		return

	var retry = MissionScript.new()
	if not _advance_to_route_decision(retry):
		return
	if not _expect(retry.on_intercepted(), "Interception did not fail active job"):
		return
	if not _expect(retry.phase == MissionScript.Phase.FAILED, "Interception did not enter FAILED"):
		return
	if not _expect(retry.reward_credits == 0, "Failed job incorrectly retained payoff"):
		return
	if not _expect("RETRY PURSUIT" in retry.objective, "Failure objective does not expose retained fast retry"):
		return
	if not _expect(retry.on_retry_started(), "Fast retry did not resume authored job"):
		return
	if not _expect(retry.phase == MissionScript.Phase.ROUTE_DECISION, "Fast retry replayed solved setup instead of route decision"):
		return
	if not _expect(retry.route_choice == MissionScript.RouteChoice.UNDECIDED, "Fast retry did not reset route choice"):
		return
	if not _expect(retry.failure_count == 1, "Failure accounting is incorrect"):
		return

	print("[MISSION_NARRATIVE_01] PASS")
	quit(0)
