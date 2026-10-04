extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const INTERCEPTOR_PATH := "res://scenes/vehicles/security_interceptor.tscn"

var _scene: Node = null
var _wanted: Node = null

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P17_SIDEARM_COMPOSITION] %s" % message)
	await _finish(1)

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_scene = null
	if _wanted != null and _wanted.has_method("reset_runtime"):
		_wanted.call("reset_runtime")
	quit(code)

func _fresh_scene() -> Node:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_scene = null
	if _wanted != null and _wanted.has_method("reset_runtime"):
		_wanted.call("reset_runtime")

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

func _fixture(scene: Node) -> Dictionary:
	var runtime := scene.get_node_or_null("GearsSidearmRuntime")
	var player := scene.get_node_or_null("Runner") as CharacterBody3D
	var touch_ui := scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	var incident := scene.get_node_or_null("GearsWorkZoneIncident")
	var crawler := incident.get_node_or_null("GearsCrawler") as CharacterBody3D if incident != null else null
	var worker := incident.get_node_or_null("GearsWorker") as CharacterBody3D if incident != null else null
	var pickup := runtime.call("get_pickup") as Node3D if runtime != null else null
	var fire_button := scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/RightTouchArea/FireButton") as Button
	return {
		"runtime": runtime,
		"player": player,
		"touch_ui": touch_ui,
		"incident": incident,
		"crawler": crawler,
		"worker": worker,
		"pickup": pickup,
		"fire_button": fire_button,
	}

func _fixture_is_complete(f: Dictionary) -> bool:
	for key in ["runtime", "player", "touch_ui", "incident", "crawler", "worker", "pickup", "fire_button"]:
		if f.get(key) == null:
			return false
	return true

func _acquire(scene: Node, f: Dictionary) -> bool:
	var runtime: Node = f["runtime"]
	var player: CharacterBody3D = f["player"]
	var pickup: Node3D = f["pickup"]
	pickup.global_position = player.global_position + Vector3(0.6, 0.3, 0.0)
	pickup.call("update_player_distance", player.global_position)
	scene.set("_active_target", pickup)
	return bool(runtime.call("handle_action_pressed"))

func _face_target(player: CharacterBody3D, target: Vector3, distance: float = 4.0) -> void:
	player.global_position = target + Vector3(0.0, 0.0, distance)
	player.velocity = Vector3.ZERO
	var pivot := player.get_node_or_null("MeshPivot") as Node3D
	if pivot != null:
		pivot.rotation.y = 0.0

func _jam_report(scene: Node, player: CharacterBody3D) -> bool:
	var access := scene.get_node_or_null("CivicReportAccess")
	if access == null:
		return false
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	scene.set("_active_target", access)
	return bool(_wanted.call("handle_action_pressed"))

func _run() -> void:
	_wanted = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return

	# A. Browser touch companions cannot create a second firearm intent, and the
	# sidearm is unavailable while mounted.
	var scene := await _fresh_scene()
	if scene == null:
		await _fail("Could not create touch/possession proof scene")
		return
	var f := _fixture(scene)
	if not _fixture_is_complete(f) or not _acquire(scene, f):
		await _fail("Touch/possession fixture could not acquire sidearm")
		return
	var runtime: Node = f["runtime"]
	var player: CharacterBody3D = f["player"]
	var touch_ui: Node = f["touch_ui"]
	var fire_button: Button = f["fire_button"]

	player.set("is_mounted", true)
	runtime.call("process_weapon_state", 0.0)
	if fire_button.visible or not fire_button.disabled or bool(runtime.call("handle_weapon_action_pressed")):
		await _fail("Mounted player retained a valid firearm action")
		return
	player.set("is_mounted", false)
	runtime.call("process_weapon_state", 0.0)
	if not fire_button.visible or fire_button.disabled:
		await _fail("Dismounted held sidearm did not restore FIRE availability")
		return

	var weapon_signal_count: Array[int] = [0]
	touch_ui.connect("weapon_action_pressed", func(): weapon_signal_count[0] += 1)
	fire_button.pressed.emit()
	if weapon_signal_count[0] != 1:
		await _fail("FireButton did not emit exactly one firearm intent")
		return
	var shot_after_button := int(runtime.call("get_shot_count"))
	var query_after_button := int(runtime.call("get_ballistic_query_count"))
	if fire_button.visible or not fire_button.disabled:
		await _fail("FIRE remained available during the accepted-shot cooldown")
		return
	if bool(runtime.call("handle_weapon_action_pressed")):
		await _fail("Cooldown accepted a second firearm action")
		return
	runtime.call("process_weapon_state", 0.33)
	if not fire_button.visible or fire_button.disabled:
		await _fail("FIRE did not restore when the shot cooldown expired")
		return
	var emulated_down := InputEventMouseButton.new()
	emulated_down.device = InputEvent.DEVICE_ID_EMULATION
	emulated_down.button_index = MOUSE_BUTTON_LEFT
	emulated_down.pressed = true
	touch_ui.call("_input", emulated_down)
	var emulated_up := InputEventMouseButton.new()
	emulated_up.device = InputEvent.DEVICE_ID_EMULATION
	emulated_up.button_index = MOUSE_BUTTON_LEFT
	emulated_up.pressed = false
	touch_ui.call("_input", emulated_up)
	if weapon_signal_count[0] != 1 	or int(runtime.call("get_shot_count")) != shot_after_button 	or int(runtime.call("get_ballistic_query_count")) != query_after_button:
		await _fail("Browser-emulated mouse companion duplicated mobile FIRE")
		return

	# B. Real Soft Failure suppresses FIRE while locked but preserves the
	# current-run sidearm and restores its availability after recovery.
	player.reset_vitals(5.0, 0.0)
	player.apply_damage(10.0)
	await process_frame
	if not bool(runtime.call("has_sidearm")) or not bool(f["pickup"].call("is_acquired")):
		await _fail("Soft Failure erased current-run sidearm possession")
		return
	if fire_button.visible or not fire_button.disabled:
		await _fail("Soft Failure input lock left FIRE available")
		return
	await create_timer(0.85).timeout
	await process_frame
	if not bool(runtime.call("has_sidearm")) or not bool(f["pickup"].call("is_acquired")):
		await _fail("Soft Failure recovery lost sidearm possession")
		return
	if not fire_button.visible or fire_button.disabled:
		await _fail("Soft Failure recovery did not restore valid held-sidearm FIRE")
		return

	# C. Ordinary geometry receives physical impact feedback but no damage seam;
	# the armored interceptor remains outside P17 firearm damage authority.
	scene = await _fresh_scene()
	if scene == null:
		await _fail("Could not create ballistic-safety proof scene")
		return
	f = _fixture(scene)
	if not _fixture_is_complete(f) or not _acquire(scene, f):
		await _fail("Ballistic-safety fixture could not acquire sidearm")
		return
	runtime = f["runtime"]
	player = f["player"]
	var crawler: CharacterBody3D = f["crawler"]
	var crawler_durability_before := int(crawler.get("current_durability"))

	var wall := StaticBody3D.new()
	wall.name = "P17ProofWall"
	wall.collision_layer = 1
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(2.0, 1.4, 0.45)
	wall_shape.shape = wall_box
	wall_shape.position = Vector3(0.0, 0.7, 0.0)
	wall.add_child(wall_shape)
	scene.add_child(wall)
	wall.global_position = Vector3(12.0, 0.0, 8.0)
	_face_target(player, wall.global_position, 4.0)
	player.velocity = Vector3(2.0, 0.0, 0.0)
	await physics_frame
	var moving_velocity := player.velocity
	if not bool(runtime.call("handle_weapon_action_pressed")):
		await _fail("Ordinary-geometry proof shot was rejected")
		return
	if String(runtime.call("get_last_impact_name")) != "P17ProofWall":
		await _fail("Ordinary geometry did not receive a truthful ballistic impact")
		return
	if player.velocity != moving_velocity:
		await _fail("Accepted FIRE altered movement velocity instead of composing with traversal")
		return
	if int(crawler.get("current_durability")) != crawler_durability_before:
		await _fail("Ordinary-geometry shot leaked damage into unrelated crawler state")
		return
	runtime.call("process_weapon_state", 0.40)
	wall.queue_free()
	await process_frame
	await physics_frame

	var interceptor_scene := load(INTERCEPTOR_PATH) as PackedScene
	if interceptor_scene == null:
		await _fail("Security Interceptor scene could not load")
		return
	var interceptor := interceptor_scene.instantiate() as CharacterBody3D
	if interceptor == null:
		await _fail("Security Interceptor fixture could not instantiate")
		return
	interceptor.name = "P17SecurityInterceptorProof"
	scene.add_child(interceptor)
	interceptor.global_position = Vector3(12.0, 0.05, 8.0)
	_face_target(player, interceptor.global_position, 4.0)
	await process_frame
	await physics_frame
	if not bool(runtime.call("handle_weapon_action_pressed")):
		await _fail("Interceptor immunity proof shot was rejected")
		return
	if String(runtime.call("get_last_impact_name")) != "P17SecurityInterceptorProof":
		await _fail("Interceptor was not the resolved physical impact target")
		return
	if int(crawler.get("current_durability")) != crawler_durability_before:
		await _fail("Interceptor shot leaked firearm damage into another target")
		return
	if interceptor.is_in_group("utility_crawlers"):
		await _fail("Security Interceptor incorrectly entered P17 firearm damage authority")
		return
	if scene.get_node_or_null("SidearmTrace") == null or scene.get_node_or_null("SidearmImpact") == null:
		await _fail("Accepted shot did not spawn transient trace/impact feedback")
		return
	runtime.call("reset_runtime")
	await process_frame
	if scene.get_node_or_null("SidearmTrace") != null or scene.get_node_or_null("SidearmImpact") != null:
		await _fail("Full Replay reset retained stale sidearm trace/impact feedback")
		return

	# D. P02 jammed reporting: local physical alarm still happens while city
	# authority remains CLEAR after exactly one accepted Report attempt.
	scene = await _fresh_scene()
	if scene == null:
		await _fail("Could not create jammed-report gunfire scene")
		return
	f = _fixture(scene)
	if not _fixture_is_complete(f):
		await _fail("Jammed-report fixture is incomplete")
		return
	player = f["player"]
	if not _jam_report(scene, player):
		await _fail("Could not physically jam retained civic Report link")
		return
	var alarm := scene.get_node_or_null("CivicServiceAlarm")
	if alarm == null or bool(alarm.get("report_enabled")):
		await _fail("Field Hacking did not establish jammed Report state")
		return
	if not _acquire(scene, f):
		await _fail("Jammed-report fixture could not acquire sidearm")
		return
	runtime = f["runtime"]
	crawler = f["crawler"]
	var worker: CharacterBody3D = f["worker"]
	var incident: Node = f["incident"]
	_face_target(player, crawler.global_position, 4.0)
	if not bool(runtime.call("handle_weapon_action_pressed")):
		await _fail("Jammed-report gunfire shot was rejected")
		return
	if String(incident.call("get_incident_state_name")) != "ALARMED" 	or int(worker.get("current_state")) != 2 	or int(crawler.get("current_state")) != 2:
		await _fail("Jammed Report incorrectly erased local gunfire reaction")
		return
	if int(incident.call("get_report_attempt_count")) != 1 	or int(_wanted.call("get_heat_level")) != 0 	or String(_wanted.call("get_wanted_state_name")) != "CLEAR":
		await _fail("Jammed gunfire did not preserve exactly-one Report attempt + CLEAR city authority")
		return
	if not bool(alarm.get("is_triggered")) or bool(alarm.get("report_enabled")):
		await _fail("Jammed gunfire did not consume retained local alarm-fault behavior")
		return

	# E. Pre-existing Wanted remains authoritative; local gunfire alarms the work
	# zone but does not request a redundant civic Report.
	scene = await _fresh_scene()
	if scene == null:
		await _fail("Could not create pre-existing-Wanted gunfire scene")
		return
	f = _fixture(scene)
	if not _fixture_is_complete(f):
		await _fail("Pre-existing-Wanted fixture is incomplete")
		return
	player = f["player"]
	if not bool(_wanted.call("request_civic_report", player.global_position)):
		await _fail("Could not establish retained Heat-1 fixture")
		return
	if int(_wanted.call("get_heat_level")) != 1:
		await _fail("Retained pre-existing Wanted fixture did not reach Heat 1")
		return
	if not _acquire(scene, f):
		await _fail("Pre-existing-Wanted fixture could not acquire sidearm")
		return
	runtime = f["runtime"]
	crawler = f["crawler"]
	worker = f["worker"]
	incident = f["incident"]
	_face_target(player, crawler.global_position, 4.0)
	if not bool(runtime.call("handle_weapon_action_pressed")):
		await _fail("Pre-existing-Wanted gunfire shot was rejected")
		return
	if String(incident.call("get_incident_state_name")) != "ALARMED" 	or int(worker.get("current_state")) != 2 	or int(crawler.get("current_state")) != 2:
		await _fail("Pre-existing Wanted suppressed local gunfire reaction")
		return
	if int(incident.call("get_report_attempt_count")) != 0 or int(_wanted.call("get_heat_level")) != 1:
		await _fail("Gunfire replaced/reset Wanted or requested a redundant civic Report")
		return

	print("[P17_SIDEARM_COMPOSITION] PASS")
	await _finish(0)
