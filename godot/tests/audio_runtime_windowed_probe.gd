extends SceneTree

# Native/windowed owner diagnostic for issue #31 plus CTW Feel 04 rendered proof.
# Launch WITHOUT --headless so Godot uses a real display/rendering driver.

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _set_status(message: String) -> void:
	print("[AUDIO_RUNTIME_31_WINDOWED] %s" % message)
	if is_instance_valid(_scene):
		var label := _scene.get_node_or_null("CanvasLayer/StatusLabel")
		if label:
			label.text = "AUDIO PROBE // %s" % message

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
	await process_frame
	await process_frame
	quit(exit_code)

func _play_test_master_probe(audio_manager: Node, duration: float = 0.80) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = "AudioRuntimeWindowedTestProbe"
	player.bus = &"Master"
	player.volume_db = -6.0
	player.stream = audio_manager.call("_create_tone_wav", 660.0, clampf(duration, 0.05, 1.0), 0.5)
	audio_manager.add_child(player)
	player.play()
	return player

func _capture_frame(path: String) -> Image:
	var viewport := _scene.get_viewport() if is_instance_valid(_scene) else null
	if viewport == null:
		return null
	var texture := viewport.get_texture()
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return null
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if image.save_png(path) != OK:
		return null
	return image

func _frame_delta_metrics(before: Image, after: Image) -> Dictionary:
	if before == null or after == null or before.get_size() != after.get_size():
		return {"valid": false}
	var width := before.get_width()
	var height := before.get_height()
	var step := 2
	var changed := 0
	var sampled := 0
	var center_changed := 0
	var center_sampled := 0
	for y in range(0, height, step):
		for x in range(0, width, step):
			var a := before.get_pixel(x, y)
			var b := after.get_pixel(x, y)
			var delta := absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
			var is_changed := delta >= 0.045
			sampled += 1
			if is_changed:
				changed += 1
			if x >= width / 4 and x < width * 3 / 4 and y >= height / 5 and y < height * 4 / 5:
				center_sampled += 1
				if is_changed:
					center_changed += 1
	return {
		"valid": true,
		"changed_ratio": float(changed) / maxf(float(sampled), 1.0),
		"center_changed_ratio": float(center_changed) / maxf(float(center_sampled), 1.0),
		"changed_samples": changed,
		"sampled_pixels": sampled,
		"size": [width, height],
	}

func _disable_dynamic_world_except_bike(bike: Node, dust: GPUParticles3D) -> void:
	if _scene.has_method("set_process"):
		_scene.set_process(false)
	if _scene.has_method("set_physics_process"):
		_scene.set_physics_process(false)
	for node in _scene.find_children("*", "CharacterBody3D", true, false):
		if node != bike:
			node.set_process(false)
			node.set_physics_process(false)
	for particles in _scene.find_children("*", "GPUParticles3D", true, false):
		if particles != dust:
			particles.emitting = false

func _run_vehicle_feedback_rendered_proof() -> void:
	var bike := _scene.get_node_or_null("CourierBike") as CourierBike
	var runner := _scene.get_node_or_null("Runner") as PlayerRunner
	var camera := _scene.get_node_or_null("ChinatownCamera3D") as ChinatownCamera3D
	if bike == null or runner == null or camera == null:
		push_error("[CTW_FEEL_04_RENDERED] Missing CourierBike/Runner/Camera")
		await _finish(20)
		return

	var dust := bike.get_node_or_null("SlipDustParticles") as GPUParticles3D
	if dust == null:
		push_error("[CTW_FEEL_04_RENDERED] SlipDustParticles is absent")
		await _finish(21)
		return

	# Use the real mounted hero composition, then freeze all unrelated movers so
	# before/after pixel delta comes from the traction cue rather than world churn.
	runner.global_position = bike.global_position + Vector3(0.0, 0.0, 0.5)
	bike.mount_interactable.is_player_in_range = true
	if not bike.request_mount(runner):
		push_error("[CTW_FEEL_04_RENDERED] Could not mount runner for rendered proof")
		await _finish(22)
		return
	await create_timer(0.32).timeout
	await process_frame

	bike.current_speed = 7.0
	bike.velocity = -bike.global_transform.basis.z * 7.0
	bike.is_handbrake_active = false
	bike.steering_angle = 0.0
	camera.reset_camera_instant(bike)
	camera.current = true
	camera.set_process(false)
	bike.set_process(false)
	bike.set_physics_process(false)
	_disable_dynamic_world_except_bike(bike, dust)
	dust.emitting = false
	await process_frame
	await process_frame
	await process_frame

	var proof_dir := ProjectSettings.globalize_path("res://verification/feel")
	var baseline_path := "%s/ctw_feel04_rendered_baseline.png" % proof_dir
	var slip_path := "%s/ctw_feel04_rendered_full_slip.png" % proof_dir
	var baseline := _capture_frame(baseline_path)
	if baseline == null:
		push_error("[CTW_FEEL_04_RENDERED] Baseline viewport capture failed")
		await _finish(23)
		return

	# Same framing and handling values, only meaningful lateral slip + handbrake.
	bike.velocity = (-bike.global_transform.basis.z * 7.0) + (bike.global_transform.basis.x * 2.8)
	bike.is_handbrake_active = true
	var telemetry: Dictionary = bike.get_vehicle_feedback_telemetry(0.2)
	if String(telemetry.get("traction_state", "")) != "FULL_SLIP":
		push_error("[CTW_FEEL_04_RENDERED] Rendered proof telemetry did not classify FULL_SLIP: %s" % telemetry)
		await _finish(24)
		return
	bike.call("_update_slip_dust", telemetry)
	dust.restart()
	await create_timer(0.45).timeout
	await process_frame
	await process_frame

	var slip := _capture_frame(slip_path)
	if slip == null:
		push_error("[CTW_FEEL_04_RENDERED] Full-slip viewport capture failed")
		await _finish(25)
		return

	var metrics := _frame_delta_metrics(baseline, slip)
	if not bool(metrics.get("valid", false)):
		push_error("[CTW_FEEL_04_RENDERED] Frame comparison is invalid")
		await _finish(26)
		return
	var changed_ratio := float(metrics.get("changed_ratio", 0.0))
	var center_ratio := float(metrics.get("center_changed_ratio", 0.0))
	if changed_ratio < 0.00002:
		push_error("[CTW_FEEL_04_RENDERED] Slip cue was not visibly distinguishable: %s" % metrics)
		await _finish(27)
		return
	if changed_ratio > 0.05 or center_ratio > 0.08:
		push_error("[CTW_FEEL_04_RENDERED] Slip cue changed too much of the route/hero frame: %s" % metrics)
		await _finish(28)
		return

	print("[CTW_FEEL_04_RENDERED] PASS metrics=%s baseline=%s slip=%s" % [metrics, baseline_path, slip_path])
	await _finish(0)

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		push_error("[AUDIO_RUNTIME_31_WINDOWED] Could not load main prototype scene")
		await _finish(1)
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame

	if OS.get_cmdline_user_args().has("--vehicle-feedback-rendered-proof"):
		await _run_vehicle_feedback_rendered_proof()
		return

	var audio_manager := _scene.get_node_or_null("AudioManager")
	var runner := _scene.get_node_or_null("Runner")
	if audio_manager == null or runner == null:
		push_error("[AUDIO_RUNTIME_31_WINDOWED] Main scene is missing AudioManager/Runner")
		await _finish(1)
		return

	if audio_manager.has_method("play_debug_output_probe"):
		push_error("[AUDIO_RUNTIME_31_WINDOWED] Production AudioManager unexpectedly exposes a debug tone API")
		await _finish(1)
		return

	var report: Dictionary = audio_manager.call("get_runtime_audio_diagnostics")
	_set_status("driver=%s device=%s outputs=%s mix=%sHz latency=%ss Master(muted=%s,db=%s)" % [
		report.get("driver_name", "UNKNOWN"),
		report.get("output_device", "UNKNOWN"),
		report.get("output_devices", []),
		report.get("mix_rate", 0.0),
		report.get("output_latency", 0.0),
		report.get("master_muted", true),
		report.get("master_volume_db", -80.0),
	])

	if bool(report.get("headless_dummy_driver", false)):
		push_error("[AUDIO_RUNTIME_31_WINDOWED] Dummy driver detected. Relaunch without --headless; this run cannot prove physical audibility.")
		await _finish(2)
		return
	if bool(report.get("master_muted", true)) or float(report.get("master_volume_db", -80.0)) <= -60.0:
		push_error("[AUDIO_RUNTIME_31_WINDOWED] Master output is muted/effectively silent before gameplay playback")
		await _finish(3)
		return

	_set_status("1/5 DIRECT MASTER TONE — 660 Hz")
	var probe := _play_test_master_probe(audio_manager, 0.80)
	if probe.stream == null or not probe.playing:
		push_error("[AUDIO_RUNTIME_31_WINDOWED] Test-only Master probe did not start")
		await _finish(4)
		return
	await create_timer(1.0).timeout
	if is_instance_valid(probe):
		probe.stop()
		probe.free()

	_set_status("2/5 FOOTSTEPS — four clicks")
	for _i in range(4):
		audio_manager.call("play_event", AudioManager.SoundEvent.FOOTSTEP, runner.global_position)
		await create_timer(0.22).timeout

	_set_status("3/5 TUNER STATIC")
	audio_manager.call("set_tuning_audio", 0.40)
	await create_timer(1.25).timeout
	audio_manager.call("set_tuning_audio", 0.0)

	_set_status("4/5 RADIO PROCEDURAL FALLBACK")
	audio_manager.call("play_radio_station")
	await create_timer(2.0).timeout

	_set_status("5/5 PURSUIT SIREN + TENSION over radio")
	audio_manager.call("set_pursuit_pressure", 10.0, runner.global_position + Vector3(2.0, 0.0, 2.0))
	await create_timer(1.75).timeout

	audio_manager.call("reset_audio_instant")
	_set_status("COMPLETE — all voices reset; report which cues were audible")
	await create_timer(0.75).timeout
	await _finish(0)
