extends RefCounted

const TouchControlsScript = preload("res://scripts/input/touch_controls.gd")

static func _approx(a: float, b: float, epsilon: float = 0.0001) -> bool:
	return absf(a - b) <= epsilon

static func verify() -> String:
	var controls := TouchControlsScript.new()
	if controls == null:
		return "Could not construct TouchControlsUI steering fixture"
	if not controls.has_method("get_conditioned_vehicle_steer"):
		controls.free()
		return "Touch steering conditioning seam is absent"

	# A = retained baseline. Default must remain exactly linear until real-device
	# qualification exists; desktop keyboard steering is outside this pure seam.
	if bool(controls.get("vehicle_steer_conditioning_enabled")):
		controls.free()
		return "Touch steering candidate became default before physical-device qualification"
	for raw_x in [-1.0, -0.6, -0.2, 0.0, 0.2, 0.6, 1.0]:
		var baseline: float = controls.call("get_conditioned_vehicle_steer", Vector2(raw_x, 0.0))
		if not _approx(baseline, raw_x):
			controls.free()
			return "Linear A baseline changed at raw steer %.2f" % raw_x

	# B = static candidate only: radial deadzone + monotonic symmetric
	# center-softening. No temporal history or speed input participates.
	controls.set("vehicle_steer_conditioning_enabled", true)
	var deadzone := float(controls.get("vehicle_steer_deadzone"))
	var response_power := float(controls.get("vehicle_steer_response_power"))
	if deadzone < 0.05 or deadzone > 0.08:
		controls.free()
		return "Candidate deadzone escaped the 0.05–0.08 search envelope"
	if response_power < 1.4 or response_power > 1.7:
		controls.free()
		return "Candidate response power escaped the 1.4–1.7 search envelope"

	var inside_deadzone: float = controls.call("get_conditioned_vehicle_steer", Vector2(deadzone * 0.5, deadzone * 0.25))
	if not _approx(inside_deadzone, 0.0):
		controls.free()
		return "Radial deadzone did not collapse tiny touch motion to zero"

	var previous := -0.001
	for raw_x in [0.10, 0.20, 0.35, 0.55, 0.75, 1.0]:
		var conditioned: float = controls.call("get_conditioned_vehicle_steer", Vector2(raw_x, 0.0))
		if conditioned <= previous:
			controls.free()
			return "Candidate steering response is not strictly monotonic"
		if raw_x < 0.75 and conditioned >= raw_x:
			controls.free()
			return "Candidate failed to soften center steering at %.2f" % raw_x
		previous = conditioned

	for raw_x in [0.12, 0.30, 0.65, 1.0]:
		var positive: float = controls.call("get_conditioned_vehicle_steer", Vector2(raw_x, 0.0))
		var negative: float = controls.call("get_conditioned_vehicle_steer", Vector2(-raw_x, 0.0))
		if not _approx(positive, -negative):
			controls.free()
			return "Candidate steering response lost left/right symmetry at %.2f" % raw_x

	# E2 canonical 90-degree turn input is full lock. Candidate must preserve
	# exact full-lock authority so downstream turn-envelope physics are unchanged.
	var e2_baseline_full_lock := 1.0
	var e2_candidate_full_lock: float = controls.call("get_conditioned_vehicle_steer", Vector2(1.0, 0.0))
	var full_left: float = controls.call("get_conditioned_vehicle_steer", Vector2(-1.0, 0.0))
	if not _approx(e2_candidate_full_lock, e2_baseline_full_lock) or not _approx(full_left, -1.0):
		controls.free()
		return "Candidate no longer reaches full normalized steering lock"

	# E3 canonical reversal is -1 -> +1 with no temporal smoothing. Preserve the
	# exact 2.0 normalized reversal span and deterministic same-frame response.
	var e3_baseline_span := 2.0
	var e3_candidate_span := e2_candidate_full_lock - full_left
	if not _approx(e3_candidate_span, e3_baseline_span):
		controls.free()
		return "Candidate changed canonical full-lock reversal span"

	# E7 canonical route uses +/-0.35 correction windows. Capture the exact
	# candidate intent attenuation so the physical-device gate can evaluate the
	# real thumb benefit later without pretending this is already retained.
	var e7_baseline_correction := 0.35
	var e7_candidate_correction: float = controls.call("get_conditioned_vehicle_steer", Vector2(e7_baseline_correction, 0.0))
	var e7_candidate_negative: float = controls.call("get_conditioned_vehicle_steer", Vector2(-e7_baseline_correction, 0.0))
	if e7_candidate_correction <= 0.0 or e7_candidate_correction >= e7_baseline_correction:
		controls.free()
		return "Candidate did not soften canonical E7 correction intent"
	if not _approx(e7_candidate_correction, -e7_candidate_negative):
		controls.free()
		return "Candidate E7 correction lost left/right symmetry"

	var diagonal: float = controls.call("get_conditioned_vehicle_steer", Vector2(0.30, 0.40))
	if diagonal <= 0.0 or diagonal >= 0.30:
		controls.free()
		return "Radial conditioning did not preserve a bounded diagonal steering contribution"

	# Repeated evaluation must be stateless: same touch vector, same result.
	var sample := Vector2(0.42, -0.18)
	var first: float = controls.call("get_conditioned_vehicle_steer", sample)
	for _i in range(8):
		if not _approx(float(controls.call("get_conditioned_vehicle_steer", sample)), first):
			controls.free()
			return "Candidate introduced temporal/history-dependent steering output"

	print("[CTW_FEEL_02] A/B deadzone=%.3f response_power=%.3f E2_full_lock_A=%.3f E2_full_lock_B=%.3f E3_span_A=%.3f E3_span_B=%.3f E7_correction_A=%.3f E7_correction_B=%.3f E7_ratio=%.3f sample_raw=0.420 sample_conditioned=%.3f" % [
		deadzone,
		response_power,
		e2_baseline_full_lock,
		e2_candidate_full_lock,
		e3_baseline_span,
		e3_candidate_span,
		e7_baseline_correction,
		e7_candidate_correction,
		e7_candidate_correction / e7_baseline_correction,
		first,
	])
	controls.free()
	return ""
