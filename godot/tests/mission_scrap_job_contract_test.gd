extends RefCounted

const MissionScript = preload("res://scripts/missions/scrap_job_mission.gd")

static func _advance_to_route_decision(mission) -> String:
	if not mission.start():
		return "Mission did not start from briefing state"
	if not mission.on_courier_bike_mounted():
		return "Courier Bike mount did not advance traversal"
	if not mission.on_tuner_arrived():
		return "Tuner arrival did not advance spoof objective"
	if not mission.on_signal_locked():
		return "Signal lock did not advance core theft objective"
	if not mission.on_core_extracted():
		return "Core extraction did not enter pursuit complication"
	if not mission.on_pursuit_active():
		return "Pursuit activation did not expose route decision"
	return ""

static func verify() -> String:
	var mission = MissionScript.new()
	if mission.phase != MissionScript.Phase.BRIEFING:
		return "Fresh mission did not begin in BRIEFING"
	if not mission.start():
		return "Mission start was rejected"
	if mission.phase != MissionScript.Phase.GET_BIKE:
		return "Briefing did not resolve to GET_BIKE"
	if "COURIER BIKE" not in mission.objective:
		return "Cold-start objective does not identify the Courier Bike"
	if not mission.contact_line.begins_with("LIRA //"):
		return "Cold-start contact line is not authored as Lira briefing"

	var phase_before_wrong_order = mission.phase
	if mission.on_signal_locked():
		return "Out-of-order signal lock mutated the mission"
	if mission.phase != phase_before_wrong_order:
		return "Wrong-order event changed mission phase"

	if not mission.on_courier_bike_mounted():
		return "Courier Bike mount did not advance mission"
	if mission.phase != MissionScript.Phase.TRAVERSE_TO_TUNER:
		return "Bike mount did not enter traversal phase"
	if "TUNER MAST" not in mission.objective:
		return "Traversal objective does not name the tuner mast"
	if not mission.on_tuner_arrived():
		return "Tuner arrival did not advance mission"
	if mission.phase != MissionScript.Phase.SPOOF_SIGNAL:
		return "Tuner arrival did not enter spoof phase"
	if not mission.on_signal_locked():
		return "Signal lock did not advance mission"
	if mission.phase != MissionScript.Phase.EXTRACT_CORE:
		return "Signal lock did not enter extraction phase"
	if "CUSTOMS CORE" not in mission.objective:
		return "Extraction objective does not identify the customs core"
	if not mission.on_core_extracted():
		return "Core extraction did not advance mission"
	if mission.phase != MissionScript.Phase.PURSUIT_COMPLICATION:
		return "Core extraction bypassed pursuit complication phase"
	if not mission.on_pursuit_active():
		return "Pursuit activation did not advance mission"
	if mission.phase != MissionScript.Phase.ROUTE_DECISION:
		return "Pursuit did not expose route decision"
	if "SIGNAL GATE" not in mission.objective or "LONG ROAD" not in mission.objective:
		return "Route objective does not expose both authored choices"
	if not mission.on_gate_triggered():
		return "Signal Gate event did not advance escape"
	if mission.route_choice != MissionScript.RouteChoice.SIGNAL_GATE:
		return "Signal Gate route was not recorded"
	if mission.phase != MissionScript.Phase.ESCAPE:
		return "Signal Gate did not enter ESCAPE"
	if not mission.on_escape_complete():
		return "Successful shortcut escape did not complete mission"
	if mission.phase != MissionScript.Phase.COMPLETE:
		return "Shortcut run did not reach COMPLETE"
	if mission.reward_credits != MissionScript.PAYOFF_CREDITS:
		return "Completed job did not award configured payoff"
	if str(MissionScript.PAYOFF_CREDITS) not in mission.objective:
		return "Payoff amount is not visible in completion objective"
	if "Municipal" not in mission.contact_line:
		return "Completion aftermath does not carry authored crime-satire consequence"

	var long_road = MissionScript.new()
	var long_road_setup := _advance_to_route_decision(long_road)
	if not long_road_setup.is_empty():
		return long_road_setup
	if not long_road.on_escape_complete():
		return "Long-road evasion did not complete from route decision"
	if long_road.route_choice != MissionScript.RouteChoice.LONG_ROAD:
		return "Ungated escape did not record LONG_ROAD"
	if long_road.phase != MissionScript.Phase.COMPLETE:
		return "Long-road run did not reach COMPLETE"

	var retry = MissionScript.new()
	var retry_setup := _advance_to_route_decision(retry)
	if not retry_setup.is_empty():
		return retry_setup
	if not retry.on_intercepted():
		return "Interception did not fail active job"
	if retry.phase != MissionScript.Phase.FAILED:
		return "Interception did not enter FAILED"
	if retry.reward_credits != 0:
		return "Failed job incorrectly retained payoff"
	if "RETRY PURSUIT" not in retry.objective:
		return "Failure objective does not expose retained fast retry"
	if not retry.on_retry_started():
		return "Fast retry did not resume authored job"
	if retry.phase != MissionScript.Phase.ROUTE_DECISION:
		return "Fast retry replayed solved setup instead of route decision"
	if retry.route_choice != MissionScript.RouteChoice.UNDECIDED:
		return "Fast retry did not reset route choice"
	if retry.failure_count != 1:
		return "Failure accounting is incorrect"

	return ""
