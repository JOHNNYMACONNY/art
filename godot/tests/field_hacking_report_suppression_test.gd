extends SceneTree

var _scene_under_test: Node = null
var _runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[FIELD_HACKING_REPORT_SUPPRESSION] %s" % message)
	await _finish(1)

func _state(authority) -> String:
	return String(authority.call("get_wanted_state_name"))

func _heat(authority) -> int:
	return int(authority.call("get_heat_level"))

func _run() -> void:
	_runtime = root.get_node_or_null("BurnsideWantedRuntime")
	if _runtime == null:
		await _fail("BurnsideWantedRuntime autoload is absent")
		return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	_runtime.call("bind_to_scene", _scene_under_test)
	await process_frame

	var player := _scene_under_test.get_node_or_null("Runner") as Node3D
	var alarm := _scene_under_test.get_node_or_null("CivicServiceAlarm")
	var access := _scene_under_test.get_node_or_null("CivicReportAccess")
	var authority = _runtime.get("wanted_authority")
	if player == null or alarm == null or authority == null:
		await _fail("Production scene is missing Runner, CivicServiceAlarm, or WantedAuthority")
		return
	if access == null:
		await _fail("Physical civic report Access Path is absent")
		return
	if not access.has_method("reset_access"):
		await _fail("Civic report Access Path lacks deterministic recovery")
		return
	if float(access.get("interaction_radius")) > 2.5:
		await _fail("Field Hacking access radius is too broad for a physical/local Access Path")
		return

	# Access Is the Puzzle: physically reach the service point, then interference is immediate.
	player.global_position = access.global_position + Vector3(0.8, 0.0, 0.0)
	access.call("update_player_distance", player.global_position)
	_scene_under_test.set("_active_target", access)
	if not bool(_runtime.call("handle_action_pressed")):
		await _fail("Local civic service access did not execute Field Hacking interference")
		return
	if bool(alarm.get("report_enabled")):
		await _fail("Successful Field Hacking did not suppress the local civic Report path")
		return
	var access_label := access.get_node_or_null("StatusLabel") as Label3D
	if access_label == null or not access_label.text.contains("REPORT LINK JAMMED"):
		await _fail("Compromised civic reporting state lacks readable local feedback")
		return

	# The same incident now fails to create Wanted because its Report path was prevented.
	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	_scene_under_test.set("_active_target", alarm)
	if not bool(_runtime.call("handle_action_pressed")):
		await _fail("Compromised civic alarm could not be triggered")
		return
	if _heat(authority) != 0 or _state(authority) != "CLEAR":
		await _fail("Suppressed Report incorrectly created Wanted state")
		return

	# Replay/service recovery restores both the access point and ordinary Report behavior.
	_runtime.call("reset_runtime")
	if not bool(alarm.get("report_enabled")):
		await _fail("Replay did not restore civic reporting service")
		return
	var restored_label := access.get_node_or_null("StatusLabel") as Label3D
	if restored_label == null or not restored_label.text.contains("SERVICE TAP"):
		await _fail("Replay did not restore readable civic access state")
		return

	player.global_position = alarm.global_position + Vector3(0.8, 0.0, 0.0)
	alarm.call("update_player_distance", player.global_position)
	_scene_under_test.set("_active_target", alarm)
	if not bool(_runtime.call("handle_action_pressed")):
		await _fail("Restored civic alarm could not be triggered")
		return
	if _heat(authority) != 1 or _state(authority) != "CONTACT":
		await _fail("Restored civic Report path did not create Heat 1 + Contact")
		return

	print("[FIELD_HACKING_REPORT_SUPPRESSION] PASS")
	await _finish(0)
