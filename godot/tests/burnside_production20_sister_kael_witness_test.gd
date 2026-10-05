extends SceneTree

const PRODUCTION_SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const CityMissionScript = preload("res://scripts/missions/city_that_forgot_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")

var _scene: Node = null
var _wanted: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_scene = null
	if _wanted != null and _wanted.has_method("reset_runtime"):
		_wanted.call("reset_runtime")
	quit(code)

func _fail(message: String) -> void:
	push_error("[P20_SISTER_KAEL_WITNESS] %s" % message)
	await _finish(1)

func _fresh_fixture() -> Dictionary:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	if _wanted != null:
		_wanted.call("reset_runtime")

	var packed := load(PRODUCTION_SCENE_PATH) as PackedScene
	if packed == null:
		return {}
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	if _wanted != null and not bool(_wanted.call("bind_to_scene", _scene)):
		return {}

	var city := _scene.get_node_or_null("CityThatForgotRuntime")
	var civic := _scene.get_node_or_null("CivicRepossessionRuntime")
	var witness := _scene.get_node_or_null("SisterKaelWitnessRuntime")
	var player := _scene.get_node_or_null("Runner") as CharacterBody3D
	var release := _scene.get_node_or_null("MemoryReleaseRelay")
	var seal := _scene.get_node_or_null("MemorySealRelay")
	var companion := _scene.get_node_or_null("BurnsideCompanionPresenceRuntime")
	var core_socket := _scene.get_node_or_null("GearsDistrictSlice01B/SilentCoreSite/SilentCoreSocket") as Marker3D
	if city == null or civic == null or witness == null or player == null or release == null or seal == null or companion == null or core_socket == null:
		return {}
	return {
		"scene": _scene,
		"city": city,
		"civic": civic,
		"witness": witness,
		"player": player,
		"release": release,
		"seal": seal,
		"companion": companion,
		"socket": core_socket,
	}

func _drive_city_to_complete(f: Dictionary) -> bool:
	var civic = f["civic"]
	var city = f["city"]
	civic.set_process(false)
	civic.mission.phase = CivicMissionScript.Phase.COMPLETE
	var mission = city.mission
	var ok: bool = mission.unlock_after_civic_repossession() 		and mission.on_silent_core_activated() 		and mission.on_echo_completed() 		and mission.on_escape_complete()
	if not ok:
		return false
	f["scene"].set("current_pursuit_state", ScrapTestBlockScript.PursuitState.CALM)
	city.call("_arm_aftermath_choice")
	f["witness"].call("process_witness_state")
	return true

func _select_relay(f: Dictionary, relay: Node) -> bool:
	var player: CharacterBody3D = f["player"]
	var other: Node = f["seal"] if relay == f["release"] else f["release"]
	player.global_position = relay.global_position
	player.velocity = Vector3.ZERO
	relay.call("update_player_distance", player.global_position)
	other.call("update_player_distance", player.global_position)
	f["scene"].call("_evaluate_target_selection")
	if f["scene"].get("_active_target") != relay:
		return false
	var touch_ui: Node = f["scene"].get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null:
		return false
	touch_ui.action_button_pressed.emit()
	await process_frame
	f["witness"].call("process_witness_state")
	return true

func _assert_base_witness(f: Dictionary) -> String:
	var witness: Node = f["witness"]
	for method_name in [
		"get_actor",
		"process_witness_state",
		"get_reaction_mode",
		"get_reaction_line",
		"get_reaction_count",
		"is_reaction_visible",
		"get_pose_snapshot",
	]:
		if not witness.has_method(method_name):
			return "Missing P20 witness seam: %s" % method_name

	var actor := witness.call("get_actor") as Node3D
	if actor == null:
		return "Sister Kael physical actor is missing"
	if actor.visible:
		return "Sister Kael is visible before Mission 03 COMPLETE"

	var interactables = f["scene"].get("_interactables")
	if not (interactables is Array):
		return "Retained interaction registry is unavailable"
	if interactables.has(actor) or interactables.has(witness):
		return "P20 registered Sister Kael as an Action target"

	var companion_snapshot: Dictionary = f["companion"].call("get_runtime_snapshot")
	if String(companion_snapshot.get("hs7_state", "")) != "CARRIED":
		return "P20 fixture lost retained HS-7 carried presence"
	return ""

func _run_outcome(choice: String) -> Dictionary:
	var f := await _fresh_fixture()
	if f.is_empty():
		return {"error": "Production P20 fixture is incomplete"}

	var base_error := _assert_base_witness(f)
	if not base_error.is_empty():
		return {"error": base_error}

	if not _drive_city_to_complete(f):
		return {"error": "Could not drive retained Mission 03 to COMPLETE"}

	var witness: Node = f["witness"]
	var actor := witness.call("get_actor") as Node3D
	if actor == null or not actor.visible:
		return {"error": "Sister Kael did not become physically present after Mission 03 COMPLETE"}

	var expected_position := (f["socket"] as Marker3D).global_position + Vector3(1.25, -0.15, -0.85)
	if actor.global_position.distance_to(expected_position) > 0.02:
		return {"error": "Sister Kael drifted from locked Silent Core staging"}

	var interactables = f["scene"].get("_interactables")
	if interactables.has(actor) or interactables.has(witness):
		return {"error": "Sister Kael stole retained target arbitration after appearing"}

	if String(f["city"].mission.get_aftermath_state_name()) != "UNDECIDED":
		return {"error": "P20 mutated P16 aftermath before relay Action"}

	var selected: Node = f["release"] if choice == "RELEASE" else f["seal"]
	if not await _select_relay(f, selected):
		return {"error": "Retained P16 %s relay did not remain authoritative" % choice}

	var expected_state := "RELEASED" if choice == "RELEASE" else "SEALED"
	if String(f["city"].mission.get_aftermath_state_name()) != expected_state:
		return {"error": "P16 did not authoritatively commit %s" % expected_state}
	if String(witness.call("get_reaction_mode")) != expected_state:
		return {"error": "Kael did not react to observed P16 %s state" % expected_state}
	if int(witness.call("get_reaction_count")) != 1:
		return {"error": "Kael reaction was not exactly once"}
	if String(witness.call("get_reaction_line")) != String(f["city"].mission.contact_line):
		return {"error": "Kael authored duplicate reaction copy instead of presenting retained P16 contact_line"}
	if not bool(witness.call("is_reaction_visible")):
		return {"error": "Kael automatic reaction presentation is not visible"}

	var pose: Dictionary = witness.call("get_pose_snapshot")
	if String(pose.get("mode", "")) != expected_state:
		return {"error": "Kael outcome pose does not match %s" % expected_state}

	# No extra Action is required or consumed by Kael. Re-processing cannot
	# duplicate the already-observed outcome reaction.
	witness.call("process_witness_state")
	if int(witness.call("get_reaction_count")) != 1:
		return {"error": "P20 duplicated reaction without a new P16 outcome"}

	return {
		"fixture": f,
		"pose": pose,
		"line": String(witness.call("get_reaction_line")),
	}

func _run() -> void:
	_wanted = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted == null:
		await _fail("BurnsideWantedRuntime autoload missing")
		return

	var release_result := await _run_outcome("RELEASE")
	if release_result.has("error"):
		await _fail(String(release_result["error"]))
		return
	var release_pose: Dictionary = release_result["pose"]

	# Full Replay clears P20 transient presentation and retained P16 aftermath.
	var release_fixture: Dictionary = release_result["fixture"]
	release_fixture["civic"].set_process(true)
	release_fixture["scene"].call("reset_slice")
	await process_frame
	await physics_frame
	await process_frame
	release_fixture["witness"].call("process_witness_state")
	if String(release_fixture["city"].mission.get_aftermath_state_name()) != "UNDECIDED":
		await _fail("Full Replay did not restore retained P16 UNDECIDED")
		return
	if int(release_fixture["witness"].call("get_reaction_count")) != 0 	or String(release_fixture["witness"].call("get_reaction_mode")) != "" 	or bool(release_fixture["witness"].call("is_reaction_visible")):
		await _fail("Full Replay leaked transient Sister Kael reaction state")
		return
	var reset_actor := release_fixture["witness"].call("get_actor") as Node3D
	if reset_actor == null or reset_actor.visible:
		await _fail("Full Replay left Sister Kael visible before Mission 03 COMPLETE")
		return

	var seal_result := await _run_outcome("SEAL")
	if seal_result.has("error"):
		await _fail(String(seal_result["error"]))
		return
	var seal_pose: Dictionary = seal_result["pose"]

	if absf(float(release_pose.get("head_z", 0.0)) - float(seal_pose.get("head_z", 0.0))) < 0.05 	and absf(float(release_pose.get("right_arm_z", 0.0)) - float(seal_pose.get("right_arm_z", 0.0))) < 0.05:
		await _fail("RELEASE and SEAL do not produce materially distinct Kael staging")
		return

	print("[P20_SISTER_KAEL_WITNESS] PASS")
	await _finish(0)
