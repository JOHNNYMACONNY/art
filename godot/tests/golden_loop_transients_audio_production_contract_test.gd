extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const GoldenLoopTransientsAudioProductionContract = preload("res://tests/golden_loop_transients_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = GoldenLoopTransientsAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01D] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01D] PASS: six exact GTA selections resolve, map and play as bounded 3D production voices with independent procedural fallback")
	quit(0)
