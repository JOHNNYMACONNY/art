extends RefCounted

const AUTHORITY_PATH := "res://scripts/world/wanted_authority.gd"

static func verify() -> String:
	if not ResourceLoader.exists(AUTHORITY_PATH):
		return "Wanted authority implementation is absent"

	var authority_script = load(AUTHORITY_PATH)
	if authority_script == null:
		return "Wanted authority script could not be loaded"
	var authority = authority_script.new()
	if authority == null:
		return "Wanted authority could not be instantiated"

	var required_methods := [
		"get_heat_level",
		"get_wanted_state_name",
		"get_tracking_position",
		"get_last_reason",
		"get_last_known_position",
		"get_last_known_direction",
		"submit_report",
		"observe_contact",
		"lose_contact",
		"reacquire",
		"advance_search",
		"reset",
	]
	for method_name in required_methods:
		if not authority.has_method(method_name):
			return "Wanted authority missing method: %s" % method_name

	if int(authority.call("get_heat_level")) != 0:
		return "Wanted authority did not begin at Heat 0"
	if String(authority.call("get_wanted_state_name")) != "CLEAR":
		return "Wanted authority did not begin CLEAR"

	var incident_pos := Vector3(4.0, 0.0, 6.0)
	var incident_dir := Vector3.FORWARD
	var suppressed := bool(authority.call("submit_report", "", incident_pos, incident_dir, ""))
	if suppressed:
		return "Suppressed/invalid Report incorrectly created Wanted"
	if int(authority.call("get_heat_level")) != 0:
		return "Invalid Report changed Heat"

	var reported := bool(authority.call(
		"submit_report",
		"gears_civic_alarm",
		incident_pos,
		incident_dir,
		"civic_alarm_direct_observation"
	))
	if not reported:
		return "Valid Report did not create Heat 1 + Contact"
	if int(authority.call("get_heat_level")) != 1:
		return "Valid Report did not set Heat 1"
	if String(authority.call("get_wanted_state_name")) != "CONTACT":
		return "Valid Report did not enter Contact"
	if String(authority.call("get_last_reason")) != "report:gears_civic_alarm":
		return "Report source was not retained as authority knowledge"

	var observed_pos := Vector3(8.0, 0.0, 11.0)
	var observed_dir := Vector3(1.0, 0.0, 0.5).normalized()
	if not bool(authority.call("observe_contact", "pursuer_direct_observation", observed_pos, observed_dir)):
		return "Concrete Contact observation refresh was rejected"
	if (authority.call("get_last_known_position") as Vector3).distance_to(observed_pos) > 0.001:
		return "Contact observation did not refresh last-known position"
	if (authority.call("get_last_known_direction") as Vector3).distance_to(observed_dir) > 0.001:
		return "Contact observation did not refresh last-known direction"
	if String(authority.call("get_last_reason")) != "observe:pursuer_direct_observation":
		return "Contact observation source was not retained"
	if bool(authority.call("observe_contact", "", Vector3(99, 0, 99), Vector3.LEFT)):
		return "Contact observation accepted an empty source"
	if (authority.call("get_last_known_position") as Vector3).distance_to(observed_pos) > 0.001:
		return "Invalid observation mutated last-known knowledge"

	var last_known := Vector3(12.0, 0.0, 18.0)
	var last_direction := Vector3(1.0, 0.0, 1.0).normalized()
	var lost := bool(authority.call("lose_contact", last_known, last_direction, "observer_los_broken"))
	if not lost:
		return "Legitimate Contact loss was rejected"
	if int(authority.call("get_heat_level")) != 1:
		return "Losing Contact incorrectly cleared Heat"
	if String(authority.call("get_wanted_state_name")) != "SEARCH":
		return "Losing Contact did not enter Search"

	var hidden_live_position := Vector3(-50.0, 0.0, -50.0)
	var search_tracking: Vector3 = authority.call("get_tracking_position", hidden_live_position)
	if search_tracking.distance_to(last_known) > 0.001:
		return "Search tracked live player transform instead of stored last-known position"

	var second_hidden_position := Vector3(80.0, 0.0, -20.0)
	var search_tracking_again: Vector3 = authority.call("get_tracking_position", second_hidden_position)
	if search_tracking_again.distance_to(last_known) > 0.001:
		return "Search knowledge moved when hidden player moved"
	if bool(authority.call("observe_contact", "pursuer_direct_observation", second_hidden_position, Vector3.RIGHT)):
		return "Search accepted a Contact-only observation refresh"

	var invalid_reacquire := bool(authority.call("reacquire", "", second_hidden_position, Vector3.RIGHT))
	if invalid_reacquire:
		return "Search reacquired without a concrete source"
	if String(authority.call("get_wanted_state_name")) != "SEARCH":
		return "Invalid reacquisition changed Search state"

	var reacquired := bool(authority.call(
		"reacquire",
		"pursuer_direct_observation",
		second_hidden_position,
		Vector3.RIGHT
	))
	if not reacquired:
		return "Concrete direct-observation reacquisition was rejected"
	if String(authority.call("get_wanted_state_name")) != "CONTACT":
		return "Concrete reacquisition did not restore Contact"
	if String(authority.call("get_last_reason")) != "reacquire:pursuer_direct_observation":
		return "Reacquisition reason was not retained"

	var contact_tracking: Vector3 = authority.call("get_tracking_position", second_hidden_position)
	if contact_tracking.distance_to(second_hidden_position) > 0.001:
		return "Contact did not use current legitimately observed position"

	if not bool(authority.call("lose_contact", second_hidden_position, Vector3.RIGHT, "observer_los_broken")):
		return "Second Contact loss was rejected"
	if not bool(authority.call("advance_search", 99.0)):
		return "Search timeout did not produce Evasion"
	if int(authority.call("get_heat_level")) != 0:
		return "Evasion did not clear Heat"
	if String(authority.call("get_wanted_state_name")) != "CLEAR":
		return "Evasion did not restore CLEAR free roam"
	if String(authority.call("get_last_reason")) != "evasion:search_timeout":
		return "Evasion reason was not retained"

	authority.call("submit_report", "gears_civic_alarm", incident_pos, incident_dir, "civic_alarm_direct_observation")
	authority.call("reset")
	if int(authority.call("get_heat_level")) != 0 or String(authority.call("get_wanted_state_name")) != "CLEAR":
		return "Reset left stale Heat/Contact/Search state"

	print("[WANTED_HEAT1_CONTRACT] PASS")
	return ""
