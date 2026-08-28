extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const MemoryEchoArcAudioProductionContract = preload("res://tests/memory_echo_arc_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = MemoryEchoArcAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01J] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01J] PASS: three exact Echo selections, shared 2D voice, finite peak metadata, phase timing and independent fallbacks verified")
	quit(0)
