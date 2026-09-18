extends SceneTree

const TEST_ROUTE_PATH := "user://tests/p06_player_survivability_integration_test.json"

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup_test_progress() -> void:
	if FileAccess.file_exists(TEST_ROUTE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROUTE_PATH))
	if FileAccess.file_exists(TEST_ROUTE_PATH + ".tmp"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROUTE_PATH + ".tmp"))

func _finish(code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_cleanup_test_progress()
	quit(code)

func _fail(message: String) -> void:
	push_error("[PLAYER_SURVIVABILITY_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n================================================================")
	print("[PLAYER_SURVIVABILITY_INTEGRATION_TEST] Starting...")
	print("================================================================\n")
	_cleanup_test_progress()

	var scene_res := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if scene_res == null:
		await _fail("Could not load retained production scene")
		return
	_scene = scene_res.instantiate()
	root.add_child(_scene)
	await process_frame
	await process_frame

	var player = _scene.get_node_or_null("Runner")
	var safe_root := _scene.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot") as Control
	var survey = _scene.get_node_or_null("GearsSurveyedServiceCutRuntime")
	var mission_runtime = _scene.get_node_or_null("MissionScrapJobRuntime")
	if player == null or safe_root == null or survey == null or mission_runtime == null:
		await _fail("Retained player/safe-area/map/mission fixture is incomplete")
		return

	for method_name in ["apply_damage", "reset_vitals", "set_safe_recovery_enabled"]:
		if not player.has_method(method_name):
			await _fail("PlayerRunner missing survivability method: " + method_name)
			return

	print("--- Stage 1: Armor-first damage, clamping, immunity ---")
	player.reset_vitals(100.0, 30.0)
	var first: Dictionary = player.apply_damage(20.0)
	if not bool(first.get("accepted", false)) or not is_equal_approx(player.current_armor, 10.0) or not is_equal_approx(player.current_health, 100.0):
		await _fail("Armor-first absorption failed")
		return
	var rejected: Dictionary = player.apply_damage(10.0)
	if bool(rejected.get("accepted", true)) or not is_equal_approx(player.current_health, 100.0) or not is_equal_approx(player.current_armor, 10.0):
		await _fail("Hit immunity did not suppress frame-spam damage")
		return
	player._update_survivability(0.60)
	var spill: Dictionary = player.apply_damage(25.0)
	if not bool(spill.get("accepted", false)) or not is_equal_approx(player.current_armor, 0.0) or not is_equal_approx(player.current_health, 85.0):
		await _fail("Armor remainder did not spill exactly into Health")
		return
	player.reset_vitals(999.0, 999.0)
	if not is_equal_approx(player.current_health, player.MAX_HEALTH) or not is_equal_approx(player.current_armor, player.MAX_ARMOR):
		await _fail("Vitals upper clamp failed")
		return
	print("  [PASS] Armor-first damage and immunity")

	print("--- Stage 2: Safe partial Health recovery only ---")
	player.reset_vitals(40.0, 0.0)
	player.apply_damage(1.0)
	player.set_safe_recovery_enabled(false)
	player._update_survivability(10.0)
	if not is_equal_approx(player.current_health, 39.0):
		await _fail("Health recovered while danger was not cleared")
		return
	player.set_safe_recovery_enabled(true)
	player._update_survivability(1.0)
	if player.current_health <= 39.0 or player.current_health > player.SAFE_RECOVERY_CAP or not is_equal_approx(player.current_armor, 0.0):
		await _fail("Safe recovery did not restore bounded Health without Armor")
		return
	player._update_survivability(10.0)
	if not is_equal_approx(player.current_health, player.SAFE_RECOVERY_CAP):
		await _fail("Passive recovery did not stop at its cap")
		return
	print("  [PASS] Partial recovery gate")

	print("--- Stage 3: Existing interception now has consequence ---")
	player.reset_vitals(100.0, 25.0)
	_scene.current_pursuit_state = _scene.PursuitState.PURSUIT_ACTIVE
	_scene._on_pursuer_intercepted()
	if not is_equal_approx(player.current_armor, 0.0) or not is_equal_approx(player.current_health, 90.0):
		await _fail("Pursuer interception did not route 35 damage through Armor first")
		return
	if _scene.current_pursuit_state != _scene.PursuitState.INTERCEPTED:
		await _fail("Nonlethal interception no longer enters retained INTERCEPTED state")
		return
	await create_timer(0.85).timeout
	if _scene.current_pursuit_state != _scene.PursuitState.RETRY_READY:
		await _fail("Nonlethal interception no longer reaches retained RETRY_READY")
		return
	print("  [PASS] Nonlethal interception preserves retry authority")

	print("--- Stage 4: Soft Failure preserves horizontal progress ---")
	var store = survey.call("get_progress_store")
	var route_id := String(survey.call("get_route_id"))
	if store == null or not bool(store.call("mark_surveyed", route_id)):
		await _fail("Could not establish durable mapped-knowledge fixture")
		return
	var mission_phase_before: int = int(mission_runtime.mission.phase)
	var soft_started := [false]
	var soft_recovered := [false]
	_scene.soft_failure_started.connect(func(): soft_started[0] = true)
	_scene.soft_failure_recovered.connect(func(): soft_recovered[0] = true)

	# Continue from Stage 3's real 90 Health / 0 Armor state. Two more
	# nonlethal catches should leave 55 then 20; the following catch depletes.
	for expected_health in [55.0, 20.0]:
		_scene.current_pursuit_state = _scene.PursuitState.PURSUIT_ACTIVE
		_scene._on_pursuer_intercepted()
		if not is_equal_approx(player.current_health, expected_health) or soft_started[0]:
			await _fail("Repeated interception damage did not accumulate predictably")
			return
		await create_timer(0.85).timeout
		if _scene.current_pursuit_state != _scene.PursuitState.RETRY_READY:
			await _fail("Repeated nonlethal interception lost retained retry authority")
			return

	_scene.current_pursuit_state = _scene.PursuitState.PURSUIT_ACTIVE
	_scene._on_pursuer_intercepted()
	if not soft_started[0] or player.current_health != 0.0 or _scene.current_pursuit_state != _scene.PursuitState.INTERCEPTED:
		await _fail("Repeated lethal interception did not enter Soft Failure")
		return
	await create_timer(0.85).timeout
	if not soft_recovered[0] or _scene.current_pursuit_state != _scene.PursuitState.RETRY_READY:
		await _fail("Soft Failure did not recover through retained retry geography")
		return
	if not is_equal_approx(player.current_health, _scene.SOFT_FAILURE_RECOVERY_HEALTH) or not is_equal_approx(player.current_armor, 0.0):
		await _fail("Soft Failure recovery vitals are incorrect")
		return
	if not bool(store.call("is_surveyed", route_id)) or not bool(survey.call("is_route_surveyed")):
		await _fail("Soft Failure erased durable mapped knowledge")
		return
	if int(mission_runtime.mission.phase) != mission_phase_before:
		await _fail("Soft Failure mutated authored mission progression")
		return
	print("  [PASS] Soft Failure preserves horizontal progress")

	print("--- Stage 4B: Non-pursuit depletion returns to CALM ---")
	soft_started[0] = false
	soft_recovered[0] = false
	player.reset_vitals(10.0, 0.0)
	_scene.current_pursuit_state = _scene.PursuitState.CALM
	player.apply_damage(20.0)
	if not soft_started[0] or _scene.current_pursuit_state != _scene.PursuitState.INTERCEPTED:
		await _fail("Generic depleted signal did not enter Soft Failure from CALM")
		return
	await create_timer(0.85).timeout
	if not soft_recovered[0] or _scene.current_pursuit_state != _scene.PursuitState.CALM:
		await _fail("Non-pursuit Soft Failure incorrectly manufactured retry state")
		return
	if not bool(store.call("is_surveyed", route_id)) or int(mission_runtime.mission.phase) != mission_phase_before:
		await _fail("Non-pursuit Soft Failure mutated horizontal progress")
		return
	print("  [PASS] Generic depletion preserves non-pursuit context")

	print("--- Stage 5: Safe-area pointer-transparent HUD ---")
	var hud := safe_root.get_node_or_null("VitalsHUD") as Control
	var health_bar := hud.get_node_or_null("VitalsMargin/VitalsStack/HealthBar") as ProgressBar if hud != null else null
	var armor_bar := hud.get_node_or_null("VitalsMargin/VitalsStack/ArmorBar") as ProgressBar if hud != null else null
	if hud == null or health_bar == null or armor_bar == null:
		await _fail("VitalsHUD is missing from retained SafeAreaRoot")
		return
	if hud.mouse_filter != Control.MOUSE_FILTER_IGNORE or health_bar.mouse_filter != Control.MOUSE_FILTER_IGNORE or armor_bar.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		await _fail("VitalsHUD intercepts gameplay pointer input")
		return
	if not is_equal_approx(health_bar.value, player.current_health) or not is_equal_approx(armor_bar.value, player.current_armor):
		await _fail("VitalsHUD is not synchronized with PlayerRunner authority")
		return
	print("  [PASS] Safe-area HUD")

	print("\n================================================================")
	print("[PLAYER_SURVIVABILITY_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("================================================================\n")
	await _finish(0)
