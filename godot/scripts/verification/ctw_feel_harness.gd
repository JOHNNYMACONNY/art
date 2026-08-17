extends SceneTree

# CTW Feel Translation Wave 1 — Ticket #11
# Standalone deterministic verification entrypoint.
#
# Run from the repository root with Godot 4.7.1:
#   godot --headless --path godot --script res://scripts/verification/ctw_feel_harness.gd -- --run-ctw-feel-baseline
#
# Optional provenance override for later candidate commits:
#   --feel-build-commit=<sha>
#
# This harness intentionally does NOT tune gameplay. It instantiates the real
# Golden Slice scene, disables autonomous processing for the measured systems,
# and drives the existing CourierBike / ChinatownCamera3D / PursuerPrototype
# implementations with a fixed 60 Hz synthetic clock.

const FIXED_DT: float = 1.0 / 60.0
const FIXED_HZ: int = 60
const BASELINE_BEHAVIOR_SHA: String = "09fa2b0ab8aebc8a2ae54b989bffad7720503e48"
const MAIN_SCENE_PATH: String = "res://scenes/prototype/scrap_test_block.tscn"
const OUTPUT_DIR: String = "res://verification/feel"
const TRACE_PREFIX: String = "baseline"
const MAX_STEPS: int = 720

var _host = null
var _bike = null
var _camera = null
var _pursuer = null
var _gate = null
var _hauler = null
var _ambient_actors: Array = []

var _scenario_id: String = ""
var _scenario_time: float = 0.0
var _scenario_step: int = 0
var _trace_enabled: bool = false
var _traces: Dictionary = {}
var _collision_events: Array = []
var _fixtures: Array[Node] = []
var _run_error: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not OS.get_cmdline_user_args().has("--run-ctw-feel-baseline"):
		push_error("[CTW_FEEL] Missing required --run-ctw-feel-baseline user argument.")
		quit(2)
		return

	print("=========================================================================\n")
	print("[CTW_FEEL] Ticket #11 deterministic Courier Bike baseline")
	print("[CTW_FEEL] Behavior source: %s" % _resolve_build_commit())
	print("[CTW_FEEL] Fixed timestep: %d Hz (%.9f s)" % [FIXED_HZ, FIXED_DT])
	print("=========================================================================\n")

	var packed: PackedScene = load(MAIN_SCENE_PATH)
	if packed == null:
		_fail("Could not load %s" % MAIN_SCENE_PATH)
		return

	_host = packed.instantiate()
	root.add_child(_host)
	await process_frame
	await physics_frame

	if not _bind_live_systems():
		return

	# Start from the same public reset path the game uses, then freeze autonomous
	# processing so every measured step is driven by the fixed synthetic clock.
	if _host.has_method("reset_slice"):
		_host.reset_slice()
	await process_frame
	await physics_frame
	_prepare_manual_mode()

	# Pass A produces the durable baseline traces. Pass B repeats the exact same
	# scenarios in-process and is used only to falsify nondeterminism.
	_trace_enabled = true
	var pass_a: Dictionary = await _run_suite("A")
	if not _run_error.is_empty():
		return

	_trace_enabled = false
	var pass_b: Dictionary = await _run_suite("B")
	if not _run_error.is_empty():
		return

	var repeatability := _compare_repeatability(pass_a, pass_b)
	var summary := {
		"schema_version": 1,
		"ticket": 11,
		"mode": "CTW_FEEL_BASELINE",
		"metadata": {
			"behavior_commit": _resolve_build_commit(),
			"baseline_behavior_sha": BASELINE_BEHAVIOR_SHA,
			"godot_version": Engine.get_version_info(),
			"fixed_hz": FIXED_HZ,
			"fixed_dt_seconds": FIXED_DT,
			"main_scene": MAIN_SCENE_PATH,
			"courier_bike_max_speed": float(_bike.max_speed),
			"courier_bike_acceleration": float(_bike.acceleration),
			"courier_bike_braking_friction": float(_bike.braking_friction),
			"camera_default_fov": float(_camera.default_fov),
			"camera_max_speed_fov": float(_camera.max_speed_fov),
			"camera_follow_speed": float(_camera.follow_speed)
		},
		"scenarios": pass_a,
		"repeatability": repeatability
	}

	if not _ensure_output_dir():
		return
	if not _write_json("%s/baseline_summary.json" % OUTPUT_DIR, summary):
		return
	if not _write_trace_artifacts():
		return
	if not _write_verification_log(summary):
		return

	print("\n[CTW_FEEL] BASELINE SUMMARY")
	for scenario in pass_a.keys():
		print("  %s: %s" % [scenario, JSON.stringify(pass_a[scenario])])
	print("[CTW_FEEL] Repeatability: %s" % ("PASS" if repeatability.passed else "FAIL"))
	if not repeatability.passed:
		for failure in repeatability.failures:
			print("  REPEATABILITY FAILURE: %s" % failure)
		push_error("[CTW_FEEL] Determinism contract failed. Baseline artifacts were written for diagnosis.")
		quit(1)
		return

	print("[CTW_FEEL] Artifacts: %s/baseline_summary.json + per-scenario traces" % OUTPUT_DIR)
	print("[CTW_FEEL] PASS — deterministic baseline captured without feel retuning.")
	quit(0)


func _bind_live_systems() -> bool:
	_bike = _host.get("courier_bike")
	_camera = _host.get("camera")
	_pursuer = _host.get("pursuer")
	_gate = _host.get("signal_gate")
	_hauler = _host.get("scrap_hauler")
	var ambient_value = _host.get("ambient_actors")
	if ambient_value is Array:
		_ambient_actors = ambient_value

	if _bike == null:
		_fail("CourierBike not found on live ScrapTestBlock")
		return false
	if _camera == null:
		_fail("ChinatownCamera3D not found on live ScrapTestBlock")
		return false
	if _pursuer == null:
		_fail("PursuerPrototype not found on live ScrapTestBlock")
		return false
	if _gate == null:
		_fail("SignalGateInteractable not found on live ScrapTestBlock")
		return false

	if not _bike.collision_contact.is_connected(_on_collision_contact):
		_bike.collision_contact.connect(_on_collision_contact)
	return true


func _prepare_manual_mode() -> void:
	# Disable autonomous systems that would otherwise introduce wall-clock delta
	# or duplicate movement alongside the harness's fixed-step calls.
	_host.set_process(false)
	_host.set_physics_process(false)
	_bike.set_process(false)
	_bike.set_physics_process(false)
	_camera.set_process(false)
	_camera.set_physics_process(false)
	_pursuer.set_process(false)
	_pursuer.set_physics_process(false)
	if _hauler != null:
		_hauler.set_process(false)
		_hauler.set_physics_process(false)
	for actor in _ambient_actors:
		if is_instance_valid(actor):
			actor.set_process(false)
			actor.set_physics_process(false)


func _run_suite(pass_name: String) -> Dictionary:
	print("[CTW_FEEL] Running deterministic pass %s..." % pass_name)
	var result := {}
	result["E1_launch_coast_brake"] = _run_e1_launch_coast_brake()
	result["E2_constant_90_turn"] = _run_e2_constant_turns()
	result["E3_steering_reversal"] = _run_e3_reversal()
	result["E4_handbrake_recovery"] = _run_e4_handbrake_recovery()
	result["E5_collision_pair"] = await _run_e5_collision_pair()
	result["E6_forward_reverse"] = _run_e6_forward_reverse()
	result["E7_pursuit_route"] = _run_e7_pursuit_route()
	return result


# -----------------------------------------------------------------------------
# E1 — launch / coast / brake
# -----------------------------------------------------------------------------
func _run_e1_launch_coast_brake() -> Dictionary:
	_begin_scenario("E1_launch_coast_brake")
	_reset_bike(Vector3(120.0, 0.05, 120.0), 0.0)

	var t_50 := -1.0
	var t_90 := -1.0
	var launch_start: Vector3 = _bike.global_position
	for _i in range(240):
		_step_bike(1.0, 0.0, false)
		var ratio: float = abs(float(_bike.current_speed)) / float(_bike.max_speed)
		if t_50 < 0.0 and ratio >= 0.5:
			t_50 = _scenario_time
		if t_90 < 0.0 and ratio >= 0.9:
			t_90 = _scenario_time
		if ratio >= 0.999:
			break
	var launch_time: float = _scenario_time
	var launch_distance: float = launch_start.distance_to(_bike.global_position)

	_reset_bike(Vector3(140.0, 0.05, 120.0), 0.0)
	_bike.current_speed = float(_bike.max_speed)
	var coast_start: Vector3 = _bike.global_position
	var coast_half := -1.0
	var coast_start_time := _scenario_time
	for _i in range(MAX_STEPS):
		_step_bike(0.0, 0.0, false)
		if coast_half < 0.0 and abs(float(_bike.current_speed)) <= float(_bike.max_speed) * 0.5:
			coast_half = _scenario_time - coast_start_time
		if abs(float(_bike.current_speed)) <= 0.05:
			break
	var coast_time: float = _scenario_time - coast_start_time
	var coast_distance: float = coast_start.distance_to(_bike.global_position)

	_reset_bike(Vector3(160.0, 0.05, 120.0), 0.0)
	_bike.current_speed = float(_bike.max_speed)
	var brake_start: Vector3 = _bike.global_position
	var brake_start_time := _scenario_time
	for _i in range(MAX_STEPS):
		_step_bike(-1.0, 0.0, false)
		if abs(float(_bike.current_speed)) <= 0.05:
			break
	var brake_time: float = _scenario_time - brake_start_time
	var brake_distance: float = brake_start.distance_to(_bike.global_position)

	return {
		"time_to_50pct_s": t_50,
		"time_to_90pct_s": t_90,
		"time_to_max_s": launch_time,
		"launch_distance_m": launch_distance,
		"coast_half_life_s": coast_half,
		"coast_stop_time_s": coast_time,
		"coast_stop_distance_m": coast_distance,
		"brake_stop_time_s": brake_time,
		"brake_stop_distance_m": brake_distance
	}


# -----------------------------------------------------------------------------
# E2 — low / medium / high speed constant-input 90 degree turn
# -----------------------------------------------------------------------------
func _run_e2_constant_turns() -> Dictionary:
	_begin_scenario("E2_constant_90_turn")
	var bands := {
		"low": float(_bike.max_speed) * 0.30,
		"medium": float(_bike.max_speed) * 0.60,
		"high": float(_bike.max_speed) * 0.90
	}
	var out := {}
	var offset_x := 180.0
	for label in bands.keys():
		var target_speed: float = bands[label]
		_reset_bike(Vector3(offset_x, 0.05, 160.0), 0.0)
		offset_x += 24.0
		_bike.current_speed = target_speed
		var start_yaw: float = float(_bike.rotation.y)
		var path_distance := 0.0
		var peak_yaw_rate := 0.0
		var start_time := _scenario_time
		var previous_pos: Vector3 = _bike.global_position
		var previous_yaw: float = start_yaw
		for _i in range(360):
			# Hold longitudinal speed constant so E2 isolates steering authority.
			_bike.set_drive_inputs(0.0, 1.0, FIXED_DT, false)
			_bike.current_speed = target_speed
			_bike._physics_process(FIXED_DT)
			_manual_camera_step()
			_advance_clock(0.0, 1.0, false)
			path_distance += previous_pos.distance_to(_bike.global_position)
			var yaw_step: float = abs(_angle_delta(previous_yaw, float(_bike.rotation.y)))
			peak_yaw_rate = maxf(peak_yaw_rate, rad_to_deg(yaw_step) / FIXED_DT)
			previous_pos = _bike.global_position
			previous_yaw = float(_bike.rotation.y)
			var total_turn: float = abs(_angle_delta(start_yaw, float(_bike.rotation.y)))
			if total_turn >= PI * 0.5:
				break
		var elapsed := _scenario_time - start_time
		out[label] = {
			"held_speed_mps": target_speed,
			"turn_90_time_s": elapsed,
			"path_length_m": path_distance,
			"radius_estimate_m": path_distance / (PI * 0.5),
			"peak_yaw_rate_deg_s": peak_yaw_rate,
			"endpoint_yaw_deg": rad_to_deg(float(_bike.rotation.y))
		}
	return out


# -----------------------------------------------------------------------------
# E3 — full-left to full-right reversal
# -----------------------------------------------------------------------------
func _run_e3_reversal() -> Dictionary:
	_begin_scenario("E3_steering_reversal")
	_reset_bike(Vector3(220.0, 0.05, 200.0), 0.0)
	var held_speed: float = float(_bike.max_speed) * 0.65
	_bike.current_speed = held_speed
	var initial_yaw: float = float(_bike.rotation.y)
	var previous_yaw := initial_yaw
	var peak_left_rate := 0.0

	for _i in range(36):
		_bike.set_drive_inputs(0.0, -1.0, FIXED_DT, false)
		_bike.current_speed = held_speed
		_bike._physics_process(FIXED_DT)
		_manual_camera_step()
		_advance_clock(0.0, -1.0, false)
		var yaw_step := _angle_delta(previous_yaw, float(_bike.rotation.y))
		peak_left_rate = maxf(peak_left_rate, abs(rad_to_deg(yaw_step) / FIXED_DT))
		previous_yaw = float(_bike.rotation.y)

	var reversal_yaw: float = float(_bike.rotation.y)
	var reversal_start_time := _scenario_time
	var opposite_response_time := -1.0
	var heading_recovery_time := -1.0
	var peak_right_rate := 0.0
	var previous_delta_sign := signf(_angle_delta(initial_yaw, reversal_yaw))

	for _i in range(180):
		var before_yaw: float = float(_bike.rotation.y)
		_bike.set_drive_inputs(0.0, 1.0, FIXED_DT, false)
		_bike.current_speed = held_speed
		_bike._physics_process(FIXED_DT)
		_manual_camera_step()
		_advance_clock(0.0, 1.0, false)
		var yaw_step := _angle_delta(before_yaw, float(_bike.rotation.y))
		var yaw_step_sign := signf(yaw_step)
		peak_right_rate = maxf(peak_right_rate, abs(rad_to_deg(yaw_step) / FIXED_DT))
		if opposite_response_time < 0.0 and previous_delta_sign != 0.0 and yaw_step_sign != 0.0 and yaw_step_sign != previous_delta_sign:
			opposite_response_time = _scenario_time - reversal_start_time
		if heading_recovery_time < 0.0 and abs(_angle_delta(initial_yaw, float(_bike.rotation.y))) <= deg_to_rad(5.0):
			heading_recovery_time = _scenario_time - reversal_start_time
			break

	return {
		"held_speed_mps": held_speed,
		"left_hold_time_s": 36.0 * FIXED_DT,
		"yaw_at_reversal_deg": rad_to_deg(reversal_yaw),
		"opposite_yaw_response_s": opposite_response_time,
		"heading_recovery_s": heading_recovery_time,
		"peak_left_yaw_rate_deg_s": peak_left_rate,
		"peak_right_yaw_rate_deg_s": peak_right_rate,
		"camera_lookahead_m": _camera_lookahead_length()
	}


# -----------------------------------------------------------------------------
# E4 — handbrake high-slip turn then release / recovery
# -----------------------------------------------------------------------------
func _run_e4_handbrake_recovery() -> Dictionary:
	_begin_scenario("E4_handbrake_recovery")
	_reset_bike(Vector3(260.0, 0.05, 220.0), 0.0)
	var held_speed: float = float(_bike.max_speed) * 0.75
	_bike.current_speed = held_speed
	var peak_slip := 0.0
	var peak_yaw_rate := 0.0
	var previous_yaw: float = float(_bike.rotation.y)

	for _i in range(42):
		_bike.set_drive_inputs(0.0, 1.0, FIXED_DT, true)
		_bike.current_speed = held_speed
		_bike._physics_process(FIXED_DT)
		_manual_camera_step()
		_advance_clock(0.0, 1.0, true)
		peak_slip = maxf(peak_slip, _lateral_slip_speed())
		var yaw_step := abs(_angle_delta(previous_yaw, float(_bike.rotation.y)))
		peak_yaw_rate = maxf(peak_yaw_rate, rad_to_deg(yaw_step) / FIXED_DT)
		previous_yaw = float(_bike.rotation.y)

	var release_time := _scenario_time
	var release_slip := _lateral_slip_speed()
	var recovery_time := -1.0
	for _i in range(180):
		_bike.set_drive_inputs(0.0, 0.0, FIXED_DT, false)
		_bike.current_speed = held_speed
		_bike._physics_process(FIXED_DT)
		_manual_camera_step()
		_advance_clock(0.0, 0.0, false)
		if _lateral_slip_speed() <= 0.25:
			recovery_time = _scenario_time - release_time
			break

	return {
		"held_speed_mps": held_speed,
		"handbrake_hold_s": 42.0 * FIXED_DT,
		"peak_lateral_slip_mps": peak_slip,
		"release_slip_mps": release_slip,
		"recovery_to_0_25_mps_s": recovery_time,
		"peak_yaw_rate_deg_s": peak_yaw_rate,
		"camera_follow_error_m": float(_camera.last_follow_error)
	}


# -----------------------------------------------------------------------------
# E5 — physical collision pair using a temporary StaticBody3D fixture
# -----------------------------------------------------------------------------
func _run_e5_collision_pair() -> Dictionary:
	_begin_scenario("E5_collision_pair")
	var head_on := await _run_collision_case("head_on", 0.0, Vector3(340.0, 0.05, 308.0))
	if not _run_error.is_empty():
		return {}
	var glance := await _run_collision_case("glance", deg_to_rad(-72.0), Vector3(315.0, 0.05, 308.0))
	return {
		"head_on": head_on,
		"glance": glance
	}


func _run_collision_case(label: String, start_yaw: float, start_pos: Vector3) -> Dictionary:
	_clear_fixtures()
	_collision_events.clear()
	_reset_bike(start_pos, start_yaw)
	_bike.current_speed = 10.0
	_spawn_wall_fixture(Vector3(340.0, 1.0, 300.0), Vector3(90.0, 2.0, 0.6), 0.0)
	# Allow the physics server one registration frame while measured actors stay disabled.
	await physics_frame
	_bike.set_physics_process(false)

	var impact_step := -1
	var impact_speed := -1.0
	var impact_ratio := -1.0
	var start_time := _scenario_time
	for i in range(360):
		_step_bike(0.0, 0.0, false)
		if not _collision_events.is_empty():
			impact_step = i
			impact_speed = float(_collision_events[0].impact_speed)
			impact_ratio = float(_collision_events[0].head_on_ratio)
			break

	if impact_step < 0:
		_fail("E5 %s fixture produced no collision within 360 fixed steps" % label)
		return {}

	for _i in range(15):
		_step_bike(0.0, 0.0, false)
	var retained_speed := abs(float(_bike.current_speed))
	var retained_ratio := retained_speed / maxf(impact_speed, 0.001)
	var elapsed_to_impact := _scenario_time - start_time - (15.0 * FIXED_DT)
	return {
		"impact_time_s": elapsed_to_impact,
		"impact_head_on_ratio": impact_ratio,
		"pre_impact_speed_mps": impact_speed,
		"speed_after_0_25s_mps": retained_speed,
		"retained_speed_ratio_0_25s": retained_ratio,
		"post_impact_yaw_deg": rad_to_deg(float(_bike.rotation.y)),
		"collision_event_count": _collision_events.size()
	}


# -----------------------------------------------------------------------------
# E6 — forward -> brake -> reverse -> forward
# -----------------------------------------------------------------------------
func _run_e6_forward_reverse() -> Dictionary:
	_begin_scenario("E6_forward_reverse")
	_reset_bike(Vector3(420.0, 0.05, 360.0), 0.0)

	for _i in range(75):
		_step_bike(1.0, 0.0, false)
	var forward_peak := float(_bike.current_speed)
	var brake_start := _scenario_time
	var reverse_entry := -1.0
	var reverse_target := -1.0
	for _i in range(240):
		_step_bike(-1.0, 0.0, false)
		if reverse_entry < 0.0 and int(_bike.current_gear) == 1:
			reverse_entry = _scenario_time - brake_start
		if float(_bike.current_speed) <= -3.0:
			reverse_target = _scenario_time - brake_start
			break

	var forward_return_start := _scenario_time
	var forward_gear_return := -1.0
	var forward_motion_return := -1.0
	for _i in range(240):
		_step_bike(1.0, 0.0, false)
		if forward_gear_return < 0.0 and int(_bike.current_gear) == 0:
			forward_gear_return = _scenario_time - forward_return_start
		if float(_bike.current_speed) >= 2.0:
			forward_motion_return = _scenario_time - forward_return_start
			break

	return {
		"forward_peak_mps": forward_peak,
		"time_to_reverse_gear_s": reverse_entry,
		"time_to_minus_3_mps_s": reverse_target,
		"time_reverse_to_forward_gear_s": forward_gear_return,
		"time_reverse_to_plus_2_mps_s": forward_motion_return,
		"final_speed_mps": float(_bike.current_speed)
	}


# -----------------------------------------------------------------------------
# E7 — deterministic pursuit route / correction pressure using real pursuer
# -----------------------------------------------------------------------------
func _run_e7_pursuit_route() -> Dictionary:
	_begin_scenario("E7_pursuit_route")
	_reset_bike(Vector3(-1.5, 0.05, 3.0), PI)
	_bike.current_speed = 0.0
	_pursuer.reset_pursuer(Vector3(0.0, 0.6, -10.0))
	_pursuer.activate_pursuit(_bike)
	_pursuer.set_physics_process(false)
	_gate.set_pursuit_active(true)

	var min_distance := INF
	var max_distance := 0.0
	var collisions_at_start := _collision_events.size()
	var route_switch_step := 96
	var detour_seen := false
	var intercepted := false
	var path_distance := 0.0
	var previous_pos: Vector3 = _bike.global_position
	var start_time := _scenario_time

	for i in range(300):
		var steer := 0.0
		if i >= 105 and i < 135:
			steer = 0.35
		elif i >= 135 and i < 165:
			steer = -0.35

		_bike.set_drive_inputs(1.0, steer, FIXED_DT, false)
		_bike._physics_process(FIXED_DT)
		_pursuer._physics_process(FIXED_DT)
		_manual_camera_step()
		_advance_clock(1.0, steer, false)

		path_distance += previous_pos.distance_to(_bike.global_position)
		previous_pos = _bike.global_position
		var dist: float = _bike.global_position.distance_to(_pursuer.global_position)
		min_distance = minf(min_distance, dist)
		max_distance = maxf(max_distance, dist)

		if i == route_switch_step:
			# Exercise the same authored detour hook used by the Signal Gate without
			# waiting on presentation tweens in the synthetic fixed-step clock.
			_host._on_signal_gate_triggered()
		if int(_pursuer.current_detour_index) >= 0:
			detour_seen = true
		if dist <= float(_pursuer.intercept_distance):
			intercepted = true
			break

	var final_distance: float = _bike.global_position.distance_to(_pursuer.global_position)
	var route_outcome := "INTERCEPTED" if intercepted else ("CONTACT_BREAK_CANDIDATE" if final_distance > 18.0 else "ACTIVE_PRESSURE")
	return {
		"duration_s": _scenario_time - start_time,
		"route_switch_time_s": float(route_switch_step) * FIXED_DT,
		"detour_state_observed": detour_seen,
		"bike_path_length_m": path_distance,
		"min_pursuer_distance_m": min_distance,
		"max_pursuer_distance_m": max_distance,
		"final_pursuer_distance_m": final_distance,
		"outcome": route_outcome,
		"collision_events": _collision_events.size() - collisions_at_start,
		"camera_follow_error_m": float(_camera.last_follow_error)
	}


# -----------------------------------------------------------------------------
# Fixed-step helpers / trace capture
# -----------------------------------------------------------------------------
func _begin_scenario(id: String) -> void:
	_scenario_id = id
	_scenario_time = 0.0
	_scenario_step = 0
	_collision_events.clear()
	if _trace_enabled:
		_traces[id] = []


func _reset_bike(pos: Vector3, yaw: float) -> void:
	_bike.set_process(false)
	_bike.set_physics_process(false)
	_bike.current_state = 2 # CourierBike.BikeState.DRIVING; setup only, physics remains real.
	_bike.current_gear = 0 # GearState.FORWARD
	_bike.current_speed = 0.0
	_bike.steering_angle = 0.0
	_bike.is_handbrake_active = false
	_bike.velocity = Vector3.ZERO
	_bike.global_position = pos
	_bike.rotation = Vector3(0.0, yaw, 0.0)
	if _bike.get("visual_root") != null:
		_bike.visual_root.rotation = Vector3.ZERO
	if _camera != null:
		_camera.set_process(false)
		_camera.reset_camera_instant(_bike)
		_camera.set_process(false)


func _step_bike(throttle: float, steer: float, handbrake: bool) -> void:
	_bike.set_drive_inputs(throttle, steer, FIXED_DT, handbrake)
	_bike._physics_process(FIXED_DT)
	_manual_camera_step()
	_advance_clock(throttle, steer, handbrake)


func _manual_camera_step() -> void:
	if _camera != null:
		_camera._process(FIXED_DT)


func _advance_clock(throttle: float, steer: float, handbrake: bool) -> void:
	_scenario_step += 1
	_scenario_time += FIXED_DT
	if _trace_enabled:
		_record_trace(throttle, steer, handbrake)


func _record_trace(throttle: float, steer: float, handbrake: bool) -> void:
	if not _traces.has(_scenario_id):
		_traces[_scenario_id] = []
	var focus_pos := Vector3.ZERO
	var look_ahead := Vector3.ZERO
	if _camera != null:
		var focus_variant = _camera.get("_smoothed_focus_pos")
		if focus_variant is Vector3:
			focus_pos = focus_variant
		var look_variant = _camera.get("_smoothed_look_ahead")
		if look_variant is Vector3:
			look_ahead = look_variant
	var pursuit_state := -1
	if _pursuer != null:
		pursuit_state = int(_pursuer.current_state)

	_traces[_scenario_id].append({
		"step": _scenario_step,
		"time_s": _scenario_time,
		"throttle": throttle,
		"steer": steer,
		"handbrake": handbrake,
		"speed_mps": float(_bike.current_speed),
		"position": _v3(_bike.global_position),
		"velocity": _v3(_bike.velocity),
		"yaw_deg": rad_to_deg(float(_bike.rotation.y)),
		"lateral_slip_mps": _lateral_slip_speed(),
		"camera_position": _v3(_camera.global_position),
		"camera_focus": _v3(focus_pos),
		"camera_look_ahead": _v3(look_ahead),
		"camera_fov_deg": float(_camera.fov),
		"camera_follow_error_m": float(_camera.last_follow_error),
		"pursuit_state": pursuit_state
	})


func _lateral_slip_speed() -> float:
	var right_dir: Vector3 = _bike.global_transform.basis.x
	return abs(float(_bike.velocity.dot(right_dir)))


func _camera_lookahead_length() -> float:
	var value = _camera.get("_smoothed_look_ahead")
	if value is Vector3:
		return value.length()
	return 0.0


func _angle_delta(from_angle: float, to_angle: float) -> float:
	return wrapf(to_angle - from_angle, -PI, PI)


func _v3(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


# -----------------------------------------------------------------------------
# Collision fixture / telemetry
# -----------------------------------------------------------------------------
func _spawn_wall_fixture(pos: Vector3, size: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = "CTWFeelCollisionFixture"
	body.position = pos
	body.rotation.y = yaw
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	_host.add_child(body)
	_fixtures.append(body)


func _clear_fixtures() -> void:
	for fixture in _fixtures:
		if is_instance_valid(fixture):
			fixture.queue_free()
	_fixtures.clear()


func _on_collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3) -> void:
	_collision_events.append({
		"scenario": _scenario_id,
		"time_s": _scenario_time,
		"head_on_ratio": head_on_ratio,
		"impact_speed": impact_speed,
		"position": _v3(collision_pos)
	})


# -----------------------------------------------------------------------------
# Repeatability falsification
# -----------------------------------------------------------------------------
func _compare_repeatability(pass_a: Dictionary, pass_b: Dictionary) -> Dictionary:
	var failures: Array[String] = []
	_compare_variant("scenarios", pass_a, pass_b, failures)
	return {
		"passed": failures.is_empty(),
		"scalar_tolerance_rule": "<= 1 fixed frame (0.016667 absolute) or <= 1% relative; yaw scalars <= 0.5 deg when larger rule would be looser",
		"failures": failures
	}


func _compare_variant(path: String, a, b, failures: Array[String]) -> void:
	if typeof(a) != typeof(b):
		failures.append("%s type mismatch: %s vs %s" % [path, typeof(a), typeof(b)])
		return

	if a is Dictionary:
		var a_dict: Dictionary = a
		var b_dict: Dictionary = b
		for key in a_dict.keys():
			if not b_dict.has(key):
				failures.append("%s.%s missing from repeat pass" % [path, key])
				continue
			_compare_variant("%s.%s" % [path, key], a_dict[key], b_dict[key], failures)
		return

	if a is Array:
		var aa: Array = a
		var bb: Array = b
		if aa.size() != bb.size():
			failures.append("%s array size mismatch: %d vs %d" % [path, aa.size(), bb.size()])
			return
		for i in range(aa.size()):
			_compare_variant("%s[%d]" % [path, i], aa[i], bb[i], failures)
		return

	if a is float or a is int:
		var af := float(a)
		var bf := float(b)
		var tolerance := maxf(FIXED_DT, absf(af) * 0.01)
		if path.to_lower().contains("yaw"):
			tolerance = minf(tolerance, 0.5) if tolerance > 0.5 else tolerance
		if absf(af - bf) > tolerance:
			failures.append("%s drift %.9f exceeds tolerance %.9f (A=%.9f B=%.9f)" % [path, absf(af - bf), tolerance, af, bf])
		return

	if a != b:
		failures.append("%s mismatch: %s vs %s" % [path, str(a), str(b)])


# -----------------------------------------------------------------------------
# Artifact / provenance helpers
# -----------------------------------------------------------------------------
func _resolve_build_commit() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--feel-build-commit="):
			var value := arg.trim_prefix("--feel-build-commit=").strip_edges()
			if not value.is_empty():
				return value
	var env_value := OS.get_environment("EITS_BUILD_COMMIT").strip_edges()
	if not env_value.is_empty():
		return env_value
	return BASELINE_BEHAVIOR_SHA


func _ensure_output_dir() -> bool:
	var absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
	var err := DirAccess.make_dir_recursive_absolute(absolute)
	if err != OK and err != ERR_ALREADY_EXISTS:
		_fail("Could not create output directory %s (error %d)" % [absolute, err])
		return false
	return true


func _write_json(path: String, data) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not open %s for write (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.store_string("\n")
	file.close()
	return true


func _write_trace_artifacts() -> bool:
	for scenario in _traces.keys():
		var path := "%s/%s_%s_trace.json" % [OUTPUT_DIR, TRACE_PREFIX, scenario]
		if not _write_json(path, {
			"schema_version": 1,
			"behavior_commit": _resolve_build_commit(),
			"fixed_hz": FIXED_HZ,
			"scenario": scenario,
			"samples": _traces[scenario]
		}):
			return false
	return true


func _write_verification_log(summary: Dictionary) -> bool:
	var path := "%s/baseline_verification.log" % OUTPUT_DIR
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not open %s for write (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_line("CTW FEEL BASELINE — Ticket #11")
	file.store_line("behavior_commit=%s" % _resolve_build_commit())
	file.store_line("baseline_behavior_sha=%s" % BASELINE_BEHAVIOR_SHA)
	file.store_line("godot_version=%s" % JSON.stringify(Engine.get_version_info()))
	file.store_line("fixed_hz=%d" % FIXED_HZ)
	file.store_line("fixed_dt=%.9f" % FIXED_DT)
	file.store_line("main_scene=%s" % MAIN_SCENE_PATH)
	file.store_line("repeatability_passed=%s" % str(summary.repeatability.passed))
	file.store_line("headless_command=godot --headless --path godot --script res://scripts/verification/ctw_feel_harness.gd -- --run-ctw-feel-baseline --feel-build-commit=<sha>")
	file.store_line("windowed_command=godot --path godot --script res://scripts/verification/ctw_feel_harness.gd -- --run-ctw-feel-baseline --feel-build-commit=<sha>")
	file.close()
	return true


func _fail(message: String) -> void:
	_run_error = message
	push_error("[CTW_FEEL] %s" % message)
	quit(1)
