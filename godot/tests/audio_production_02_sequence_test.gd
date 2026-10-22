extends SceneTree

# Audio Production 02: one continuous *automated routing* scenario.
# No listening claims, no candidate media, no changes to production code/saves.
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const CALM_WIND_DB := -18.0
const PRIORITY_WIND_DB := -30.0
var _problems: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_problems.append(message)

func _check_stream_player(player: Node, label: String) -> void:
	_check(player != null and is_instance_valid(player), "%s player missing" % label)
	if player == null or not is_instance_valid(player):
		return
	_check(player is AudioStreamPlayer or player is AudioStreamPlayer3D, "%s not an audio player" % label)
	if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
		_check(player.get("stream") != null, "%s stream missing" % label)
		_check(bool(player.get("playing")), "%s did not start" % label)

func _run() -> void:
	var manager := AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame
	var wind := manager.get_node_or_null("AmbientWindPlayer") as AudioStreamPlayer
	var engine := manager.get_node_or_null("EngineRevPlayer") as AudioStreamPlayer3D
	var static_player := manager.get_node_or_null("StaticNoisePlayer") as AudioStreamPlayer
	var siren := manager.get_node_or_null("SirenAlarmPlayer") as AudioStreamPlayer3D
	var tension := manager.get_node_or_null("PursuitTensionPlayer") as AudioStreamPlayer

	if wind == null or engine == null or static_player == null or siren == null or tension == null:
		push_error("[AUDIO_02_SEQUENCE] Required production player missing")
		manager.queue_free()
		quit(1)
		return

	# Step 1: calm yard, persistent ambiance but no accidental threat.
	_check(wind.playing and wind.stream != null, "Quiet yard has no ambiance")
	_check(is_equal_approx(wind.volume_db, CALM_WIND_DB), "Calm yard wind changed")
	_check(not siren.playing, "Siren leaked into quiet yard")

	# Step 2: walking + physical interaction, without bypassing the transient cap.
	manager.play_event(AudioManagerScript.SoundEvent.FOOTSTEP, Vector3.ZERO)
	manager.play_event(AudioManagerScript.SoundEvent.PANEL_PEEL, Vector3.ZERO)
	var voices: Array = manager.get("_active_transients")
	_check(voices.size() >= 2 and voices.size() <= 8, "Walking / metal voices absent or unbounded")
	if not voices.is_empty():
		_check_stream_player(voices.back(), "Walking / panel transient")

	# Step 3: tuner and radio transition.
	manager.set_tuning_audio(0.45)
	_check_stream_player(static_player, "Tuner static")
	manager.set_tuning_audio(0.0)
	_check(not static_player.playing, "Tuner static carried into driving/radio phase")
	manager.play_radio_station()
	await process_frame
	var radio: Node = manager.get_radio_player()
	_check(bool(radio.call("is_playing")), "Radio not active in drive phase")
	_check(is_equal_approx(float(manager.get_radio_duck()), 0.0), "Unexpected calm radio duck")

	# Step 4: speed/load-controlled drivetrain. Validate the un-ducked reference.
	var telemetry := {
		"speed_ratio": 0.95,
		"load_ratio": 1.0,
		"traction_state": "STABLE",
		"slip_intensity": 0.0,
	}
	manager.update_vehicle_feedback(telemetry, Vector3.ZERO)
	_check_stream_player(engine, "Moving bike drivetrain")
	var unthreatened_engine_db: float = engine.volume_db
	_check(unthreatened_engine_db > -12.0, "Steady drive engine reference unexpectedly quiet")

	# Step 5: pursuit prioritizes threat and makes space by ducking radio,
	# the environmental bed, and the vehicle, without muting the danger cues.
	manager.set_pursuit_pressure(10.0, Vector3.ZERO)
	manager.update_vehicle_feedback(telemetry, Vector3.ZERO)
	_check(is_equal_approx(wind.volume_db, PRIORITY_WIND_DB), "Pursuit failed to duck yard wind")
	_check(float(manager.get_radio_duck()) <= -8.0, "Pursuit failed to duck radio")
	_check_stream_player(siren, "Pursuit siren")
	_check_stream_player(tension, "Pursuit tension")
	_check(engine.volume_db <= -12.0 and engine.volume_db < unthreatened_engine_db, "Pursuit failed to reduce bike prominence")

	# Step 6: escape decay must restore all three relationships without residue.
	manager.start_pursuit_release_decay(0.15)
	await create_timer(0.65).timeout
	manager.update_vehicle_feedback(telemetry, Vector3.ZERO)
	_check(is_equal_approx(wind.volume_db, CALM_WIND_DB), "Escape left yard ambience attenuated")
	_check(is_equal_approx(float(manager.get_radio_duck()), 0.0), "Escape left radio duck active")
	_check(not siren.playing and not tension.playing, "Escape left threat running")
	_check(is_equal_approx(engine.volume_db, unthreatened_engine_db), "Escape did not restore steady engine level")

	# Step 7: authoritative replay reset, then quiet-yard restart.
	manager.reset_audio_instant()
	_check(not siren.playing and not static_player.playing, "Reset left temporary signals active")
	_check(not bool(manager.is_radio_playing()), "Reset left station active")
	_check(is_equal_approx(float(manager.get_radio_duck()), 0.0), "Reset left radio duck active")
	await process_frame
	await process_frame
	_check(wind.playing and is_equal_approx(wind.volume_db, CALM_WIND_DB), "Reset did not re-arm quiet yard")
	_check(not engine.playing, "Reset left bike drivetrain active")

	manager.queue_free()
	await process_frame
	await process_frame

	if not _problems.is_empty():
		for problem in _problems:
			push_error("[AUDIO_02_SEQUENCE] %s" % problem)
		quit(1)
		return
	print("[AUDIO_02_SEQUENCE] PASS: quiet-yard -> walk/metal -> tuner -> drive/radio -> pursuit -> escape -> replay reset (automated routing only; NO listening/recorded assets)")
	quit(0)
