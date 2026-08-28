extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const LivingYardAmbientMovementAudioProductionContract = preload("res://tests/living_yard_ambient_movement_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = LivingYardAmbientMovementAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01K] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01K] PASS: exact footstep production, single looping wind layer, priority mix/reset lifecycle and chatter retention verified")
	quit(0)
