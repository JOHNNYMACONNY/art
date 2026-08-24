extends RefCounted

const PursuerScript = preload("res://scripts/entities/pursuer_prototype.gd")

static func _heading_error(from_pos: Vector3, destination: Vector3, reference: Vector3) -> float:
	var a := destination - from_pos
	var b := reference - from_pos
	a.y = 0.0
	b.y = 0.0
	if a.length() <= 0.001 or b.length() <= 0.001:
		return 0.0
	return absf(a.normalized().angle_to(b.normalized()))

static func _finish(fixture: Node, message: String) -> String:
	if is_instance_valid(fixture):
		fixture.free()
	return message

static func verify(tree_root: Node) -> String:
	if tree_root == null:
		return "Pursuer intercept contract requires a SceneTree root"

	# Keep this A/B contract independent from the live prototype scene. Retained
	# V4/V5/M15 suites own pursuit/gate/retry lifecycle coverage. The synthetic
	# nodes are attached only so production global_position semantics are valid.
	var fixture := Node3D.new()
	fixture.name = "PursuerInterceptContractFixture"
	tree_root.add_child(fixture)
	var pursuer := PursuerScript.new()
	var target := CharacterBody3D.new()
	fixture.add_child(pursuer)
	fixture.add_child(target)

	if not pursuer.has_method("get_bounded_chase_destination"):
		return _finish(fixture, "Pursuer bounded chase destination seam is absent")
	if not pursuer.has_method("get_navigation_destination"):
		return _finish(fixture, "Pursuer navigation destination seam is absent")

	var baseline_max_speed := float(pursuer.max_speed)
	var baseline_acceleration := float(pursuer.acceleration)
	pursuer.global_position = Vector3.ZERO
	target.global_position = Vector3(0.0, 0.0, 18.0)
	target.velocity = Vector3(9.0, 0.0, 0.0)
	pursuer.target_node = target
	pursuer.current_state = PursuerScript.PursuerState.CHASING
	pursuer.detour_waypoints.clear()
	pursuer.current_detour_index = -1

	# A = direct world target, B = bounded observable-velocity interception.
	# Same production pursuer object, target pose and motion; only the experiment
	# flag changes the selected navigation destination.
	pursuer.bounded_intercept_enabled = false
	var direct: Vector3 = pursuer.call("get_navigation_destination")
	if direct.distance_to(target.global_position) > 0.001:
		return _finish(fixture, "A baseline did not resolve to current target position")

	pursuer.bounded_intercept_enabled = true
	var candidate: Vector3 = pursuer.call("get_navigation_destination")
	var helper_candidate: Vector3 = pursuer.call("get_bounded_chase_destination", direct, target.velocity)
	if candidate.distance_to(helper_candidate) > 0.001:
		return _finish(fixture, "B navigation destination diverged from bounded helper")

	var lead := candidate - direct
	lead.y = 0.0
	if lead.length() <= 0.5:
		return _finish(fixture, "Qualified moving target produced no meaningful bounded lead")
	if lead.length() > 4.001:
		return _finish(fixture, "Bounded lead exceeded the 4 m experiment cap")
	if lead.normalized().dot(Vector3.RIGHT) < 0.99:
		return _finish(fixture, "Bounded lead did not follow current observable target velocity")

	var observable_future := direct + target.velocity * 0.35
	var direct_error := _heading_error(pursuer.global_position, direct, observable_future)
	var candidate_error := _heading_error(pursuer.global_position, candidate, observable_future)
	var improvement := direct_error - candidate_error
	if improvement < deg_to_rad(3.0):
		return _finish(fixture, "Bounded lead did not create measurable cut-off heading improvement")
	print("[CTW_FEEL_06] A/B lead_m=%.3f direct_error_deg=%.3f bounded_error_deg=%.3f improvement_deg=%.3f" % [
		lead.length(),
		rad_to_deg(direct_error),
		rad_to_deg(candidate_error),
		rad_to_deg(improvement),
	])

	var low_speed: Vector3 = pursuer.call("get_bounded_chase_destination", direct, Vector3(0.25, 0.0, 0.0))
	if low_speed.distance_to(direct) > 0.05:
		return _finish(fixture, "Prediction did not collapse at very low target speed")

	target.global_position = Vector3(0.0, 0.0, 2.0)
	var close_direct := target.global_position
	var close_candidate: Vector3 = pursuer.call("get_bounded_chase_destination", close_direct, Vector3(9.0, 0.0, 0.0))
	if close_candidate.distance_to(close_direct) > 0.05:
		return _finish(fixture, "Prediction did not collapse at close range")

	target.global_position = Vector3(0.0, 0.0, 18.0)
	var right_candidate: Vector3 = pursuer.call("get_bounded_chase_destination", target.global_position, Vector3(9.0, 0.0, 0.0))
	var left_candidate: Vector3 = pursuer.call("get_bounded_chase_destination", target.global_position, Vector3(-9.0, 0.0, 0.0))
	if right_candidate.x <= target.global_position.x or left_candidate.x >= target.global_position.x:
		return _finish(fixture, "Sharp target reversal preserved stale lead direction")

	var waypoint := Vector3(6.0, 0.0, 12.0)
	var detour_fixture: Array[Vector3] = [waypoint]
	pursuer.detour_waypoints = detour_fixture
	pursuer.current_detour_index = 0
	pursuer.current_state = PursuerScript.PursuerState.DETOURING
	var detour_destination: Vector3 = pursuer.call("get_navigation_destination")
	if detour_destination.distance_to(waypoint) > 0.001:
		return _finish(fixture, "DETOURING waypoint stopped being authoritative over prediction")

	if not is_equal_approx(float(pursuer.max_speed), baseline_max_speed):
		return _finish(fixture, "Feel 06 changed pursuer top speed during destination A/B")
	if not is_equal_approx(float(pursuer.acceleration), baseline_acceleration):
		return _finish(fixture, "Feel 06 changed pursuer acceleration during destination A/B")

	return _finish(fixture, "")
