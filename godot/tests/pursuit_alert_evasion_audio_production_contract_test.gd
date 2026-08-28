extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const PursuitAlertEvasionAudioProductionContract = preload("res://tests/pursuit_alert_evasion_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = PursuitAlertEvasionAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01H] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01H] PASS: exact pursuit alert/evasion production paths, siren side effect, radio ownership, fallbacks and scanner retention verified")
	quit(0)
