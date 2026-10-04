extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CLEAR_LINES := [
	["BURN", "You brought me a city truck with the seal still warm."],
	["RUNNER", "You wanted the truck."],
	["BURN", "I wanted to see if you came back. Armor’s in the bay. Keep the city outside."],
]
const REFUSAL := "Not with half the city looking over your shoulder. Lose them."

var _scene: Node = null
var _wanted: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _wanted != null and _wanted.has_method("reset_runtime"):
		_wanted.call("reset_runtime")
	quit(code)

func _fail(message: String) -> void:
	push_error("[P18_MAYOR_BURN] %s" % message)
	await _finish(1)

func _run() -> void:
	_wanted = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return
	_wanted.call("reset_runtime")

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame

	if _wanted.has_method("bind_to_scene") and not bool(_wanted.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime could not bind to production scene")
		return

	var runtime := _scene.get_node_or_null("MayorBurnEncounterRuntime")
	if runtime == null:
		await _fail("MayorBurnEncounterRuntime is absent")
		return

	for method_name in [
		"get_actor",
		"get_contact_interactable",
		"get_affordance_text",
		"get_dialogue_speaker",
		"get_dialogue_line",
		"is_presentation_visible",
		"get_encounter_start_count",
		"process_encounter_state",
		"advance_dialogue_for_test",
		"reset_encounter_presentation",
	]:
		if not runtime.has_method(method_name):
			await _fail("P18 runtime lacks %s" % method_name)
			return

	var actor := runtime.call("get_actor") as Node3D
	var encounter_target: Node = runtime.call("get_contact_interactable") as Node
	var player := _scene.get_node_or_null("Runner") as CharacterBody3D
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var contact_runtime := _scene.get_node_or_null("MayorBurnContactServiceRuntime")
	var action_button := touch_ui.get("action_button") as Button if touch_ui != null else null
	if actor == null or encounter_target == null or player == null or touch_ui == null or contact_runtime == null or action_button == null:
		await _fail("P18 fixture is incomplete")
		return
	if not actor.visible:
		await _fail("Physical Mayor Burn is not visible before KNOWN")
		return

	var store = contact_runtime.call("get_progress_store")
	if store == null:
		await _fail("Retained Mayor Burn contact store is unavailable")
		return
	if bool(store.call("is_known")):
		await _fail("P18 test must begin with UNESTABLISHED contact state")
		return

	player.global_position = actor.global_position + Vector3(0.0, 0.0, 1.6)
	player.velocity = Vector3.ZERO
	runtime.call("process_encounter_state")
	await process_frame
	if bool(encounter_target.get("is_powered")):
		await _fail("Pre-KNOWN Burn encounter became actionable")
		return
	if not String(runtime.call("get_affordance_text")).is_empty():
		await _fail("Pre-KNOWN Burn encounter exposed prompt text")
		return

	if not bool(store.call("mark_known")) or not bool(store.call("is_known")):
		await _fail("Retained contact store could not establish KNOWN")
		return
	runtime.call("process_encounter_state")
	_scene.call("_evaluate_target_selection")
	if not bool(encounter_target.get("is_powered")):
		await _fail("KNOWN on-foot proximity did not power Burn interaction")
		return
	if _scene.get("_active_target") != encounter_target:
		await _fail("Retained active-target arbitration did not select Burn")
		return
	if String(runtime.call("get_affordance_text")) != "BURN // ACTION":
		await _fail("KNOWN Burn prompt is not the bounded Action affordance")
		return

	var start_count := int(runtime.call("get_encounter_start_count"))
	touch_ui.emit_signal("weapon_action_pressed")
	touch_ui.emit_signal("tool_action_pressed")
	touch_ui.emit_signal("strike_pressed")
	var emulated := InputEventMouseButton.new()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = true
	touch_ui.call("_input", emulated)
	if int(runtime.call("get_encounter_start_count")) != start_count:
		await _fail("Non-Action input synthesized Burn interaction")
		return

	var desktop_action := InputEventKey.new()
	desktop_action.keycode = KEY_E
	desktop_action.physical_keycode = KEY_E
	desktop_action.pressed = true
	touch_ui.call("_input", desktop_action)
	await process_frame
	if int(runtime.call("get_encounter_start_count")) != start_count + 1:
		await _fail("Desktop Action did not start exactly one Burn encounter")
		return
	if not bool(runtime.call("is_presentation_visible")):
		await _fail("Clear-state Burn presentation did not open")
		return
	if action_button.visible:
		await _fail("Ordinary Action UI remained visible during Burn character moment")
		return
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != encounter_target:
		await _fail("Burn did not retain active-target ownership during the exchange")
		return
	if String(runtime.call("get_dialogue_speaker")) != CLEAR_LINES[0][0] or String(runtime.call("get_dialogue_line")) != CLEAR_LINES[0][1]:
		await _fail("Clear-state first authored line is wrong")
		return

	for index in [1, 2]:
		runtime.call("advance_dialogue_for_test")
		if String(runtime.call("get_dialogue_speaker")) != CLEAR_LINES[index][0] or String(runtime.call("get_dialogue_line")) != CLEAR_LINES[index][1]:
			await _fail("Clear-state authored line %d is wrong" % (index + 1))
			return

	player.global_position = actor.global_position + Vector3(0.0, 0.0, 8.0)
	runtime.call("process_encounter_state")
	if bool(runtime.call("is_presentation_visible")):
		await _fail("Leaving Burn interaction radius left stale presentation")
		return
	if not action_button.visible:
		await _fail("Burn encounter did not restore ordinary Action UI after leaving")
		return

	player.global_position = actor.global_position + Vector3(0.0, 0.0, 1.6)
	player.velocity = Vector3.ZERO
	if not bool(_wanted.call("request_civic_report", player.global_position)):
		await _fail("Could not create retained Wanted state for refusal proof")
		return
	await process_frame
	await process_frame
	var heat_before := int(_wanted.call("get_heat_level"))
	if heat_before <= 0:
		await _fail("Retained Wanted authority did not enter active Heat")
		return

	runtime.call("process_encounter_state")
	_scene.call("_evaluate_target_selection")
	var before_refusal := int(runtime.call("get_encounter_start_count"))
	touch_ui.emit_signal("action_button_pressed")
	await process_frame
	if int(runtime.call("get_encounter_start_count")) != before_refusal + 1:
		await _fail("Mobile/shared Action did not start Wanted refusal")
		return
	if String(runtime.call("get_dialogue_speaker")) != "BURN" or String(runtime.call("get_dialogue_line")) != REFUSAL:
		await _fail("Wanted refusal text is wrong")
		return
	if action_button.visible:
		await _fail("Wanted refusal leaked ordinary Action UI into the character moment")
		return
	if int(_wanted.call("get_heat_level")) != heat_before:
		await _fail("P18 mutated authoritative Wanted Heat")
		return

	touch_ui.emit_signal("replay_pressed")
	await process_frame
	if bool(runtime.call("is_presentation_visible")):
		await _fail("Full Replay did not clear transient Burn presentation")
		return
	if not bool(store.call("is_known")):
		await _fail("Full Replay incorrectly erased durable KNOWN")
		return

	print("[P18_MAYOR_BURN] PASS")
	await _finish(0)
