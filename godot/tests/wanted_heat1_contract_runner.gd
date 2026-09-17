extends SceneTree

const WantedHeat1Contract = preload("res://tests/wanted_heat1_contract_test.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var error := WantedHeat1Contract.verify()
	if not error.is_empty():
		push_error("[WANTED_HEAT1_CONTRACT] %s" % error)
		quit(1)
		return
	quit(0)
