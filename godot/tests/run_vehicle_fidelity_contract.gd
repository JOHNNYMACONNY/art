extends SceneTree

func _init():
	print("\n=======================================================")
	print("[GEARS VEHICLE FIDELITY CONTRACT TEST RUNNER]")
	print("=======================================================")
	var script = load("res://tests/embedded/gears_vehicle_fidelity_contract_test.gd")
	if script == null:
		printerr("FAILED to load vehicle fidelity contract test script!")
		quit(1)
		return

	var results: Dictionary = script.run_test()
	for k in results.keys():
		print("  %s: %s" % [k, str(results[k])])
	print("=======================================================")

	if results.get("all_passed", false):
		print("\nSTATUS: PASS (ALL GREEN)\n")
		quit(0)
	else:
		print("\nSTATUS: FAIL (TDD RED / QUALITY GAP DETECTED)\n")
		quit(1)
