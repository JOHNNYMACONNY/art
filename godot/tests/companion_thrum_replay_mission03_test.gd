extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const STORE_SCRIPT_PATH := "res://scripts/progress/surveyed_route_progress_store.gd"
const AUDIO_MANAGER_SCRIPT_PATH := "res://scripts/audio/audio_manager.gd"
const ROUTE_ID := "gears.service_alley_north_connector"

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
	push_error("[P08_THRUM_REPLAY_M03] %s" % message)
	await _finish(1)

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		await _fail("Failed to load production scene %s" % SCENE_PATH)
		return

	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await physics_frame
	await process_frame

	var runtime := _scene.get_node_or_null("BurnsideCompanionPresenceRuntime")
	if runtime == null:
		await _fail("BurnsideCompanionPresenceRuntime node missing from scene")
		return

	var fb13 := _scene.get_node_or_null("FB13CompanionBody")
	if fb13 == null:
		await _fail("FB13CompanionBody node missing from scene")
		return

	var runner := _scene.get_node_or_null("Runner") as Node3D
	if runner == null:
		await _fail("Runner node missing from scene")
		return

	var thrum_event := _scene.get_node_or_null("FB13ThrumWorldEvent")
	if thrum_event == null:
		await _fail("FB13ThrumWorldEvent node missing from scene")
		return

	var audio_mgr := _scene.get_node_or_null("AudioManager")
	if audio_mgr == null:
		await _fail("AudioManager node missing from scene")
		return

	# 1. Capture before-state
	var contract_before: Dictionary = thrum_event.call("get_world_event_contract")
	var before_trigger_count: int = int(thrum_event.get("trigger_count"))
	var audio_counts: Dictionary = audio_mgr.get("event_counts")
	var audio_script = load(AUDIO_MANAGER_SCRIPT_PATH)
	var thrum_event_id: int = audio_script.SoundEvent.FB13_THRUM if audio_script else 26
	var before_audio_count: int = int(audio_counts.get(thrum_event_id, 0))
	var before_reaction_count: int = int(fb13.call("get_thrum_reaction_count"))

	# Move runner to primary resonance point
	var primary := _scene.get_node_or_null("GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate") as Node3D
	if primary == null:
		await _fail("CivicUtilityPlate primary resonance point missing")
		return

	runner.global_position = primary.global_position
	for _i in range(10):
		await process_frame
		await physics_frame

	var after_trigger_count: int = int(thrum_event.get("trigger_count"))
	if after_trigger_count != before_trigger_count + 1:
		await _fail("Thrum trigger_count did not increment (before=%d, after=%d)" % [before_trigger_count, after_trigger_count])
		return

	audio_counts = audio_mgr.get("event_counts")
	var after_audio_count: int = int(audio_counts.get(thrum_event_id, 0))
	if after_audio_count != before_audio_count + 1:
		await _fail("AudioManager FB13_THRUM count did not increment by exactly 1 (before=%d, after=%d)" % [before_audio_count, after_audio_count])
		return

	var after_reaction_count: int = int(fb13.call("get_thrum_reaction_count"))
	if after_reaction_count != before_reaction_count + 1:
		await _fail("FB-13 get_thrum_reaction_count did not increment by exactly 1 (before=%d, after=%d)" % [before_reaction_count, after_reaction_count])
		return

	var contract_after: Dictionary = thrum_event.call("get_world_event_contract")
	if contract_before != contract_after:
		await _fail("Thrum world event contract changed after trigger")
		return

	# 2. Seed P06 mapped knowledge store
	var store_script := load(STORE_SCRIPT_PATH)
	if store_script:
		var store = store_script.new()
		store.call("configure")
		store.call("mark_surveyed", ROUTE_ID)

	# Put FB-13 in non-following state (e.g. REJOINING or DOCKING)
	fb13.set("current_state", 1)

	# Full slice reset
	_scene.call("reset_slice")
	await process_frame
	await physics_frame

	# Verify reset state
	if int(fb13.call("get_presence_state")) != 0: # FOLLOWING
		await _fail("FB-13 not in FOLLOWING state after reset_slice (got %d)" % int(fb13.call("get_presence_state")))
		return

	var hs7_socket := runner.get_node_or_null("MeshPivot/Torso/HS7CarrySocket") as Node3D
	if hs7_socket == null or hs7_socket.get_child_count() == 0:
		await _fail("HS-7 carried module missing from carry socket after reset_slice")
		return

	# Verify P06 knowledge remained surveyed
	if store_script:
		var store_check = store_script.new()
		store_check.call("configure")
		if not bool(store_check.call("is_surveyed", ROUTE_ID)):
			await _fail("Mapped knowledge was reset by reset_slice (must persist across full replay)")
			return

	# 3. Mission 03 / HS-7 contract check
	var CityThatForgotContract = load("res://tests/city_that_forgot_mission_contract_test.gd")
	if CityThatForgotContract == null:
		await _fail("CityThatForgotContract missing")
		return
	var m03_err: String = CityThatForgotContract.verify()
	if not m03_err.is_empty():
		await _fail("Mission 03 contract regression: %s" % m03_err)
		return

	print("[P08_THRUM_REPLAY_M03] PASS")
	await _finish(0)
