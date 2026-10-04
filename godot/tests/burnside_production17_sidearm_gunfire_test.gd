extends SceneTree

const PRODUCTION_SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

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
	push_error("[P17_SIDEARM_GUNFIRE] %s" % message)
	await _finish(1)

func _acquire(runtime: Node, pickup: Node, player: Node3D) -> bool:
	pickup.global_position = player.global_position + Vector3(0.6, 0.3, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	return bool(runtime.call("handle_action_pressed"))

func _run() -> void:
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return
	if _wanted_runtime.has_method("reset_runtime"):
		_wanted_runtime.call("reset_runtime")

	var packed := load(PRODUCTION_SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Production scene could not load")
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame
	await process_frame

	if _wanted_runtime.has_method("bind_to_scene") and not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime could not bind to the P17 production scene")
		return

	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null:
		await _fail("Retained TouchControlsUI missing")
		return
	if not touch_ui.has_signal("weapon_action_pressed"):
		await _fail("Retained input surface lacks weapon_action_pressed")
		return
	if not touch_ui.has_method("set_weapon_action_available"):
		await _fail("Retained input surface lacks weapon availability API")
		return

	var fire_button := _scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/RightTouchArea/FireButton") as Button
	if fire_button == null:
		await _fail("Mobile FireButton missing")
		return

	var sidearm_runtime := _scene.get_node_or_null("GearsSidearmRuntime")
	if sidearm_runtime == null:
		await _fail("GearsSidearmRuntime missing")
		return
	for method_name in [
		"has_sidearm",
		"get_pickup",
		"handle_weapon_action_pressed",
		"get_shot_count",
		"get_ballistic_query_count",
		"get_last_impact_name",
		"process_weapon_state",
	]:
		if not sidearm_runtime.has_method(method_name):
			await _fail("Sidearm runtime lacks %s" % method_name)
			return

	var incident := _scene.get_node_or_null("GearsWorkZoneIncident")
	if incident == null or not incident.has_method("trigger_gunfire_incident"):
		await _fail("Gears work-zone lacks bounded gunfire incident seam")
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
		await _fail("AudioManager lacks SIDEARM_FIRE semantic event")
		return

	var player := _scene.get_node_or_null("Runner") as Node3D
	var pickup := sidearm_runtime.call("get_pickup") as Node
	var crawler := incident.get_node_or_null("GearsCrawler") as CharacterBody3D
	if player == null or pickup == null or crawler == null:
		await _fail("P17 player, pickup, or retained work-zone crawler fixture is missing")
		return

	if bool(sidearm_runtime.call("has_sidearm")) or bool(pickup.call("is_acquired")):
		await _fail("Sidearm must begin physically unacquired")
		return
	if fire_button.visible or not fire_button.disabled:
		await _fail("FIRE must begin unavailable before physical acquisition")
		return

	if not _acquire(sidearm_runtime, pickup, player):
		await _fail("Retained Action arbitration could not acquire the physical sidearm pickup")
		return
	if not bool(sidearm_runtime.call("has_sidearm")) or not bool(pickup.call("is_acquired")) or pickup.visible:
		await _fail("Sidearm acquisition did not establish one truthful held/current-run state")
		return
	if not fire_button.visible or fire_button.disabled:
		await _fail("FIRE did not become available after valid on-foot acquisition")
		return

	# The retained route-sheet modal owns interaction while open; it must suppress
	# firearm input just as it already suppresses Action/Tool.
	if touch_ui.has_method("set_map_modal_active"):
		touch_ui.call("set_map_modal_active", true)
		touch_ui.call("trigger_weapon_action")
		if int(sidearm_runtime.call("get_shot_count")) != 0:
			await _fail("Route-sheet modal leaked firearm input")
			return
		touch_ui.call("set_map_modal_active", false)

	# Player-level input locks also reject fire without faking a shot/query.
	player.set("is_input_locked", true)
	sidearm_runtime.call("process_weapon_state", 0.0)
	if bool(sidearm_runtime.call("handle_weapon_action_pressed")):
		await _fail("Input-locked player fired sidearm")
		return
	if int(sidearm_runtime.call("get_shot_count")) != 0 or int(sidearm_runtime.call("get_ballistic_query_count")) != 0:
		await _fail("Rejected locked input mutated shot/query counts")
		return
	player.set("is_input_locked", false)
	sidearm_runtime.call("process_weapon_state", 0.0)

	# Put the Runner four meters behind the retained P04 crawler and align the
	# visual facing directly through its real collider.
	player.global_position = crawler.global_position + Vector3(0.0, 0.0, 4.0)
	var mesh_pivot := player.get_node_or_null("MeshPivot") as Node3D
	if mesh_pivot != null:
		mesh_pivot.rotation.y = 0.0
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO

	var fire_event: int = int(sound_event["SIDEARM_FIRE"])
	var audio_before := int(audio_mgr.call("get_event_count", fire_event))
	if not bool(sidearm_runtime.call("handle_weapon_action_pressed")):
		await _fail("Valid first sidearm shot was rejected")
		return
	if int(sidearm_runtime.call("get_shot_count")) != 1 or int(sidearm_runtime.call("get_ballistic_query_count")) != 1:
		await _fail("One accepted FIRE did not resolve exactly one ballistic query")
		return
	if int(crawler.get("current_durability")) != 1:
		await _fail("First sidearm hit did not reduce retained crawler durability 2 -> 1")
		return
	if String(sidearm_runtime.call("get_last_impact_name")) != "GearsCrawler":
		await _fail("First sidearm ray did not resolve the retained GearsCrawler ancestor")
		return
	if int(audio_mgr.call("get_event_count", fire_event)) != audio_before + 1:
		await _fail("Accepted FIRE did not route exactly one SIDEARM_FIRE semantic audio event")
		return
	if String(incident.call("get_incident_state_name")) != "ALARMED":
		await _fail("First bounded gunfire did not alarm the local Gears work zone")
		return
	if int(incident.call("get_report_attempt_count")) != 1:
		await _fail("First bounded gunfire did not make exactly one civic Report attempt")
		return
	if int(_wanted_runtime.call("get_heat_level")) != 1:
		await _fail("Live clear-state gunfire Report did not compose into retained Heat 1")
		return

	# Cooldown rejection must not produce a second ray, audio event, or Report.
	if bool(sidearm_runtime.call("handle_weapon_action_pressed")):
		await _fail("Sidearm cooldown accepted an immediate duplicate shot")
		return
	if int(sidearm_runtime.call("get_shot_count")) != 1 	or int(sidearm_runtime.call("get_ballistic_query_count")) != 1 	or int(incident.call("get_report_attempt_count")) != 1 	or int(audio_mgr.call("get_event_count", fire_event)) != audio_before + 1:
		await _fail("Cooldown rejection leaked duplicate ballistic/audio/report side effects")
		return

	# Expire only the sidearm cooldown without advancing the alarmed crawler away
	# from the captured proof line, then use its existing second-hit lifecycle.
	sidearm_runtime.call("process_weapon_state", 0.40)
	if not bool(sidearm_runtime.call("handle_weapon_action_pressed")):
		await _fail("Valid second sidearm shot was rejected after cooldown")
		return
	if int(sidearm_runtime.call("get_shot_count")) != 2 or int(sidearm_runtime.call("get_ballistic_query_count")) != 2:
		await _fail("Second accepted FIRE did not preserve one-ray-per-shot")
		return
	if int(crawler.get("current_durability")) != 0 or int(crawler.get("current_state")) != int(UtilityCrawler.CrawlerState.DISABLED):
		await _fail("Second sidearm hit did not use retained crawler DISABLED lifecycle")
		return
	if int(incident.call("get_report_attempt_count")) != 1:
		await _fail("Repeated gunfire in the active incident spammed civic Reports")
		return

	# Full Replay is the possession reset authority. Exercise the real shared
	# signal so root, incident, and P17 subscribers reset together.
	touch_ui.emit_signal("replay_pressed")
	await process_frame
	await physics_frame
	await process_frame
	if bool(sidearm_runtime.call("has_sidearm")) or bool(pickup.call("is_acquired")) or not pickup.visible:
		await _fail("Full Replay did not restore pickup and clear current-run possession")
		return
	if fire_button.visible or not fire_button.disabled:
		await _fail("Full Replay left FIRE available without possession")
		return
	if int(crawler.get("current_durability")) != int(UtilityCrawler.MAX_DURABILITY):
		await _fail("Full Replay did not restore retained crawler durability")
		return
	if String(incident.call("get_incident_state_name")) != "ROUTINE" or int(incident.call("get_report_attempt_count")) != 0:
		await _fail("Full Replay left stale P17 local incident/report state")
		return

	print("[P17_SIDEARM_GUNFIRE] PASS")
	await _finish(0)
