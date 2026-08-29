extends SceneTree

const YardlineRadioInterstitialAudioProductionContract = preload("res://tests/yardline_radio_interstitial_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var error: String = YardlineRadioInterstitialAudioProductionContract.verify()
	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01O_MEDIA] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01O_MEDIA] PASS: 6 Yardline interstitial production assets ingested, catalog-verified, stream resolution validated, exact hashes confirmed, fallbacks retained")
	quit(0)
