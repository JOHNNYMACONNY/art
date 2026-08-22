extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

var _manager: Node = null

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[AUDIO_RUNTIME_31] %s" % message)
	if is_instance_valid(_manager):
		_manager.queue_free()
	await process_frame
	quit(1)

func _run() -> void:
	_manager = AudioManagerScript.new()
	root.add_child(_manager)
	await process_frame

	# RED on current main: #31 needs an explicit, bounded output diagnostic/probe seam.
	if not _manager.has_method("get_runtime_audio_diagnostics"):
		await _fail("Runtime audio diagnostics seam is absent")
		return
	if not _manager.has_method("play_debug_output_probe"):
		await _fail("Dev-only output probe seam is absent")
		return

	var report: Dictionary = _manager.call("get_runtime_audio_diagnostics")
	var required_keys := [
		"driver_name",
		"output_device",
		"output_devices",
		"mix_rate",
		"output_latency",
		"master_bus_index",
		"master_muted",
		"master_volume_db",
		"headless_dummy_driver",
	]
	for key in required_keys:
		if not report.has(key):
			await _fail("Diagnostic report missing key: %s" % key)
			return

	var master_idx := int(report["master_bus_index"])
	if master_idx < 0:
		await _fail("Master bus is unavailable")
		return
	if bool(report["master_muted"]):
		await _fail("Master bus is unexpectedly muted")
		return
	if float(report["master_volume_db"]) <= -60.0:
		await _fail("Master bus volume is effectively silent")
		return

	# Headless CI is expected to use Godot's Dummy driver; that is diagnostic
	# evidence, not physical-audibility proof. The synthesized PCM must still be real.
	var tone: AudioStreamWAV = _manager.call("_create_tone_wav", 440.0, 0.10, 0.5)
	if tone == null or tone.data.is_empty():
		await _fail("Procedural fallback tone contains no PCM data")
		return
	var minimum_byte := 255
	var maximum_byte := 0
	for sample_byte in tone.data:
		minimum_byte = mini(minimum_byte, int(sample_byte))
		maximum_byte = maxi(maximum_byte, int(sample_byte))
	if maximum_byte - minimum_byte < 32:
		await _fail("Procedural fallback tone has insufficient PCM amplitude")
		return

	var probe_player = _manager.call("play_debug_output_probe", 0.20)
	if probe_player == null or not is_instance_valid(probe_player):
		await _fail("Debug output probe did not return a live player")
		return
	if StringName(probe_player.bus) != &"Master":
		await _fail("Debug output probe is not routed to Master")
		return
	if probe_player.stream == null:
		await _fail("Debug output probe has no stream")
		return
	if not probe_player.playing:
		await _fail("Debug output probe did not enter playing state")
		return

	print("[AUDIO_RUNTIME_31] diagnostics=%s" % report)
	print("[AUDIO_RUNTIME_31] PASS (structural/runtime activation only; physical audibility remains external)")
	_manager.queue_free()
	await process_frame
	quit(0)