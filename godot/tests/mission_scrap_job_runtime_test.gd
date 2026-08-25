extends SceneTree

var _scene_under_test: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[MISSION_NARRATIVE_01_RUNTIME] %s" % message)
	await _finish(1)

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load the production scrap_test_block scene")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	await process_frame

	var runtime := _scene_under_test.get_node_or_null("MissionScrapJobRuntime")
	if runtime == null:
		await _fail("Production scene does not contain MissionScrapJobRuntime")
		return
	if not bool(runtime.get("_bound")):
		await _fail("Mission runtime did not bind to the retained gameplay systems")
		return

	var safe_root := _scene_under_test.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot")
	var mission_hud := safe_root.get_node_or_null("MissionHUD") if safe_root != null else null
	if mission_hud == null:
		await _fail("Mission HUD was not created inside SafeAreaRoot")
		return

	var title := mission_hud.find_child("MissionTitle", true, false) as Label
	var objective := mission_hud.find_child("ObjectiveLabel", true, false) as Label
	var contact := mission_hud.find_child("ContactLabel", true, false) as Label
	if title == null or objective == null or contact == null:
		await _fail("Mission HUD is missing title/objective/contact labels")
		return
	if title.text != "SCRAP JOB 01 // CITY PROPERTY":
		await _fail("Mission title does not identify the authored job")
		return
	if "COURIER BIKE" not in objective.text:
		await _fail("Cold-start runtime objective does not point to the Courier Bike")
		return
	if not contact.text.begins_with("LIRA //"):
		await _fail("Cold-start runtime contact line is not the Lira briefing")
		return

	var bike = _scene_under_test.get("courier_bike")
	if bike == null:
		await _fail("Retained Courier Bike runtime reference is absent")
		return
	bike.mounted.emit(_scene_under_test.get_node("Runner"))
	await process_frame
	if "TUNER MAST" not in objective.text:
		await _fail("Actual Courier Bike mounted signal did not advance the mission HUD")
		return

	print("[MISSION_NARRATIVE_01_RUNTIME] PASS")
	await _finish(0)
