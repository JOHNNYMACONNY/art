extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const UIAudioIdentityLayerScript = preload("res://scripts/audio/ui_audio_identity_layer.gd")
const VehicleFeedbackContract = preload("res://tests/vehicle_feedback_contract_test.gd")
const UIAudioIdentityContract = preload("res://tests/ui_audio_identity_contract_test.gd")
const AudioFirstRetentionContract = preload("res://tests/audio_first_retention_contract_test.gd")
const GateSlamAudioProductionContract = preload("res://tests/gate_slam_audio_production_contract.gd")
const GoldenLoopTransientsAudioProductionContract = preload("res://tests/golden_loop_transients_audio_production_contract.gd")
const SignalLockAudioProductionContract = preload("res://tests/signal_lock_audio_production_contract.gd")
const ImpactsCollisionsAudioProductionContract = preload("res://tests/impacts_collisions_audio_production_contract.gd")
const PursuitAlertEvasionAudioProductionContract = preload("res://tests/pursuit_alert_evasion_audio_production_contract.gd")
const MemoryEchoArcAudioProductionContract = preload("res://tests/memory_echo_arc_audio_production_contract.gd")
const LivingYardAmbientMovementAudioProductionContract = preload("res://tests/living_yard_ambient_movement_audio_production_contract.gd")
const ContinuousSignatureLoopsAudioProductionContract = preload("res://tests/continuous_signature_loops_audio_production_contract.gd")
const YardlineStationIdentityAudioProductionContract = preload("res://tests/yardline_station_identity_audio_production_contract.gd")
const UIAudioIdentityAudioProductionContract = preload("res://tests/ui_audio_identity_audio_production_contract.gd")
const YardlineRadioInterstitialAudioProductionContract = preload("res://tests/yardline_radio_interstitial_audio_production_contract.gd")

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

func _pcm_span(stream: AudioStreamWAV) -> int:
	if stream == null or stream.data.is_empty():
		return 0
	var minimum_byte := 255
	var maximum_byte := 0
	for sample_byte in stream.data:
		minimum_byte = mini(minimum_byte, int(sample_byte))
		maximum_byte = maxi(maximum_byte, int(sample_byte))
	return maximum_byte - minimum_byte

func _play_test_master_probe(duration: float = 0.20) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = "AudioRuntimeTestProbe"
	player.bus = &"Master"
	player.volume_db = -6.0
	player.stream = _manager.call("_create_tone_wav", 660.0, clampf(duration, 0.05, 1.0), 0.5)
	_manager.add_child(player)
	player.play()
	return player

func _run_ci_windowed_vehicle_proof() -> String:
	if OS.get_environment("ECHOES_RUN_WINDOWED_VEHICLE_PROOF") != "1":
		print("[CTW_FEEL_04_RENDERED] SKIP generic audio CI; set ECHOES_RUN_WINDOWED_VEHICLE_PROOF=1 for targeted proof")
		return ""
	if OS.get_environment("CI").to_lower() != "true" or not OS.has_feature("linux"):
		print("[CTW_FEEL_04_RENDERED] SKIP outside Linux CI")
		return ""

	var output: Array = []
	var project_path := ProjectSettings.globalize_path("res://")
	var args := PackedStringArray([
		"-a",
		"-s",
		"-screen 0 1280x720x24",
		OS.get_executable_path(),
		"--path", project_path,
		"--rendering-method", "gl_compatibility",
		"--script", "res://tests/audio_runtime_windowed_probe.gd",
		"--", "--vehicle-feedback-rendered-proof",
	])
	var exit_code := OS.execute("xvfb-run", args, output, true)
	var combined := "\n".join(output)
	if exit_code != 0:
		return "windowed rendered proof exited %d; output=%s" % [exit_code, combined.right(2000)]
	if not combined.contains("[CTW_FEEL_04_RENDERED] PASS"):
		return "windowed rendered proof exited 0 without PASS marker; output=%s" % combined.right(2000)
	print("[AUDIO_RUNTIME_31] CTW Feel 04 windowed rendered proof PASS")
	return ""

func _run() -> void:
	_manager = AudioManagerScript.new()
	root.add_child(_manager)
	var ui_layer := UIAudioIdentityLayerScript.new()
	ui_layer.name = "UIAudioIdentityLayer"
	_manager.add_child(ui_layer)
	ui_layer.call("configure", _manager)
	await process_frame

	var gate_slam_error: String = GateSlamAudioProductionContract.verify(_manager)
	if not gate_slam_error.is_empty():
		await _fail("Audio Production 01C: %s" % gate_slam_error)
		return
	await process_frame

	var golden_loop_error: String = GoldenLoopTransientsAudioProductionContract.verify(_manager)
	if not golden_loop_error.is_empty():
		await _fail("Audio Production 01D: %s" % golden_loop_error)
		return
	await process_frame

	var signal_lock_error: String = SignalLockAudioProductionContract.verify(_manager)
	if not signal_lock_error.is_empty():
		await _fail("Audio Production 01F: %s" % signal_lock_error)
		return
	await process_frame

	var impacts_error: String = ImpactsCollisionsAudioProductionContract.verify(_manager)
	if not impacts_error.is_empty():
		await _fail("Audio Production 01G: %s" % impacts_error)
		return
	await process_frame

	var pursuit_pack_error: String = PursuitAlertEvasionAudioProductionContract.verify(_manager)
	if not pursuit_pack_error.is_empty():
		await _fail("Audio Production 01H: %s" % pursuit_pack_error)
		return
	await process_frame

	var memory_echo_error: String = MemoryEchoArcAudioProductionContract.verify(_manager)
	if not memory_echo_error.is_empty():
		await _fail("Audio Production 01J: %s" % memory_echo_error)
		return
	await process_frame

	var living_yard_error: String = LivingYardAmbientMovementAudioProductionContract.verify(_manager)
	if not living_yard_error.is_empty():
		await _fail("Audio Production 01K: %s" % living_yard_error)
		return
	await process_frame

	# Keep the 01L production-media contract inside this exact-head runtime gate before generic output probes.
	var continuous_loops_error: String = ContinuousSignatureLoopsAudioProductionContract.verify(_manager)
	if not continuous_loops_error.is_empty():
		await _fail("Audio Production 01L: %s" % continuous_loops_error)
		return
	await process_frame

	# Keep the 01M production-media contract inside this exact-head runtime gate before generic output probes.
	var yardline_identity_error: String = YardlineStationIdentityAudioProductionContract.verify()
	if not yardline_identity_error.is_empty():
		await _fail("Audio Production 01M: %s" % yardline_identity_error)
		return
	await process_frame

	# Keep the 01N UI production-media contract inside this exact-head runtime gate before generic output probes.
	var ui_identity_error: String = UIAudioIdentityAudioProductionContract.verify(_manager, ui_layer)
	if not ui_identity_error.is_empty():
		await _fail("Audio Production 01N: %s" % ui_identity_error)
		return
	await process_frame

	# Keep the 01O production-media contract inside this exact-head runtime gate before generic output probes.
	var yardline_interstitial_error: String = YardlineRadioInterstitialAudioProductionContract.verify()
	if not yardline_interstitial_error.is_empty():
		await _fail("Audio Production 01O: %s" % yardline_interstitial_error)
		return
	await process_frame

	if not _manager.has_method("get_runtime_audio_diagnostics"):
		await _fail("Runtime audio diagnostics seam is absent")
		return

	if _manager.has_method("play_debug_output_probe"):
		await _fail("Debug output probe leaked into the production AudioManager API")
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
		await _fail("Master bus is muted in runtime configuration")
		return
	if float(report["master_volume_db"]) <= -60.0:
		await _fail("Master bus volume is effectively silent")
		return

	var tone: AudioStreamWAV = _manager.call("_create_tone_wav", 440.0, 0.10, 0.5)
	if _pcm_span(tone) < 32:
		await _fail("Procedural fallback tone has insufficient PCM amplitude")
		return
	tone = null

	var probe_player := _play_test_master_probe(0.20)
	if not await _require_player(probe_player, "Test output probe"):
		return
	if not probe_player.stream is AudioStreamWAV or _pcm_span(probe_player.stream as AudioStreamWAV) < 32:
		await _fail("Test output probe is playing silent/insufficient PCM")
		return
	probe_player.stop()
	probe_player.free()
	probe_player = null

	_manager.call("play_event", AudioManagerScript.SoundEvent.FOOTSTEP, Vector3.ZERO)
	var active_transients: Array = _manager.get("_active_transients")
	if active_transients.is_empty():
		await _fail("Footstep event did not create a transient voice")
		return
	if not await _require_player(active_transients.back(), "Footstep"):
		return
	await create_timer(0.12).timeout

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

	var retention_error: String = AudioFirstRetentionContract.verify()
	if not retention_error.is_empty():
		await _fail("Audio 07: %s" % retention_error)
		return

	var ui_error: String = UIAudioIdentityContract.verify(_manager, ui_layer)
	if not ui_error.is_empty():
		await _fail("Audio 06: %s" % ui_error)
		return

	var vehicle_error: String = VehicleFeedbackContract.verify(_manager)
	if not vehicle_error.is_empty():
		await _fail("CTW Feel 04: %s" % vehicle_error)
		return

	var rendered_error := _run_ci_windowed_vehicle_proof()
	if not rendered_error.is_empty():
		await _fail("CTW Feel 04 rendered proof: %s" % rendered_error)
		return

	print("[AUDIO_RUNTIME_31] diagnostics=%s" % report)
	print("[AUDIO_RUNTIME_31] PASS (Audio Production 01O Yardline interstitial media + 01N UI identity media + 01M Yardline station identity + 01L continuous signature loops + 01K footstep/wind + 01J Memory Echo arc + 01H pursuit alert/evasion + 01G impacts/collisions + 01F signal lock + 01D six-transient pack + 01C gate slam + Audio 07 retention/report + output + Audio 06 UI identity + CTW Feel 04 telemetry/mix/reset; physical audibility remains external)")

	active_transients = []
	tuner_player = null
	radio_stream_player = null
	radio_player = null
	siren_player = null
	tension_player = null
	ui_layer = null
	_manager.queue_free()
	await process_frame
	await process_frame
	await process_frame
	quit(0)
