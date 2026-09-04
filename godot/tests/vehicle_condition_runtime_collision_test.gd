extends SceneTree

const BIKE_SCENE := "res://scenes/vehicles/courier_bike.tscn"
const HAULER_SCENE := "res://scenes/vehicles/scrap_hauler.tscn"
const PHYSICS_DT := 1.0 / 60.0

var _nodes: Array[Node] = []

func _init() -> void:
	call_deferred("_run")

func _finish(code: int) -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	await process_frame
	await physics_frame
	quit(code)

func _fail(message: String) -> void:
	push_error("[P07_REAL_COLLISION_RUNTIME] %s" % message)
	await _finish(1)

func _make_wall() -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.name = "P07RuntimeImpactWall"
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8.0, 4.0, 0.5)
	shape_node.shape = shape
	wall.add_child(shape_node)
	wall.global_position = Vector3(0.0, 1.0, 0.0)
	root.add_child(wall)
	_nodes.append(wall)
	return wall

func _make_vehicle(scene_path: String, node_name: String) -> Node:
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

func _prime_drive(vehicle: Node, z_start: float, impact_speed: float = 10.0) -> void:
	vehicle.global_position = Vector3(0.0, 0.0, z_start)
	vehicle.global_rotation = Vector3.ZERO
	vehicle.set("velocity", Vector3.ZERO)
	vehicle.set("current_state", 2) # retained DRIVING enum value on both production vehicles
	vehicle.set("current_gear", 0) # retained FORWARD enum value
	vehicle.set("current_speed", impact_speed)
	vehicle.set("steering_angle", 0.0)
	vehicle.set("is_handbrake_active", false)

func _drive_until_condition_changes(vehicle: Node, max_frames: int = 90) -> bool:
	for _frame in range(max_frames):
		await physics_frame
		if String(vehicle.call("get_condition_name")) != "ROADWORTHY":
			return true
	return false

func _drive_until_critical(vehicle: Node, z_start: float, max_frames: int = 90) -> bool:
	vehicle.set("_condition_contact_cooldown", 0.0)
	_prime_drive(vehicle, z_start, 10.0)
	for _frame in range(max_frames):
		await physics_frame
		if String(vehicle.call("get_condition_name")) == "CRITICAL":
			return true
	return false

func _prove_real_collision(vehicle: Node, label: String, z_start: float) -> String:
	if vehicle == null or not vehicle.has_signal("collision_contact"):
		return "%s collision telemetry is unavailable" % label
	if not vehicle.has_method("get_condition_name"):
		return "%s P07 condition API is unavailable" % label

	var telemetry := {"count": 0, "max_impact": 0.0, "max_head_on": 0.0}
	vehicle.collision_contact.connect(func(head_on_ratio: float, impact_speed: float, _collision_pos: Vector3) -> void:
		telemetry.count = int(telemetry.count) + 1
		telemetry.max_impact = maxf(float(telemetry.max_impact), impact_speed)
		telemetry.max_head_on = maxf(float(telemetry.max_head_on), head_on_ratio)
	)

	vehicle.call("reset_condition")
	_prime_drive(vehicle, z_start, 10.0)
	if not await _drive_until_condition_changes(vehicle):
		return "%s real move_and_slide collision never changed condition" % label
	if int(telemetry.count) <= 0:
		return "%s condition changed without real collision_contact telemetry" % label
	if float(telemetry.max_impact) < 4.0 or float(telemetry.max_head_on) < 0.75:
		return "%s runtime fixture did not produce a meaningful head-on impact (speed=%.3f head_on=%.3f)" % [label, float(telemetry.max_impact), float(telemetry.max_head_on)]
	if String(vehicle.call("get_condition_name")) != "BATTERED":
		return "%s first real severe collision did not stop at BATTERED" % label

	var first_load := float(vehicle.call("get_condition_load"))
	var telemetry_after_first := int(telemetry.count)
	# Keep processing the same wall contact for a few frames: neutral collision
	# telemetry may repeat, but accepted condition load may not melt through cooldown.
	for _frame in range(5):
		await physics_frame
	if int(telemetry.count) <= telemetry_after_first:
		return "%s sustained wall contact did not exercise repeated collision callbacks" % label
	if not is_equal_approx(float(vehicle.call("get_condition_load")), first_load):
		return "%s sustained collision callbacks bypassed condition cooldown" % label

	if not await _drive_until_critical(vehicle, z_start):
		return "%s second distinct real severe impact did not produce CRITICAL" % label
	return ""

func _prove_critical_limp(vehicle: Node, label: String) -> String:
	if String(vehicle.call("get_condition_name")) != "CRITICAL":
		return "%s limp proof did not start CRITICAL" % label
	var usable_cap := float(vehicle.call("get_usable_max_speed"))
	if usable_cap <= 0.0:
		return "%s CRITICAL usable cap is zero" % label

	vehicle.global_position = Vector3(0.0, 0.0, 6.0)
	vehicle.global_rotation = Vector3.ZERO
	vehicle.set("velocity", Vector3.ZERO)
	vehicle.set("current_state", 2)
	vehicle.set("current_gear", 0)
	vehicle.set("current_speed", 0.0)
	var start_pos: Vector3 = vehicle.global_position
	for _frame in range(120):
		vehicle.call("set_drive_inputs", 1.0, 0.28, PHYSICS_DT, false)
		await physics_frame
	var forward_distance := vehicle.global_position.distance_to(start_pos)
	var forward_speed := float(vehicle.get("current_speed"))
	if forward_distance < 2.0:
		return "%s CRITICAL vehicle did not physically limp forward (distance=%.3f)" % [label, forward_distance]
	if forward_speed <= 0.0 or forward_speed > usable_cap + 0.05:
		return "%s CRITICAL runtime speed escaped limp cap (speed=%.3f cap=%.3f)" % [label, forward_speed, usable_cap]
	if abs(vehicle.global_rotation.y) < 0.03:
		return "%s CRITICAL runtime steering produced no heading change" % label

	vehicle.set("velocity", Vector3.ZERO)
	vehicle.set("current_speed", 0.0)
	vehicle.set("current_gear", 1)
	vehicle.set("_gear_settle_timer", 0.0)
	var reverse_start: Vector3 = vehicle.global_position
	for _frame in range(60):
		vehicle.call("set_drive_inputs", -1.0, 0.0, PHYSICS_DT, false)
		await physics_frame
	if float(vehicle.get("current_speed")) >= -0.05:
		return "%s CRITICAL runtime reverse never engaged" % label
	if vehicle.global_position.distance_to(reverse_start) < 0.5:
		return "%s CRITICAL runtime reverse produced no physical movement" % label
	return ""

func _run() -> void:
	var wall := _make_wall()
	var bike := _make_vehicle(BIKE_SCENE, "P07RuntimeBike")
	if wall == null or bike == null:
		await _fail("Could not create Bike runtime collision fixture")
		return
	await physics_frame
	await process_frame

	var bike_collision_error := await _prove_real_collision(bike, "CourierBike", 4.0)
	if bike_collision_error != "":
		await _fail(bike_collision_error)
		return

	# Remove impact geometry before proving that CRITICAL is still a controllable
	# pressure state rather than hidden immobilization.
	wall.queue_free()
	_nodes.erase(wall)
	await physics_frame
	await process_frame
	var bike_limp_error := await _prove_critical_limp(bike, "CourierBike")
	if bike_limp_error != "":
		await _fail(bike_limp_error)
		return

	bike.queue_free()
	_nodes.erase(bike)
	await physics_frame

	var hauler_wall := _make_wall()
	var hauler := _make_vehicle(HAULER_SCENE, "P07RuntimeHauler")
	if hauler_wall == null or hauler == null:
		await _fail("Could not create Hauler runtime collision fixture")
		return
	await physics_frame
	await process_frame
	var hauler_collision_error := await _prove_real_collision(hauler, "ScrapHauler", 5.5)
	if hauler_collision_error != "":
		await _fail(hauler_collision_error)
		return

	print("[P07_REAL_COLLISION_RUNTIME] PASS")
	await _finish(0)