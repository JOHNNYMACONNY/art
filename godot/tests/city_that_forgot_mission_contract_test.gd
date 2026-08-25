extends RefCounted

const MISSION_PATH := "res://scripts/missions/city_that_forgot_mission.gd"

static func verify() -> String:
	var mission_script = load(MISSION_PATH)
	if mission_script == null:
		return "The City That Forgot mission script is missing"

	var mission = mission_script.new()
	if mission.phase != mission_script.Phase.LOCKED:
		return "Fresh Mission 03 did not begin LOCKED"
	if mission.on_silent_core_activated():
		return "Locked Mission 03 accepted Silent Core activation"
	if mission.on_echo_completed():
		return "Locked Mission 03 accepted Echo completion"
	if mission.on_escape_complete():
		return "Locked Mission 03 accepted escape completion"

	if not mission.unlock_after_civic_repossession():
		return "Civic Repossession completion did not unlock Mission 03"
	if mission.phase != mission_script.Phase.REACH_SILENT_CORE:
		return "Mission 03 unlock did not enter REACH_SILENT_CORE"
	if "SILENT CORE" not in mission.objective:
		return "Mission 03 unlock objective does not identify the Silent Core"
	if not mission.contact_line.begins_with("SISTER KAEL //"):
		return "Sister Kael does not own the Mission 03 briefing"
	if mission.on_echo_completed():
		return "Mission 03 accepted Echo completion before Silent Core activation"
	if mission.on_intercepted():
		return "Mission 03 accepted interception before pursuit"

	if not mission.on_silent_core_activated():
		return "Silent Core activation did not start the authored Echo"
	if mission.phase != mission_script.Phase.ECHO_ACTIVE:
		return "Silent Core activation did not enter ECHO_ACTIVE"
	if mission.on_silent_core_activated():
		return "Mission 03 accepted duplicate Silent Core activation"
	if mission.on_escape_complete():
		return "Mission 03 accepted escape while Echo was active"

	if not mission.on_echo_completed():
		return "Authored Echo completion did not start Mission 03 escape"
	if mission.phase != mission_script.Phase.ESCAPE:
		return "Echo completion did not enter ESCAPE"
	if "ESCAPE" not in mission.objective:
		return "Mission 03 escape objective is not explicit"

	if not mission.on_intercepted():
		return "Retained interception did not fail Mission 03"
	if mission.phase != mission_script.Phase.FAILED:
		return "Mission 03 interception did not enter FAILED"
	if mission.failure_count != 1:
		return "Mission 03 failure accounting is incorrect"
	if "RETRY PURSUIT" not in mission.objective:
		return "Mission 03 failure objective does not expose fast retry"
	if not mission.on_retry_started():
		return "Retained fast retry did not resume Mission 03"
	if mission.phase != mission_script.Phase.ESCAPE:
		return "Mission 03 fast retry did not resume ESCAPE"

	if not mission.on_escape_complete():
		return "Retained evasion did not complete Mission 03"
	if mission.phase != mission_script.Phase.COMPLETE:
		return "Mission 03 evasion did not reach COMPLETE"
	if mission.reward_credits != 0:
		return "Mission 03 introduced an economy reward despite narrative-only scope"
	if "CITY THAT FORGOT" not in mission.objective:
		return "Mission 03 completion does not name the authored chapter"
	if not mission.contact_line.begins_with("SISTER KAEL //"):
		return "Sister Kael does not own the Mission 03 aftermath"

	return ""
