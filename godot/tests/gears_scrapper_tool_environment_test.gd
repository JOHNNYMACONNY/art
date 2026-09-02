extends SceneTree

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _wanted_runtime != null and _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")
	quit(code)

func _fail(message: String) -> void:
	push_error("[GEARS_SCRAPPER_TOOL_ENVIRONMENT] %s" % message)
	await _finish(1)

func _run() -> void:
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to the production scene")
		return

	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	if district == null or not district.has_method("get_production_contract"):
		await _fail("Retained Gears district production fixture is missing")
		return
	var district_contract: Dictionary = district.call("get_production_contract")
	if not bool(district_contract.get("owns_no_gameplay_authority", false)):
		await _fail("Retained Gears district authority boundary regressed before P05")
		return

	var runtime := _scene.get_node_or_null("GearsScrapperToolRuntime")
	if runtime == null:
		await _fail("Production 05 Scrapper runtime / jammed service access capability is absent")
		return

	print("[GEARS_SCRAPPER_TOOL_ENVIRONMENT] PASS")
	await _finish(0)
