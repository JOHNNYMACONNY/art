extends SceneTree

const OUTPUT_DIR := "res://verification/production18"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

var _scene: Node = null
var _wanted: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P18_MAYOR_BURN_RENDER] %s" % message)
	quit(1)

func _free_scene() -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_scene = null
	if _wanted != null and _wanted.has_method("reset_runtime"):
		_wanted.call("reset_runtime")

func _fresh_scene() -> Node:
	await _free_scene()
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		return null
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame
	if _wanted != null and _wanted.has_method("bind_to_scene"):
		if not bool(_wanted.call("bind_to_scene", _scene)):
			return null
	return _scene

func _frame_actor(scene: Node, actor: Node3D) -> Camera3D:
	var camera := scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	if camera == null or actor == null:
		return null
	camera.set_process(true)
	camera.call("reset_camera_instant", actor)
	camera.call("set_interaction_mode", true, actor)
	camera.fov = 40.0
	await process_frame
	await process_frame
	await process_frame
	return camera

func _capture(file_name: String, scene: Node, runtime: Node, camera: Camera3D, outcome: String) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var save_error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]
	var actor := runtime.call("get_actor") as Node3D
	var entry := {
		"file": file_name,
		"outcome": outcome,
		"actor_visible": actor != null and actor.visible,
		"actor_in_frustum": camera != null and actor != null and camera.is_position_in_frustum(actor.global_position + Vector3(0.0, 1.2, 0.0)),
		"affordance": String(runtime.call("get_affordance_text")),
		"speaker": String(runtime.call("get_dialogue_speaker")),
		"line": String(runtime.call("get_dialogue_line")),
		"presentation_visible": bool(runtime.call("is_presentation_visible")),
		"heat": int(_wanted.call("get_heat_level")),
		"wanted_state": String(_wanted.call("get_wanted_state_name")),
	}
	_captures.append(entry)
	return ""

func _run() -> void:
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create proof directory")
		return

	_wanted = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted == null:
		_fail("BurnsideWantedRuntime autoload is missing")
		return

	var scene := await _fresh_scene()
	if scene == null:
		_fail("Could not instantiate production scene")
		return
	var runtime := scene.get_node_or_null("MayorBurnEncounterRuntime")
	var contact_runtime := scene.get_node_or_null("MayorBurnContactServiceRuntime")
	var player := scene.get_node_or_null("Runner") as CharacterBody3D
	if runtime == null or contact_runtime == null or player == null:
		_fail("P18 render fixture is incomplete")
		return
	var actor := runtime.call("get_actor") as Node3D
	if actor == null:
		_fail("Physical Mayor Burn actor is missing")
		return
	var store = contact_runtime.call("get_progress_store")
	if store == null:
		_fail("Retained contact store is missing")
		return

	var camera := await _frame_actor(scene, actor)
	if camera == null:
		_fail("Could not frame Mayor Burn")
		return
	var error := await _capture("01_burn_present_preknown.png", scene, runtime, camera, "PHYSICAL_BURN_PREKNOWN")
	if not error.is_empty():
		_fail(error)
		return

	if not bool(store.call("mark_known")) and not bool(store.call("is_known")):
		_fail("Could not establish retained KNOWN for render proof")
		return
	player.global_position = actor.global_position + Vector3(0.0, 0.0, 1.6)
	player.velocity = Vector3.ZERO
	runtime.call("process_encounter_state")
	scene.call("_evaluate_target_selection")
	if not bool(runtime.call("handle_action_pressed")):
		_fail("Could not start clear Burn exchange")
		return
	camera = await _frame_actor(scene, actor)
	error = await _capture("02_burn_known_clear.png", scene, runtime, camera, "KNOWN_CLEAR_FIRST_LINE")
	if not error.is_empty():
		_fail(error)
		return

	runtime.call("advance_dialogue_for_test")
	runtime.call("advance_dialogue_for_test")
	error = await _capture("03_burn_clear_final_line.png", scene, runtime, camera, "KNOWN_CLEAR_FINAL_LINE")
	if not error.is_empty():
		_fail(error)
		return

	runtime.call("reset_encounter_presentation")
	if not bool(_wanted.call("request_civic_report", player.global_position)):
		_fail("Could not create retained Wanted state")
		return
	await process_frame
	await process_frame
	runtime.call("process_encounter_state")
	scene.call("_evaluate_target_selection")
	if not bool(runtime.call("handle_action_pressed")):
		_fail("Could not start Wanted refusal")
		return
	error = await _capture("04_burn_wanted_refusal.png", scene, runtime, camera, "WANTED_REFUSAL")
	if not error.is_empty():
		_fail(error)
		return

	var report := {
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"capture_count": _captures.size(),
		"captures": _captures,
	}
	var file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if file == null:
		_fail("Could not write render report")
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()

	print("[P18_MAYOR_BURN_RENDER] PASS")
	await _free_scene()
	quit(0)
