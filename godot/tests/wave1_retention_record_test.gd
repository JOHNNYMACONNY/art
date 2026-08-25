extends RefCounted

const TouchControlsScript = preload("res://scripts/input/touch_controls.gd")
const PursuerScript = preload("res://scripts/entities/pursuer_prototype.gd")
const RECORD_PATH := "res://verification/feel/wave1_retention_summary.json"
const EXPECTED_BEHAVIOR_SHA := "a10ac0ce235fa56ca8084cae05ad0959751a821b"

static func verify() -> String:
	if not FileAccess.file_exists(RECORD_PATH):
		return "Wave 1 retention record is absent"
	var raw := FileAccess.get_file_as_string(RECORD_PATH)
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return "Wave 1 retention record is not valid JSON object data"
	var record: Dictionary = parsed
	if int(record.get("schema_version", 0)) != 1 or int(record.get("ticket", 0)) != 17:
		return "Wave 1 retention record schema/ticket mismatch"
	if String(record.get("integrated_behavior_sha", "")) != EXPECTED_BEHAVIOR_SHA:
		return "Integrated behavior SHA is not pinned to the pre-ticket gameplay main"

	var dispositions = record.get("candidate_dispositions", {})
	if not (dispositions is Dictionary):
		return "Candidate disposition table is absent"
	var expected := {
		"12": "PENDING",
		"13": "REVERTED",
		"14": "RETAINED",
		"15": "RETAINED",
		"16": "RETAINED",
	}
	for ticket in expected:
		var entry = dispositions.get(ticket, {})
		if not (entry is Dictionary) or String(entry.get("disposition", "")) != expected[ticket]:
			return "Ticket #%s disposition is not %s" % [ticket, expected[ticket]]

	var touch := TouchControlsScript.new()
	if bool(touch.vehicle_steer_conditioning_enabled):
		touch.free()
		return "Touch candidate is enabled despite PENDING disposition"
	touch.free()

	var pursuer := PursuerScript.new()
	if not bool(pursuer.bounded_intercept_enabled):
		pursuer.free()
		return "Retained bounded interception is not the production default"
	pursuer.free()

	var gates = record.get("perceptual_gates", {})
	if not (gates is Dictionary):
		return "Perceptual gate classification is absent"
	if String(gates.get("fresh_player", "")) != "PENDING":
		return "Fresh-player gate must remain PENDING"
	if String(gates.get("touch_candidate", "")) != "NOT_REQUIRED_FOR_DEFAULT__CANDIDATE_PENDING":
		return "Touch-device gate classification does not match retained linear default"
	if String(record.get("completion_state", "")) != "FUNCTIONAL_WAVE_VERIFIED__PERCEPTUAL_GATE_PENDING":
		return "Wave 1 completion state is inflated or missing"
	return ""
