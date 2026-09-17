extends SceneTree

const Contract = preload("res://tests/utility_crawler_world_event_contract.gd")

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		push_error("Could not load scrap_test_block.tscn")
		await _finish(1)
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame

	var err := Contract.verify(_scene)
	if err != "":
		push_error("[CRAWLER_WORLD_EVENT] FAIL: %s" % err)
		await _finish(1)
		return

	print("[CRAWLER_WORLD_EVENT] 100% CONTRACT PASS")
	await _finish(0)
