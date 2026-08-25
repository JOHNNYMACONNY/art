extends SceneTree

# CTW Feel 07 — integrated retention gate.
# Verification-only wrapper around the immutable Ticket #11 E1-E7 harness.
# It runs the exact existing scenario implementation on the current checkout,
# restores immutable baseline artifacts, and compares retained behavior.

const FIXED_DT: float = 1.0 / 60.0
const OUTPUT_DIR := "res://verification/feel"
const BASELINE_SUMMARY_PATH := "res://verification/feel/baseline_summary.json"
const BASELINE_LOG_PATH := "res://verification/feel/baseline_verification.log"
const INTEGRATED_SUMMARY_PATH := "res://verification/feel/integrated_summary.json"
const INTEGRATED_LOG_PATH := "res://verification/feel/integrated_verification.log"
const BASELINE_HARNESS_PATH := "res://scripts/verification/ctw_feel_harness.gd"
const INTEGRATED_BEHAVIOR_SHA := "a10ac0ce235fa56ca8084cae05ad0959751a821b"
const IMMUTABLE_BASELINE_BEHAVIOR_SHA := "09fa2b0ab8aebc8a2ae54b989bffad7720503e48"

var _baseline_summary_text: String = ""
var _baseline_log_text: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not OS.get_cmdline_user_args().has("--run-ctw-feel-integrated"):
		_fail("Missing --run-ctw-feel-integrated user argument.", 2)
		return
	if not FileAccess.file_exists(BASELINE_SUMMARY_PATH):
		_fail("Immutable Ticket #11 baseline summary is absent.")
		return

	_baseline_summary_text = FileAccess.get_file_as_string(BASELINE_SUMMARY_PATH)
	if FileAccess.file_exists(BASELINE_LOG_PATH):
		_baseline_log_text = FileAccess.get_file_as_string(BASELINE_LOG_PATH)
	var baseline_value = JSON.parse_string(_baseline_summary_text)
	if not (baseline_value is Dictionary):
		_fail("Immutable Ticket #11 baseline summary is invalid JSON.")
		return
	var baseline: Dictionary = baseline_value
	if String(baseline.get("metadata", {}).get("baseline_behavior_sha", "")) != IMMUTABLE_BASELINE_BEHAVIOR_SHA:
		_fail("Immutable baseline behavior SHA changed unexpectedly.")
		return

	var child_output: Array = []
	var project_path: String = ProjectSettings.globalize_path("res://")
	var verification_commit: String = _resolve_verification_commit()
	var args := PackedStringArray([
		"--headless",
		"--rendering-method", "gl_compatibility",
		"--path", project_path,
		"--script", BASELINE_HARNESS_PATH,
		"--",
		"--run-ctw-feel-baseline",
		"--feel-build-commit=%s" % verification_commit,
	])
	var exit_code: int = OS.execute(OS.get_executable_path(), args, child_output, true)
	var child_text: String = "\n".join(child_output)
	if exit_code != 0:
		_restore_immutable_baseline()
		_fail("Current-build E1-E7 harness exited %d; output=%s" % [exit_code, child_text.right(3000)])
		return
	if not child_text.contains("[CTW_FEEL] PASS"):
		_restore_immutable_baseline()
		_fail("Current-build E1-E7 harness exited 0 without baseline PASS marker.")
		return

	var current_text: String = FileAccess.get_file_as_string(BASELINE_SUMMARY_PATH)
	var current_value = JSON.parse_string(current_text)
	if not (current_value is Dictionary):
		_restore_immutable_baseline()
		_fail("Current-build E1-E7 summary is invalid JSON.")
		return
	var current: Dictionary = current_value

	var trace_error: String = _preserve_integrated_traces(current)
	_restore_immutable_baseline()
	if not trace_error.is_empty():
		_fail(trace_error)
		return

	var comparison: Dictionary = _compare_to_immutable_baseline(baseline, current)
	var summary: Dictionary = {
		"schema_version": 4,
		"ticket": 17,
		"mode": "CTW_FEEL_INTEGRATED",
		"metadata": {
			"integrated_behavior_sha": INTEGRATED_BEHAVIOR_SHA,
			"verification_commit": verification_commit,
			"immutable_baseline_behavior_sha": IMMUTABLE_BASELINE_BEHAVIOR_SHA,
			"godot_version": Engine.get_version_info(),
			"source_harness": BASELINE_HARNESS_PATH,
			"gameplay_mutation_by_ticket_17": false,
		},
		"scenarios": current.get("scenarios", {}),
		"repeatability": current.get("repeatability", {}),
		"baseline_comparison": comparison,
	}
	if not _write_json(INTEGRATED_SUMMARY_PATH, summary):
		_fail("Could not write integrated_summary.json")
		return
	if not _write_integrated_log(summary):
		_fail("Could not write integrated_verification.log")
		return

	print("[CTW_FEEL] Integrated behavior SHA: %s" % INTEGRATED_BEHAVIOR_SHA)
	print("[CTW_FEEL] Verification commit: %s" % verification_commit)
	print("[CTW_FEEL] Baseline comparison: %s" % JSON.stringify(comparison))
	if not bool(comparison.get("passed", false)):
		for failure in comparison.get("failures", []):
			print("[CTW_FEEL] INTEGRATED FAILURE: %s" % String(failure))
		push_error("[CTW_FEEL] Integrated Wave 1 hard regression detected.")
		quit(1)
		return

	print("[CTW_FEEL] INTEGRATED PASS — retained E1-E7 behavior is baseline-safe; intended pursuer-distance deltas are classified.")
	quit(0)

func _compare_to_immutable_baseline(baseline: Dictionary, current: Dictionary) -> Dictionary:
	var failures: Array[String] = []
	var baseline_metadata: Dictionary = baseline.get("metadata", {})
	var current_metadata: Dictionary = current.get("metadata", {})
	for key in [
		"courier_bike_max_speed",
		"courier_bike_acceleration",
		"courier_bike_braking_friction",
		"camera_default_fov",
		"camera_max_speed_fov",
		"camera_follow_speed",
	]:
		var baseline_value: float = float(baseline_metadata.get(key, NAN))
		var current_value: float = float(current_metadata.get(key, NAN))
		if is_nan(baseline_value) or is_nan(current_value) or not is_equal_approx(baseline_value, current_value):
			failures.append("metadata.%s changed: baseline=%s current=%s" % [key, str(baseline_value), str(current_value)])

	if not bool(current.get("repeatability", {}).get("passed", false)):
		failures.append("Current integrated E1-E7 repeatability failed")

	var baseline_scenarios: Dictionary = baseline.get("scenarios", {})
	var current_scenarios: Dictionary = current.get("scenarios", {})
	for scenario in [
		"E1_launch_coast_brake",
		"E2_constant_90_turn",
		"E3_steering_reversal",
		"E4_handbrake_recovery",
		"E5_collision_pair",
		"E6_forward_reverse",
	]:
		if not baseline_scenarios.has(scenario) or not current_scenarios.has(scenario):
			failures.append("Scenario %s missing from baseline or integrated result" % scenario)
			continue
		_compare_variant("scenarios.%s" % scenario, baseline_scenarios[scenario], current_scenarios[scenario], failures, [])

	var e7_ignored: Array[String] = [
		"scenarios.E7_pursuit_route.min_pursuer_distance_m",
		"scenarios.E7_pursuit_route.max_pursuer_distance_m",
		"scenarios.E7_pursuit_route.final_pursuer_distance_m",
		"scenarios.E7_pursuit_route.pursuer_endpoint_position",
	]
	if baseline_scenarios.has("E7_pursuit_route") and current_scenarios.has("E7_pursuit_route"):
		_compare_variant(
			"scenarios.E7_pursuit_route",
			baseline_scenarios["E7_pursuit_route"],
			current_scenarios["E7_pursuit_route"],
			failures,
			e7_ignored
		)
		var current_e7: Dictionary = current_scenarios["E7_pursuit_route"]
		if not bool(current_e7.get("detour_state_observed", false)):
			failures.append("E7 lost authored Signal Gate detour authority")
		if String(current_e7.get("outcome", "")) == "INTERCEPTED":
			failures.append("E7 integrated route regressed to interception")
	else:
		failures.append("E7 pursuit route missing from baseline or integrated result")

	var observed_deltas: Dictionary = {}
	if baseline_scenarios.has("E7_pursuit_route") and current_scenarios.has("E7_pursuit_route"):
		var baseline_e7: Dictionary = baseline_scenarios["E7_pursuit_route"]
		var current_e7_metrics: Dictionary = current_scenarios["E7_pursuit_route"]
		for metric in ["min_pursuer_distance_m", "max_pursuer_distance_m", "final_pursuer_distance_m"]:
			observed_deltas[metric] = {
				"baseline": baseline_e7.get(metric),
				"integrated": current_e7_metrics.get(metric),
				"delta": float(current_e7_metrics.get(metric, 0.0)) - float(baseline_e7.get(metric, 0.0)),
			}

	return {
		"passed": failures.is_empty(),
		"failures": failures,
		"tolerance_rule": "E1-E6 and non-pursuer E7 metrics use Ticket #11 repeatability tolerance: <=1 fixed frame or <=1%; positions <=0.05 m; yaw <=0.5 deg.",
		"allowed_intentional_deltas": e7_ignored,
		"observed_pursuer_deltas": observed_deltas,
	}

func _compare_variant(path: String, baseline_value, current_value, failures: Array[String], ignored_paths: Array[String]) -> void:
	if ignored_paths.has(path):
		return
	if typeof(baseline_value) != typeof(current_value):
		failures.append("%s type mismatch: baseline=%s current=%s" % [path, typeof(baseline_value), typeof(current_value)])
		return
	if baseline_value is Dictionary:
		var baseline_dict: Dictionary = baseline_value
		var current_dict: Dictionary = current_value
		for key in baseline_dict.keys():
			if not current_dict.has(key):
				failures.append("%s.%s missing from integrated result" % [path, key])
				continue
			_compare_variant("%s.%s" % [path, key], baseline_dict[key], current_dict[key], failures, ignored_paths)
		return
	if baseline_value is Array:
		var baseline_array: Array = baseline_value
		var current_array: Array = current_value
		if baseline_array.size() != current_array.size():
			failures.append("%s array size mismatch: baseline=%d current=%d" % [path, baseline_array.size(), current_array.size()])
			return
		for index in range(baseline_array.size()):
			_compare_variant("%s[%d]" % [path, index], baseline_array[index], current_array[index], failures, ignored_paths)
		return
	if baseline_value is float or baseline_value is int:
		var baseline_number: float = float(baseline_value)
		var current_number: float = float(current_value)
		var lower_path: String = path.to_lower()
		var tolerance: float = maxf(FIXED_DT, absf(baseline_number) * 0.01)
		if lower_path.contains("position"):
			tolerance = 0.05
		elif lower_path.contains("yaw"):
			tolerance = 0.5
		if absf(baseline_number - current_number) > tolerance:
			failures.append("%s drift %.9f exceeds %.9f (baseline=%.9f current=%.9f)" % [path, absf(baseline_number - current_number), tolerance, baseline_number, current_number])
		return
	if baseline_value != current_value:
		failures.append("%s mismatch: baseline=%s current=%s" % [path, str(baseline_value), str(current_value)])

func _preserve_integrated_traces(current: Dictionary) -> String:
	var scenarios: Dictionary = current.get("scenarios", {})
	for scenario in scenarios.keys():
		var source_path: String = "%s/baseline_%s_trace.json" % [OUTPUT_DIR, scenario]
		var destination_path: String = "%s/integrated_%s_trace.json" % [OUTPUT_DIR, scenario]
		if not FileAccess.file_exists(source_path):
			return "Current-build trace missing for %s" % scenario
		var text: String = FileAccess.get_file_as_string(source_path)
		if not _write_text(destination_path, text):
			return "Could not preserve integrated trace for %s" % scenario
		var absolute_source: String = ProjectSettings.globalize_path(source_path)
		DirAccess.remove_absolute(absolute_source)
	return ""

func _restore_immutable_baseline() -> void:
	if not _baseline_summary_text.is_empty():
		_write_text(BASELINE_SUMMARY_PATH, _baseline_summary_text)
	if not _baseline_log_text.is_empty():
		_write_text(BASELINE_LOG_PATH, _baseline_log_text)

func _resolve_verification_commit() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--feel-build-commit="):
			var value: String = arg.trim_prefix("--feel-build-commit=").strip_edges()
			if not value.is_empty():
				return value
	var github_sha: String = OS.get_environment("GITHUB_SHA").strip_edges()
	if not github_sha.is_empty():
		return github_sha
	return "LOCAL_UNPINNED"

func _write_json(path: String, data) -> bool:
	return _write_text(path, JSON.stringify(data, "\t") + "\n")

func _write_text(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true

func _write_integrated_log(summary: Dictionary) -> bool:
	var comparison: Dictionary = summary.get("baseline_comparison", {})
	var lines: Array[String] = [
		"CTW FEEL INTEGRATED RETENTION — Ticket #17",
		"integrated_behavior_sha=%s" % INTEGRATED_BEHAVIOR_SHA,
		"verification_commit=%s" % String(summary.get("metadata", {}).get("verification_commit", "")),
		"immutable_baseline_behavior_sha=%s" % IMMUTABLE_BASELINE_BEHAVIOR_SHA,
		"repeatability_passed=%s" % str(summary.get("repeatability", {}).get("passed", false)),
		"baseline_comparison_passed=%s" % str(comparison.get("passed", false)),
		"allowed_intentional_deltas=%s" % JSON.stringify(comparison.get("allowed_intentional_deltas", [])),
		"observed_pursuer_deltas=%s" % JSON.stringify(comparison.get("observed_pursuer_deltas", {})),
	]
	return _write_text(INTEGRATED_LOG_PATH, "\n".join(lines) + "\n")

func _fail(message: String, exit_code: int = 1) -> void:
	_restore_immutable_baseline()
	push_error("[CTW_FEEL] %s" % message)
	quit(exit_code)
