extends Node

# CTW Feel Wave 1 / Ticket #15
# Chase-local retry authority for the Golden Slice.
#
# This component deliberately does NOT own pursuit AI, vehicle physics, camera
# follow behavior, Echo lifecycle, or the existing full Replay path. It binds to
# the live ScrapTestBlock and restores only a deterministic post-Echo/pre-chase
# checkpoint before re-entering the existing trigger_disturbance_alert() path.

const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")
const MemoryEchoControllerScript = preload("res://scripts/prototype/memory_echo_controller.gd")

const RETRY_ARM_DELAY: float = 0.85
const RETRY_ACTIVE_TARGET_SECONDS: float = 3.0
const DEFAULT_BIKE_CHECKPOINT: Vector3 = Vector3(-1.5, 0.05, 3.0)
const PLAYER_MOUNT_OFFSET: Vector3 = Vector3(0.0, 0.0, 0.5)
const PURSUER_START: Vector3 = Vector3(0.0, 0.6, -10.0)
const PROOF_DIR: String = "res://verification/feel/retry"

var _host = null
var _player = null
var _bike = null
var _camera = null
var _pursuer = null
var _gate = null
var _audio_mgr = null
var _touch_ui = null

var _retry_ready: bool = false
var _generation: int = 0
var _bound: bool = false
var _verification_started: bool = false

var _overlay: PanelContainer = null
var _retry_button: Button = null
var _replay_button: Button = null
var _status_label: Label = null


func _ready() -> void:
	set_process(true)
	call_deferred("_try_bind_current_scene")


func _process(_delta: float) -> void:
	if not _bound:
		_try_bind_current_scene()


func _try_bind_current_scene() -> void:
	if _bound:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	bind_to_scene(scene)


func bind_to_scene(scene: Node) -> bool:
	if scene == null:
		return false
	if scene.get("pursuer") == null or scene.get("touch_ui") == null:
		return false

	_host = scene
	_player = scene.get("player")
	_bike = scene.get("courier_bike")
	_camera = scene.get("camera")
	_pursuer = scene.get("pursuer")
	_gate = scene.get("signal_gate")
	_audio_mgr = scene.get("audio_mgr")
	_touch_ui = scene.get("touch_ui")

	if _player == null or _bike == null or _camera == null or _pursuer == null or _gate == null or _audio_mgr == null or _touch_ui == null:
		return false

	_build_retry_overlay()
	if not _pursuer.intercepted_target.is_connected(_on_intercepted):
		_pursuer.intercepted_target.connect(_on_intercepted)
	if not _touch_ui.replay_pressed.is_connected(_on_existing_replay_pressed):
		_touch_ui.replay_pressed.connect(_on_existing_replay_pressed)

	_bound = true
	set_process(false)
	call_deferred("_maybe_start_verification")
	return true


func is_retry_ready() -> bool:
	return _retry_ready


func is_retry_overlay_visible() -> bool:
	return _overlay != null and _overlay.visible


func get_retry_overlay_rect() -> Rect2:
	if _overlay:
		return _overlay.get_global_rect()
	return Rect2()


func request_retry_chase() -> bool:
	if not _bound or not _retry_ready:
		return false
	if int(_host.current_pursuit_state) != int(ScrapTestBlockScript.PursuitState.CALM):
		return false
	if not _echo_is_completed():
		return false

	# Consume authority immediately. A second tap in the same frame fails closed.
	_retry_ready = false
	_generation += 1
	_hide_retry_overlay()

	# Chase-local cleanup. Full Replay remains the only path that resets Echo and
	# solved Tuner/Panel progression.
	_host._contact_broken_timer = 0.0
	_host._steer_input = 0.0
	_host._throttle_input = 0.0
	_host._handbrake_input = false
	_host._active_target = null

	if _host.has_method("_end_pursuit_common"):
		_host._end_pursuit_common()
	_gate.reset_for_pursuit_retry()
	_audio_mgr.reset_audio_instant()
	_touch_ui.reset_all_input_states()
	_touch_ui.set_route_switch_button_visible(false)

	var active_vehicle = _host.get("active_vehicle")
	if active_vehicle != null and active_vehicle.has_method("force_dismount"):
		active_vehicle.force_dismount()
	_host.set("active_vehicle", null)

	# Courier Bike is the Wave 1 reference/checkpoint vehicle even though M06 now
	# supports the Hauler. This avoids silently changing #15's defined checkpoint.
	_bike.force_dismount()
	_bike.global_position = _resolve_checkpoint()
	_bike.rotation = Vector3.ZERO
	_bike.velocity = Vector3.ZERO
	_bike.current_speed = 0.0
	_bike.steering_angle = 0.0
	_bike.is_handbrake_active = false
	if _bike.get("visual_root") is Node3D:
		_bike.visual_root.rotation = Vector3.ZERO

	_player.global_position = _bike.global_position + PLAYER_MOUNT_OFFSET
	_player.velocity = Vector3.ZERO
	_player.visible = true
	_player.is_input_locked = false
	var player_collision := _player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if player_collision:
		player_collision.disabled = false

	if _bike.mount_interactable:
		_bike.mount_interactable.is_powered = true
		_bike.mount_interactable.visible = true
		_bike.mount_interactable.update_player_distance(_player.global_position)

	_pursuer.reset_pursuer(PURSUER_START)
	_pursuer.rotation = Vector3.ZERO

	var mounted: bool = _bike.request_mount(_player)
	if not mounted:
		# Fail safe: keep the player at a valid checkpoint with an obvious retry
		# action rather than entering a half-reset pursuit.
		_retry_ready = true
		_show_retry_overlay("[ RETRY CHECKPOINT BLOCKED ]")
		return false

	_camera.reset_camera_instant(_bike)

	# The existing authority owns the 0.75s disturbance -> active pursuit handoff,
	# ambient reactions, audio onset, pursuer activation, and gate readiness.
	_host.trigger_disturbance_alert()
	return true


func request_replay_slice() -> void:
	_generation += 1
	_retry_ready = false
	_hide_retry_overlay()
	if _bound and _host.has_method("reset_slice"):
		_host.reset_slice()


func _on_intercepted() -> void:
	if not _bound:
		return
	_generation += 1
	var token: int = _generation
	_retry_ready = false
	_hide_retry_overlay()
	get_tree().create_timer(RETRY_ARM_DELAY).timeout.connect(func():
		if token != _generation:
			return
		if int(_host.current_pursuit_state) != int(ScrapTestBlockScript.PursuitState.CALM):
			return
		if not _echo_is_completed():
			return
		_retry_ready = true
		_show_retry_overlay("[ PURSUIT INTERRUPTED ]")
	)


func _on_existing_replay_pressed() -> void:
	# The Golden Slice already owns this signal -> reset_slice connection. We only
	# invalidate retry authority/UI so both paths cannot race.
	_generation += 1
	_retry_ready = false
	_hide_retry_overlay()


func _echo_is_completed() -> bool:
	var echo_controller = _host.get("echo_controller")
	return echo_controller != null and echo_controller.has_completed()


func _resolve_checkpoint() -> Vector3:
	var marker = _host.get("_recovery_marker")
	if marker is Vector3:
		return marker
	return DEFAULT_BIKE_CHECKPOINT


func _build_retry_overlay() -> void:
	if _overlay or _touch_ui.safe_area_root == null:
		return

	_overlay = PanelContainer.new()
	_overlay.name = "PursuitRetryOverlay"
	_overlay.visible = false
	_overlay.z_index = 80
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.anchor_left = 0.5
	_overlay.anchor_top = 0.5
	_overlay.anchor_right = 0.5
	_overlay.anchor_bottom = 0.5
	_overlay.offset_left = -190.0
	_overlay.offset_top = -110.0
	_overlay.offset_right = 190.0
	_overlay.offset_bottom = 110.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.035, 0.05, 0.96)
	style.border_color = Color(0.75, 0.18, 0.16, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	_overlay.add_theme_stylebox_override("panel", style)
	_touch_ui.safe_area_root.add_child(_overlay)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_overlay.add_child(column)

	_status_label = Label.new()
	_status_label.text = "[ PURSUIT INTERRUPTED ]"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25, 1.0))
	_status_label.add_theme_font_size_override("font_size", 18)
	column.add_child(_status_label)

	_retry_button = Button.new()
	_retry_button.name = "RetryChaseButton"
	_retry_button.text = "[ RETRY CHASE ]"
	_retry_button.custom_minimum_size = Vector2(0.0, 60.0)
	_retry_button.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0, 1.0))
	_retry_button.pressed.connect(func(): request_retry_chase())
	column.add_child(_retry_button)

	_replay_button = Button.new()
	_replay_button.name = "ReplaySliceButton"
	_replay_button.text = "[ REPLAY SLICE ]"
	_replay_button.custom_minimum_size = Vector2(0.0, 54.0)
	_replay_button.pressed.connect(request_replay_slice)
	column.add_child(_replay_button)


func _show_retry_overlay(status: String) -> void:
	if not _overlay:
		return
	_status_label.text = status
	_overlay.visible = true
	_retry_button.grab_focus()


func _hide_retry_overlay() -> void:
	if _overlay:
		_overlay.visible = false


# -----------------------------------------------------------------------------
# Focused falsification / rendered proof
# -----------------------------------------------------------------------------
func _maybe_start_verification() -> void:
	if _verification_started:
		return
	var args := OS.get_cmdline_user_args()
	if args.has("--run-ctw-feel-retry-assertions"):
		_verification_started = true
		await _run_retry_assertions(false)
	elif args.has("--export-ctw-feel-retry-proof"):
		_verification_started = true
		await _run_retry_assertions(true)


func _prepare_completed_echo_and_active_pursuit() -> void:
	_host.reset_slice()
	await get_tree().process_frame

	# Focused fixture: preserve the real post-extraction lifecycle while avoiding
	# replaying the entire Tuner/Panel gesture sequence in this retry-only suite.
	_host.current_world_state = ScrapTestBlockScript.WorldLoopState.CORE_EXTRACTED
	_host.signal_tuner._set_state(_host.signal_tuner.TunerState.LOCKED)
	_host.corroded_panel.current_step = _host.corroded_panel.Step.EXTRACTED
	_host.corroded_panel.is_powered = true

	_player.global_position = _bike.global_position + PLAYER_MOUNT_OFFSET
	_bike.mount_interactable.update_player_distance(_player.global_position)
	assert(_bike.request_mount(_player), "RETRY FIXTURE: Courier Bike mount must succeed")
	await get_tree().create_timer(0.30).timeout

	assert(_host._trigger_echo_sequence(), "RETRY FIXTURE: real Echo sequence must trigger")
	var echo_controller = _host.echo_controller
	echo_controller.set_process(false)
	# Advance one real state-machine transition per call: ONSET -> PEAK -> RELEASE -> DONE.
	echo_controller._process(MemoryEchoControllerScript.ONSET_DURATION + 0.02)
	echo_controller._process(MemoryEchoControllerScript.PEAK_DURATION + 0.02)
	echo_controller._process(MemoryEchoControllerScript.RELEASE_DURATION + 0.02)
	await get_tree().create_timer(0.80).timeout
	assert(echo_controller.has_completed(), "RETRY FIXTURE: Echo must be DONE")
	assert(int(_host.current_pursuit_state) == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE), "RETRY FIXTURE: pursuit must become active through normal authority")


func _emit_intercept_and_wait_ready() -> void:
	_pursuer.intercepted_target.emit()
	await get_tree().create_timer(RETRY_ARM_DELAY + 0.08).timeout
	assert(_retry_ready, "RETRY: intercept must arm Retry Chase")
	assert(is_retry_overlay_visible(), "RETRY: intercept must show retry overlay")


func _run_retry_assertions(export_proof: bool) -> void:
	print("=========================================================================\n")
	print("[CTW_FEEL_RETRY] Starting fast pursuit retry falsification suite...")
	print("=========================================================================\n")

	await _prepare_completed_echo_and_active_pursuit()
	var echo_controller = _host.echo_controller
	var original_echo_count: int = echo_controller.get_trigger_count()

	# A1: retry cannot mutate a healthy active chase.
	assert(not request_retry_chase(), "A1 FAIL: Retry Chase must reject before interception")
	assert(int(_host.current_pursuit_state) == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE), "A1 FAIL: rejected retry must preserve pursuit")

	# Put gate fully into the spent/solid state to falsify stale tween/collision leakage.
	_gate.trigger_gate()
	await get_tree().create_timer(0.36).timeout
	assert(int(_gate.current_state) == int(_gate.GateState.TRIGGERED), "A2 FIXTURE FAIL: gate must be TRIGGERED")
	assert(not _gate.barrier_collision.disabled, "A2 FIXTURE FAIL: triggered gate must be solid")

	# Seed stale control state so Retry must authoritatively neutralize it.
	_host._steer_input = 0.8
	_host._throttle_input = 1.0
	_host._handbrake_input = true
	_touch_ui._is_gas_pressed = true
	_touch_ui._gas_touch_index = 7
	_touch_ui._is_handbrake_pressed = true
	_touch_ui._handbrake_touch_index = 8

	await _emit_intercept_and_wait_ready()
	assert(echo_controller.get_trigger_count() == original_echo_count, "A2 FAIL: interception cannot retrigger Echo")
	assert(echo_controller.has_completed(), "A2 FAIL: Echo must remain DONE at retry surface")

	# Safe-area proof: modal must remain inside the resolved canvas-safe rectangle.
	_touch_ui.set_simulated_safe_area(Rect2i(36, 24, 888, 492), Vector2i(960, 540))
	await get_tree().process_frame
	var safe_rect: Rect2 = _touch_ui.get_resolved_safe_rect()
	var modal_rect: Rect2 = get_retry_overlay_rect()
	assert(safe_rect.encloses(modal_rect), "A3 FAIL: Retry modal must remain inside safe area")

	if export_proof:
		await _save_viewport_png("retry_01_intercepted.png")

	var retry_started_msec: int = Time.get_ticks_msec()
	assert(request_retry_chase(), "A4 FAIL: first valid Retry Chase must succeed")
	assert(not request_retry_chase(), "A4 FAIL: immediate double-tap must fail closed")
	assert(_host._steer_input == 0.0 and _host._throttle_input == 0.0 and not _host._handbrake_input, "A4 FAIL: host drive inputs must reset neutral")
	assert(not _touch_ui._is_gas_pressed and not _touch_ui._is_handbrake_pressed, "A4 FAIL: touch drive state must reset neutral")
	assert(int(_gate.current_state) == int(_gate.GateState.DORMANT), "A4 FAIL: gate must reset before chase restart")
	assert(_gate.barrier_collision.disabled, "A4 FAIL: gate collision must be disabled at retry checkpoint")
	assert(_camera._smoothed_look_ahead == Vector3.ZERO, "A4 FAIL: camera stale look-ahead must clear")
	assert(echo_controller.has_completed() and echo_controller.get_trigger_count() == original_echo_count, "A4 FAIL: Retry Chase must not reset/re-arm/retrigger Echo")
	assert(not _audio_mgr._engine_player.playing, "A4 FAIL: stale engine loop must be cleared")

	await get_tree().create_timer(0.82).timeout
	var retry_elapsed: float = float(Time.get_ticks_msec() - retry_started_msec) / 1000.0
	assert(retry_elapsed < RETRY_ACTIVE_TARGET_SECONDS, "A5 FAIL: Retry Chase must become controllable within target")
	assert(_bike.occupant == _player, "A5 FAIL: player must be remounted on Courier Bike")
	assert(int(_bike.current_state) == int(_bike.BikeState.DRIVING), "A5 FAIL: bike must be DRIVING")
	assert(int(_host.current_pursuit_state) == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE), "A5 FAIL: pursuit must restart through normal authority")
	assert(int(_gate.current_state) == int(_gate.GateState.READY), "A5 FAIL: gate must become READY through normal pursuit startup")
	assert(echo_controller.has_completed() and echo_controller.get_trigger_count() == original_echo_count, "A5 FAIL: restarted chase must preserve one-shot Echo")
	assert(int(_host.current_world_state) == int(ScrapTestBlockScript.WorldLoopState.CORE_EXTRACTED), "A5 FAIL: solved world progression must remain post-extraction")
	assert(int(_host.corroded_panel.current_step) == int(_host.corroded_panel.Step.EXTRACTED), "A5 FAIL: panel extraction must remain solved")

	if export_proof:
		await _save_viewport_png("retry_02_restarted_chase.png")

	# A6: repeat the whole failure/retry cycle and prove deterministic checkpoint.
	await _emit_intercept_and_wait_ready()
	assert(request_retry_chase(), "A6 FAIL: second Retry Chase must succeed")
	await get_tree().create_timer(0.82).timeout
	assert(_bike.occupant == _player and int(_host.current_pursuit_state) == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE), "A6 FAIL: repeated retry must re-enter active chase")
	assert(echo_controller.get_trigger_count() == original_echo_count and echo_controller.has_completed(), "A6 FAIL: repeated retry must not duplicate Echo")

	# A7: Full Replay remains the only cold-start reset and clears retry authority.
	request_replay_slice()
	await get_tree().process_frame
	assert(int(_host.current_world_state) == int(ScrapTestBlockScript.WorldLoopState.START), "A7 FAIL: full Replay must restore START world state")
	assert(int(_host.current_pursuit_state) == int(ScrapTestBlockScript.PursuitState.CALM), "A7 FAIL: full Replay must restore CALM pursuit")
	assert(_host.echo_controller.current_phase == MemoryEchoControllerScript.EchoPhase.IDLE, "A7 FAIL: full Replay must reset Echo to IDLE")
	assert(_host.echo_controller.get_trigger_count() == 0, "A7 FAIL: full Replay must clear Echo trigger count")
	assert(not _retry_ready and not is_retry_overlay_visible(), "A7 FAIL: full Replay must clear retry authority/UI")

	_touch_ui.clear_simulated_safe_area()
	print("[CTW_FEEL_RETRY] PASS — fast Retry Chase lifecycle verified.\n")
	get_tree().quit(0)


func _save_viewport_png(filename: String) -> void:
	var absolute_dir: String = ProjectSettings.globalize_path(PROOF_DIR)
	var err: Error = DirAccess.make_dir_recursive_absolute(absolute_dir)
	assert(err == OK or err == ERR_ALREADY_EXISTS, "PROOF FAIL: could not create retry proof dir")
	await RenderingServer.frame_post_draw
	var texture: ViewportTexture = get_viewport().get_texture()
	var image: Image = texture.get_image()
	assert(image != null and not image.is_empty(), "PROOF FAIL: viewport image unavailable")
	var save_err: Error = image.save_png("%s/%s" % [PROOF_DIR, filename])
	assert(save_err == OK, "PROOF FAIL: could not save %s" % filename)
