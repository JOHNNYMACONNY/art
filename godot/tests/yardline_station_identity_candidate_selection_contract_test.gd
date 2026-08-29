extends SceneTree

const YardlineStationIdentityCandidateSelectionContract = preload("res://tests/yardline_station_identity_candidate_selection_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var error: String = YardlineStationIdentityCandidateSelectionContract.verify()
	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01M_CANDIDATE] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01M_CANDIDATE] PASS: Yardline sweeper + two station IDs remain fallback-only, catalog-locked, independently synthesizable, and owned by the single existing radio player")
	quit(0)
