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
	await process_frame
	quit(1)

func _require_player(player: Node, label: String) -> bool:
	if player == null or not is_instance_valid(player):
		await _fail("%s player is unavailable" % label)
		return false
	if player.stream == null:
		await _fail("%s player has no stream" % label)
		return false
	if StringName(player.bus) != &"Master":
		await _fail("%s player is not routed to Master" % label)
		return false
	if not player.playing:
		await _fail("%s player did not enter playing state" % label)
		return false
	return true

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

	# Direct non-spatial Master probe.
	var probe_player = _manager.call("play_debug_output_probe", 0.20)
	if not await _require_player(probe_player, "Debug output probe"):
		return
	await create_timer(0.30).timeout
	if is_instance_valid(probe_player):
		await _fail("Debug output probe did not self-clean")
		return

	# Normal gameplay activation paths must reach live Master-routed players too.
	_manager.call("play_event", AudioManagerScript.SoundEvent.FOOTSTEP, Vector3.ZERO)
	var active_transients: Array = _manager.get("_active_transients")
	if active_transients.is_empty():
		await _fail("Footstep event did not create a transient voice")
		return
	if not await _require_player(active_transients.back(), "Footstep"):
		return

	_manager.call("set_tuning_audio", 0.40)
	var tuner_player := _manager.get_node_or_null("StaticNoisePlayer")
	if not await _require_player(tuner_player, "Tuner"):
		return

	_manager.call("play_radio_station")
	await process_frame
	var radio_player: Node = _manager.call("get_radio_player")
	if not bool(radio_player.call("is_playing")) or not bool(radio_player.call("is_stream_playing")):
		await _fail("Radio fallback did not enter active stream playback")
		return
	var radio_stream_player := radio_player.get_node_or_null("RadioAudioStreamPlayer")
	if not await _require_player(radio_stream_player, "Radio fallback"):
		return

	_manager.call("set_pursuit_pressure", 10.0, Vector3.ZERO)
	var siren_player := _manager.get_node_or_null("SirenAlarmPlayer")
	var tension_player := _manager.get_node_or_null("PursuitTensionPlayer")
	if not await _require_player(siren_player, "Pursuit siren"):
		return
	if not await _require_player(tension_player, "Pursuit tension"):
		return

	_manager.call("reset_audio_instant")
	if tuner_player.playing or siren_player.playing or tension_player.playing:
		await _fail("Authoritative reset left a continuous output voice playing")
		return
	if bool(_manager.call("is_radio_playing")):
		await _fail("Authoritative reset left radio playback active")
		return

	print("[AUDIO_RUNTIME_31] diagnostics=%s" % report)
	print("[AUDIO_RUNTIME_31] PASS (probe + footstep + tuner + radio + pursuit structurally active; physical audibility remains external)")
	_manager.queue_free()
	await process_frame
	await process_frame
	quit(0)
