extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const ImpactsCollisionsAudioProductionContract = preload("res://tests/impacts_collisions_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = ImpactsCollisionsAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01G] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01G] PASS: three exact impact selections, 3D production playback, interception side effects, collision energy gain and independent fallbacks verified")
	quit(0)
