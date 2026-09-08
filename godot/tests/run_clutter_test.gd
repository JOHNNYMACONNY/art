extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	
	var tester = load("res://tests/embedded/gears_street_clutter_contract_test.gd")
	tester.run(scene)
	quit(0)
