extends SceneTree

const YardlineMusicCandidateSelectionContract = preload("res://tests/yardline_music_candidate_selection_contract.gd")

func _init() -> void:
	var error := YardlineMusicCandidateSelectionContract.verify()
	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01Q_CANDIDATE] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01Q_CANDIDATE] PASS: all 6 Yardline music track slots verified under frozen candidate selection lock")
	quit(0)
