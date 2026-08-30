extends SceneTree

const YardlineMusicAudioProductionContract = preload("res://tests/yardline_music_audio_production_contract.gd")

func _init() -> void:
	var err := YardlineMusicAudioProductionContract.verify()
	if not err.is_empty():
		push_error("[AUDIO_PRODUCTION_01Q_MEDIA] FAIL: %s" % err)
		quit(1)
		return
	print("[AUDIO_PRODUCTION_01Q_MEDIA] PASS: all 6 Yardline music track slots verified under production media ingestion contract")
	quit(0)
