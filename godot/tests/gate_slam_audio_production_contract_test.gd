extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const GateSlamAudioProductionContract = preload("res://tests/gate_slam_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	var error: String = GateSlamAudioProductionContract.verify(manager)
	manager.queue_free()
	await process_frame
	await process_frame

	if not error.is_empty():
		push_error("[GATE_SLAM_AUDIO_PRODUCTION] FAIL: %s" % error)
		quit(1)
		return

	print("[GATE_SLAM_AUDIO_PRODUCTION] PASS: exact selected gate WAV, semantic mapping, 3D production playback and procedural fallback verified")
	quit(0)
