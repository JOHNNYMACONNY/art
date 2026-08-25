extends SceneTree

const TouchControlsScript = preload("res://scripts/input/touch_controls.gd")
const PursuerScript = preload("res://scripts/entities/pursuer_prototype.gd")
const RECORD_PATH := "res://verification/feel/wave1_retention_summary.json"
const EXPECTED_BEHAVIOR_SHA := "a10ac0ce235fa56ca8084cae05ad0959751a821b"

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[CTW_FEEL_07] %s" % message)
	quit(1)

func _run() -> void:
	if not FileAccess.file_exists(RECORD_PATH):
		_fail("Wave 1 retention record is absent")
		return
	var raw := FileAccess.get_file_as_string(RECORD_PATH)
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		_fail("Wave 1 retention record is not valid JSON object data")
		return
	var record: Dictionary = parsed
	if int(record.get("schema_version", 0)) != 1 or int(record.get("ticket", 0)) != 17:
		_fail("Wave 1 retention record schema/ticket mismatch")
		return
	if String(record.get("integrated_behavior_sha", "")) != EXPECTED_BEHAVIOR_SHA:
		_fail("Integrated behavior SHA is not pinned to the verified pre-ticket gameplay main")
		return

	var dispositions = record.get("candidate_dispositions", {})
	if not (dispositions is Dictionary):
		_fail("Candidate disposition table is absent")
		return
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
			_fail("Ticket #%s disposition is not %s" % [ticket, expected[ticket]])
			return

	var touch := TouchControlsScript.new()
	if bool(touch.vehicle_steer_conditioning_enabled):
		touch.free()
		_fail("Touch candidate is enabled despite PENDING disposition")
		return
	touch.free()

	var pursuer := PursuerScript.new()
	if not bool(pursuer.bounded_intercept_enabled):
		pursuer.free()
		_fail("Retained bounded interception is not the production default")
		return
	pursuer.free()

	var gates = record.get("perceptual_gates", {})
	if not (gates is Dictionary):
		_fail("Perceptual gate classification is absent")
		return
	if String(gates.get("fresh_player", "")) != "PENDING":
		_fail("Fresh-player gate must remain PENDING")
		return
	if String(gates.get("touch_candidate", "")) != "NOT_REQUIRED_FOR_DEFAULT__CANDIDATE_PENDING":
		_fail("Touch-device gate classification does not match retained linear default")
		return
	if String(record.get("completion_state", "")) != "FUNCTIONAL_WAVE_VERIFIED__PERCEPTUAL_GATE_PENDING":
		_fail("Wave 1 completion state is inflated or missing")
		return

	print("[CTW_FEEL_07] RETENTION_RECORD PASS")
	quit(0)
