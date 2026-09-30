extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const CLAIM_TEST_PATH := "user://tests/p11_burnside_checkpoint_courier_recognition_test.json"

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _cleanup() -> void:
	for path in [CLAIM_TEST_PATH, CLAIM_TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _finish(code: int) -> void:
	if _wanted_runtime != null:
		if _wanted_runtime.has_method("reset_runtime"):
			_wanted_runtime.call("reset_runtime")
		_wanted_runtime.set_process(true)
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	_cleanup()
	quit(code)

func _fail(message: String) -> void:
	push_error("[P15_CHECKPOINT_RECOGNITION] " + message)
	await _finish(1)

func _set_on_foot(player: Node, bike: Node, hauler: Node) -> void:
	if bike != null:
		bike.set("occupant", null)
	if hauler != null:
		hauler.set("occupant", null)
	player.set("is_mounted", false)
	_scene.set("active_vehicle", null)

func _set_active_vehicle(player: Node, vehicle: Node, other_vehicle: Node = null) -> void:
	if other_vehicle != null:
		other_vehicle.set("occupant", null)
	vehicle.set("occupant", player)
	player.set("is_mounted", true)
	_scene.set("active_vehicle", vehicle)

func _rearm_from_far(event: Node, active_entity: Node3D, checkpoint: Node3D) -> void:
	active_entity.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 14.0)
	event.call("_process", 8.1)

func _run() -> void:
	_cleanup()
	_wanted_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _wanted_runtime == null:
		await _fail("BurnsideWantedRuntime autoload is missing")
		return

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
	await process_frame

	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to production scene")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")

	var event := _scene.get_node_or_null("SecurityCheckpointWorldEvent")
	var checkpoint := _scene.get_node_or_null("GearsDistrictSlice01B/StreetClutter/SecurityCheckpoint") as Node3D
	var player := _scene.get_node_or_null("Runner")
	var bike = _scene.get("courier_bike")
	var hauler = _scene.get("scrap_hauler")
	var claim_runtime := _scene.get_node_or_null("BurnGarageCourierBikeClaimRuntime")
	var alarm := _scene.get_node_or_null("CivicServiceAlarm")
	var access := _scene.get_node_or_null("CivicReportAccess")
	if event == null or checkpoint == null or player == null or bike == null or hauler == null or claim_runtime == null or alarm == null or access == null:
		await _fail("Production composition is missing checkpoint / player / vehicles / claim / civic-report dependencies")
		return

	for method_name in [
		"is_courier_bike_watchlisted",
		"get_watchlist_report_attempt_count",
		"get_watchlist_label_text",
		"ram_breach",
		"pay_toll",
		"reset_world_event",
	]:
		if not event.has_method(method_name):
			await _fail("P15 checkpoint seam missing: " + method_name)
			return

	var claim_store = claim_runtime.call("get_progress_store")
	if claim_store == null:
		await _fail("P11 claim store is unavailable")
		return
	if String(claim_store.call("get_storage_path")) != CLAIM_TEST_PATH:
		await _fail("P11 claim fixture did not use isolated P15 test storage")
		return
	if bool(claim_store.call("is_claimed")):
		await _fail("P15 fixture unexpectedly began with claimed Courier Bike")
		return

	var authority = _wanted_runtime.get("wanted_authority")
	if authority == null:
		await _fail("P01 WantedAuthority is unavailable")
		return

	# Retained ordinary first approach remains the toll standoff.
	event.call("reset_world_event", true)
	_set_on_foot(player, bike, hauler)
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.1)
	if int(event.get("current_state")) != 1:
		await _fail("Ordinary first approach no longer enters retained STANDOFF")
		return
	event.call("reset_world_event")

	# An unclaimed Courier Bike can breach, but must not establish P15 recognition.
	_set_active_vehicle(player, bike, hauler)
	bike.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.1)
	if not bool(event.call("ram_breach", 8.5)):
		await _fail("Retained high-speed Courier Bike breach failed")
		return
	if bool(event.call("is_courier_bike_watchlisted")):
		await _fail("Unclaimed Courier Bike breach incorrectly armed P15 watchlist")
		return
	if int(_scene.get("current_pursuit_state")) != 0:
		await _fail("Checkpoint breach still entered legacy root pursuit instead of P01 authority")
		return
	if int(authority.call("get_heat_level")) != 1 or String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("Checkpoint breach did not create Heat 1 + Contact through retained civic Report authority")
		return
	_wanted_runtime.call("reset_runtime")
	event.call("reset_world_event")

	# Establish authoritative P11 ownership directly in its isolated production store.
	if not bool(claim_store.call("mark_claimed")) or not bool(claim_store.call("is_claimed")):
		await _fail("Could not establish claimed Courier Bike fixture")
		return

	# Claimed Courier breach arms local memory and still uses P01/P02 authority.
	_set_active_vehicle(player, bike, hauler)
	bike.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.1)
	if int(event.get("current_state")) != 1:
		await _fail("Claimed Bike approach did not enter STANDOFF before breach")
		return
	if not bool(event.call("ram_breach", 8.5)):
		await _fail("Claimed Courier Bike breach failed")
		return
	if not bool(event.call("is_courier_bike_watchlisted")):
		await _fail("Claimed Courier Bike breach did not arm checkpoint recognition")
		return
	if int(authority.call("get_heat_level")) != 1:
		await _fail("Claimed breach lost retained civic Report consequence")
		return

	# Simulate completed evasion through the P01 authority reset seam, then ordinary rearm.
	_wanted_runtime.call("reset_runtime")
	_rearm_from_far(event, bike, checkpoint)
	if int(event.get("current_state")) != 0:
		await _fail("Ordinary cooldown/distance recovery did not rearm checkpoint")
		return
	if not bool(event.call("is_courier_bike_watchlisted")):
		await _fail("Ordinary checkpoint rearm erased temporary claimed-Bike memory")
		return

	# Same claimed Bike returns: local recognition + one civic Report.
	bike.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.1)
	if int(event.get("current_state")) != 5:
		await _fail("Watchlisted claimed Bike return did not enter WATCHLISTED")
		return
	if int(event.call("get_watchlist_report_attempt_count")) != 1:
		await _fail("WATCHLISTED encounter did not request exactly one civic Report")
		return
	if int(authority.call("get_heat_level")) != 1 or String(authority.call("get_wanted_state_name")) != "CONTACT":
		await _fail("WATCHLISTED return did not create Heat 1 + Contact")
		return
	if String(event.call("get_watchlist_label_text")) != "VEHICLE FLAGGED // HOLD":
		await _fail("Successful recognition lacks required checkpoint-local HOLD feedback")
		return
	event.call("_process", 0.5)
	if int(event.call("get_watchlist_report_attempt_count")) != 1:
		await _fail("WATCHLISTED encounter spammed duplicate civic Reports")
		return
	if bool(event.call("pay_toll")):
		await _fail("Ordinary toll incorrectly cleared WATCHLISTED recognition")
		return

	# A watchlisted player can still choose physical force.
	if not bool(event.call("ram_breach", 8.5)) or int(event.get("current_state")) != 3:
		await _fail("WATCHLISTED checkpoint could not be breached again")
		return

	# Control: another vehicle sees the ordinary toll standoff, not the claimed-Bike watchlist.
	_wanted_runtime.call("reset_runtime")
	_rearm_from_far(event, bike, checkpoint)
	_set_active_vehicle(player, hauler, bike)
	hauler.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.1)
	if int(event.get("current_state")) != 1:
		await _fail("Different vehicle incorrectly inherited claimed Courier Bike recognition")
		return
	if int(authority.call("get_heat_level")) != 0:
		await _fail("Ordinary different-vehicle approach created Wanted without a crime")
		return
	event.call("reset_world_event")

	# Control: on-foot return also remains ordinary.
	_set_on_foot(player, bike, hauler)
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.1)
	if int(event.get("current_state")) != 1:
		await _fail("On-foot return incorrectly inherited claimed Courier Bike recognition")
		return
	event.call("reset_world_event")

	# P02 composition: jam the physical Report link before the watchlisted Bike returns.
	_wanted_runtime.call("reset_runtime")
	_set_on_foot(player, bike, hauler)
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	_scene.set("_active_target", access)
	if not bool(_wanted_runtime.call("handle_action_pressed")):
		await _fail("Could not establish retained Field-Hacking suppression fixture")
		return
	if bool(alarm.get("report_enabled")):
		await _fail("Field-Hacking fixture did not suppress civic Report path")
		return

	_set_active_vehicle(player, bike, hauler)
	bike.global_position = checkpoint.global_position + Vector3(0.0, 0.0, 4.0)
	event.call("_process", 0.1)
	if int(event.get("current_state")) != 5:
		await _fail("Jammed return erased local WATCHLISTED recognition")
		return
	if int(authority.call("get_heat_level")) != 0 or String(authority.call("get_wanted_state_name")) != "CLEAR":
		await _fail("Jammed WATCHLISTED scan incorrectly created Wanted")
		return
	if String(event.call("get_watchlist_label_text")) != "VEHICLE FLAGGED // LINK FAULT":
		await _fail("Jammed recognition lacks required checkpoint-local LINK FAULT feedback")
		return
	if int(event.call("get_watchlist_report_attempt_count")) != 1:
		await _fail("Jammed recognition did not make exactly one bounded Report attempt")
		return

	# Full Replay clears local friction while retaining P11 ownership.
	_scene.call("reset_slice")
	await process_frame
	await process_frame
	if bool(event.call("is_courier_bike_watchlisted")):
		await _fail("Full Replay retained temporary checkpoint watchlist")
		return
	if not bool(claim_store.call("is_claimed")):
		await _fail("Full Replay incorrectly erased durable claimed Bike ownership")
		return
	if int(event.get("current_state")) != 0:
		await _fail("Full Replay did not restore checkpoint ARMED state")
		return

	print("[P15_CHECKPOINT_RECOGNITION] PASS")
	await _finish(0)
