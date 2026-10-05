extends SceneTree

const OUTPUT_DIR := "res://verification/production20"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")
const PROOF_FOV := 44.0

var _scene: Node = null
var _wanted: Node = null
var _captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P20_SISTER_KAEL_RENDER] %s" % message)
	quit(1)

func _free_scene() -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_scene = null
	if _wanted != null and _wanted.has_method("reset_runtime"):
		_wanted.call("reset_runtime")

func _fresh_fixture() -> Dictionary:
	await _free_scene()
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		return {}
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame
	if _wanted == null or not bool(_wanted.call("bind_to_scene", _scene)):
		return {}

	var city := _scene.get_node_or_null("CityThatForgotRuntime")
	var civic := _scene.get_node_or_null("CivicRepossessionRuntime")
	var witness := _scene.get_node_or_null("SisterKaelWitnessRuntime")
	var player := _scene.get_node_or_null("Runner") as CharacterBody3D
	var release := _scene.get_node_or_null("MemoryReleaseRelay") as Node3D
	var seal := _scene.get_node_or_null("MemorySealRelay") as Node3D
	var core := _scene.get_node_or_null("SilentCore") as Node3D
	var companion := _scene.get_node_or_null("BurnsideCompanionPresenceRuntime")
	var camera := _scene.get_node_or_null("ChinatownCamera3D") as Camera3D
	if city == null or civic == null or witness == null or player == null or release == null 	or seal == null or core == null or companion == null or camera == null:
		return {}
	return {
		"city": city,
		"civic": civic,
		"witness": witness,
		"player": player,
		"release": release,
		"seal": seal,
		"core": core,
		"companion": companion,
		"camera": camera,
	}

func _drive_complete(f: Dictionary) -> bool:
	var civic = f["civic"]
	var city = f["city"]
	civic.set_process(false)
	civic.mission.phase = CivicMissionScript.Phase.COMPLETE
	var mission = city.mission
	var ok: bool = mission.unlock_after_civic_repossession() 		and mission.on_silent_core_activated() 		and mission.on_echo_completed() 		and mission.on_escape_complete()
	if not ok:
		return false
	_scene.set("current_pursuit_state", ScrapTestBlockScript.PursuitState.CALM)
	city.call("_arm_aftermath_choice")
	f["witness"].call("process_witness_state")
	return true

func _frame_site(f: Dictionary, marker_name: String) -> Camera3D:
	var actor := f["witness"].call("get_actor") as Node3D
	if actor == null:
		return null
	var marker := Marker3D.new()
	marker.name = marker_name
	_scene.add_child(marker)
	marker.global_position = (
		actor.global_position
		+ (f["release"] as Node3D).global_position
		+ (f["seal"] as Node3D).global_position
		+ (f["core"] as Node3D).global_position
	) / 4.0
	marker.global_position.y += 0.65

	var camera: Camera3D = f["camera"]
	camera.set_process(true)
	camera.call("reset_camera_instant", marker)
	camera.call("set_interaction_mode", true, marker)
	camera.fov = PROOF_FOV
	camera.set_process(false)
	await process_frame
	await process_frame
	await process_frame
	return camera

func _screen(camera: Camera3D, node: Node3D) -> Vector2:
	if camera == null or node == null or camera.is_position_behind(node.global_position):
		return Vector2(-1.0, -1.0)
	return camera.unproject_position(node.global_position)

func _in_view(camera: Camera3D, node: Node3D) -> bool:
	if camera == null or node == null or not camera.is_position_in_frustum(node.global_position + Vector3(0.0, 0.7, 0.0)):
		return false
	var p := _screen(camera, node)
	var size := root.get_visible_rect().size
	return p.x >= 0.0 and p.y >= 0.0 and p.x <= size.x and p.y <= size.y

func _select_relay(f: Dictionary, relay: Node3D) -> bool:
	var player: CharacterBody3D = f["player"]
	var release: Node3D = f["release"]
	var seal: Node3D = f["seal"]
	player.global_position = relay.global_position
	player.velocity = Vector3.ZERO
	release.call("update_player_distance", player.global_position)
	seal.call("update_player_distance", player.global_position)
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != relay:
		return false
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null:
		return false
	touch_ui.action_button_pressed.emit()
	await process_frame
	f["witness"].call("process_witness_state")
	return true

func _capture(file_name: String, f: Dictionary, camera: Camera3D, outcome: String) -> String:
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return "Rendered viewport is empty for %s" % file_name
	var save_error := image.save_png(OUTPUT_DIR + "/" + file_name)
	if save_error != OK:
		return "Could not save %s: %s" % [file_name, save_error]

	var witness: Node = f["witness"]
	var actor := witness.call("get_actor") as Node3D
	var city = f["city"]
	var companion_snapshot: Dictionary = f["companion"].call("get_runtime_snapshot")
	var entry := {
		"file": file_name,
		"outcome": outcome,
		"aftermath_state": String(city.mission.get_aftermath_state_name()),
		"mission_contact_line": String(city.mission.contact_line),
		"actor_visible": actor != null and actor.visible,
		"actor_in_view": _in_view(camera, actor),
		"release_in_view": _in_view(camera, f["release"]),
		"seal_in_view": _in_view(camera, f["seal"]),
		"core_in_view": _in_view(camera, f["core"]),
		"reaction_mode": String(witness.call("get_reaction_mode")),
		"reaction_line": String(witness.call("get_reaction_line")),
		"reaction_count": int(witness.call("get_reaction_count")),
		"reaction_visible": bool(witness.call("is_reaction_visible")),
		"pose": witness.call("get_pose_snapshot"),
		"release_status": f["release"].call("get_status"),
		"seal_status": f["seal"].call("get_status"),
		"hs7_state": String(companion_snapshot.get("hs7_state", "")),
		"actor_world": actor.global_position if actor != null else Vector3.ZERO,
		"actor_screen": _screen(camera, actor) if actor != null else Vector2(-1.0, -1.0),
	}
	_captures.append(entry)
	return ""

func _run() -> void:
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create P20 proof directory")
		return

	_wanted = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted == null:
		_fail("BurnsideWantedRuntime autoload is missing")
		return

	# 1. Mission complete, retained P16 relays READY, Kael physically witnesses.
	var f := await _fresh_fixture()
	if f.is_empty() or not _drive_complete(f):
		_fail("Could not establish P20 pre-choice fixture")
		return
	var witness: Node = f["witness"]
	var actor := witness.call("get_actor") as Node3D
	if actor == null or not actor.visible:
		_fail("Sister Kael is not physically present at Mission 03 COMPLETE")
		return
	if String(f["city"].mission.get_aftermath_state_name()) != "UNDECIDED":
		_fail("Pre-choice P20 fixture mutated P16 outcome")
		return
	witness.set_process(false)
	var camera := await _frame_site(f, "P20PreChoiceFocus")
	if camera == null or not _in_view(camera, actor) or not _in_view(camera, f["release"]) or not _in_view(camera, f["seal"]):
		_fail("Pre-choice Kael / relays are not readable together")
		return
	var err := await _capture("01_kael_witnesses_ready_relays.png", f, camera, "KAEL_PRESENT_P16_UNDECIDED")
	if not err.is_empty():
		_fail(err)
		return

	# 2. RELEASE remains P16-owned; Kael reads and presents retained contact_line.
	witness.set_process(true)
	if not await _select_relay(f, f["release"]):
		_fail("Could not select retained RELEASE relay")
		return
	if String(f["city"].mission.get_aftermath_state_name()) != "RELEASED":
		_fail("Retained P16 did not commit RELEASED")
		return
	if String(witness.call("get_reaction_mode")) != "RELEASED" 	or String(witness.call("get_reaction_line")) != String(f["city"].mission.contact_line) 	or int(witness.call("get_reaction_count")) != 1:
		_fail("Kael RELEASE reaction is not a single P16-read-only presentation")
		return
	witness.set_process(false)
	camera = await _frame_site(f, "P20ReleaseFocus")
	err = await _capture("02_kael_release_reaction.png", f, camera, "P16_RELEASED_KAEL_REACTS")
	if not err.is_empty():
		_fail(err)
		return
	if not bool(witness.call("is_reaction_visible")):
		_fail("RELEASE reaction capture drifted after framing")
		return

	# 3. Fresh SEAL path proves a materially different reaction/pose with no Report.
	f = await _fresh_fixture()
	if f.is_empty() or not _drive_complete(f):
		_fail("Could not establish P20 SEAL fixture")
		return
	witness = f["witness"]
	if not await _select_relay(f, f["seal"]):
		_fail("Could not select retained SEAL relay")
		return
	if String(f["city"].mission.get_aftermath_state_name()) != "SEALED":
		_fail("Retained P16 did not commit SEALED")
		return
	if String(witness.call("get_reaction_mode")) != "SEALED" 	or String(witness.call("get_reaction_line")) != String(f["city"].mission.contact_line) 	or int(witness.call("get_reaction_count")) != 1:
		_fail("Kael SEAL reaction is not a single P16-read-only presentation")
		return
	witness.set_process(false)
	camera = await _frame_site(f, "P20SealFocus")
	err = await _capture("03_kael_seal_reaction.png", f, camera, "P16_SEALED_KAEL_REACTS")
	if not err.is_empty():
		_fail(err)
		return
	if not bool(witness.call("is_reaction_visible")):
		_fail("SEAL reaction capture drifted after framing")
		return

	var report := {
		"schema_version": 1,
		"source_sha": OS.get_environment("SOURCE_SHA"),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"display_server": DisplayServer.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(),
		"real_playable_scene": true,
		"capture_count": _captures.size(),
		"captures": _captures,
	}
	var report_file := FileAccess.open(OUTPUT_DIR + "/render_report.json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write P20 render report")
		return
	report_file.store_string(JSON.stringify(report, "  ") + "\n")
	report_file.close()

	print("[P20_SISTER_KAEL_RENDER] PASS")
	await _free_scene()
	quit(0)
