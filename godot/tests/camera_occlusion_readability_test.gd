extends SceneTree

# Issue #13 RED-first contract: explicit camera occluders may be visually cut away
# without changing the retained dynamic camera/control frame or gameplay collision.

const CameraScript = preload("res://scripts/camera/camera_3d.gd")
const OCCLUSION_LAYER: int = 1 << 30

var _fixture_root: Node3D = null
var _camera: Camera3D = null
var _target: Node3D = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_fixture_root):
		_fixture_root.queue_free()
	await process_frame
	await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[CAMERA_OCCLUSION_13] %s" % message)
	await _finish(1)

func _make_occluder(name: String, position: Vector3, tagged: bool = true) -> Dictionary:
	var root_node := Node3D.new()
	root_node.name = name
	root_node.position = position
	if tagged:
		root_node.add_to_group("camera_occluder")
	_fixture_root.add_child(root_node)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.5, 1.5, 1.5)
	mesh_instance.mesh = mesh
	root_node.add_child(mesh_instance)

	var area := Area3D.new()
	area.name = "CameraOcclusionProxy"
	area.collision_layer = OCCLUSION_LAYER
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	root_node.add_child(area)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 1.5)
	collision.shape = shape
	area.add_child(collision)

	return {
		"root": root_node,
		"visual": mesh_instance,
		"area": area,
		"collision": collision,
		"initial_layer": area.collision_layer,
		"initial_mask": area.collision_mask,
		"initial_disabled": collision.disabled,
	}

func _property_exists(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false

func _run() -> void:
	_fixture_root = Node3D.new()
	_fixture_root.name = "CameraOcclusionFixture"
	root.add_child(_fixture_root)

	_target = Node3D.new()
	_target.name = "Target"
	_target.position = Vector3.ZERO
	_fixture_root.add_child(_target)

	_camera = CameraScript.new()
	_camera.name = "Camera"
	_fixture_root.add_child(_camera)
	_camera.call("reset_camera_instant", _target)
	await process_frame
	await physics_frame

	# RED on current main: #13 has no explicit occlusion capability yet.
	if not _camera.has_method("get_active_occluder_count"):
		await _fail("Camera occlusion capability is absent")
		return
	if not _property_exists(_camera, &"occlusion_enabled") or not _property_exists(_camera, &"occlusion_collision_mask"):
		await _fail("Camera occlusion configuration is not exposed")
		return
	if not _property_exists(_camera, &"max_occluders") or not _property_exists(_camera, &"occluder_restore_delay"):
		await _fail("Camera occlusion bounds are not exposed")
		return

	_camera.set("occlusion_enabled", true)
	_camera.set("occlusion_collision_mask", OCCLUSION_LAYER)
	_camera.set("max_occluders", 3)
	_camera.set("occluder_restore_delay", 0.25)

	var focus_point: Vector3 = _target.global_position + Vector3(0.0, 0.5, 0.0)
	var camera_point: Vector3 = _camera.global_position

	# A malformed proxy on the same layer but without the semantic group must be ignored
	# and must not prevent farther valid tagged occluders from being discovered.
	var untagged := _make_occluder("UntaggedProxy", camera_point.lerp(focus_point, 0.10), false)
	var occluders: Array[Dictionary] = []
	for i in range(4):
		occluders.append(_make_occluder(
			"Occluder%d" % (i + 1),
			camera_point.lerp(focus_point, 0.25 + float(i) * 0.18),
			true
		))

	await physics_frame
	await physics_frame

	var yaw_before := float(_camera.get("_current_yaw_rad"))
	var focus_before: Vector3 = _camera.get("_smoothed_focus_pos")
	var look_ahead_before: Vector3 = _camera.get("_smoothed_look_ahead")
	var fov_before := _camera.fov

	_camera.call("_process", 0.016)

	if int(_camera.call("get_active_occluder_count")) != 3:
		await _fail("Camera did not enforce the three-occluder cutaway cap")
		return
	if not bool(untagged["visual"].visible):
		await _fail("Untagged geometry was visually modified")
		return
	for i in range(3):
		if bool(occluders[i]["visual"].visible):
			await _fail("Tagged occluder %d was not cut away" % (i + 1))
			return
	if not bool(occluders[3]["visual"].visible):
		await _fail("Occluder cap was exceeded")
		return

	# The detection proxy/collider contract must be unchanged by visual cutaway.
	for entry in occluders:
		var area: Area3D = entry["area"]
		var collision: CollisionShape3D = entry["collision"]
		if area.collision_layer != int(entry["initial_layer"]) or area.collision_mask != int(entry["initial_mask"]):
			await _fail("Occlusion cutaway mutated collision routing")
			return
		if collision.disabled != bool(entry["initial_disabled"]):
			await _fail("Occlusion cutaway disabled a collision shape")
			return

	# Static-target occlusion must not perturb retained camera state.
	if abs(wrapf(float(_camera.get("_current_yaw_rad")) - yaw_before, -PI, PI)) > 0.0001:
		await _fail("Occlusion changed retained dynamic camera yaw")
		return
	if (_camera.get("_smoothed_focus_pos") as Vector3).distance_to(focus_before) > 0.0001:
		await _fail("Occlusion changed authoritative focus state")
		return
	if (_camera.get("_smoothed_look_ahead") as Vector3).distance_to(look_ahead_before) > 0.0001:
		await _fail("Occlusion changed look-ahead state")
		return
	if abs(_camera.fov - fov_before) > 0.0001:
		await _fail("Occlusion changed FOV for a static target")
		return

	# Clear the ray. Cutaways remain briefly hidden, then restore together.
	for entry in occluders:
		var node: Node3D = entry["root"]
		node.global_position += Vector3(100.0, 0.0, 0.0)
	await physics_frame
	await physics_frame

	for _i in range(4):
		_camera.call("_process", 0.05)
	for i in range(3):
		if bool(occluders[i]["visual"].visible):
			await _fail("Occluder restored before the configured clear delay")
			return

	for _i in range(2):
		_camera.call("_process", 0.05)
	if int(_camera.call("get_active_occluder_count")) != 0:
		await _fail("Cleared occluders did not leave active cutaway state")
		return
	for i in range(3):
		if not bool(occluders[i]["visual"].visible):
			await _fail("Cleared occluder %d did not restore" % (i + 1))
			return

	# Reset/replay must never leave world art hidden.
	var reset_entry: Dictionary = occluders[0]
	(reset_entry["root"] as Node3D).global_position = camera_point.lerp(focus_point, 0.40)
	await physics_frame
	await physics_frame
	_camera.call("_process", 0.016)
	if bool(reset_entry["visual"].visible):
		await _fail("Reset fixture occluder was not cut away before reset")
		return
	_camera.call("reset_camera_instant", _target)
	if not bool(reset_entry["visual"].visible) or int(_camera.call("get_active_occluder_count")) != 0:
		await _fail("Camera reset did not restore all cutaway visuals")
		return

	print("[CAMERA_OCCLUSION_13] PASS")
	await _finish(0)
