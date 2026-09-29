extends SceneTree

const BIKE_SCENE := "res://scenes/vehicles/courier_bike.tscn"

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
	push_error("[P14_BASH_BAR_DIRECTION] " + message)
	await _finish(1)

func _make_wall() -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.name = "P14DirectionWall"
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8.0, 4.0, 0.5)
	shape_node.shape = shape
	wall.add_child(shape_node)
	wall.global_position = Vector3(0.0, 1.0, 0.0)
	root.add_child(wall)
	_nodes.append(wall)
	return wall

func _make_bike(name_value: String) -> CourierBike:
	var packed := load(BIKE_SCENE) as PackedScene
	if packed == null:
		return null
	var bike := packed.instantiate() as CourierBike
	if bike == null:
		return null
	bike.name = name_value
	root.add_child(bike)
	_nodes.append(bike)
	return bike

func _prime(bike: CourierBike, z_start: float, signed_speed: float) -> void:
	bike.global_position = Vector3(0.0, 0.0, z_start)
	bike.global_rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	bike.current_state = CourierBike.BikeState.DRIVING
	bike.current_gear = CourierBike.GearState.FORWARD if signed_speed >= 0.0 else CourierBike.GearState.REVERSE
	bike.current_speed = signed_speed
	bike.steering_angle = 0.0
	bike.is_handbrake_active = false
	bike.reset_condition()
	bike.set_scrap_bash_bar_installed(true)

func _wait_for_first_condition_load(bike: CourierBike, max_frames: int = 90) -> bool:
	for _frame in range(max_frames):
		await physics_frame
		if float(bike.get_condition_load()) > 0.0:
			return true
	return false

func _run() -> void:
	var wall := _make_wall()
	var forward_bike := _make_bike("P14ForwardBike")
	if wall == null or forward_bike == null:
		await _fail("Could not create forward physical fixture")
		return
	await physics_frame
	await process_frame

	var forward_telemetry := {"count": 0, "max_head_on": 0.0, "max_impact": 0.0}
	forward_bike.collision_contact.connect(func(head_on_ratio: float, impact_speed: float, _collision_pos: Vector3) -> void:
		forward_telemetry.count = int(forward_telemetry.count) + 1
		forward_telemetry.max_head_on = maxf(float(forward_telemetry.max_head_on), head_on_ratio)
		forward_telemetry.max_impact = maxf(float(forward_telemetry.max_impact), impact_speed)
	)
	_prime(forward_bike, 4.0, 10.0)
	if not await _wait_for_first_condition_load(forward_bike):
		await _fail("Forward fitted Bike never produced condition load")
		return
	if int(forward_telemetry.count) <= 0 or float(forward_telemetry.max_head_on) < 0.75:
		await _fail("Forward fixture did not produce meaningful head-on telemetry")
		return
	if String(forward_bike.get_condition_name()) != "ROADWORTHY":
		await _fail("Fitted forward impact was not protected")
		return
	if float(forward_bike.get_condition_load()) >= 0.75:
		await _fail("Fitted forward impact load escaped bash-bar protection")
		return

	forward_bike.queue_free()
	_nodes.erase(forward_bike)
	await physics_frame
	await process_frame

	var reverse_bike := _make_bike("P14ReverseBike")
	if reverse_bike == null:
		await _fail("Could not create reverse physical fixture")
		return
	await physics_frame
	await process_frame

	var reverse_telemetry := {"count": 0, "max_head_on": 0.0, "max_impact": 0.0}
	reverse_bike.collision_contact.connect(func(head_on_ratio: float, impact_speed: float, _collision_pos: Vector3) -> void:
		reverse_telemetry.count = int(reverse_telemetry.count) + 1
		reverse_telemetry.max_head_on = maxf(float(reverse_telemetry.max_head_on), head_on_ratio)
		reverse_telemetry.max_impact = maxf(float(reverse_telemetry.max_impact), impact_speed)
	)
	_prime(reverse_bike, -4.0, -10.0)
	if not await _wait_for_first_condition_load(reverse_bike):
		await _fail("Reverse fitted Bike never produced condition load")
		return
	if int(reverse_telemetry.count) <= 0 or float(reverse_telemetry.max_head_on) < 0.75:
		await _fail("Reverse fixture did not produce meaningful square-impact telemetry")
		return
	if String(reverse_bike.get_condition_name()) != "BATTERED":
		await _fail("Rear impact incorrectly received front bash-bar protection")
		return
	if float(reverse_bike.get_condition_load()) < 0.75:
		await _fail("Rear impact load was incorrectly reduced")
		return

	print("[P14_BASH_BAR_DIRECTION] PASS")
	await _finish(0)
