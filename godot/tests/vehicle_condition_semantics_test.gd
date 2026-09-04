extends SceneTree

const BIKE_SCENE := "res://scenes/vehicles/courier_bike.tscn"
const HAULER_SCENE := "res://scenes/vehicles/scrap_hauler.tscn"
const CONDITION_API := [
	"get_condition_name",
	"get_condition_load",
	"get_usable_max_speed",
	"apply_collision_condition",
	"repair_condition",
	"reset_condition",
	"get_condition_presentation_snapshot",
]

var _nodes: Array[Node] = []

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	await process_frame
	quit(code)

func _fail(message: String) -> void:
	push_error("[P07_VEHICLE_CONDITION] %s" % message)
	await _finish(1)

func _instantiate_vehicle(scene_path: String, node_name: String) -> Node:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return null
	var vehicle := packed.instantiate()
	if vehicle == null:
		return null
	vehicle.name = node_name
	root.add_child(vehicle)
	_nodes.append(vehicle)
	return vehicle

func _has_condition_api(vehicle: Node) -> bool:
	for method_name in CONDITION_API:
		if not vehicle.has_method(method_name):
			return false
	return vehicle.has_signal("condition_changed")

func _assert_vehicle_contract(vehicle: Node, label: String) -> String:
	if not _has_condition_api(vehicle):
		return "%s Production-07 condition API is absent" % label
	if String(vehicle.call("get_condition_name")) != "ROADWORTHY":
		return "%s did not start ROADWORTHY" % label
	if not is_zero_approx(float(vehicle.call("get_condition_load"))):
		return "%s did not start at zero internal condition load" % label

	var baseline := {
		"max_speed": float(vehicle.get("max_speed")),
		"max_reverse_speed": float(vehicle.get("max_reverse_speed")),
		"acceleration": float(vehicle.get("acceleration")),
		"braking_friction": float(vehicle.get("braking_friction")),
		"steering_speed": float(vehicle.get("steering_speed")),
	}

	if bool(vehicle.call("apply_collision_condition", 1.0, 3.5)):
		return "%s accepted a harmless sub-threshold contact" % label
	if not is_zero_approx(float(vehicle.call("get_condition_load"))):
		return "%s harmless contact changed condition load" % label

	if not bool(vehicle.call("apply_collision_condition", 1.0, 10.0)):
		return "%s rejected a severe head-on impact" % label
	if String(vehicle.call("get_condition_name")) != "BATTERED":
		return "%s severe head-on impact did not produce BATTERED" % label
	var first_load := float(vehicle.call("get_condition_load"))
	if first_load <= 0.0 or first_load >= 1.50:
		return "%s first severe impact produced unbounded load %.3f" % [label, first_load]
	if bool(vehicle.call("apply_collision_condition", 1.0, 10.0)):
		return "%s sustained-contact cooldown accepted an immediate duplicate" % label
	if not is_equal_approx(float(vehicle.call("get_condition_load")), first_load):
		return "%s cooldown rejection still mutated condition load" % label

	var battered_presentation = vehicle.call("get_condition_presentation_snapshot")
	if not (battered_presentation is Dictionary):
		return "%s condition presentation snapshot is not a Dictionary" % label
	if not bool(battered_presentation.get("damage_tag_visible", false)) or not bool(battered_presentation.get("smoke_emitting", false)):
		return "%s BATTERED state is not visibly represented" % label
	var condition_tag := vehicle.get_node_or_null("VehicleConditionTag") as Label3D
	if condition_tag == null:
		return "%s damage tag node is missing" % label
	if not condition_tag.no_depth_test or not condition_tag.fixed_size:
		return "%s damage tag can be occluded or shrink below readable production-camera size" % label

	vehicle.call("reset_condition")
	vehicle.set("_condition_contact_cooldown", 0.0)
	if not bool(vehicle.call("apply_collision_condition", 0.10, 10.0)):
		return "%s rejected matched-speed glancing impact" % label
	var glance_load := float(vehicle.call("get_condition_load"))
	vehicle.call("reset_condition")
	vehicle.set("_condition_contact_cooldown", 0.0)
	if not bool(vehicle.call("apply_collision_condition", 1.0, 10.0)):
		return "%s rejected matched-speed head-on comparison impact" % label
	var head_on_load := float(vehicle.call("get_condition_load"))
	if not head_on_load > glance_load:
		return "%s matched-speed head-on did not contribute more than glance (%.3f <= %.3f)" % [label, head_on_load, glance_load]

	# A second legitimate severe impact after elapsed cooldown must reach CRITICAL.
	vehicle.set("_condition_contact_cooldown", 0.0)
	if not bool(vehicle.call("apply_collision_condition", 1.0, 10.0)):
		return "%s rejected second legitimate severe impact" % label
	if String(vehicle.call("get_condition_name")) != "CRITICAL":
		return "%s repeated severe impacts did not produce CRITICAL" % label
	if not is_equal_approx(float(vehicle.call("get_usable_max_speed")), baseline.max_speed * 0.52):
		return "%s CRITICAL usable max speed is not the approved 0.52 limp cap" % label

	# Condition may not rewrite retained exported handling values.
	for key in baseline.keys():
		if not is_equal_approx(float(vehicle.get(key)), float(baseline[key])):
			return "%s condition rewrote retained handling export %s" % [label, key]

	# CRITICAL remains drivable forward and in reverse.
	vehicle.set("current_state", 2) # retained DRIVING enum value on both production controllers
	vehicle.set("current_speed", 0.0)
	vehicle.set("current_gear", 0)
	vehicle.call("set_drive_inputs", 1.0, 0.35, 1.0, false)
	var limp_speed := float(vehicle.get("current_speed"))
	if limp_speed <= 0.0 or limp_speed > float(vehicle.call("get_usable_max_speed")) + 0.001:
		return "%s CRITICAL forward drive is not a bounded non-zero limp" % label
	vehicle.set("current_speed", 0.0)
	vehicle.set("current_gear", 1) # retained REVERSE enum value
	vehicle.set("_gear_settle_timer", 0.0)
	vehicle.call("set_drive_inputs", -1.0, -0.35, 1.0, false)
	var reverse_speed := float(vehicle.get("current_speed"))
	if reverse_speed >= 0.0 or reverse_speed < float(baseline.max_reverse_speed) - 0.001:
		return "%s CRITICAL reverse is unavailable or exceeds retained reverse limit" % label

	if not bool(vehicle.call("repair_condition")):
		return "%s damaged repair did not restore condition" % label
	if String(vehicle.call("get_condition_name")) != "ROADWORTHY" or not is_zero_approx(float(vehicle.call("get_condition_load"))):
		return "%s repair did not restore ROADWORTHY baseline" % label
	if bool(vehicle.call("repair_condition")):
		return "%s repair was not idempotent once ROADWORTHY" % label
	if not is_equal_approx(float(vehicle.call("get_usable_max_speed")), baseline.max_speed):
		return "%s repair did not restore ordinary usable max speed" % label
	var clean_presentation = vehicle.call("get_condition_presentation_snapshot")
	if bool(clean_presentation.get("damage_tag_visible", true)) or bool(clean_presentation.get("smoke_emitting", true)):
		return "%s ROADWORTHY presentation still shows damage" % label

	return ""

func _run() -> void:
	var bike := _instantiate_vehicle(BIKE_SCENE, "P07Bike")
	var hauler := _instantiate_vehicle(HAULER_SCENE, "P07Hauler")
	if bike == null or hauler == null:
		await _fail("Production vehicle scenes could not instantiate")
		return
	await process_frame

	if not _has_condition_api(bike) or not _has_condition_api(hauler):
		await _fail("Production-07 condition surfaces are absent on the retained production vehicles")
		return

	# Independence is explicit: damaging one production vehicle may not mutate the other.
	bike.call("reset_condition")
	hauler.call("reset_condition")
	bike.set("_condition_contact_cooldown", 0.0)
	bike.call("apply_collision_condition", 1.0, 10.0)
	if String(bike.call("get_condition_name")) != "BATTERED" or String(hauler.call("get_condition_name")) != "ROADWORTHY":
		await _fail("Courier Bike and Scrap Hauler condition are not independent")
		return
	bike.call("reset_condition")

	var bike_error := _assert_vehicle_contract(bike, "CourierBike")
	if bike_error != "":
		await _fail(bike_error)
		return
	var hauler_error := _assert_vehicle_contract(hauler, "ScrapHauler")
	if hauler_error != "":
		await _fail(hauler_error)
		return

	print("[P07_VEHICLE_CONDITION] PASS")
	await _finish(0)