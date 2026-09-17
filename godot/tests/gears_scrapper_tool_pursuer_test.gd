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
	push_error("[GEARS_SCRAPPER_TOOL_PURSUER] %s" % message)
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

	var player := _scene.get_node_or_null("Runner") as Node3D
	var pursuer := _scene.get_node_or_null("PursuerPrototype") as Node3D
	var runtime := _scene.get_node_or_null("GearsScrapperToolRuntime")
	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	var authority = _wanted_runtime.get("wanted_authority")
	if player == null or pursuer == null or runtime == null or alarm == null or authority == null:
		await _fail("P05 pursuer fixture is incomplete")
		return
	for method_name in ["apply_scrapper_stagger", "is_scrapper_staggered", "get_scrapper_stagger_remaining", "get_scrapper_stagger_velocity"]:
		if not pursuer.has_method(method_name):
			await _fail("Production 05 pursuer seam is absent: %s" % method_name)
			return
	for method_name in ["get_pickup", "acquire_active_pickup", "handle_tool_action_pressed", "process_tool_state", "get_last_contact_name"]:
		if not runtime.has_method(method_name):
			await _fail("Production 05 runtime pursuer seam is absent: %s" % method_name)
			return

	# Non-hostile/non-chase states never accept physical combat-like authority.
	if bool(pursuer.call("apply_scrapper_stagger", Vector3.FORWARD)):
		await _fail("Inactive pursuer accepted Scrapper stagger")
		return
	pursuer.call("activate_pursuit", player)
	if bool(pursuer.call("apply_scrapper_stagger", Vector3.ZERO)):
		await _fail("Zero-direction Scrapper impact was accepted")
		return
	pursuer.call("start_de_escalation")
	if bool(pursuer.call("apply_scrapper_stagger", Vector3.FORWARD)):
		await _fail("De-escalating pursuer accepted Scrapper stagger")
		return

	# Acquire the one physical tool through retained contextual Action.
	var pickup := runtime.call("get_pickup") as Node3D
	if pickup == null:
		await _fail("Scrapper pickup fixture is missing")
		return
	player.global_position = pickup.global_position + Vector3(0.4, 0.0, 0.0)
	pickup.call("update_player_distance", player.global_position)
	_scene.set("_active_target", pickup)
	if not bool(runtime.call("acquire_active_pickup")):
		await _fail("Could not acquire Scrapper for pursuer tracer")
		return

	# A still-active but DE_ESCALATING response asset must not qualify as tool contact.
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if pivot == null:
		await _fail("Player MeshPivot fixture is missing")
		return
	player.global_position = Vector3(18.0, 0.1, -18.0)
	pursuer.global_position = player.global_position + Vector3(0.0, 0.5, -1.1)
	pivot.rotation.y = 0.0
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("De-escalating qualification swing was not accepted")
		return
	runtime.call("process_tool_state", 0.15)
	if String(runtime.call("get_last_contact_name")) == "PURSUER" or bool(pursuer.call("is_scrapper_staggered")):
		await _fail("Non-CHASING/DETOURING pursuer was classified as valid Scrapper contact")
		return
	runtime.call("process_tool_state", 0.50)

	# Reset only the response asset, then establish real Heat-1 Contact through the retained civic Report path.
	pursuer.call("reset_pursuer")
	alarm.set("report_enabled", true)
	alarm.call("reset_alarm")
	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	_scene.set("_active_target", alarm)
	if not bool(_wanted_runtime.call("handle_action_pressed")):
		await _fail("Could not establish retained civic Report for pursuer tracer")
		return
	if int(authority.call("get_heat_level")) != 1 or String(authority.call("get_wanted_state_name")) != "CONTACT" or not bool(pursuer.get("is_active")):
		await _fail("Retained civic Report did not establish Heat 1 + active pursuer")
		return

	var preserved_state := int(pursuer.get("current_state"))
	var preserved_target: Node = pursuer.get("target_node")
	var preserved_heat := int(authority.call("get_heat_level"))
	var preserved_wanted_state := String(authority.call("get_wanted_state_name"))
	var preserved_reason := String(authority.call("get_last_reason"))
	var preserved_known_position := Vector3(authority.call("get_last_known_position"))

	# Out of range: no stagger, exactly a miss.
	player.global_position = Vector3(22.0, 0.1, -22.0)
	pursuer.global_position = player.global_position + Vector3(0.0, 0.5, -3.0)
	pivot.rotation.y = 0.0
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Out-of-range pursuer swing was not accepted")
		return
	runtime.call("process_tool_state", 0.15)
	if String(runtime.call("get_last_contact_name")) != "MISS" or bool(pursuer.call("is_scrapper_staggered")):
		await _fail("Out-of-range pursuer contact qualified")
		return
	runtime.call("process_tool_state", 0.50)

	# Behind captured facing: no stagger.
	pursuer.global_position = player.global_position + Vector3(0.0, 0.5, 1.1)
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Behind-facing pursuer swing was not accepted")
		return
	runtime.call("process_tool_state", 0.15)
	if String(runtime.call("get_last_contact_name")) != "MISS" or bool(pursuer.call("is_scrapper_staggered")):
		await _fail("Behind-facing pursuer contact qualified")
		return
	runtime.call("process_tool_state", 0.50)

	# In range and in front: one brief physical interruption, no authority mutation.
	pursuer.global_position = player.global_position + Vector3(0.0, 0.5, -1.1)
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Valid pursuer swing was not accepted")
		return
	runtime.call("process_tool_state", 0.15)
	if String(runtime.call("get_last_contact_name")) != "PURSUER" or not bool(pursuer.call("is_scrapper_staggered")):
		await _fail("Valid pursuer contact did not create the bounded stagger")
		return
	var stagger_before := float(pursuer.call("get_scrapper_stagger_remaining"))
	if stagger_before <= 0.0 or stagger_before > 0.3001:
		await _fail("Scrapper stagger window exceeded the bounded 0.30 s contract")
		return
	if Vector3(pursuer.call("get_scrapper_stagger_velocity")).length() < 3.0:
		await _fail("Scrapper stagger did not create a material physical shove")
		return

	# Swing recovery is longer than stagger, so repeated input cannot refresh a stun-lock.
	if bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Swing recovery allowed immediate repeated pursuer stun-lock")
		return
	var stagger_origin := pursuer.global_position
	pursuer.call("_physics_process", 0.12)
	if pursuer.global_position.distance_to(stagger_origin) <= 0.01:
		await _fail("Scrapper stagger did not physically displace the pursuer")
		return
	if float(pursuer.call("get_scrapper_stagger_remaining")) >= stagger_before:
		await _fail("Scrapper stagger timer did not decay")
		return
	if int(pursuer.get("current_state")) != preserved_state or pursuer.get("target_node") != preserved_target or not bool(pursuer.get("is_active")):
		await _fail("Scrapper stagger mutated pursuer state/target/active authority")
		return
	if int(authority.call("get_heat_level")) != preserved_heat or String(authority.call("get_wanted_state_name")) != preserved_wanted_state:
		await _fail("Scrapper stagger mutated Heat/Wanted authority")
		return
	if String(authority.call("get_last_reason")) != preserved_reason or Vector3(authority.call("get_last_known_position")).distance_to(preserved_known_position) > 0.001:
		await _fail("Scrapper stagger mutated retained Contact knowledge")
		return

	pursuer.call("_physics_process", 0.20)
	if bool(pursuer.call("is_scrapper_staggered")) or float(pursuer.call("get_scrapper_stagger_remaining")) > 0.0:
		await _fail("Scrapper stagger did not expire automatically")
		return
	if int(pursuer.get("current_state")) != preserved_state or pursuer.get("target_node") != preserved_target or not bool(pursuer.get("is_active")):
		await _fail("Stagger expiry failed to resume retained pursuit state")
		return

	# Once ordinary 0.60 s swing recovery ends, a later discrete hit may stagger again.
	runtime.call("process_tool_state", 0.50)
	pursuer.global_position = player.global_position + Vector3(0.0, 0.5, -1.1)
	if not bool(runtime.call("handle_tool_action_pressed")):
		await _fail("Post-recovery discrete Scrapper swing was not restored")
		return
	runtime.call("process_tool_state", 0.15)
	if not bool(pursuer.call("is_scrapper_staggered")):
		await _fail("Post-recovery discrete pursuer stagger did not occur")
		return

	# Retained pursuer reset deterministically clears the temporary modifier.
	pursuer.call("reset_pursuer")
	if bool(pursuer.call("is_scrapper_staggered")) or Vector3(pursuer.call("get_scrapper_stagger_velocity")).length_squared() > 0.0001:
		await _fail("Pursuer reset left stale Scrapper stagger state")
		return
	if int(authority.call("get_heat_level")) != preserved_heat or String(authority.call("get_wanted_state_name")) != preserved_wanted_state:
		await _fail("Pursuer physical reset mutated Wanted authority")
		return

	print("[GEARS_SCRAPPER_TOOL_PURSUER] PASS")
	await _finish(0)
