extends SceneTree

func _init() -> void:
	var script_cls = load("res://tests/embedded/clankers_production_contract_test.gd")
	var res: Dictionary = script_cls.run_test()
	print("\n=======================================================")
	print("[CLANKERS PRODUCTION CONTRACT TEST RESULTS]")
	print("=======================================================")
	for k in res.keys():
		print("  ", k, ": ", res[k])
	print("=======================================================\n")
	if res["all_passed"]:
		print("STATUS: PASS (ALL GREEN)")
		quit(0)
	else:
		print("STATUS: RED (FAILING AS EXPECTED IN TDD RED PHASE)")
		quit(1)
