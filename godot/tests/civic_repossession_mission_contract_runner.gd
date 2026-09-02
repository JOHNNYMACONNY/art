extends SceneTree

const CivicRepossessionContract = preload("res://tests/civic_repossession_mission_contract_test.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var error := CivicRepossessionContract.verify()
	if not error.is_empty():
		push_error("[MISSION_NARRATIVE_02_CONTRACT] %s" % error)
		quit(1)
		return
	print("[MISSION_NARRATIVE_02_CONTRACT] PASS")
	quit(0)
