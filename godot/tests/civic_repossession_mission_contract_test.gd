extends RefCounted

const MissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")

static func verify() -> String:
	var mission = MissionScript.new()
	if mission.phase != MissionScript.Phase.LOCKED:
		return "Fresh Civic Repossession mission did not begin LOCKED"
	if mission.on_vehicle_mounted("ScrapHauler"):
		return "Locked mission accepted Hauler mount before Mission 01 completion"
	if mission.on_return_zone_entered():
		return "Locked mission accepted return-zone completion"

	if not mission.unlock_after_scrap_job():
		return "Mission 01 completion did not unlock Civic Repossession"
	if mission.phase != MissionScript.Phase.GET_HAULER:
		return "Unlock did not enter GET_HAULER"
	if "SCRAP HAULER" not in mission.objective:
		return "Unlock objective does not identify the Scrap Hauler"
	if not mission.contact_line.begins_with("MAYOR BURN //"):
		return "Mayor Burn does not own the Civic Repossession briefing"

	var phase_before_wrong_vehicle = mission.phase
	if mission.on_vehicle_mounted("CourierBike"):
		return "Courier Bike incorrectly satisfied the Hauler acquisition objective"
	if mission.phase != phase_before_wrong_vehicle:
		return "Wrong vehicle mutated Civic Repossession phase"
	if mission.on_return_zone_entered():
		return "Return zone completed before Hauler theft/escape"

	if not mission.on_vehicle_mounted("ScrapHauler"):
		return "Scrap Hauler mount did not start the escape"
	if mission.phase != MissionScript.Phase.ESCAPE:
		return "Scrap Hauler mount did not enter ESCAPE"
	if "SIGNAL GATE" not in mission.objective or "LONG ROAD" not in mission.objective:
		return "Escape objective does not expose retained route choice"

	if not mission.on_gate_triggered():
		return "Signal Gate did not record Civic Repossession shortcut"
	if mission.route_choice != MissionScript.RouteChoice.SIGNAL_GATE:
		return "Signal Gate route choice was not recorded"

	if not mission.on_intercepted():
		return "Controller interception did not fail Civic Repossession"
	if mission.phase != MissionScript.Phase.FAILED:
		return "Interception did not enter FAILED"
	if "RETRY PURSUIT" not in mission.objective:
		return "Failure objective does not expose retained fast retry"
	if mission.reward_credits != 0:
		return "Failed mission retained payoff"
	if not mission.on_retry_started():
		return "Fast retry did not resume Civic Repossession"
	if mission.phase != MissionScript.Phase.ESCAPE:
		return "Fast retry did not resume the escape phase"
	if mission.route_choice != MissionScript.RouteChoice.UNDECIDED:
		return "Fast retry did not reset route decision"
	if mission.failure_count != 1:
		return "Failure accounting is incorrect"

	if not mission.on_evasion_complete():
		return "Successful evasion did not advance to delivery"
	if mission.phase != MissionScript.Phase.DELIVERY:
		return "Evasion did not enter DELIVERY"
	if mission.route_choice != MissionScript.RouteChoice.LONG_ROAD:
		return "Ungated retry escape did not record LONG_ROAD"
	if "RETURN" not in mission.objective or "HAULER" not in mission.objective:
		return "Delivery objective does not identify the Hauler return"
	if not mission.on_return_zone_entered():
		return "Return zone did not complete Civic Repossession"
	if mission.phase != MissionScript.Phase.COMPLETE:
		return "Delivery did not reach COMPLETE"
	if mission.reward_credits != MissionScript.PAYOFF_CREDITS:
		return "Completion did not award configured payoff"
	if str(MissionScript.PAYOFF_CREDITS) not in mission.objective:
		return "Completion objective does not expose payoff"
	if "municipal" not in mission.contact_line.to_lower():
		return "Aftermath line does not preserve Civic Repossession satire"

	var shortcut = MissionScript.new()
	if not shortcut.unlock_after_scrap_job():
		return "Shortcut fixture did not unlock"
	if not shortcut.on_vehicle_mounted("ScrapHauler"):
		return "Shortcut fixture did not accept Hauler"
	if not shortcut.on_gate_triggered():
		return "Shortcut fixture did not accept Signal Gate"
	if not shortcut.on_evasion_complete():
		return "Shortcut fixture did not advance after evasion"
	if shortcut.route_choice != MissionScript.RouteChoice.SIGNAL_GATE:
		return "Shortcut choice was lost during evasion"
	if not shortcut.on_return_zone_entered():
		return "Shortcut fixture did not complete delivery"

	return ""
