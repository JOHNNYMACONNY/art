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

static func verify(pursuer: Node, target: Node3D) -> String:
	if pursuer == null or target == null:
		return "Pursuer intercept contract requires live pursuer and target nodes"
	if not pursuer.has_method("get_bounded_chase_destination"):
		return "Pursuer bounded chase destination seam is absent"
	if not pursuer.has_method("get_navigation_destination"):
		return "Pursuer navigation destination seam is absent"

	var baseline_max_speed := float(pursuer.max_speed)
	var baseline_acceleration := float(pursuer.acceleration)
	var original_pursuer_pos := pursuer.global_position
	var original_target_pos := target.global_position
	var original_target_velocity = target.get("velocity")
	var original_state := int(pursuer.current_state)
	var original_target_node = pursuer.target_node
	var original_detours: Array[Vector3] = pursuer.detour_waypoints.duplicate()
	var original_detour_index := int(pursuer.current_detour_index)

	pursuer.global_position = Vector3.ZERO
	target.global_position = Vector3(0.0, 0.0, 18.0)
	target.set("velocity", Vector3(9.0, 0.0, 0.0))
	pursuer.target_node = target
	pursuer.current_state = PursuerScript.PursuerState.CHASING
	pursuer.detour_waypoints.clear()
	pursuer.current_detour_index = -1

	var direct := target.global_position
	var candidate: Vector3 = pursuer.call("get_bounded_chase_destination", direct, target.get("velocity"))
	var lead := candidate - direct
	lead.y = 0.0
	if lead.length() <= 0.5:
		return "Qualified moving target produced no meaningful bounded lead"
	if lead.length() > 4.001:
		return "Bounded lead exceeded the 4 m experiment cap"
	if lead.normalized().dot(Vector3.RIGHT) < 0.99:
		return "Bounded lead did not follow observable current target velocity"

	# Compare against the target's short observable continuation. The candidate
	# should reduce the heading error versus tail-following without teleporting.
	var observable_future := direct + Vector3(9.0, 0.0, 0.0) * 0.35
	var direct_error := _heading_error(pursuer.global_position, direct, observable_future)
	var candidate_error := _heading_error(pursuer.global_position, candidate, observable_future)
	if candidate_error >= direct_error - deg_to_rad(3.0):
		return "Bounded lead did not create a measurable cut-off heading improvement"

	# Low target speed collapses to the direct baseline.
	var low_speed: Vector3 = pursuer.call("get_bounded_chase_destination", direct, Vector3(0.25, 0.0, 0.0))
	if low_speed.distance_to(direct) > 0.05:
		return "Prediction did not collapse at very low target speed"

	# Close range collapses toward zero even for a fast target.
	target.global_position = Vector3(0.0, 0.0, 2.0)
	var close_direct := target.global_position
	var close_candidate: Vector3 = pursuer.call("get_bounded_chase_destination", close_direct, Vector3(9.0, 0.0, 0.0))
	if close_candidate.distance_to(close_direct) > 0.05:
		return "Prediction did not collapse at close range"

	# Reversal must respond only to the current observable velocity—no stale lead.
	target.global_position = Vector3(0.0, 0.0, 18.0)
	var right_candidate: Vector3 = pursuer.call("get_bounded_chase_destination", target.global_position, Vector3(9.0, 0.0, 0.0))
	var left_candidate: Vector3 = pursuer.call("get_bounded_chase_destination", target.global_position, Vector3(-9.0, 0.0, 0.0))
	if right_candidate.x <= target.global_position.x or left_candidate.x >= target.global_position.x:
		return "Sharp target reversal preserved stale lead direction"

	# Authored Signal Gate detours remain authoritative over prediction.
	var waypoint := Vector3(6.0, 0.0, 12.0)
	pursuer.detour_waypoints = [waypoint]
	pursuer.current_detour_index = 0
	pursuer.current_state = PursuerScript.PursuerState.DETOURING
	var detour_destination: Vector3 = pursuer.call("get_navigation_destination")
	if detour_destination.distance_to(waypoint) > 0.001:
		return "DETOURING waypoint stopped being authoritative over prediction"

	if not is_equal_approx(float(pursuer.max_speed), baseline_max_speed):
		return "Feel 06 changed pursuer top speed during destination A/B"
	if not is_equal_approx(float(pursuer.acceleration), baseline_acceleration):
		return "Feel 06 changed pursuer acceleration during destination A/B"

	# Restore the live fixture so the existing vehicle-authority integration test
	# continues from its canonical setup.
	pursuer.global_position = original_pursuer_pos
	target.global_position = original_target_pos
	target.set("velocity", original_target_velocity)
	pursuer.current_state = original_state
	pursuer.target_node = original_target_node
	pursuer.detour_waypoints = original_detours
	pursuer.current_detour_index = original_detour_index
	return ""
