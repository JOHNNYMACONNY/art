extends SceneTree

const YardlineRadioInterstitialCandidateSelectionContract = preload("res://tests/yardline_radio_interstitial_candidate_selection_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var error: String = YardlineRadioInterstitialCandidateSelectionContract.verify()
	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01O_CANDIDATE] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01O_CANDIDATE] PASS: 6 Yardline interstitial slots (2 DJ links, 2 adverts, 2 world events) locked, catalog-bound, independently synthesizable, and verified")
	quit(0)
