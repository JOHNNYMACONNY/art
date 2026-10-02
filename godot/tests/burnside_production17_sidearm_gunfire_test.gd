extends SceneTree

const PRODUCTION_SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	quit(code)

func _fail(message: String) -> void:
	push_error("[P17_SIDEARM_GUNFIRE] %s" % message)
	await _finish(1)

func _run() -> void:
	var packed := load(PRODUCTION_SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame

	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null:
		await _fail("Retained TouchControlsUI missing")
		return
	if not touch_ui.has_signal("weapon_action_pressed"):
		await _fail("P17 RED: retained input surface lacks weapon_action_pressed")
		return
	if not touch_ui.has_method("set_weapon_action_available"):
		await _fail("P17 RED: retained input surface lacks weapon availability API")
		return
	var fire_button := _scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/RightTouchArea/FireButton")
	if fire_button == null:
		await _fail("P17 RED: mobile FireButton missing")
		return

	var sidearm_runtime := _scene.get_node_or_null("GearsSidearmRuntime")
	if sidearm_runtime == null:
		await _fail("P17 RED: GearsSidearmRuntime missing")
		return
	for method_name in [
		"has_sidearm",
		"get_pickup",
		"handle_weapon_action_pressed",
		"get_shot_count",
		"get_ballistic_query_count",
		"get_last_impact_name",
	]:
		if not sidearm_runtime.has_method(method_name):
			await _fail("P17 RED: sidearm runtime lacks %s" % method_name)
			return

	var incident := _scene.get_node_or_null("GearsWorkZoneIncident")
	if incident == null or not incident.has_method("trigger_gunfire_incident"):
		await _fail("P17 RED: Gears work-zone lacks bounded gunfire incident seam")
		return

	var audio_mgr := _scene.get_node_or_null("AudioManager")
	if audio_mgr == null:
		await _fail("Retained AudioManager missing")
		return
	var audio_script = audio_mgr.get_script()
	if audio_script == null:
		await _fail("AudioManager script missing")
		return
	var sound_event = audio_script.get_script_constant_map().get("SoundEvent", {})
	if not (sound_event is Dictionary) or not sound_event.has("SIDEARM_FIRE"):
		await _fail("P17 RED: AudioManager lacks SIDEARM_FIRE semantic event")
		return

	print("[P17_SIDEARM_GUNFIRE] PASS")
	await _finish(0)
