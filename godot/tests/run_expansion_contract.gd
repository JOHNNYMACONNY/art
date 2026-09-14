extends SceneTree

func _init() -> void:
	var script := load("res://tests/embedded/gears_expansion_contract_test.gd")
	var results: Dictionary = script.run_test()

	print("\n=======================================================")
	print("[GEARS EXPANSION & VEHICLE FLEET CONTRACT TEST RESULTS]")
	print("=======================================================")
	for k in results.keys():
		print("  %s: %s" % [k, results[k]])
	print("=======================================================\n")

	if results.get("all_passed", false):
		print("STATUS: PASS (ALL GREEN)")
		quit(0)
	else:
		print("STATUS: FAIL (RED - TDD GATE ACTIVE)")
		quit(1)
