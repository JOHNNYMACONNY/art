extends SceneTree

# Native/windowed owner diagnostic for issue #31.
# Launch WITHOUT --headless so Godot uses the real platform audio driver.
# This script sequences the same Master-routed paths covered structurally in CI.

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
