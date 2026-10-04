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
	push_error("[P19_SIDEARM_PURSUER_SUPPRESSION] %s" % message)
	await _finish(1)

func _acquire_sidearm(runtime: Node, pickup: Node3D, player: Node3D) -> bool:
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

	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime could not bind to production scene")
		return

	var player := _scene.get_node_or_null("Runner") as Node3D
	var pursuer := _scene.get_node_or_null("PursuerPrototype") as Node3D
	var sidearm_runtime := _scene.get_node_or_null("GearsSidearmRuntime")
	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	var incident := _scene.get_node_or_null("GearsWorkZoneIncident")
	var crawler := incident.get_node_or_null("GearsCrawler") as Node3D if incident != null else null
	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var authority = _wanted_runtime.get("wanted_authority")
	if player == null or pursuer == null or sidearm_runtime == null or alarm == null or incident == null or crawler == null or touch_ui == null or authority == null:
		await _fail("P19 fixture is incomplete")
		return

	for method_name in ["apply_sidearm_suppression", "is_sidearm_suppressed", "get_sidearm_suppression_remaining"]:
		if not pursuer.has_method(method_name):
			await _fail("Missing locked P19 pursuer seam: %s" % method_name)
			return

	var pickup := sidearm_runtime.call("get_pickup") as Node3D
	if pickup == null or not _acquire_sidearm(sidearm_runtime, pickup, player):
		await _fail("Could not acquire retained P17 sidearm")
		return

	# Inactive response assets never accept the firearm modifier.
	if bool(pursuer.call("apply_sidearm_suppression")):
		await _fail("Inactive pursuer accepted P19 suppression")
		return

	# Establish real retained Heat 1 + Contact through the civic Report path.
	alarm.set("report_enabled", true)
	alarm.call("reset_alarm")
	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	_scene.set("_active_target", alarm)
	if not bool(_wanted_runtime.call("handle_action_pressed")):
		await _fail("Could not establish retained civic Report")
		return
	if int(authority.call("get_heat_level")) != 1 or String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("Retained Report did not establish Heat 1 + CONTACT")
		return

	# Use the retained P17 crawler firing lane as the known unobstructed ballistic
	# fixture. Move only the crawler test actor aside, then occupy its proven
	# collider slot with the retained physical pursuer.
	var ballistic_target_position := crawler.global_position
	crawler.global_position += Vector3(20.0, 0.0, 20.0)
	pursuer.global_position = ballistic_target_position
	player.global_position = ballistic_target_position + Vector3(0.0, 0.0, 4.0)
	await physics_frame
	await process_frame
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if pivot != null:
		pivot.rotation.y = 0.0
	if not bool(_wanted_runtime.call("has_direct_observation", pursuer, player)):
		await _fail("P19 clear-road ballistic fixture is unexpectedly occluded")
		return
	_wanted_runtime.call("process_wanted", 0.1)
	if String(authority.call("get_wanted_state_name")) != "CONTACT" or pursuer.get("target_node") != player:
		await _fail("Retained Wanted logic did not establish direct CONTACT tracking")
		return

	var pursuer_constants = pursuer.get_script().get_script_constant_map()
	var sidearm_constants = sidearm_runtime.get_script().get_script_constant_map()
	var wanted_constants = _wanted_runtime.get_script().get_script_constant_map()
	if not pursuer_constants.has("SIDEARM_SUPPRESSION_SEC") or not pursuer_constants.has("SIDEARM_SUPPRESSION_TRANSLATION_SCALE"):
		await _fail("P19 suppression constants are missing")
		return
	var suppression_sec := float(pursuer_constants["SIDEARM_SUPPRESSION_SEC"])
	var suppression_scale := float(pursuer_constants["SIDEARM_SUPPRESSION_TRANSLATION_SCALE"])
	var fire_cooldown := float(sidearm_constants.get("FIRE_COOLDOWN_SEC", 0.0))
	var contact_loss_grace := float(wanted_constants.get("CONTACT_LOSS_GRACE_SECONDS", 0.0))
	if absf(suppression_sec - 0.18) > 0.001 or absf(suppression_scale - 0.35) > 0.001:
		await _fail("P19 locked 0.18 s / 35%% translation tuning drifted")
		return
	if suppression_sec >= fire_cooldown or suppression_sec >= contact_loss_grace:
		await _fail("P19 timing can overlap FIRE cadence or CONTACT-loss authority window")
		return

	var max_speed := float(pursuer.get("max_speed"))
	var runner_speed := float(player.get("move_speed"))
	var repeated_fire_average := (
		max_speed * suppression_scale * suppression_sec
		+ max_speed * (fire_cooldown - suppression_sec)
	) / fire_cooldown
	if repeated_fire_average <= runner_speed:
		await _fail("Locked P19 cadence could let repeated fire win an open-road foot chase")
		return

	var preserved_state := int(pursuer.get("current_state"))
	var preserved_target: Node = pursuer.get("target_node")
	var preserved_reason := String(authority.call("get_last_reason"))
	var preserved_known_position := Vector3(authority.call("get_last_known_position"))
	pursuer.set("current_speed", max_speed)

	var shots_before := int(sidearm_runtime.call("get_shot_count"))
	var queries_before := int(sidearm_runtime.call("get_ballistic_query_count"))
	if not bool(sidearm_runtime.call("handle_weapon_action_pressed")):
		await _fail("Valid retained FIRE was rejected")
		return
	if int(sidearm_runtime.call("get_shot_count")) != shots_before + 1 or int(sidearm_runtime.call("get_ballistic_query_count")) != queries_before + 1:
		await _fail("P19 changed P17 one-shot / one-ray ownership")
		return
	if String(sidearm_runtime.call("get_last_impact_name")) != "PursuerPrototype":
		await _fail("Physical sidearm ray did not resolve the pursuer ancestor; impact=%s" % String(sidearm_runtime.call("get_last_impact_name")))
		return
	if not bool(pursuer.call("is_sidearm_suppressed")):
		await _fail("Valid sidearm hit did not create bounded pursuer suppression")
		return
	if bool(pursuer.call("is_scrapper_staggered")):
		await _fail("Sidearm hit incorrectly synthesized P05 Scrapper displacement")
		return
	if int(pursuer.get("current_state")) != preserved_state or pursuer.get("target_node") != preserved_target or not bool(pursuer.get("is_active")):
		await _fail("P19 mutated pursuer chase/target/active authority")
		return
	if int(authority.call("get_heat_level")) != 1 or String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("P19 sidearm hit directly mutated Heat/Wanted state")
		return
	if String(authority.call("get_last_reason")) != preserved_reason or Vector3(authority.call("get_last_known_position")).distance_to(preserved_known_position) > 0.001:
		await _fail("P19 sidearm hit mutated retained Contact knowledge")
		return

	# Immediate repeated FIRE is still owned by P17 cooldown.
	if bool(sidearm_runtime.call("handle_weapon_action_pressed")):
		await _fail("P19 bypassed retained FIRE cooldown")
		return

	# During suppression, translation is reduced but retained current_speed is not reset.
	var speed_before := float(pursuer.get("current_speed"))
	var suppression_origin := pursuer.global_position
	pursuer.call("_physics_process", suppression_sec * 0.5)
	var suppressed_velocity := Vector3(pursuer.get("velocity")).length()
	if suppressed_velocity > max_speed * suppression_scale + 0.15:
		await _fail("P19 suppression exceeded locked translation scale")
		return
	if pursuer.global_position.distance_to(suppression_origin) <= 0.01:
		await _fail("P19 suppression became a full stop instead of bounded hesitation")
		return
	if absf(float(pursuer.get("current_speed")) - speed_before) > 0.001:
		await _fail("P19 suppression reset retained chase speed and could compound into pinning")
		return

	pursuer.call("_physics_process", suppression_sec * 0.6)
	if bool(pursuer.call("is_sidearm_suppressed")) or float(pursuer.call("get_sidearm_suppression_remaining")) > 0.0:
		await _fail("P19 suppression did not expire automatically")
		return
	if absf(float(pursuer.get("current_speed")) - speed_before) > 0.001:
		await _fail("P19 suppression expiry did not preserve chase speed")
		return

	# A normal chase frame resumes before FIRE cooldown is available again.
	pursuer.call("_physics_process", 0.05)
	if Vector3(pursuer.get("velocity")).length() < max_speed * 0.9:
		await _fail("Pursuer did not regain ordinary chase translation after suppression")
		return

	# Clear LOS plus any amount of P19 hit response remains CONTACT.
	for _i in range(3):
		_wanted_runtime.call("process_wanted", 0.4)
	if String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("P19 suppression synthesized SEARCH while direct observation remained clear")
		return

	# P05 remains the stronger close-range body-space verb; overlapping P19 is rejected.
	if not bool(pursuer.call("apply_scrapper_stagger", Vector3.FORWARD)):
		await _fail("Retained P05 Scrapper stagger was unavailable")
		return
	if bool(pursuer.call("apply_sidearm_suppression")):
		await _fail("P19 stacked on top of active P05 Scrapper stagger")
		return
	pursuer.call("clear_scrapper_stagger")

	# Only real geometry + retained 0.8 s observation grace may produce SEARCH.
	pursuer.global_position = Vector3(-4.5, 0.5, -35.0)
	player.global_position = Vector3(-17.0, 0.1, -35.0)
	if bool(_wanted_runtime.call("has_direct_observation", pursuer, player)):
		await _fail("Commercial Frontage did not physically break P19 proof LOS")
		return
	for _i in range(3):
		_wanted_runtime.call("process_wanted", 0.4)
	if String(authority.call("get_wanted_state_name")) != "SEARCH" or int(authority.call("get_heat_level")) != 1:
		await _fail("Retained physical LOS loss did not authoritatively produce SEARCH")
		return

	# Reacquisition also remains retained Wanted authority.
	pursuer.global_position = Vector3(-4.5, 0.5, -33.0)
	player.global_position = Vector3(-4.5, 0.1, -29.0)
	_wanted_runtime.call("process_wanted", 0.1)
	if String(authority.call("get_wanted_state_name")) != "CONTACT" or pursuer.get("target_node") != player:
		await _fail("Retained physical observation did not reacquire CONTACT")
		return

	# Full Replay must clear transient P19 state through existing owners.
	if not bool(pursuer.call("apply_sidearm_suppression")):
		await _fail("Could not establish P19 replay-reset fixture")
		return
	touch_ui.emit_signal("replay_pressed")
	await process_frame
	await physics_frame
	await process_frame
	if bool(pursuer.call("is_sidearm_suppressed")):
		await _fail("Full Replay left stale P19 suppression")
		return
	if int(authority.call("get_heat_level")) != 0 or String(authority.call("get_wanted_state_name")) != "CLEAR":
		await _fail("Full Replay failed retained Wanted reset")
		return
	if bool(sidearm_runtime.call("has_sidearm")):
		await _fail("Full Replay failed retained P17 possession reset")
		return

	print("[P19_SIDEARM_PURSUER_SUPPRESSION] PASS")
	await _finish(0)
