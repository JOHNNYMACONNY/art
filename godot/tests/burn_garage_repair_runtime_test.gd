extends SceneTree

const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"

var _scene: Node = null
var _wanted_runtime: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	if _wanted_runtime != null:
		if _wanted_runtime.has_method("reset_runtime"):
			_wanted_runtime.call("reset_runtime")
		_wanted_runtime.set_process(true)
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	quit(code)

func _fail(message: String) -> void:
	push_error("[P07_BURN_GARAGE_REPAIR] %s" % message)
	await _finish(1)

func _damage_once(vehicle: Node) -> bool:
	if vehicle == null or not vehicle.has_method("apply_collision_condition"):
		return false
	vehicle.call("reset_condition")
	vehicle.set("_condition_contact_cooldown", 0.0)
	return bool(vehicle.call("apply_collision_condition", 1.0, 10.0))

func _run() -> void:
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

	if not bool(_wanted_runtime.call("bind_to_scene", _scene)):
		await _fail("Wanted runtime did not bind to production scene")
		return
	_wanted_runtime.set_process(false)
	_wanted_runtime.call("reset_runtime")

	var runtime := _scene.get_node_or_null("BurnGarageRepairRuntime")
	if runtime == null:
		await _fail("Production-07 BurnGarageRepairRuntime is absent")
		return
	for method_name in ["get_repair_socket_position", "get_repair_interactable", "get_affordance_text", "attempt_repair", "is_vehicle_in_repair_radius"]:
		if not runtime.has_method(method_name):
			await _fail("BurnGarageRepairRuntime is missing %s" % method_name)
			return
	var repair_label := runtime.get_node_or_null("BurnGarageRepairAffordance") as Label3D
	if repair_label == null:
		await _fail("Burn Garage repair affordance label is missing")
		return
	if not repair_label.no_depth_test or not repair_label.fixed_size:
		await _fail("Burn Garage repair affordance can be occluded or shrink below readable production-camera size")
		return
	if repair_label.font_size < 5 or repair_label.font_size > 8 or repair_label.outline_size > 3:
		await _fail("Burn Garage fixed-size repair affordance exceeds bounded readable screen footprint")
		return

	var bike = _scene.get("courier_bike")
	var hauler = _scene.get("scrap_hauler")
	if bike == null or hauler == null:
		await _fail("Production vehicles are missing")
		return
	if not bike.has_method("apply_collision_condition") or not hauler.has_method("apply_collision_condition"):
		await _fail("Production-07 vehicle condition API is absent")
		return

	var district := _scene.get_node_or_null("GearsDistrictSlice01B")
	var socket := district.get_node_or_null("MissionDestinationSocket") as Marker3D if district != null else null
	if socket == null:
		await _fail("Retained MissionDestinationSocket is missing")
		return
	var runtime_socket: Vector3 = runtime.call("get_repair_socket_position")
	if runtime_socket.distance_to(socket.global_position) > 0.001:
		await _fail("P07 repair point is not mounted at the authored MissionDestinationSocket")
		return

	if not _damage_once(bike) or String(bike.call("get_condition_name")) != "BATTERED":
		await _fail("Could not establish damaged Bike fixture")
		return
	_scene.set("active_vehicle", bike)
	bike.global_position = socket.global_position + Vector3(12.0, 0.0, 0.0)
	bike.set("current_speed", 0.0)
	if bool(runtime.call("is_vehicle_in_repair_radius", bike)) or bool(runtime.call("attempt_repair", bike)):
		await _fail("Repair succeeded outside Burn Garage radius")
		return

	bike.global_position = socket.global_position
	bike.set("current_speed", 1.0)
	if not bool(runtime.call("is_vehicle_in_repair_radius", bike)):
		await _fail("Bike at authored socket is not inside repair radius")
		return
	if bool(runtime.call("attempt_repair", bike)) or String(bike.call("get_condition_name")) != "BATTERED":
		await _fail("Moving damaged vehicle repaired")
		return

	var authority = _wanted_runtime.get("wanted_authority")
	if authority == null:
		await _fail("WantedAuthority is unavailable")
		return
	bike.set("current_speed", 0.0)

	if not bool(authority.call("submit_report", "p07_test", bike.global_position, Vector3.FORWARD, "p07_test_observer")):
		await _fail("Could not establish authoritative CONTACT fixture")
		return
	var contact_heat := int(_wanted_runtime.call("get_heat_level"))
	var contact_state := String(_wanted_runtime.call("get_wanted_state_name"))
	if contact_state != "CONTACT":
		await _fail("Wanted fixture did not enter CONTACT")
		return
	var contact_load := float(bike.call("get_condition_load"))
	if bool(runtime.call("attempt_repair", bike)):
		await _fail("Burn Garage repaired during CONTACT")
		return
	if int(_wanted_runtime.call("get_heat_level")) != contact_heat or String(_wanted_runtime.call("get_wanted_state_name")) != contact_state:
		await _fail("Rejected CONTACT repair mutated Wanted authority")
		return
	if not is_equal_approx(float(bike.call("get_condition_load")), contact_load):
		await _fail("Rejected CONTACT repair mutated vehicle condition")
		return

	if not bool(authority.call("lose_contact", bike.global_position, Vector3.FORWARD, "p07_test_loss")):
		await _fail("Could not establish authoritative SEARCH fixture")
		return
	if String(_wanted_runtime.call("get_wanted_state_name")) != "SEARCH":
		await _fail("Wanted fixture did not enter SEARCH")
		return
	if bool(runtime.call("attempt_repair", bike)):
		await _fail("Burn Garage repaired during SEARCH")
		return
	if String(bike.call("get_condition_name")) != "BATTERED":
		await _fail("SEARCH rejection changed condition")
		return

	authority.call("reset")
	var before_clear_heat := int(_wanted_runtime.call("get_heat_level"))
	var before_clear_state := String(_wanted_runtime.call("get_wanted_state_name"))
	if before_clear_heat != 0 or before_clear_state != "CLEAR":
		await _fail("Could not restore CLEAR fixture")
		return
	if not bool(runtime.call("attempt_repair", bike)):
		await _fail("Eligible CLEAR/stopped Garage repair failed")
		return
	if String(bike.call("get_condition_name")) != "ROADWORTHY":
		await _fail("Successful repair did not restore ROADWORTHY")
		return
	if bool(runtime.call("attempt_repair", bike)):
		await _fail("ROADWORTHY vehicle repaired more than once")
		return
	if int(_wanted_runtime.call("get_heat_level")) != before_clear_heat or String(_wanted_runtime.call("get_wanted_state_name")) != before_clear_state:
		await _fail("Successful repair mutated Wanted authority")
		return

	runtime.set("_success_until_msec", 0)

	if not _damage_once(hauler):
		await _fail("Could not establish damaged Hauler fixture")
		return
	hauler.global_position = socket.global_position
	hauler.set("current_speed", 0.0)
	_scene.set("active_vehicle", hauler)
	if runtime.has_method("_process"):
		runtime.call("_process", 0.0)
	var interactable = runtime.call("get_repair_interactable")
	if interactable == null:
		await _fail("Garage repair interactable is missing")
		return
	var root_interactables = _scene.get("_interactables")
	if not (root_interactables is Array) or not root_interactables.has(interactable):
		await _fail("Garage repair interactable is not registered in the retained root interaction list")
		return
	if _scene.call("_get_active_vehicle") != hauler:
		await _fail("Retained generic active-vehicle seam does not resolve the Scrap Hauler")
		return
	if not bool(interactable.get("is_powered")):
		await _fail("Garage repair interactable is registered but unpowered; affordance=%s success_until=%d now=%d" % [String(runtime.call("get_affordance_text")), int(runtime.get("_success_until_msec")), Time.get_ticks_msec()])
		return
	interactable.call("update_player_distance", hauler.global_position)
	if not bool(interactable.get("is_player_in_range")):
		await _fail("Garage repair interactable is powered but out of range; target=%s vehicle=%s" % [str(interactable.global_position), str(hauler.global_position)])
		return
	_scene.call("_evaluate_target_selection")
	if _scene.get("_active_target") != interactable:
		var selected = _scene.get("_active_target")
		var selected_name := String(selected.name) if selected != null else "<none>"
		var selected_score: float = -9999.0
		if selected != null:
			selected_score = float(selected.call("get_interaction_priority")) * 10.0 - selected.global_position.distance_to(hauler.global_position)
		var repair_score: float = float(interactable.call("get_interaction_priority")) * 10.0 - interactable.global_position.distance_to(hauler.global_position)
		await _fail("Garage target lost retained selector despite registration/range; selected=%s selected_score=%.3f repair_score=%.3f" % [selected_name, selected_score, repair_score])
		return
	if String(runtime.call("get_affordance_text")).is_empty():
		await _fail("Damaged vehicle near Garage has no clear repair affordance")
		return

	var touch_ui := _scene.get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null:
		await _fail("Retained TouchControlsUI is missing")
		return
	touch_ui.action_button_pressed.emit()
	await process_frame
	if String(hauler.call("get_condition_name")) != "ROADWORTHY":
		await _fail("Eligible Scrap Hauler did not repair through retained Action routing")
		return

	print("[P07_BURN_GARAGE_REPAIR] PASS")
	await _finish(0)