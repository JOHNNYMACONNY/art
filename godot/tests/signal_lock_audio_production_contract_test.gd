extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const SignalLockAudioProductionContract = preload("res://tests/signal_lock_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = SignalLockAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01F] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01F] PASS: exact selected signal lock WAV, 3D semantic repair, production playback and procedural fallback verified")
	quit(0)
