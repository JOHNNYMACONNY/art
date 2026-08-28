extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const ContinuousSignatureLoopsAudioProductionContract = preload("res://tests/continuous_signature_loops_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = ContinuousSignatureLoopsAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01L] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01L] PASS: exact engine/siren/interference production loops, existing player ownership, modulation, suppression, fallbacks and reset verified")
	quit(0)
