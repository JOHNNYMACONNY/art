extends SceneTree

const TacticalPackCandidateSelectionContract = preload("res://tests/tactical_pack_candidate_selection_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var error: String = TacticalPackCandidateSelectionContract.verify()
	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01P_CANDIDATE] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01P_CANDIDATE] PASS: 5 tactical slots locked, frozen invariants verified, winner/runner-up metadata validated")
	quit(0)
